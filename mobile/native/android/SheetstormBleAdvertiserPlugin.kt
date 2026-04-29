/*
 * Sheetstorm — Native BLE-Advertiser für Android.
 * Copyright (C) 2026 Sheetstorm contributors. AGPL-3.0-only.
 *
 * Capacitor 6 Plugin in Kotlin. Stellt einen GATT-Server bereit, der den
 * Sheetstorm-Service (UUID 0000F517-7E5F-7E57-0000-000000000000) bereitstellt
 * und über die Schedule-Characteristic per "notify" signierte Click/Tempo-
 * Pakete an Followers schickt.
 *
 * Setup nach `npx cap add android`:
 *   1) Diese Datei kopieren nach
 *      mobile/android/app/src/main/java/de/sheetstorm/app/SheetstormBleAdvertiserPlugin.kt
 *   2) In MainActivity.java vor `super.onCreate(savedInstanceState);`
 *      registerPlugin(SheetstormBleAdvertiserPlugin.class) eintragen.
 *   3) AndroidManifest.xml braucht die Bluetooth-Permissions (siehe README).
 *   4) build.gradle: minSdkVersion 26.
 */
package de.sheetstorm.app

import android.Manifest
import android.bluetooth.*
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.BluetoothLeAdvertiser
import android.content.Context
import android.os.Build
import android.os.ParcelUuid
import androidx.annotation.RequiresPermission
import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import com.getcapacitor.annotation.Permission
import com.getcapacitor.annotation.PermissionCallback
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

private val SERVICE_UUID: UUID = UUID.fromString("0000F517-7E5F-7E57-0000-000000000000")
private val CHAR_SCHEDULE: UUID = UUID.fromString("0000F517-7E5F-7E57-0000-000000000001")
private val CHAR_PIECE:    UUID = UUID.fromString("0000F517-7E5F-7E57-0000-000000000002")
private val CCCD_UUID:     UUID = UUID.fromString("00002902-0000-1000-8000-00805F9B34FB")

@CapacitorPlugin(
    name = "SheetstormBleAdvertiser",
    permissions = [
        Permission(
            alias = "advertise",
            strings = [
                Manifest.permission.BLUETOOTH_ADVERTISE,
                Manifest.permission.BLUETOOTH_CONNECT,
                Manifest.permission.BLUETOOTH_SCAN,
            ]
        )
    ]
)
class SheetstormBleAdvertiserPlugin : Plugin() {

    private var manager: BluetoothManager? = null
    private var advertiser: BluetoothLeAdvertiser? = null
    private var gattServer: BluetoothGattServer? = null
    private var scheduleChar: BluetoothGattCharacteristic? = null
    private var pieceChar: BluetoothGattCharacteristic? = null

    /** Verbundene Subscriber (Followers, die "notify" aktiviert haben). */
    private val subscribers = ConcurrentHashMap<String, BluetoothDevice>()

    private val advertiseCallback = object : AdvertiseCallback() {
        override fun onStartFailure(errorCode: Int) {
            notifyListeners("advertise-failed", JSObject().apply { put("code", errorCode) })
        }
        override fun onStartSuccess(settingsInEffect: AdvertiseSettings) {
            notifyListeners("advertise-started", JSObject())
        }
    }

    private val gattCallback = object : BluetoothGattServerCallback() {
        override fun onConnectionStateChange(device: BluetoothDevice, status: Int, newState: Int) {
            val ev = JSObject().apply {
                put("address", device.address)
                put("state", newState)
            }
            notifyListeners("connection-changed", ev)
            if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                subscribers.remove(device.address)
            }
        }

