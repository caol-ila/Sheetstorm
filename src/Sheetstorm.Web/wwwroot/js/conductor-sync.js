/* Sheetstorm Conductor Sync — Browser-Side Ed25519 + (BLE-Roadmap) */

const DB_NAME = 'sheetstorm-keys';
const STORE_NAME = 'session-keys';
const SHEETSTORM_MAGIC = 0x5350;

function ed25519Available() {
  return !!(globalThis.crypto?.subtle);
}

async function generateKeyPair() {
  const kp = await crypto.subtle.generateKey({ name: 'Ed25519' }, true, ['sign', 'verify']);
  const pubRaw = new Uint8Array(await crypto.subtle.exportKey('raw', kp.publicKey));
  const privJwk = await crypto.subtle.exportKey('jwk', kp.privateKey);
  return { publicKey: kp.publicKey, privateKey: kp.privateKey, publicKeyRaw: pubRaw, privateKeyJwk: privJwk };
}

function bytesToBase64(bytes) {
  let bin = '';
  for (let i = 0; i < bytes.byteLength; i++) bin += String.fromCharCode(bytes[i]);
  return btoa(bin);
}

function base64ToBytes(b64) {
  const bin = atob(b64);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

async function importPublicKey(b64) {
  const raw = base64ToBytes(b64);
  return crypto.subtle.importKey('raw', raw, { name: 'Ed25519' }, true, ['verify']);
}

async function importPrivateKey(jwk) {
  return crypto.subtle.importKey('jwk', jwk, { name: 'Ed25519' }, false, ['sign']);
}

async function sign(privateKey, dataBytes) {
  const sig = await crypto.subtle.sign({ name: 'Ed25519' }, privateKey, dataBytes);
  return new Uint8Array(sig);
}

async function verify(publicKey, signatureBytes, dataBytes) {
  return crypto.subtle.verify({ name: 'Ed25519' }, publicKey, signatureBytes, dataBytes);
}

function buildPayload(eventIdShort, pieceIdShort, counter) {
  const buf = new ArrayBuffer(27);
  const v = new DataView(buf);
  v.setUint16(0, SHEETSTORM_MAGIC, false);
  v.setUint8(2, 0x01);
  for (let i = 0; i < 8; i++) v.setUint8(3 + i, eventIdShort[i]);
  for (let i = 0; i < 8; i++) v.setUint8(11 + i, pieceIdShort[i]);
  v.setBigUint64(19, BigInt(counter), false);
  return new Uint8Array(buf);
}

function shortIdFromGuid(guidStr) {
  const hex = guidStr.replace(/-/g, '').slice(0, 16);
  const out = new Uint8Array(8);
  for (let i = 0; i < 8; i++) out[i] = parseInt(hex.slice(i * 2, i * 2 + 2), 16);
  return out;
}

function openKeyDb() {
  return new Promise((resolve, reject) => {
    const req = indexedDB.open(DB_NAME, 1);
    req.onupgradeneeded = () => req.result.createObjectStore(STORE_NAME);
    req.onsuccess = () => resolve(req.result);
    req.onerror = () => reject(req.error);
  });
}

async function saveKey(eventId, jwk) {
  const db = await openKeyDb();
  await new Promise((resolve, reject) => {
    const tx = db.transaction(STORE_NAME, 'readwrite');
    tx.objectStore(STORE_NAME).put(jwk, eventId);
    tx.oncomplete = () => resolve();
    tx.onerror = () => reject(tx.error);
  });
}

async function loadKey(eventId) {
  const db = await openKeyDb();
  return new Promise((resolve, reject) => {
    const tx = db.transaction(STORE_NAME, 'readonly');
    const r = tx.objectStore(STORE_NAME).get(eventId);
    r.onsuccess = () => resolve(r.result);
    r.onerror = () => reject(r.error);
  });
}

window.__sheetstormSync = {
  ed25519Available,

  async createConductorKey(eventId) {
    const kp = await generateKeyPair();
    await saveKey(eventId, kp.privateKeyJwk);
    return bytesToBase64(kp.publicKeyRaw);
  },

  async signOpenPiece(eventId, pieceId, counter) {
    const jwk = await loadKey(eventId);
    if (!jwk) throw new Error('Kein Privat-Key fuer Event ' + eventId + ' im lokalen Store.');
    const priv = await importPrivateKey(jwk);
    const payload = buildPayload(shortIdFromGuid(eventId), shortIdFromGuid(pieceId), counter);
    const sig = await sign(priv, payload);
    return { payload: bytesToBase64(payload), signature: bytesToBase64(sig) };
  },

  async verifyOpenPiece(publicKeyBase64, payloadBase64, signatureBase64) {
    const pub = await importPublicKey(publicKeyBase64);
    const sig = base64ToBytes(signatureBase64);
    const payload = base64ToBytes(payloadBase64);
    return verify(pub, sig, payload);
  },

  _internal: { generateKeyPair, sign, verify, buildPayload, bytesToBase64, base64ToBytes, shortIdFromGuid },

  bluetoothAvailable: !!(navigator.bluetooth?.requestLEScan),
};
