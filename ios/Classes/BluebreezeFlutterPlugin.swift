//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import BlueBreeze
import Combine
import Flutter
import UIKit

public class BluebreezeFlutterPlugin: NSObject, FlutterPlugin {
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

    private func initServices(_ device: BBDevice, _ services: [BBUUID: [BBCharacteristic]]) {
        // Clean up device data by removing missing services
        dispatchBagServices[device.id] =
            dispatchBagServices[device.id]?.filter({ key, value in
                services[key] != nil
            }) ?? [:]

        // Init all existing services
        services.forEach { serviceId, value in
            // Clean up service data by removing missing characteristics
            dispatchBagServices[device.id]![serviceId] =
                dispatchBagServices[device.id]![serviceId]?.filter({ key, _ in
                    value.first(where: { $0.id == key }) != nil
                }) ?? [:]

            // Init all existing characteristics
            value.forEach { characteristic in
                guard dispatchBagServices[device.id]![serviceId]![characteristic.id] == nil else {
                    return
                }

                dispatchBagServices[device.id]![serviceId]![characteristic.id] = []

                characteristic.isNotifying
                    .receive(on: DispatchQueue.main)
                    .sink {
                        self.reportDeviceCharacteristicIsNotifying(
                            device.id, serviceId, characteristic.id, $0)
                    }
                    .store(in: &dispatchBagServices[device.id]![serviceId]![characteristic.id]!)

                characteristic.data
                    .receive(on: DispatchQueue.main)
                    .sink {
                        self.reportDeviceCharacteristicData(
                            device.id, serviceId, characteristic.id, $0)
                    }
                    .store(in: &dispatchBagServices[device.id]![serviceId]![characteristic.id]!)
            }
        }
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "bluebreeze",
            binaryMessenger: registrar.messenger()
        )
        let instance = BluebreezeFlutterPlugin(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            reportState(manager.state.value)
            reportAuthorizationStatus(manager.authorizationStatus.value)
            reportScanEnabled(manager.scanEnabled.value)
            reportDevices(manager.devices.value)
            result([:])

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
                let device = manager.devices.value[uuid],
                let mtu = arguments["value"] as? Int
            else {
                result(FlutterError(code: "Bad arguments", message: nil, details: nil))
                return
            }

            Task {
                do {
                    try await device.requestMTU(mtu)
                    result(mtu)
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

            guard let service = device.services.value[BBUUID(string: serviceUuidString)],
                let characteristic = service.first(where: {
                    $0.id == BBUUID(string: characteristicUuidString)
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

            guard let service = device.services.value[BBUUID(string: serviceUuidString)],
                let characteristic = service.first(where: {
                    $0.id == BBUUID(string: characteristicUuidString)
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

            guard let service = device.services.value[BBUUID(string: serviceUuidString)],
                let characteristic = service.first(where: {
                    $0.id == BBUUID(string: characteristicUuidString)
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

            guard let service = device.services.value[BBUUID(string: serviceUuidString)],
                let characteristic = service.first(where: {
                    $0.id == BBUUID(string: characteristicUuidString)
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

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func reportState(_ value: BBState) {
        channel.invokeMethod(
            "stateUpdate",
            arguments: [
                "value": "\(value)"
            ]
        )
    }

    private func reportAuthorizationStatus(_ value: BBAuthorization) {
        channel.invokeMethod(
            "authorizationStatusUpdate",
            arguments: [
                "value": "\(value)"
            ]
        )
    }

    private func reportScanEnabled(_ value: Bool) {
        channel.invokeMethod(
            "scanEnabledUpdate",
            arguments: [
                "value": value
            ]
        )
    }

    private func reportScanResult(_ value: BBScanResult) {
        channel.invokeMethod(
            "scanResultUpdate",
            arguments: [
                "value": value.toFlutter
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
                "value": "\(value)",
            ]
        )
    }

    private func reportDeviceServices(_ deviceId: UUID, _ value: [BBUUID: [BBCharacteristic]]) {
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
            "manufacturerString": manufacturerName as Any,
            "manufacturerData": manufacturerData?.toFlutter as Any,
        ]
    }
}

extension [BBUUID: [BBCharacteristic]] {
    var toFlutter: [[String: Any]] {
        return map {
            [
                "id": $0.key.uuidString,
                "name": BBConstants.knownServices[$0.key] as Any,
                "characteristics": $0.value.map { $0.toFlutter },
            ]
        }
    }
}

extension BBCharacteristic {
    var toFlutter: [String: Any] {
        return [
            "id": id.uuidString,
            "name": BBConstants.knownCharacteristics[id] as Any,
            "properties": properties.map { "\($0)" },
        ]
    }
}

extension Data {
    var toFlutter: FlutterStandardTypedData {
        return FlutterStandardTypedData(bytes: self)
    }
}
