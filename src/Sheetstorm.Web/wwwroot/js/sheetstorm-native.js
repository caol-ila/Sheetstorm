/* Sheetstorm Native Bridge.
 *
 * Liegt zwischen Blazor-JS-Interop und nativen Capacitor-Plugins (BLE,
 * Push, Preferences). Funktioniert in zwei Modi:
 *
 *   1) Native (Capacitor-Wrapper): nutzt @capacitor-community/bluetooth-le.
 *      Conductor advertised; Followers scannen + verbinden + abonnieren
 *      Schedule-Notifications.
 *
 *   2) Web (Browser-PWA): nutzt WebBluetooth, wo verfuegbar (Chrome / Edge
 *      auf Desktop, Chrome auf Android). Auf iOS-Safari ist WebBluetooth
 *      nicht verfuegbar -> dann meldet die Bridge `unsupported` und Blazor
 *      faellt auf den (spaeter folgenden) WLAN-Multicast-Pfad zurueck.
 *
 * Sicherheit (siehe docs/14):
 *   - Conductor erzeugt beim Event-Start ein Ed25519-Keypair (lokal).
 *   - Public-Key wird per HTTPS an /api/events/{id}/conductor-key gemeldet.
 *   - Followers holen den Public-Key beim Pairing ab.
 *   - Schedule-Pakete sind Ed25519-signiert; Followers verifizieren bevor
 *     sie auf das Tempo umschalten.
 *
 * Service- und Characteristic-UUIDs (festgelegt in Spec 14):
 */
const SHEETSTORM_SERVICE      = '0000f517-7e5f-7e57-0000-000000000000';
const CHAR_CONDUCTOR_SCHEDULE = '0000f517-7e5f-7e57-0000-000000000001';
const CHAR_CONDUCTOR_PIECE    = '0000f517-7e5f-7e57-0000-000000000002';
const CHAR_TUNING_REFERENCE   = '0000f517-7e5f-7e57-0000-000000000003';

function isCapacitor() {
  return !!(window.Capacitor && typeof window.Capacitor.isNativePlatform === 'function' && window.Capacitor.isNativePlatform());
}

function hasWebBluetooth() {
  return typeof navigator !== 'undefined' && !!navigator.bluetooth;
}

async function loadCapBle() {
  if (!isCapacitor()) return null;
  try {
    const mod = await import('@capacitor-community/bluetooth-le');
    return mod.BleClient;
  } catch (e) {
    console.warn('Capacitor BLE-Plugin nicht verfügbar:', e);
    return null;
  }
}

