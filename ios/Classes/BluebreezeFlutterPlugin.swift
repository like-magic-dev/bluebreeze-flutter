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
            .sink { self.reportDeviceServices(device.id, $0) }
            .store(in: &dispatchBag)
        
        device.mtu
            .receive(on: DispatchQueue.main)
            .sink { self.reportDeviceMTU(device.id, $0) }
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
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func reportState(_ state: BBState) {
        channel.invokeMethod("stateUpdate", arguments: ["name": "\(state)"])
    }
    
    private func reportAuthorizationStatus(_ authorizationStatus: BBAuthorization) {
        channel.invokeMethod(
            "authorizationStatusUpdate", arguments: ["name": "\(authorizationStatus)"])
    }
    
    private func reportScanningEnabled(_ scanningEnabled: Bool) {
        channel.invokeMethod(
            "scanningEnabledUpdate", arguments: ["value": scanningEnabled]
        )
    }
    
    private func reportScanningDevice(_ device: BBDevice) {
        channel.invokeMethod(
            "scanningDevicesUpdate", arguments: device.toFlutter
        )
    }
    
    private func reportDevices(_ devices: [UUID: BBDevice]) {
        channel.invokeMethod(
            "devicesUpdate", arguments: [
                "devices": devices.values.map { $0.toFlutter }
            ]
        )
    }
    
    private func reportDeviceConnectionStatus(_ id: UUID, _ connectionStatus: BBDeviceConnectionStatus) {
        channel.invokeMethod(
            "deviceConnectionStatusUpdate", arguments: [
                "id": id.uuidString,
                "connectionStatus": "\(connectionStatus)"
            ]
        )
    }
    
    private func reportDeviceServices(_ id: UUID, _ services: [BBUUID: [BBCharacteristic]]) {
        channel.invokeMethod(
            "deviceServicesUpdate", arguments: [
                "id": id.uuidString,
                "services": services.map {[
                    "id": $0.key.uuidString,
                    "name": BBConstants.knownServices[$0.key] as Any,
                    "characteristics": $0.value.map {[
                        "id": $0.id.uuidString,
                        "name": BBConstants.knownCharacteristics[$0.id]
                    ]}
                ]}
            ]
        )
    }
    
    private func reportDeviceMTU(_ id: UUID, _ mtu: Int) {
        channel.invokeMethod(
            "deviceMTUUpdate", arguments: [
                "id": id.uuidString,
                "mtu": mtu
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

extension Data {
    var toFlutter: FlutterStandardTypedData {
        get {
            return FlutterStandardTypedData(bytes: self)
        }
    }
}
