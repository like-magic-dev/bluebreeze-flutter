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
    var dispatchBagDevices: Set<UUID> = []
    var dispatchBagCharacteristics: [UUID: Set<BBUUID>] = [:]

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
        
        manager.scanningEnabled
            .receive(on: DispatchQueue.main)
            .sink { self.reportScanningEnabled($0) }
            .store(in: &dispatchBag)
        
        manager.scanningDevices
            .receive(on: DispatchQueue.main)
            .sink {
                self.initDevice($0)
                self.reportScanningDevice($0)
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
        guard !dispatchBagDevices.contains(device.id) else {
            return
        }
        
        dispatchBagDevices.insert(device.id)
        
        device.connectionStatus
            .receive(on: DispatchQueue.main)
            .sink { self.reportDeviceConnectionStatus(device.id, $0) }
            .store(in: &dispatchBag)
        
        device.services
            .receive(on: DispatchQueue.main)
            .sink {
                $0.forEach { service in
                    service.value.forEach { characteristic in
                        self.initCharacteristic(device, service.key, characteristic)
                    }
                }
                self.reportDeviceServices(device.id, $0)
            }
            .store(in: &dispatchBag)
        
        device.mtu
            .receive(on: DispatchQueue.main)
            .sink { self.reportDeviceMTU(device.id, $0) }
            .store(in: &dispatchBag)
    }
    
    private func initCharacteristic(_ device: BBDevice, _ serviceId: BBUUID, _ characteristic: BBCharacteristic) {
        guard dispatchBagCharacteristics[device.id]?.contains(characteristic.id) != true else {
            return
        }
        
        dispatchBagCharacteristics[device.id] = dispatchBagCharacteristics[device.id] ?? []
        dispatchBagCharacteristics[device.id]?.insert(characteristic.id)
        
        characteristic.isNotifying
            .receive(on: DispatchQueue.main)
            .sink { self.reportDeviceCharacteristicIsNotifying(device.id, serviceId, characteristic.id, $0) }
            .store(in: &dispatchBag)

        characteristic.data
            .receive(on: DispatchQueue.main)
            .sink { self.reportDeviceCharacteristicData(device.id, serviceId, characteristic.id, $0) }
            .store(in: &dispatchBag)
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
            reportScanningEnabled(manager.scanningEnabled.value)
            reportDevices(manager.devices.value)
            result([:])
            
        case "authorizationRequest":
            manager.authorizationRequest()
            result([:])
        
        case "scanningStart":
            manager.scanningStart()
            result([:])
        
        case "scanningStop":
            manager.scanningStop()
            result([:])
            
        case "deviceConnect":
            guard let arguments = call.arguments as? [String: Any],
                  let uuidString = arguments["id"] as? String,
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
                  let uuidString = arguments["id"] as? String,
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
                  let uuidString = arguments["id"] as? String,
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
                  let uuidString = arguments["id"] as? String,
                  let uuid = UUID(uuidString: uuidString),
                  let device = manager.devices.value[uuid],
                  let mtu = arguments["mtu"] as? Int
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
                  let uuidString = arguments["id"] as? String,
                  let uuid = UUID(uuidString: uuidString),
                  let device = manager.devices.value[uuid],
                  let serviceUuidString = arguments["serviceId"] as? String,
                  let characteristicUuidString = arguments["characteristicId"] as? String
            else {
                result(FlutterError(code: "Bad arguments", message: nil, details: nil))
                return
            }
            
            guard let service = device.services.value[BBUUID(string: serviceUuidString)],
                  let characteristic = service.first(where: { $0.id == BBUUID(string: characteristicUuidString) })
            else {
                result(FlutterError(code: "Characteristic not found", message: nil, details: nil))
                return
            }

            Task {
                do {
                    try await characteristic.read()
                    result(Data())
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
            "stateUpdate", arguments: [
                "value": "\(value)"
            ]
        )
    }
    
    private func reportAuthorizationStatus(_ value: BBAuthorization) {
        channel.invokeMethod(
            "authorizationStatusUpdate", arguments: [
                "value": "\(value)"
            ]
        )
    }
    
    private func reportScanningEnabled(_ value: Bool) {
        channel.invokeMethod(
            "scanningEnabledUpdate", arguments: [
                "value": value
            ]
        )
    }
    
    private func reportScanningDevice(_ value: BBDevice) {
        channel.invokeMethod(
            "scanningDevicesUpdate", arguments: [
                "value": value.toFlutter
            ]
        )
    }
    
    private func reportDevices(_ value: [UUID: BBDevice]) {
        channel.invokeMethod(
            "devicesUpdate", arguments: [
                "value": value.values.map { $0.toFlutter }
            ]
        )
    }
    
    private func reportDeviceConnectionStatus(_ deviceId: UUID, _ value: BBDeviceConnectionStatus) {
        channel.invokeMethod(
            "deviceConnectionStatusUpdate", arguments: [
                "deviceId": deviceId.uuidString,
                "value": "\(value)"
            ]
        )
    }
    
    private func reportDeviceServices(_ deviceId: UUID, _ value: [BBUUID: [BBCharacteristic]]) {
        channel.invokeMethod(
            "deviceServicesUpdate", arguments: [
                "deviceId": deviceId.uuidString,
                "value": value.toFlutter
            ]
        )
    }
    
    private func reportDeviceMTU(_ deviceId: UUID, _ value: Int) {
        channel.invokeMethod(
            "deviceMTUUpdate", arguments: [
                "deviceId": deviceId.uuidString,
                "value": value
            ]
        )
    }
    
    private func reportDeviceCharacteristicIsNotifying(_ deviceId: UUID, _ serviceId: BBUUID, _ characteristicId: BBUUID, _ value: Bool) {
        channel.invokeMethod(
            "deviceCharacteristicIsNotifyingUpdate", arguments: [
                "deviceId": deviceId.uuidString,
                "serviceId": serviceId.uuidString,
                "characteristicId": characteristicId.uuidString,
                "value": value
            ]
        )
    }
    
    private func reportDeviceCharacteristicData(_ deviceId: UUID, _ serviceId: BBUUID, _ characteristicId: BBUUID, _ value: Data) {
        channel.invokeMethod(
            "deviceCharacteristicDataUpdate", arguments: [
                "deviceId": deviceId.uuidString,
                "serviceId": serviceId.uuidString,
                "characteristicId": characteristicId.uuidString,
                "value": value.toFlutter
            ]
        )
    }
}

extension BBDevice {
    var toFlutter: Dictionary<String, Any> {
        get {
            return [
                "id": id.uuidString,
                "name": name as Any,
                "rssi": rssi,
                "isConnectable": isConnectable,
                "advertisedServices": advertisedServices.map(\.uuidString),
                "manufacturerId": manufacturerId as Any,
                "manufacturerString": manufacturerName as Any,
                "manufacturerData": manufacturerData?.toFlutter as Any
            ]
        }
    }
}

extension [BBUUID: [BBCharacteristic]] {
    var toFlutter: [Dictionary<String, Any>] {
        get {
            return map{[
                "id": $0.key.uuidString,
                "name": BBConstants.knownServices[$0.key] as Any,
                "characteristics": $0.value.map { $0.toFlutter }
            ]}
        }
    }
}

extension BBCharacteristic {
    var toFlutter: Dictionary<String, Any> {
        get {
            return [
                "id": id.uuidString,
                "name": BBConstants.knownCharacteristics[id] as Any,
                "properties": properties.map { "\($0)" }
            ]
        }
    }
}

extension Data {
    var toFlutter: FlutterStandardTypedData {
        get {
            return FlutterStandardTypedData(bytes: self)
        }
    }
}
