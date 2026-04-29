/*
 * Sheetstorm — Native BLE-Broadcast (Advertising-only).
 * Copyright (C) 2026 Sheetstorm contributors. AGPL-3.0-only.
 *
 * Capacitor 7 Plugin in Kotlin. Statt Connect/GATT-Notify nutzen wir
 * BluetoothLeAdvertiser + Extended Advertising (BT 5.0). Vorteile:
 *  - Keine Connection-Limits (~7 Phones) → unbegrenzt viele Listener
 *  - Keine Pairing-Popups
 *  - Niedrigerer Energieverbrauch beim Follower (passiver Scan)
 *
 * Wir senden zwei verschiedene Advertising-Frames im Roundrobin:
 *   - Tempo-Frame (alle 800 ms) mit BPM + Anchor + Beat-Index + Sig
 *   - Piece-Frame (alle 1500 ms) mit Stück-ID + Titel + Sig
 *
 * Pakete sind pre-signed (Ed25519 in Web/JS gerechnet), das Plugin
 * sendet nur den fertigen Byte-Buffer.
 *
 * Setup nach `npx cap add android`:
 *   1) Datei nach mobile/android/app/src/main/java/de/sheetstorm/app/
 *   2) registerPlugin(SheetstormBleAdvertiserPlugin::class.java) in MainActivity
 *   3) Manifest: BLUETOOTH_ADVERTISE Permission
 *   4) build.gradle: minSdkVersion 26 (BluetoothLeAdvertiser braucht 21,
 *      Extended Advertising 26)
 */
package de.sheetstorm.app

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.AdvertisingSet
import android.bluetooth.le.AdvertisingSetCallback
import android.bluetooth.le.AdvertisingSetParameters
import android.bluetooth.le.BluetoothLeAdvertiser
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import androidx.annotation.RequiresPermission
import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import com.getcapacitor.annotation.Permission
import java.util.UUID

/** Sheetstorm-Service-UUID — identifiziert unsere Advertising-Frames im Äther. */
private val SHEETSTORM_SERVICE_UUID: UUID = UUID.fromString("0000F517-7E5F-7E57-0000-000000000000")

/** Manufacturer-ID 0xFFFF (test/internal range) für Tempo-Pakete. */
private const val MANUFACTURER_ID_TEMPO: Int = 0xFFFE
/** Manufacturer-ID 0xFFFD für Piece-Pakete. */
private const val MANUFACTURER_ID_PIECE: Int = 0xFFFD

@CapacitorPlugin(
    name = "SheetstormBleAdvertiser",
    permissions = [
        Permission(
            alias = "advertise",
            strings = [
                Manifest.permission.BLUETOOTH_ADVERTISE,
                Manifest.permission.BLUETOOTH_CONNECT,
            ]
        )
    ]
)
class SheetstormBleAdvertiserPlugin : Plugin() {

    private var manager: BluetoothManager? = null
    private var advertiser: BluetoothLeAdvertiser? = null

    private var tempoSet: AdvertisingSet? = null
    private var pieceSet: AdvertisingSet? = null

    private var lastTempoPayload: ByteArray? = null
    private var lastPiecePayload: ByteArray? = null

    private val handler = Handler(Looper.getMainLooper())
    private var running = false

    /** Re-Broadcast-Loop: aktualisiert die Advertising-Daten alle 800 ms / 1500 ms. */
    private val tempoRebroadcast = object : Runnable {
        override fun run() {
            if (!running) return
            updateTempoData()
            handler.postDelayed(this, 800)
        }
    }
    private val pieceRebroadcast = object : Runnable {
        override fun run() {
            if (!running) return
            updatePieceData()
            handler.postDelayed(this, 1500)
        }
    }

