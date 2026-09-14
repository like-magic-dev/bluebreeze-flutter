//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import BlueBreeze
import Combine
import Flutter
import UIKit

public class BluebreezePlugin: NSObject, FlutterPlugin {
    let channel: FlutterMethodChannel
    let manager = BBManager()

    var dispatchBag: Set<AnyCancellable> = []
    var dispatchBagDevices: [UUID: Set<AnyCancellable>] = [:]
    var dispatchBagServices: [UUID: [BBUUID: [BBUUID: Set<AnyCancellable>]]] = [:]

    init(channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()

        manager.state
            .receive(on: DispatchQueue.main)
            .sink { self.reportState($0) }
            .store(in: &dispatchBag)

        manager.authorizationStatus
            .receive(on: DispatchQueue.main)
            .sink { self.reportAuthorizationStatus($0) }
            .store(in: &dispatchBag)

        manager.scanEnabled
            .receive(on: DispatchQueue.main)
            .sink { self.reportScanEnabled($0) }
            .store(in: &dispatchBag)

        manager.scanResults
            .receive(on: DispatchQueue.main)
            .sink {
                self.reportScanResult($0)
            }
            .store(in: &dispatchBag)

        manager.devices
            .receive(on: DispatchQueue.main)
            .sink {
                $0.forEach { self.initDevice($0.value) }
                self.reportDevices($0)
            }
            .store(in: &dispatchBag)
    }

    private func initDevice(_ device: BBDevice) {
        guard dispatchBagDevices[device.id] == nil else {
            return
        }

        dispatchBagDevices[device.id] = []

        device.connectionStatus
            .receive(on: DispatchQueue.main)
            .sink { self.reportDeviceConnectionStatus(device.id, $0) }
            .store(in: &dispatchBagDevices[device.id]!)

        device.services
            .receive(on: DispatchQueue.main)
            .sink {
                self.initServices(device, $0)
                self.reportDeviceServices(device.id, $0)
            }
            .store(in: &dispatchBagDevices[device.id]!)

        device.mtu
            .receive(on: DispatchQueue.main)
            .sink { self.reportDeviceMTU(device.id, $0) }
            .store(in: &dispatchBagDevices[device.id]!)
    }