window.SheetstormNative = {
  get isCapacitor() { return isCapacitor(); },
  get hasWebBluetooth() { return hasWebBluetooth(); },
  get bleAvailable() { return isCapacitor() || hasWebBluetooth(); },

  serviceUuid: SHEETSTORM_SERVICE,
  charSchedule: CHAR_CONDUCTOR_SCHEDULE,
  charPiece: CHAR_CONDUCTOR_PIECE,
  charTuning: CHAR_TUNING_REFERENCE,

  /**
   * Sucht in der Naehe nach Sheetstorm-Sessions.
   * onDevice: ({deviceId, name, rssi}) => void
   * Rueckgabe: stop()-Funktion.
   */
  async scanForConductor(onDevice, durationMs = 8000) {
    const ble = await loadCapBle();
    if (ble) {
      await ble.initialize({ androidNeverForLocation: true });
      await ble.requestLEScan({ services: [SHEETSTORM_SERVICE] }, (r) => {
        try { onDevice && onDevice({ deviceId: r.device.deviceId, name: r.device.name, rssi: r.rssi }); } catch { }
      });
      const stop = async () => { try { await ble.stopLEScan(); } catch { } };
      if (durationMs > 0) setTimeout(stop, durationMs);
      return stop;
    }
    if (hasWebBluetooth()) {
      // WebBluetooth scannt nicht passiv; wir nutzen requestDevice fuer Picker.
      const dev = await navigator.bluetooth.requestDevice({ filters: [{ services: [SHEETSTORM_SERVICE] }] });
      onDevice && onDevice({ deviceId: dev.id, name: dev.name, rssi: null });
      return async () => { /* nichts zu stoppen — Picker einmalig */ };
    }
    return null; // unsupported
  },

  /**
   * Verbindet als Follower zum Conductor und abonniert die Schedule-Notify.
   * onSchedule: (Uint8Array signierte Payload) => void
   */
  async connectAsFollower(deviceId, onSchedule) {
    const ble = await loadCapBle();
    if (ble) {
      await ble.connect(deviceId);
      await ble.startNotifications(deviceId, SHEETSTORM_SERVICE, CHAR_CONDUCTOR_SCHEDULE, (data) => {
        onSchedule && onSchedule(new Uint8Array(data.buffer));
      });
      return async () => {
        try { await ble.stopNotifications(deviceId, SHEETSTORM_SERVICE, CHAR_CONDUCTOR_SCHEDULE); } catch { }
        try { await ble.disconnect(deviceId); } catch { }
      };
    }
    if (hasWebBluetooth()) {
      const dev = await navigator.bluetooth.requestDevice({ filters: [{ services: [SHEETSTORM_SERVICE] }] });
      const server = await dev.gatt.connect();
      const svc = await server.getPrimaryService(SHEETSTORM_SERVICE);
      const ch = await svc.getCharacteristic(CHAR_CONDUCTOR_SCHEDULE);
      const handler = (evt) => onSchedule && onSchedule(new Uint8Array(evt.target.value.buffer));
      ch.addEventListener('characteristicvaluechanged', handler);
      await ch.startNotifications();
      return async () => {
        try { ch.removeEventListener('characteristicvaluechanged', handler); } catch { }
        try { await ch.stopNotifications(); } catch { }
        try { await server.disconnect(); } catch { }
      };
    }
    throw new Error('BLE nicht verfügbar');
  },

  /**
   * Conductor-Seite: startet einen GATT-Server und sendet Schedule-Pakete
   * an alle Subscribers. Nur in Capacitor moeglich (WebBluetooth kann nur
   * Central, kein Peripheral).
   */
  async startConductor() {
    if (!isCapacitor()) throw new Error('Conductor-Mode benötigt die native App.');
    // Custom Plugin SheetstormBleAdvertiser (Android, siehe mobile/native/android/)
    const plugin = window.Capacitor.Plugins.SheetstormBleAdvertiser;
    if (!plugin) throw new Error('Plugin SheetstormBleAdvertiser nicht installiert. Siehe mobile/native/android/README.md.');
    return await plugin.start();
  },

  async stopConductor() {
    if (!isCapacitor()) return;
    const plugin = window.Capacitor.Plugins.SheetstormBleAdvertiser;
    if (plugin) try { await plugin.stop(); } catch { }
  },

  /**
   * Sendet eine signierte Schedule-Payload als Notify an verbundene Followers.
   * Rolle: Conductor.
   */
  async broadcastSchedule(payloadBytes) {
    if (!isCapacitor()) throw new Error('Broadcast benötigt native App.');
    const plugin = window.Capacitor.Plugins.SheetstormBleAdvertiser;
    if (!plugin) throw new Error('Plugin nicht installiert.');
    const b64 = btoa(String.fromCharCode(...payloadBytes));
    return await plugin.notifySchedule({ data: b64 });
  },

  /**
   * Crypto-Hilfen: Ed25519-Keypair via WebCrypto / liballe SubtleCrypto.
   * Speicherung im Native: Capacitor Preferences. Im Web: localStorage.
   */
  async generateConductorKey() {
    // Browser haben Ed25519 in WebCrypto seit ~2023 (Chrome/Edge/Firefox).
    if (!window.crypto || !window.crypto.subtle) throw new Error('WebCrypto fehlt');
    try {
      const kp = await crypto.subtle.generateKey({ name: 'Ed25519' }, true, ['sign', 'verify']);
      const pubRaw = await crypto.subtle.exportKey('raw', kp.publicKey);
      const privRaw = await crypto.subtle.exportKey('pkcs8', kp.privateKey);
      return {
        publicKey: btoa(String.fromCharCode(...new Uint8Array(pubRaw))),
        privateKey: btoa(String.fromCharCode(...new Uint8Array(privRaw))),
      };
    } catch (e) {
      // Fallback: Ed25519 nicht supported — nutze ECDSA P-256 als interim.
      console.warn('Ed25519 nicht supported, falle auf ECDSA P-256 zurueck:', e);
      const kp = await crypto.subtle.generateKey({ name: 'ECDSA', namedCurve: 'P-256' }, true, ['sign', 'verify']);
      const pubRaw = await crypto.subtle.exportKey('raw', kp.publicKey);
      const privRaw = await crypto.subtle.exportKey('pkcs8', kp.privateKey);
      return {
        publicKey: btoa(String.fromCharCode(...new Uint8Array(pubRaw))),
        privateKey: btoa(String.fromCharCode(...new Uint8Array(privRaw))),
        algorithm: 'ECDSA-P256',
      };
    }
  },

  /**
   * Verifiziert ein BLE-Schedule-Paket gegen den Conductor-Public-Key.
   * Format: 64-byte Signatur || Payload
   */
  async verifySchedule(publicKeyBase64, packetBytes) {
    if (packetBytes.length < 65) return null;
    const sig = packetBytes.slice(0, 64);
    const payload = packetBytes.slice(64);
    const pubRaw = Uint8Array.from(atob(publicKeyBase64), c => c.charCodeAt(0));
    try {
      const key = await crypto.subtle.importKey('raw', pubRaw, { name: 'Ed25519' }, false, ['verify']);
      const ok = await crypto.subtle.verify('Ed25519', key, sig, payload);
      return ok ? new TextDecoder().decode(payload) : null;
    } catch {
      return null;
    }
  },
};

/**
 * Globaler Helper fuer die /ble-test-Seite. Wird von Blazor via
 * JS.InvokeAsync aufgerufen mit (dotnetRef, methodName).
 *
 * Triggert den WebBluetooth-Picker, verbindet zur Schedule-Characteristic
 * und ruft bei jedem Notification-Event dotnetRef.invokeMethodAsync(methodName, base64).
 */
window.ssBleTestConnect = async function (dotnetRef, methodName) {
  if (!navigator.bluetooth) return false;
  try {
    const svcUuid = window.SheetstormNative.serviceUuid;
    const dev = await navigator.bluetooth.requestDevice({ filters: [{ services: [svcUuid] }] });
    const server = await dev.gatt.connect();
    const svc = await server.getPrimaryService(svcUuid);
    const ch = await svc.getCharacteristic(window.SheetstormNative.charSchedule);
    ch.addEventListener('characteristicvaluechanged', (e) => {
      const u = new Uint8Array(e.target.value.buffer);
      const b64 = btoa(String.fromCharCode(...u));
      try { dotnetRef.invokeMethodAsync(methodName, b64); } catch { }
    });
    await ch.startNotifications();
    window.__ssBleDevice = dev;
    window.__ssBleServer = server;
    return true;
  } catch (e) {
    console.warn('ssBleTestConnect:', e);
    return false;
  }
};