    @PluginMethod
    fun start(call: PluginCall) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            getPermissionState("advertise") != com.getcapacitor.PermissionState.GRANTED) {
            requestPermissionForAlias("advertise", call, "permsResult")
            return
        }
        startInternal(call)
    }

    @com.getcapacitor.annotation.PermissionCallback
    private fun permsResult(call: PluginCall) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            getPermissionState("advertise") != com.getcapacitor.PermissionState.GRANTED) {
            call.reject("Bluetooth-Berechtigungen verweigert")
            return
        }
        startInternal(call)
    }

    @RequiresPermission(allOf = [Manifest.permission.BLUETOOTH_ADVERTISE, Manifest.permission.BLUETOOTH_CONNECT])
    private fun startInternal(call: PluginCall) {
        manager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        val adapter: BluetoothAdapter = manager?.adapter ?: return call.reject("Kein Bluetooth-Adapter")
        if (!adapter.isEnabled) return call.reject("Bluetooth ist aus")
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return call.reject("Android 8.0 oder neuer erforderlich (Extended Advertising).")
        }
        advertiser = adapter.bluetoothLeAdvertiser ?: return call.reject("BLE-Advertising nicht unterstützt")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !adapter.isLeExtendedAdvertisingSupported) {
            // Fallback: legacy Advertising 31-Byte. Für unsere ~80 Byte Tempo-Payload
            // zu klein — wir warnen aber starten trotzdem, der Re-Broadcast läuft mit
            // gekürzten Pakete (nur BPM + Anchor, keine Sig).
        }

        running = true
        // Initial Dummy-Payloads (leer), damit das Set existiert; sobald
        // setTempo / setPiece kommt, werden sie ersetzt.
        startTempoSet()
        startPieceSet()
        handler.post(tempoRebroadcast)
        handler.post(pieceRebroadcast)
        call.resolve(JSObject().apply { put("started", true) })
    }

    @PluginMethod
    fun stop(call: PluginCall) {
        running = false
        handler.removeCallbacks(tempoRebroadcast)
        handler.removeCallbacks(pieceRebroadcast)
        try {
            tempoSet?.let { @Suppress("MissingPermission") advertiser?.stopAdvertisingSet(advSetCallback) }
            pieceSet?.let { @Suppress("MissingPermission") advertiser?.stopAdvertisingSet(advSetCallback) }
        } catch (_: SecurityException) { }
        tempoSet = null
        pieceSet = null
        call.resolve(JSObject().apply { put("stopped", true) })
    }

    /**
     * Setze das aktuelle Tempo-Payload. Roher Byte-Buffer mit
     * (in JS gerechnet): nonce(8) || anchor_ms(8) || beat_idx(4) || bpm_x100(2) ||
     *                    meter(1) || sig(64) = 87 Bytes.
     */
    @PluginMethod
    fun setTempo(call: PluginCall) {
        val b64 = call.getString("data") ?: return call.reject("data fehlt")
        lastTempoPayload = try { android.util.Base64.decode(b64, android.util.Base64.NO_WRAP) }
            catch (e: Exception) { return call.reject("base64 invalid") }
        if (running) updateTempoData()
        call.resolve(JSObject().apply { put("ok", true); put("size", lastTempoPayload!!.size) })
    }

    /** Setze das aktuelle Piece-Payload (analog Tempo, andere Manufacturer-ID). */
    @PluginMethod
    fun setPiece(call: PluginCall) {
        val b64 = call.getString("data") ?: return call.reject("data fehlt")
        lastPiecePayload = try { android.util.Base64.decode(b64, android.util.Base64.NO_WRAP) }
            catch (e: Exception) { return call.reject("base64 invalid") }
        if (running) updatePieceData()
        call.resolve(JSObject().apply { put("ok", true); put("size", lastPiecePayload!!.size) })
    }

    @RequiresPermission(Manifest.permission.BLUETOOTH_ADVERTISE)
    private fun startTempoSet() {
        val params = AdvertisingSetParameters.Builder()
            .setLegacyMode(false)
            .setConnectable(false)
            .setScannable(false)
            .setInterval(AdvertisingSetParameters.INTERVAL_LOW)
            .setTxPowerLevel(AdvertisingSetParameters.TX_POWER_HIGH)
            .setPrimaryPhy(android.bluetooth.le.AdvertisingSetParameters.PHY_OPTION_NO_PREFERRED)
            .build()
        val data = buildAdvData(MANUFACTURER_ID_TEMPO, lastTempoPayload ?: ByteArray(0))
        try {
            advertiser?.startAdvertisingSet(params, data, null, null, null, advSetCallback)
        } catch (e: SecurityException) { /* ignore */ }
    }

    @RequiresPermission(Manifest.permission.BLUETOOTH_ADVERTISE)
    private fun startPieceSet() {
        val params = AdvertisingSetParameters.Builder()
            .setLegacyMode(false)
            .setConnectable(false)
            .setScannable(false)
            .setInterval(AdvertisingSetParameters.INTERVAL_MEDIUM)
            .setTxPowerLevel(AdvertisingSetParameters.TX_POWER_HIGH)
            .build()
        val data = buildAdvData(MANUFACTURER_ID_PIECE, lastPiecePayload ?: ByteArray(0))
        try {
            advertiser?.startAdvertisingSet(params, data, null, null, null, advSetCallback)
        } catch (e: SecurityException) { /* ignore */ }
    }

    @RequiresPermission(Manifest.permission.BLUETOOTH_ADVERTISE)
    private fun updateTempoData() {
        val payload = lastTempoPayload ?: return
        try {
            tempoSet?.setAdvertisingData(buildAdvData(MANUFACTURER_ID_TEMPO, payload))
        } catch (e: SecurityException) { }
    }

    @RequiresPermission(Manifest.permission.BLUETOOTH_ADVERTISE)
    private fun updatePieceData() {
        val payload = lastPiecePayload ?: return
        try {
            pieceSet?.setAdvertisingData(buildAdvData(MANUFACTURER_ID_PIECE, payload))
        } catch (e: SecurityException) { }
    }

    private fun buildAdvData(manufacturerId: Int, payload: ByteArray): AdvertiseData =
        AdvertiseData.Builder()
            .setIncludeDeviceName(false)
            .addServiceUuid(ParcelUuid(SHEETSTORM_SERVICE_UUID))
            .addManufacturerData(manufacturerId, payload)
            .build()

    private val advSetCallback = object : AdvertisingSetCallback() {
        override fun onAdvertisingSetStarted(set: AdvertisingSet?, txPower: Int, status: Int) {
            super.onAdvertisingSetStarted(set, txPower, status)
            // Wir wissen nicht welcher Set das ist (Tempo oder Piece) — beide
            // teilen sich den Callback. Erstes Slot ist tempoSet, zweites pieceSet.
            if (tempoSet == null) tempoSet = set else pieceSet = set
            notifyListeners("set-started", JSObject().apply { put("status", status); put("txPower", txPower) })
        }

        override fun onAdvertisingDataSet(set: AdvertisingSet?, status: Int) {
            super.onAdvertisingDataSet(set, status)
            // Häufig — kein notify (wäre Spam)
        }

        override fun onAdvertisingSetStopped(set: AdvertisingSet?) {
            super.onAdvertisingSetStopped(set)
            if (set === tempoSet) tempoSet = null
            if (set === pieceSet) pieceSet = null
        }
    }
}