    private func initServices(_ device: BBDevice, _ services: [BBService]) {
        let serviceUUIDs = Set(services.map { $0.uuid })

        // Clean up device data by removing missing services
        dispatchBagServices[device.id] =
            dispatchBagServices[device.id]?.filter({ key, _ in
                serviceUUIDs.contains(key)
            }) ?? [:]

        // Init all existing services
        services.forEach { service in
            let serviceId = service.uuid
            let characteristicUUIDs = Set(service.characteristics.map { $0.uuid })

            // Clean up service data by removing missing characteristics
            dispatchBagServices[device.id]![serviceId] =
                dispatchBagServices[device.id]![serviceId]?.filter({ key, _ in
                    characteristicUUIDs.contains(key)
                }) ?? [:]

            // Init all existing characteristics
            service.characteristics.forEach { characteristic in
                guard dispatchBagServices[device.id]![serviceId]![characteristic.uuid] == nil else {
                    return
                }

                dispatchBagServices[device.id]![serviceId]![characteristic.uuid] = []

                characteristic.isNotifying
                    .receive(on: DispatchQueue.main)
                    .sink {
                        self.reportDeviceCharacteristicIsNotifying(
                            device.id, serviceId, characteristic.uuid, $0)
                    }
                    .store(in: &dispatchBagServices[device.id]![serviceId]![characteristic.uuid]!)

                characteristic.data
                    .receive(on: DispatchQueue.main)
                    .compactMap { $0 }
                    .sink {
                        self.reportDeviceCharacteristicData(
                            device.id, serviceId, characteristic.uuid, $0)
                    }
                    .store(in: &dispatchBagServices[device.id]![serviceId]![characteristic.uuid]!)
            }
        }
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "bluebreeze",
            binaryMessenger: registrar.messenger()
        )
        let instance = BluebreezePlugin(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            reportState(manager.state.value)
            reportAuthorizationStatus(manager.authorizationStatus.value)
            reportScanEnabled(manager.scanEnabled.value)
            reportDevices(manager.devices.value)
            result([
                "supportsExtended": manager.supportsExtended
            ])

        case "authorizationRequest":
            manager.authorizationRequest()
            result([:])

        case "authorizationOpenSettings":
            manager.authorizationOpenSettings()
            result([:])

        case "scanStart":
            let arguments = call.arguments as? [String: Any]
            let services = arguments?["services"] as? [String]
            manager.scanStart(serviceUuids: services?.map({
                BBUUID(string: $0)
            }))
            result([:])

        case "scanStop":
            manager.scanStop()
            result([:])

        case "deviceConnect":
            guard let arguments = call.arguments as? [String: Any],
                let uuidString = arguments["deviceId"] as? String,
                let uuid = UUID(uuidString: uuidString),
                let device = manager.devices.value[uuid]
            else {
                result(FlutterError(code: "Bad arguments", message: nil, details: nil))
                return
            }

            Task {
                do {
                    try await device.connect()
                    result([:])
                } catch {
                    result(FlutterError(code: "Error", message: nil, details: nil))
                }
            }

        case "deviceDisconnect":
            guard let arguments = call.arguments as? [String: Any],
                let uuidString = arguments["deviceId"] as? String,
                let uuid = UUID(uuidString: uuidString),
                let device = manager.devices.value[uuid]
            else {
                result(FlutterError(code: "Bad arguments", message: nil, details: nil))
                return
            }

            Task {
                do {
                    try await device.disconnect()
                    result([:])
                } catch {
                    result(FlutterError(code: "Error", message: nil, details: nil))
                }
            }

        case "deviceDiscoverServices":
            guard let arguments = call.arguments as? [String: Any],
                let uuidString = arguments["deviceId"] as? String,
                let uuid = UUID(uuidString: uuidString),
                let device = manager.devices.value[uuid]
            else {
                result(FlutterError(code: "Bad arguments", message: nil, details: nil))
                return
            }

            Task {
                do {
                    try await device.discoverServices()
                    result([:])
                } catch {
                    result(FlutterError(code: "Error", message: nil, details: nil))
                }
            }

        case "deviceRequestMTU":
            guard let arguments = call.arguments as? [String: Any],
                let uuidString = arguments["deviceId"] as? String,
                let uuid = UUID(uuidString: uuidString),
                let device = manager.devices.value[uuid]
            else {
                result(FlutterError(code: "Bad arguments", message: nil, details: nil))
                return
            }

            Task {
                do {
                    // iOS negotiates the MTU automatically as part of connecting; there is no
                    // API to request a specific value, so this only reads back the result.
                    try await device.negotiateMTU()
                    result(device.mtu.value)
                } catch {
                    result(FlutterError(code: "Error", message: nil, details: nil))
                }
            }

        case "deviceCharacteristicRead":
            guard let arguments = call.arguments as? [String: Any],
                let uuidString = arguments["deviceId"] as? String,
                let uuid = UUID(uuidString: uuidString),
                let device = manager.devices.value[uuid],
                let serviceUuidString = arguments["serviceId"] as? String,
                let characteristicUuidString = arguments["characteristicId"] as? String
            else {
                result(FlutterError(code: "Bad arguments", message: nil, details: nil))
                return
            }

            guard let service = device.services.value.first(where: {
                    $0.uuid == BBUUID(string: serviceUuidString)
                }),
                let characteristic = service.characteristics.first(where: {
                    $0.uuid == BBUUID(string: characteristicUuidString)
                })
            else {
                result(FlutterError(code: "Characteristic not found", message: nil, details: nil))
                return
            }

            Task {
                do {
                    let value = try await characteristic.read()
                    result(value ?? Data())
                } catch {
                    result(FlutterError(code: "Error", message: nil, details: nil))
                }
            }

        case "deviceCharacteristicWrite":
            guard let arguments = call.arguments as? [String: Any],
                let uuidString = arguments["deviceId"] as? String,
                let uuid = UUID(uuidString: uuidString),
                let device = manager.devices.value[uuid],
                let serviceUuidString = arguments["serviceId"] as? String,
                let characteristicUuidString = arguments["characteristicId"] as? String,
                let value = arguments["value"] as? FlutterStandardTypedData,
                let withResponse = arguments["withResponse"] as? Bool
            else {
                result(FlutterError(code: "Bad arguments", message: nil, details: nil))
                return
            }

            guard let service = device.services.value.first(where: {
                    $0.uuid == BBUUID(string: serviceUuidString)
                }),
                let characteristic = service.characteristics.first(where: {
                    $0.uuid == BBUUID(string: characteristicUuidString)
                })
            else {
                result(FlutterError(code: "Characteristic not found", message: nil, details: nil))
                return
            }

            Task {
                do {
                    try await characteristic.write(value.data, withResponse: withResponse)
                    result([:])
                } catch {
                    result(FlutterError(code: "Error", message: nil, details: nil))
                }
            }

        case "deviceCharacteristicSubscribe":
            guard let arguments = call.arguments as? [String: Any],
                let uuidString = arguments["deviceId"] as? String,
                let uuid = UUID(uuidString: uuidString),
                let device = manager.devices.value[uuid],
                let serviceUuidString = arguments["serviceId"] as? String,
                let characteristicUuidString = arguments["characteristicId"] as? String
            else {
                result(FlutterError(code: "Bad arguments", message: nil, details: nil))
                return
            }

            guard let service = device.services.value.first(where: {
                    $0.uuid == BBUUID(string: serviceUuidString)
                }),
                let characteristic = service.characteristics.first(where: {
                    $0.uuid == BBUUID(string: characteristicUuidString)
                })
            else {
                result(FlutterError(code: "Characteristic not found", message: nil, details: nil))
                return
            }

            Task {
                do {
                    try await characteristic.subscribe()
                    result([:])
                } catch {
                    result(FlutterError(code: "Error", message: nil, details: nil))
                }
            }

        case "deviceCharacteristicUnsubscribe":
            guard let arguments = call.arguments as? [String: Any],
                let uuidString = arguments["deviceId"] as? String,
                let uuid = UUID(uuidString: uuidString),
                let device = manager.devices.value[uuid],
                let serviceUuidString = arguments["serviceId"] as? String,
                let characteristicUuidString = arguments["characteristicId"] as? String
            else {
                result(FlutterError(code: "Bad arguments", message: nil, details: nil))
                return
            }

            guard let service = device.services.value.first(where: {
                    $0.uuid == BBUUID(string: serviceUuidString)
                }),
                let characteristic = service.characteristics.first(where: {
                    $0.uuid == BBUUID(string: characteristicUuidString)
                })
            else {
                result(FlutterError(code: "Characteristic not found", message: nil, details: nil))
                return
            }

            Task {
                do {
                    try await characteristic.unsubscribe()
                    result([:])
                } catch {
                    result(FlutterError(code: "Error", message: nil, details: nil))
                }
            }

        case "handleHotReload":
            // Nothing to do on iOS
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func reportState(_ value: BBState) {
        channel.invokeMethod(
            "stateUpdate",
            arguments: [
                "value": value.toFlutter,
            ]
        )
    }

    private func reportAuthorizationStatus(_ value: BBAuthorization) {
        channel.invokeMethod(
            "authorizationStatusUpdate",
            arguments: [
                "value": value.toFlutter,
            ]
        )
    }

    private func reportScanEnabled(_ value: Bool) {
        channel.invokeMethod(
            "scanEnabledUpdate",
            arguments: [
                "value": value,
            ]
        )
    }

    private func reportScanResult(_ value: BBScanResult) {
        channel.invokeMethod(
            "scanResultUpdate",
            arguments: [
                "value": value.toFlutter,
            ]
        )
    }

    private func reportDevices(_ value: [UUID: BBDevice]) {
        channel.invokeMethod(
            "devicesUpdate",
            arguments: [
                "value": value.values.map { $0.toFlutter }
            ]
        )
    }

    private func reportDeviceConnectionStatus(_ deviceId: UUID, _ value: BBDeviceConnectionStatus) {
        channel.invokeMethod(
            "deviceConnectionStatusUpdate",
            arguments: [
                "deviceId": deviceId.uuidString,
                "value": value.toFlutter,
            ]
        )
    }

    private func reportDeviceServices(_ deviceId: UUID, _ value: [BBService]) {
        channel.invokeMethod(
            "deviceServicesUpdate",
            arguments: [
                "deviceId": deviceId.uuidString,
                "value": value.toFlutter,
            ]
        )
    }

    private func reportDeviceMTU(_ deviceId: UUID, _ value: Int) {
        channel.invokeMethod(
            "deviceMTUUpdate",
            arguments: [
                "deviceId": deviceId.uuidString,
                "value": value,
            ]
        )
    }

    private func reportDeviceCharacteristicIsNotifying(
        _ deviceId: UUID, _ serviceId: BBUUID, _ characteristicId: BBUUID, _ value: Bool
    ) {
        channel.invokeMethod(
            "deviceCharacteristicIsNotifyingUpdate",
            arguments: [
                "deviceId": deviceId.uuidString,
                "serviceId": serviceId.uuidString,
                "characteristicId": characteristicId.uuidString,
                "value": value,
            ]
        )
    }

    private func reportDeviceCharacteristicData(
        _ deviceId: UUID, _ serviceId: BBUUID, _ characteristicId: BBUUID, _ value: Data
    ) {
        channel.invokeMethod(
            "deviceCharacteristicDataUpdate",
            arguments: [
                "deviceId": deviceId.uuidString,
                "serviceId": serviceId.uuidString,
                "characteristicId": characteristicId.uuidString,
                "value": value.toFlutter,
            ]
        )
    }
}

/// Converters to flutter

extension BBState {
    var toFlutter: String {
        switch self {
            case .unknown: return "unknown"
            case .resetting: return "resetting"
            case .unsupported: return "unsupported"
            case .unauthorized: return "unauthorized"
            case .poweredOff: return "poweredOff"
            case .poweredOn: return "poweredOn"
        }
    }
}

extension BBAuthorization {
    var toFlutter: String {
        switch self {
            case .unknown: return "unknown"
            case .denied: return "denied"
            case .authorized: return "authorized"
        }
    }
}

extension BBDeviceConnectionStatus {
    var toFlutter: String {
        switch self {
            case .disconnected: return "disconnected"
            case .connected: return "connected"
        }
    }
}

extension BBDevice {
    var toFlutter: [String: Any] {
        return [
            "id": id.uuidString,
            "name": name as Any,
        ]
    }
}

extension BBScanResult {
    var toFlutter: [String: Any] {
        return [
            "id": device.id.uuidString,
            "name": name as Any,
            "rssi": rssi,
            "connectable": connectable,
            "advertisedServices": advertisedServices.map(\.uuidString),
            "manufacturerId": manufacturerId as Any,
            "manufacturerName": manufacturerName as Any,
            "manufacturerData": manufacturerData?.toFlutter as Any,
        ]
    }
}

extension [BBService] {
    var toFlutter: [[String: Any]] {
        return map {
            [
                "id": $0.uuid.uuidString,
                "name": BBAssignedNumbers.serviceUUIDs[$0.uuid] as Any,
                "characteristics": $0.characteristics.map { $0.toFlutter },
            ]
        }
    }
}

extension BBCharacteristic {
    var toFlutter: [String: Any] {
        return [
            "id": uuid.uuidString,
            "name": BBAssignedNumbers.characteristicUUIDs[uuid] as Any,
            "properties": properties.map { $0.toFlutter },
        ]
    }
}

extension BBCharacteristicProperty {
    var toFlutter: String {
        switch self {
            case .read: return "read"
            case .writeWithResponse: return "writeWithResponse"
            case .writeWithoutResponse: return "writeWithoutResponse"
            case .notify: return "notify"
        }
    }
}

extension Data {
    var toFlutter: FlutterStandardTypedData {
        return FlutterStandardTypedData(bytes: self)
    }
}
