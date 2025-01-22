import BlueBreeze
import Combine
import Flutter
import UIKit

public class BluebreezeFlutterPlugin: NSObject, FlutterPlugin {
    let channel: FlutterMethodChannel
    let manager = BBManager()

    var dispatchBag: Set<AnyCancellable> = []

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
            .sink { self.reportScanningDevice($0) }
            .store(in: &dispatchBag)
        
        manager.devices
            .receive(on: DispatchQueue.main)
            .sink { self.reportDevices($0) }
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
            "scanningDevicesUpdate", arguments: device.dict
        )
    }
    
    private func reportDevices(_ devices: [UUID: BBDevice]) {
        channel.invokeMethod(
            "devicesUpdate", arguments: [
                "devices": devices.values.map { $0.dict }
            ]
        )
    }
}

extension BBDevice {
    var dict: Dictionary<String, Any> {
        get {
            return [
                "id": id.uuidString,
                "name": name as Any,
                "rssi": rssi,
                "isConnectable": isConnectable,
//                        "advertisementData": $0.advertisementData,
                "advertisedServices": advertisedServices.map(\.uuidString),
                "manufacturerId": manufacturerId as Any,
                "manufacturerString": manufacturerName as Any
            ]
        }
    }
}
