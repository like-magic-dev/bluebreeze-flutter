//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

package dev.likemagic.bluebreeze_flutter

import android.app.Activity
import android.content.Context
import dev.likemagic.bluebreeze.BBAuthorization
import dev.likemagic.bluebreeze.BBCharacteristic
import dev.likemagic.bluebreeze.BBConstants
import dev.likemagic.bluebreeze.BBDevice
import dev.likemagic.bluebreeze.BBDeviceConnectionStatus
import dev.likemagic.bluebreeze.BBManager
import dev.likemagic.bluebreeze.BBScanResult
import dev.likemagic.bluebreeze.BBService
import dev.likemagic.bluebreeze.BBState
import dev.likemagic.bluebreeze.BBUUID
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch

class BluebreezeFlutterPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private lateinit var manager: BBManager

    private var application: Context? = null
    private var activity: Activity? = null

    private val coroutineScope: CoroutineScope = CoroutineScope(Dispatchers.Main)
    private var coroutineJobs: MutableList<Job> = mutableListOf()
    private var coroutineDeviceJobs: MutableMap<String, MutableList<Job>> = mutableMapOf()
    private var coroutineDeviceServiceJobs: MutableMap<String, MutableMap<BBUUID, MutableMap<BBUUID, MutableList<Job>>>> =
        mutableMapOf()

    // region Engine lifecycle

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        application = flutterPluginBinding.applicationContext

        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "bluebreeze")
        channel.setMethodCallHandler(this)

        manager = BBManager(flutterPluginBinding.applicationContext)

        initialize()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        application = null

        coroutineDeviceJobs.forEach { list -> list.value.forEach { it.cancel() } }
        coroutineDeviceJobs.clear()

        coroutineJobs.forEach { it.cancel() }
        coroutineJobs.clear()

        channel.setMethodCallHandler(null)
    }

    // endregion

    // region Activity lifecycle

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    // endregion

    // region Initialization

    private fun initialize() {
        coroutineScope.launch {
            manager.state.collect {
                reportState(it)
            }
        }.storeIn(coroutineJobs)

        coroutineScope.launch {
            manager.authorizationStatus.collect {
                reportAuthorizationStatus(it)
            }
        }.storeIn(coroutineJobs)

        coroutineScope.launch {
            manager.scanEnabled.collect {
                reportScanEnabled(it)
            }
        }.storeIn(coroutineJobs)

        coroutineScope.launch {
            manager.scanResults.collect {
                reportScanResult(it)
            }
        }.storeIn(coroutineJobs)

        coroutineScope.launch {
            manager.devices.collect {
                it.values.forEach { device -> initializeDevice(device) }
                reportDevices(it)
            }
        }.storeIn(coroutineJobs)
    }

    private fun initializeDevice(device: BBDevice) {
        if (coroutineDeviceJobs[device.address] != null) {
            return
        }

        val coroutineDeviceJobsList = mutableListOf<Job>()
        coroutineDeviceJobs[device.address] = coroutineDeviceJobsList

        coroutineScope.launch {
            device.connectionStatus.collect {
                reportDeviceConnectionStatus(device, it)
            }
        }.storeIn(coroutineDeviceJobsList)

        coroutineScope.launch {
            device.services.collect {
                initializeServices(device, it)
                reportDeviceServices(device, it)
            }
        }.storeIn(coroutineDeviceJobsList)

        coroutineScope.launch {
            device.mtu.collect {
                reportDeviceMTU(device, it)
            }
        }.storeIn(coroutineDeviceJobsList)
    }

    private fun initializeServices(device: BBDevice, services: List<BBService>) {
        val coroutineDeviceServicesJobsMap =
            coroutineDeviceServiceJobs[device.address] ?: mutableMapOf()

        // Clean up device data by removing missing services
        coroutineDeviceServicesJobsMap.keys.removeAll {
            services.none { service -> (service.uuid == it) }
        }

        // Init all existing services
        services.forEach { service ->
            val coroutineDeviceServiceJobsMap =
                coroutineDeviceServicesJobsMap[service.uuid] ?: mutableMapOf()

            // Clean up service data by removing missing characteristics
            coroutineDeviceServiceJobsMap.keys.removeAll {
                service.characteristics.none { characteristic -> (characteristic.uuid == it) }
            }

            // Init all existing characteristics
            service.characteristics.forEach { characteristic ->
                if (coroutineDeviceServiceJobsMap[characteristic.uuid] != null) {
                    return
                }

                val coroutineCharacteristicJobsList = mutableListOf<Job>()
                coroutineDeviceServiceJobsMap[characteristic.uuid] = coroutineCharacteristicJobsList

                coroutineScope.launch {
                    characteristic.isNotifying.collect {
                        reportDeviceCharacteristicIsNotifying(device, service, characteristic, it)
                    }
                }.storeIn(coroutineCharacteristicJobsList)

                coroutineScope.launch {
                    characteristic.data.collect {
                        reportDeviceCharacteristicData(device, service, characteristic, it)
                    }
                }.storeIn(coroutineCharacteristicJobsList)
            }

            coroutineDeviceServicesJobsMap[service.uuid] = coroutineDeviceServiceJobsMap
        }

        coroutineDeviceServiceJobs[device.address] = coroutineDeviceServicesJobsMap
    }

    // endregion

    // region Method callback

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> {
                reportState(manager.state.value)
                reportAuthorizationStatus(manager.authorizationStatus.value)
                reportScanEnabled(manager.scanEnabled.value)
                reportDevices(manager.devices.value)
                result.success(null)
                return
            }

            "authorizationRequest" -> {
                val context = activity ?: application ?: run {
                    result.error("Not attached to context", null, null)
                    return
                }

                manager.authorizationRequest(context)
                result.success(null)
                return
            }

            "authorizationOpenSettings" -> {
                val context = activity ?: application ?: run {
                    result.error("Not attached to context", null, null)
                    return
                }

                manager.authorizationOpenSettings(context)
                result.success(null)
                return
            }

            "scanStart" -> {
                val context = activity ?: application ?: run {
                    result.error("Not attached to activity", null, null)
                    return
                }

                val arguments = call.arguments as? Map<*, *>
                val services = arguments?.get("services") as? List<*>
                val serviceUUIDs = services?.filterIsInstance<String>()?.map { BBUUID.fromString(it) }

                manager.scanStart(
                    context = context,
                    serviceUUIDs = serviceUUIDs ?: emptyList()
                )

                result.success(null)
                return
            }

            "scanStop" -> {
                val context = activity ?: application ?: run {
                    result.error("Not attached to activity", null, null)
                    return
                }

                manager.scanStop(context)
                result.success(null)
                return
            }
        }

        if (call.method.startsWith("device")) {
            val arguments = call.arguments as? Map<*, *>

            val deviceId = arguments?.get("deviceId") as? String ?: run {
                result.error("No device ID", null, null)
                return
            }

            val device = manager.devices.value[deviceId] ?: run {
                result.error("Device not found", null, null)
                return
            }

            when (call.method) {
                "deviceConnect" -> {
                    coroutineScope.launch {
                        try {
                            device.connect()
                            result.success(null)
                        } catch (e: Throwable) {
                            result.error("Error", e.message, null)
                        }
                    }
                    return
                }

                "deviceDisconnect" -> {
                    coroutineScope.launch {
                        try {
                            device.disconnect()
                            result.success(null)
                        } catch (e: Throwable) {
                            result.error("Error", e.message, null)
                        }
                    }
                    return
                }

                "deviceDiscoverServices" -> {
                    coroutineScope.launch {
                        try {
                            device.discoverServices()
                            result.success(null)
                        } catch (e: Throwable) {
                            result.error("Error", e.message, null)
                        }
                    }
                    return
                }

                "deviceRequestMTU" -> {
                    val value = arguments["value"] as? Int ?: run {
                        result.error("No value", null, null)
                        return
                    }

                    coroutineScope.launch {
                        try {
                            val newMtu = device.requestMTU(value)
                            result.success(newMtu)
                        } catch (e: Throwable) {
                            result.error("Error", e.message, null)
                        }
                    }
                    return
                }
            }

            if (call.method.startsWith("deviceCharacteristic")) {
                val serviceId = arguments.get("serviceId") as? String ?: run {
                    result.error("No service ID", null, null)
                    return
                }

                val characteristicId = arguments.get("characteristicId") as? String ?: run {
                    result.error("No characteristic ID", null, null)
                    return
                }

                val service =
                    device.services.value.firstOrNull { it.uuid == BBUUID.fromString(serviceId) }
                        ?: run {
                            result.error("Service not found", null, null)
                            return
                        }

                val characteristic = service.characteristics.firstOrNull {
                    it.uuid == BBUUID.fromString(characteristicId)
                } ?: run {
                    result.error("Characteristic not found", null, null)
                    return
                }

                when (call.method) {
                    "deviceCharacteristicRead" -> {
                        coroutineScope.launch {
                            try {
                                val value = characteristic.read()
                                result.success(value)
                            } catch (e: Throwable) {
                                result.error("Error", e.message, null)
                            }
                        }
                        return
                    }

                    "deviceCharacteristicWrite" -> {
                        val value = arguments.get("value") as? ByteArray ?: run {
                            result.error("No value", null, null)
                            return
                        }

                        val withResponse = arguments.get("withResponse") as? Boolean ?: run {
                            result.error("No with-response flag", null, null)
                            return
                        }

                        coroutineScope.launch {
                            try {
                                characteristic.write(value, withResponse)
                                result.success(null)
                            } catch (e: Throwable) {
                                result.error("Error", e.message, null)
                            }
                        }
                        return
                    }

                    "deviceCharacteristicSubscribe" -> {
                        coroutineScope.launch {
                            try {
                                characteristic.subscribe()
                                result.success(null)
                            } catch (e: Throwable) {
                                result.error("Error", e.message, null)
                            }
                        }
                        return
                    }

                    "deviceCharacteristicUnsubscribe" -> {
                        coroutineScope.launch {
                            try {
                                characteristic.unsubscribe()
                                result.success(null)
                            } catch (e: Throwable) {
                                result.error("Error", e.message, null)
                            }
                        }
                        return
                    }
                }
            }
        }

        // If we get here, the message was not processed
        result.notImplemented()
    }

    // endregion

    // region Report values

    private fun reportState(value: BBState) {
        channel.invokeMethod(
            "stateUpdate",
            mapOf(
                "value" to value.name
            )
        )
    }

    private fun reportAuthorizationStatus(value: BBAuthorization) {
        channel.invokeMethod(
            "authorizationStatusUpdate",
            mapOf(
                "value" to value.name
            )
        )
    }

    private fun reportScanEnabled(value: Boolean) {
        channel.invokeMethod(
            "scanEnabledUpdate",
            mapOf(
                "value" to value
            )
        )
    }

    private fun reportScanResult(value: BBScanResult) {
        channel.invokeMethod(
            "scanResultUpdate",
            mapOf(
                "value" to value.toFlutter
            )
        )
    }

    private fun reportDevices(value: Map<String, BBDevice>) {
        channel.invokeMethod(
            "devicesUpdate",
            mapOf(
                "value" to value.values.map { it.toFlutter }
            )
        )
    }

    private fun reportDeviceConnectionStatus(device: BBDevice, value: BBDeviceConnectionStatus) {
        channel.invokeMethod(
            "deviceConnectionStatusUpdate",
            mapOf(
                "deviceId" to device.address,
                "value" to value.name,
            )
        )
    }

    private fun reportDeviceServices(device: BBDevice, value: List<BBService>) {
        channel.invokeMethod(
            "deviceServicesUpdate",
            mapOf(
                "deviceId" to device.address,
                "value" to value.toFlutter,
            )
        )
    }

    private fun reportDeviceMTU(device: BBDevice, value: Int) {
        channel.invokeMethod(
            "deviceMTUUpdate",
            mapOf(
                "deviceId" to device.address,
                "value" to value,
            )
        )
    }

    private fun reportDeviceCharacteristicIsNotifying(
        device: BBDevice,
        service: BBService,
        characteristic: BBCharacteristic,
        value: Boolean
    ) {
        channel.invokeMethod(
            "deviceCharacteristicIsNotifyingUpdate",
            mapOf(
                "deviceId" to device.address,
                "serviceId" to service.uuid.toString(),
                "characteristicId" to characteristic.uuid.toString(),
                "value" to value,
            )
        )
    }

    private fun reportDeviceCharacteristicData(
        device: BBDevice,
        service: BBService,
        characteristic: BBCharacteristic,
        value: ByteArray
    ) {
        channel.invokeMethod(
            "deviceCharacteristicDataUpdate",
            mapOf(
                "deviceId" to device.address,
                "serviceId" to service.uuid.toString(),
                "characteristicId" to characteristic.uuid.toString(),
                "value" to value,
            ),
        )
    }

    // endregion
}

val BBDevice.toFlutter
    get() = mapOf(
        "id" to address,
        "name" to name,
    )

val BBScanResult.toFlutter
    get() = mapOf(
        "id" to address,
        "rssi" to rssi,
        "connectable" to connectable,
        "advertisedServices" to advertisedServices.map { it.toString() },
        "manufacturerId" to manufacturerId,
        "manufacturerString" to manufacturerName,
        "manufacturerData" to manufacturerData
    )

val List<BBService>.toFlutter
    get() = map { it.toFlutter }

val BBService.toFlutter
    get() = mapOf(
        "id" to uuid.toString(),
        "name" to BBConstants.Service.knownUUIDs.get(uuid),
        "characteristics" to characteristics.map { it.toFlutter }
    )

val BBCharacteristic.toFlutter
    get() = mapOf(
        "id" to uuid.toString(),
        "name" to BBConstants.Characteristic.knownUUIDs[uuid],
        "properties" to properties.map { it.name }
    )

fun Job.storeIn(jobs: MutableList<Job>) {
    jobs.add(this)
}