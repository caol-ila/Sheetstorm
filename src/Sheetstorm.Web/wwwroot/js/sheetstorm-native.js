/* Sheetstorm Native Bridge — Pure-Broadcast-Modus (V2).
 *
 * Architektur (siehe docs/14):
 *   Conductor:
 *     - generiert Ed25519-Keypair lokal (WebCrypto)
 *     - meldet Public-Key per HTTPS an /api/events/{id}/conductor-key
 *     - baut Tempo-/Piece-Pakete, signiert sie, übergibt sie an das
 *       native BLE-Plugin (Android, Capacitor) das sie permanent
 *       als Manufacturer-Data im Extended Advertising sendet.
 *
 *   Follower:
 *     - Web-Bluetooth `requestLEScan({acceptAllAdvertisements:true})`
 *       (auf Edge/Chrome ab ~118; experimental, "Experimental
 *       Web Platform features" Flag muss an sein)
 *     - Native Capacitor `BleClient.requestLEScan` mit Service-UUID
 *     - filtert auf Sheetstorm-Service-UUID + Manufacturer-IDs
 *     - verifiziert Ed25519-Sig
 *     - aktualisiert lokalen WebAudio-Click-Scheduler mit Anchor+BPM
 *
 * Pakete-Format (verbatim als Manufacturer-Data):
 *   Tempo (~87 Byte):
 *     u64 nonce          (8)   monoton steigend, anti-replay
 *     u64 anchor_ms      (8)   Performance.now()-Wert beim Anker
 *     u32 beat_idx       (4)   Beat-Nummer am Anker
 *     u16 bpm_x100       (2)   z.B. 12000 = 120.00 bpm
 *     u8  meter_num      (1)   z.B. 4
 *     u8  flags          (1)   bit0=clickActive, bit1=isFermate
 *     u8[64] sig                Ed25519 über (alle Felder davor)
 *   Piece (~variabel):
 *     u64 nonce          (8)
 *     u8[16] piece_id    (16)  GUID
 *     u8[N] title_utf8   (N)   bis zu 50 Bytes
 *     u8[64] sig                Ed25519 über (alle Felder davor)
 */
const SHEETSTORM_SERVICE   = '0000f517-7e5f-7e57-0000-000000000000';
const MANUFACTURER_TEMPO   = 0xFFFE;
const MANUFACTURER_PIECE   = 0xFFFD;

function isCapacitor() {
  return !!(window.Capacitor && typeof window.Capacitor.isNativePlatform === 'function' && window.Capacitor.isNativePlatform());
}
function hasWebBluetooth() {
  return typeof navigator !== 'undefined' && !!navigator.bluetooth;
}
function hasWebBluetoothScan() {
  return hasWebBluetooth() && typeof navigator.bluetooth.requestLEScan === 'function';
}

async function loadCapBle() {
  if (!isCapacitor()) return null;
  try { return (await import('@capacitor-community/bluetooth-le')).BleClient; }
  catch (e) { console.warn('Capacitor BLE-Plugin nicht verfügbar:', e); return null; }
}

function bytesToB64(u8) { let s = ''; for (const b of u8) s += String.fromCharCode(b); return btoa(s); }
function b64ToBytes(b64) { const bin = atob(b64); const u = new Uint8Array(bin.length); for (let i=0;i<bin.length;i++) u[i]=bin.charCodeAt(i); return u; }