        override fun onDescriptorWriteRequest(
            device: BluetoothDevice, requestId: Int, descriptor: BluetoothGattDescriptor,
            preparedWrite: Boolean, responseNeeded: Boolean, offset: Int, value: ByteArray
        ) {
            // CCCD: Subscribe/Unsubscribe für notify
            if (descriptor.uuid == CCCD_UUID) {
                val subscribe = value.contentEquals(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE)
                if (subscribe) {
                    subscribers[device.address] = device
                    notifyListeners("subscribed", JSObject().apply { put("address", device.address) })
                } else {
                    subscribers.remove(device.address)
                    notifyListeners("unsubscribed", JSObject().apply { put("address", device.address) })
                }
            }
            try {
                @Suppress("MissingPermission")
                gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, 0, null)
            } catch (_: SecurityException) { }
        }
    }

    @PluginMethod
    fun start(call: PluginCall) {
        if (!hasRequiredPermissions()) {
            requestPermissionForAlias("advertise", call, "permsResult")
            return
        }
        startInternal(call)
    }

    @PermissionCallback
    private fun permsResult(call: PluginCall) {
        if (!hasRequiredPermissions()) {
            call.reject("Bluetooth-Berechtigungen verweigert")
            return
        }
        startInternal(call)
    }

    @RequiresPermission(allOf = [Manifest.permission.BLUETOOTH_ADVERTISE, Manifest.permission.BLUETOOTH_CONNECT])
    private fun startInternal(call: PluginCall) {
        val ctx: Context = context
        manager = ctx.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        val adapter = manager?.adapter ?: return call.reject("Kein Bluetooth-Adapter")
        if (!adapter.isEnabled) return call.reject("Bluetooth ist aus")
        advertiser = adapter.bluetoothLeAdvertiser ?: return call.reject("BLE-Advertising nicht unterstützt")

        try {
            // GATT-Server aufsetzen
            gattServer = manager!!.openGattServer(ctx, gattCallback)
            val service = BluetoothGattService(SERVICE_UUID, BluetoothGattService.SERVICE_TYPE_PRIMARY)

            scheduleChar = BluetoothGattCharacteristic(
                CHAR_SCHEDULE,
                BluetoothGattCharacteristic.PROPERTY_NOTIFY or BluetoothGattCharacteristic.PROPERTY_READ,
                BluetoothGattCharacteristic.PERMISSION_READ
            ).also {
                it.addDescriptor(BluetoothGattDescriptor(CCCD_UUID,
                    BluetoothGattDescriptor.PERMISSION_READ or BluetoothGattDescriptor.PERMISSION_WRITE))
                service.addCharacteristic(it)
            }

            pieceChar = BluetoothGattCharacteristic(
                CHAR_PIECE,
                BluetoothGattCharacteristic.PROPERTY_NOTIFY or BluetoothGattCharacteristic.PROPERTY_READ,
                BluetoothGattCharacteristic.PERMISSION_READ
            ).also {
                it.addDescriptor(BluetoothGattDescriptor(CCCD_UUID,
                    BluetoothGattDescriptor.PERMISSION_READ or BluetoothGattDescriptor.PERMISSION_WRITE))
                service.addCharacteristic(it)
            }

            gattServer?.addService(service)

            // Advertising starten
            val settings = AdvertiseSettings.Builder()
                .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
                .setConnectable(true)
                .setTimeout(0)
                .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
                .build()
            val data = AdvertiseData.Builder()
                .setIncludeDeviceName(true)
                .addServiceUuid(ParcelUuid(SERVICE_UUID))
                .build()
            advertiser?.startAdvertising(settings, data, advertiseCallback)
            call.resolve(JSObject().apply { put("started", true) })
        } catch (e: SecurityException) {
            call.reject("Sicherheits-Ausnahme: ${e.message}")
        } catch (e: Exception) {
            call.reject("Start fehlgeschlagen: ${e.message}")
        }
    }

    @PluginMethod
    fun stop(call: PluginCall) {
        try {
            @Suppress("MissingPermission")
            advertiser?.stopAdvertising(advertiseCallback)
            @Suppress("MissingPermission")
            gattServer?.close()
        } catch (_: Exception) { }
        gattServer = null
        scheduleChar = null
        pieceChar = null
        subscribers.clear()
        call.resolve(JSObject().apply { put("stopped", true) })
    }

    /**
     * Push einer signierten Schedule-Payload an alle Subscriber.
     * args:
     *   data: Base64-encoded bytes (signed payload, max 512 byte gesplittet)
     */
    @PluginMethod
    fun notifySchedule(call: PluginCall) {
        val b64 = call.getString("data") ?: return call.reject("data fehlt")
        val bytes = try { android.util.Base64.decode(b64, android.util.Base64.NO_WRAP) }
            catch (e: Exception) { return call.reject("base64-fehler") }
        val ch = scheduleChar ?: return call.reject("nicht gestartet")
        ch.value = bytes
        var sent = 0
        for ((_, dev) in subscribers) {
            try {
                @Suppress("MissingPermission")
                gattServer?.notifyCharacteristicChanged(dev, ch, false)
                sent++
            } catch (_: SecurityException) { }
        }
        call.resolve(JSObject().apply { put("subscribers", subscribers.size); put("sent", sent) })
    }

    private fun hasRequiredPermissions(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        return getPermissionState("advertise") == com.getcapacitor.PermissionState.GRANTED
    }
}