window.SheetstormNative = {
  get isCapacitor() { return isCapacitor(); },
  get hasWebBluetooth() { return hasWebBluetooth(); },
  get hasWebBluetoothScan() { return hasWebBluetoothScan(); },
  get bleAvailable() { return isCapacitor() || hasWebBluetooth(); },
  get bleScanAvailable() { return isCapacitor() || hasWebBluetoothScan(); },

  serviceUuid: SHEETSTORM_SERVICE,
  manufacturerIdTempo: MANUFACTURER_TEMPO,
  manufacturerIdPiece: MANUFACTURER_PIECE,

  /* ---------- Crypto ---------- */
  async generateConductorKey() {
    if (!window.crypto?.subtle) throw new Error('WebCrypto fehlt');
    const kp = await crypto.subtle.generateKey({ name: 'Ed25519' }, true, ['sign', 'verify']);
    const pubRaw  = await crypto.subtle.exportKey('raw',   kp.publicKey);
    const privRaw = await crypto.subtle.exportKey('pkcs8', kp.privateKey);
    return { publicKey: bytesToB64(new Uint8Array(pubRaw)), privateKey: bytesToB64(new Uint8Array(privRaw)) };
  },
  async importPrivateKey(b64) {
    return await crypto.subtle.importKey('pkcs8', b64ToBytes(b64), { name: 'Ed25519' }, false, ['sign']);
  },
  async importPublicKey(b64) {
    return await crypto.subtle.importKey('raw', b64ToBytes(b64), { name: 'Ed25519' }, false, ['verify']);
  },
  async signBytes(privKey, bytes) {
    return new Uint8Array(await crypto.subtle.sign({ name: 'Ed25519' }, privKey, bytes));
  },
  async verifyBytes(pubKey, sig, bytes) {
    try { return await crypto.subtle.verify({ name: 'Ed25519' }, pubKey, sig, bytes); }
    catch { return false; }
  },

  /* ---------- Conductor ---------- */
  async startConductor() {
    if (!isCapacitor()) throw new Error('Conductor-Mode benötigt die native App.');
    const plugin = window.Capacitor.Plugins.SheetstormBleAdvertiser;
    if (!plugin) throw new Error('Plugin SheetstormBleAdvertiser nicht installiert.');
    return await plugin.start();
  },
  async stopConductor() {
    if (!isCapacitor()) return;
    const plugin = window.Capacitor.Plugins.SheetstormBleAdvertiser;
    if (plugin) try { await plugin.stop(); } catch { }
  },

  /**
   * Setzt das aktuelle Tempo-Paket. Plugin re-broadcastet automatisch.
   * @param {string} privateKeyB64 Conductor private key (pkcs8 base64)
   * @param {{nonce:bigint, anchorMs:number, beatIdx:number, bpm:number, meter:number, click:boolean}} t
   */
  async broadcastTempo(privateKeyB64, t) {
    const buf = new ArrayBuffer(24);
    const dv = new DataView(buf);
    const nonce = typeof t.nonce === 'bigint' ? t.nonce : BigInt(t.nonce ?? 0);
    dv.setBigUint64(0,  nonce, true);
    dv.setBigUint64(8,  BigInt(Math.round(t.anchorMs)), true);
    dv.setUint32(16,    (t.beatIdx | 0) >>> 0, true);
    dv.setUint16(20,    Math.round(t.bpm * 100) & 0xFFFF, true);
    dv.setUint8(22,     t.meter & 0xFF);
    dv.setUint8(23,     (t.click ? 1 : 0) | (t.fermate ? 2 : 0));
    if (window.__SS_BLE_DEBUG) console.log('[ss-ble] broadcastTempo bpm=', t.bpm, 'beatIdx=', t.beatIdx);
    const payload = new Uint8Array(buf);
    const priv = await this.importPrivateKey(privateKeyB64);
    const sig = await this.signBytes(priv, payload);
    const packet = new Uint8Array(payload.length + sig.length);
    packet.set(payload, 0); packet.set(sig, payload.length);

    if (isCapacitor()) {
      const plugin = window.Capacitor.Plugins.SheetstormBleAdvertiser;
      if (!plugin) throw new Error('Plugin nicht installiert.');
      return await plugin.setTempo({ data: bytesToB64(packet) });
    }
    // Web-Konduktor (Edge/Chrome) kann selbst nicht advertisen — wir
    // emit-en das Paket nur als Event, damit der Web-Loopback-Test
    // funktioniert.
    window.dispatchEvent(new CustomEvent('ss-tempo-loop', { detail: { packet } }));
    return { ok: true, web: true };
  },

  /**
   * Setzt das aktuelle Piece-Paket.
   * @param {string} privateKeyB64
   * @param {{nonce:bigint, pieceId:string, title:string}} p
   */
  async broadcastPiece(privateKeyB64, p) {
    const idBytes = guidToBytes(p.pieceId);
    const titleBytes = new TextEncoder().encode((p.title || '').slice(0, 50));
    const payload = new Uint8Array(8 + 16 + titleBytes.length);
    const dv = new DataView(payload.buffer);
    const nonce = typeof p.nonce === 'bigint' ? p.nonce : BigInt(p.nonce ?? 0);
    dv.setBigUint64(0, nonce, true);
    payload.set(idBytes, 8);
    payload.set(titleBytes, 24);
    const priv = await this.importPrivateKey(privateKeyB64);
    const sig = await this.signBytes(priv, payload);
    const packet = new Uint8Array(payload.length + sig.length);
    packet.set(payload, 0); packet.set(sig, payload.length);

    if (isCapacitor()) {
      const plugin = window.Capacitor.Plugins.SheetstormBleAdvertiser;
      if (!plugin) throw new Error('Plugin nicht installiert.');
      return await plugin.setPiece({ data: bytesToB64(packet) });
    }
    window.dispatchEvent(new CustomEvent('ss-piece-loop', { detail: { packet } }));
    return { ok: true, web: true };
  },

  /* ---------- Follower-Scanner ---------- */
  /**
   * Startet einen passiven Scan und ruft bei jedem signierten Tempo-/Piece-
   * Paket den Callback. Validiert Ed25519-Sig vor dem Callback.
   *
   * @param {string} publicKeyB64 erwarteter Conductor-Public-Key
   * @param {(kind:'tempo'|'piece', data:object, raw:Uint8Array) => void} onPacket
   * @returns {Promise<() => Promise<void>>} stop-Funktion
   */
  async startScan(publicKeyB64, onPacket) {
    const pub = await this.importPublicKey(publicKeyB64);

    const handle = async (manufacturerId, payload) => {
      if (window.__SS_BLE_DEBUG) console.log('[ss-ble] handle id=', manufacturerId.toString(16), 'len=', payload.length);
      if (payload.length < 65) return;
      const sig  = payload.slice(payload.length - 64);
      const data = payload.slice(0, payload.length - 64);
      const ok = await this.verifyBytes(pub, sig, data);
      if (window.__SS_BLE_DEBUG) console.log('[ss-ble] verify=', ok);
      if (!ok) return;
      if (manufacturerId === MANUFACTURER_TEMPO) {
        const dv = new DataView(data.buffer, data.byteOffset, data.byteLength);
        const nonce = dv.getBigUint64(0, true);
        const anchorMs = Number(dv.getBigUint64(8, true));
        const beatIdx  = dv.getUint32(16, true);
        const bpm = dv.getUint16(20, true) / 100;
        const meter = dv.getUint8(22);
        const flags = dv.getUint8(23);
        onPacket('tempo', { nonce, anchorMs, beatIdx, bpm, meter, click: !!(flags & 1), fermate: !!(flags & 2) }, payload);
      } else if (manufacturerId === MANUFACTURER_PIECE) {
        const dv = new DataView(data.buffer, data.byteOffset, data.byteLength);
        const nonce = dv.getBigUint64(0, true);
        const pieceId = bytesToGuid(data.slice(8, 24));
        const title = new TextDecoder().decode(data.slice(24));
        onPacket('piece', { nonce, pieceId, title }, payload);
      }
    };

    // Loopback: wenn Conductor in derselben Tab läuft (Web), greifen wir
    // den dispatchEvent direkt ab.
    const onLoopTempo = (e) => handle(MANUFACTURER_TEMPO, e.detail.packet);
    const onLoopPiece = (e) => handle(MANUFACTURER_PIECE, e.detail.packet);
    window.addEventListener('ss-tempo-loop', onLoopTempo);
    window.addEventListener('ss-piece-loop', onLoopPiece);

    let stopFn = async () => {
      window.removeEventListener('ss-tempo-loop', onLoopTempo);
      window.removeEventListener('ss-piece-loop', onLoopPiece);
    };

    if (isCapacitor()) {
      const ble = await loadCapBle();
      if (ble) {
        await ble.initialize({ androidNeverForLocation: true });
        await ble.requestLEScan(
          { services: [SHEETSTORM_SERVICE], allowDuplicates: true },
          (r) => {
            const md = r.manufacturerData || {};
            for (const [idHex, dataView] of Object.entries(md)) {
              const id = parseInt(idHex, 16);
              const u8 = new Uint8Array(dataView.buffer, dataView.byteOffset, dataView.byteLength);
              handle(id, u8);
            }
          }
        );
        const innerStop = stopFn;
        stopFn = async () => { try { await ble.stopLEScan(); } catch { } await innerStop(); };
      }
    } else if (hasWebBluetoothScan()) {
      try {
        const scan = await navigator.bluetooth.requestLEScan({
          filters: [{ services: [SHEETSTORM_SERVICE] }],
          keepRepeatedDevices: true,
          acceptAllAdvertisements: false,
        });
        const onAdv = (event) => {
          for (const [id, dataView] of event.manufacturerData.entries()) {
            const u8 = new Uint8Array(dataView.buffer, dataView.byteOffset, dataView.byteLength);
            handle(id, u8);
          }
        };
        navigator.bluetooth.addEventListener('advertisementreceived', onAdv);
        const innerStop = stopFn;
        stopFn = async () => {
          try { navigator.bluetooth.removeEventListener('advertisementreceived', onAdv); } catch { }
          try { scan.stop(); } catch { }
          await innerStop();
        };
      } catch (e) {
        console.warn('Web-Bluetooth-Scan fehlgeschlagen:', e);
        // Loopback-only — okay
      }
    }
    // Sonst: nur Loopback (Tab-internes Testen)
    return stopFn;
  },

  /* ---------- WebAudio-Click-Scheduler ---------- */
  /**
   * Lookahead-Scheduler: berechnet aus (anchorMs, beatIdx, bpm) den nächsten
   * Click-Zeitpunkt und plant ihn im AudioContext. Drift wird kontinuierlich
   * korrigiert über BPM-Updates.
   *
   * @returns {{stop:()=>void, update:(t:object)=>void, getDrift:()=>number}}
   */
  createClickScheduler() {
    let ctx = null;
    let timer = null;
    let lastTempo = null;       // {anchorMs, beatIdx, bpm, meter, click}
    let nextBeat = 0;           // nächster zu schedulender Beat-Index
    let scheduledUpTo = 0;      // bis zu welchem audioCtx-Zeitpunkt geplant
    let lastDrift = 0;          // ms zwischen Soll und Ist

    function ensureCtx() {
      if (!ctx) ctx = new (window.AudioContext || window.webkitAudioContext)();
      return ctx;
    }

    function clickAt(audioTime, accent) {
      const c = ensureCtx();
      const osc = c.createOscillator();
      const gain = c.createGain();
      osc.frequency.value = accent ? 1500 : 1000;
      gain.gain.setValueAtTime(0.0001, audioTime);
      gain.gain.exponentialRampToValueAtTime(0.6, audioTime + 0.001);
      gain.gain.exponentialRampToValueAtTime(0.0001, audioTime + 0.04);
      osc.connect(gain).connect(c.destination);
      osc.start(audioTime);
      osc.stop(audioTime + 0.05);
    }

    function tick() {
      if (!lastTempo) return;
      const c = ensureCtx();
      const lookaheadSec = 0.2;
      const horizonAudio = c.currentTime + lookaheadSec;

      const beatLenMs = 60000 / lastTempo.bpm;
      // anchorMs ist Unix-Epoch (Date.now()). Konversion auf audioCtx-Zeit:
      const nowEpochMs = Date.now();
      const audioOffset = c.currentTime - nowEpochMs / 1000;

      while (true) {
        const targetPerfMs = lastTempo.anchorMs + (nextBeat - lastTempo.beatIdx) * beatLenMs;
        const targetAudio = targetPerfMs / 1000 + audioOffset;
        if (targetAudio > horizonAudio) break;
        if (targetAudio > c.currentTime - 0.05) {
          if (lastTempo.click) {
            const accent = (nextBeat % lastTempo.meter) === 0;
            clickAt(targetAudio, accent);
          }
          lastDrift = (targetAudio - c.currentTime) * 1000;
        }
        nextBeat++;
        scheduledUpTo = targetAudio;
      }
    }

    return {
      update(t) {
        const wasTempoChange = !lastTempo || lastTempo.bpm !== t.bpm || lastTempo.click !== t.click;
        lastTempo = { ...t };
        // Ankerwechsel: re-syncen indem wir nextBeat auf den ersten Beat
        // setzen, der nach jetzt liegt. anchorMs ist Unix-Epoch-Millisekunden.
        const now = Date.now();
        const beatLenMs = 60000 / t.bpm;
        const beatsSinceAnchor = Math.floor((now - t.anchorMs) / beatLenMs);
        const candidate = t.beatIdx + Math.max(0, beatsSinceAnchor + 1);
        if (wasTempoChange || Math.abs(candidate - nextBeat) > 1) {
          nextBeat = candidate;
        }
        if (!timer) timer = setInterval(tick, 50);
        if (ctx?.state === 'suspended') ctx.resume();
      },
      stop() {
        if (timer) { clearInterval(timer); timer = null; }
        if (ctx) { try { ctx.close(); } catch { } ctx = null; }
        lastTempo = null;
      },
      getDrift() { return lastDrift; },
    };
  },
};

/* ---------- Helper: GUID <-> Bytes ---------- */
function guidToBytes(guid) {
  const hex = guid.replace(/[{}-]/g, '');
  if (hex.length !== 32) throw new Error('Invalid GUID');
  const u = new Uint8Array(16);
  for (let i = 0; i < 16; i++) u[i] = parseInt(hex.substr(i * 2, 2), 16);
  return u;
}
function bytesToGuid(u8) {
  const hex = Array.from(u8).map(b => b.toString(16).padStart(2, '0')).join('');
  return `${hex.substr(0,8)}-${hex.substr(8,4)}-${hex.substr(12,4)}-${hex.substr(16,4)}-${hex.substr(20,12)}`;
}

/* ---------- Test-Helpers für /ble-test ---------- */
window.ssBleTestStartScan = async function (publicKeyB64, dotnetRef, methodName) {
  // Wir starten den Scan immer — startScan registriert mindestens den
  // Loopback-Listener (Browser-only-Test). Echtes BLE wird nur dann genutzt
  // wenn vorhanden.
  try {
    const stop = await window.SheetstormNative.startScan(publicKeyB64, (kind, data) => {
      try {
        // BigInt nicht JSON-fähig — als String senden
        const safe = { ...data, nonce: data.nonce.toString() };
        dotnetRef.invokeMethodAsync(methodName, kind, JSON.stringify(safe));
      } catch { }
    });
    window.__ssBleStop = stop;
    return true;
  } catch (e) {
    console.warn('ssBleTestStartScan:', e);
    return false;
  }
};
window.ssBleTestStopScan = async function () {
  if (window.__ssBleStop) { try { await window.__ssBleStop(); } catch { } window.__ssBleStop = null; }
};

/**
 * Loopback-Conductor für Browser-only-E2E-Test.
 * Erzeugt Tempo-Pakete im selben Tab und feuert das ss-tempo-loop-Event.
 * Wird vom Test mit JS.InvokeVoidAsync('ssBleLoopbackStart', privKey, bpm) aufgerufen.
 */
window.ssBleLoopback = null;
window.ssBleLoopbackStart = async function (privateKeyB64, bpm, meter) {
  if (window.ssBleLoopback) return;
  let nonce = 0n;
  const anchor = Date.now();
  const beatIdx = 0;
  const pieceId = (window.crypto?.randomUUID?.() || '00000000-0000-4000-8000-000000000001');
  let pieceNonce = 0n;

  async function sendTempo() {
    await window.SheetstormNative.broadcastTempo(privateKeyB64, {
      nonce: ++nonce, anchorMs: anchor, beatIdx, bpm, meter: meter || 4, click: true, fermate: false,
    });
  }
  async function sendPiece() {
    await window.SheetstormNative.broadcastPiece(privateKeyB64, {
      nonce: ++pieceNonce, pieceId, title: 'Loopback-Demo',
    });
  }

  await sendTempo();
  await sendPiece();
  const tempoHandle = setInterval(() => sendTempo().catch(e => console.warn('loopback tempo:', e)), 500);
  const pieceHandle = setInterval(() => sendPiece().catch(e => console.warn('loopback piece:', e)), 1500);
  window.ssBleLoopback = { tempoHandle, pieceHandle };
  return true;
};
window.ssBleLoopbackStop = function () {
  if (window.ssBleLoopback) {
    clearInterval(window.ssBleLoopback.tempoHandle);
    clearInterval(window.ssBleLoopback.pieceHandle);
    window.ssBleLoopback = null;
  }
};
