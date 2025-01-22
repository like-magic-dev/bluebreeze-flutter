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

    private func reportDevices(_ devices: [UUID: BBDevice]) {
        channel.invokeMethod(
            "devicesUpdate", arguments: [
                "devices": devices.values.map {
                    [
                        "id": $0.id.uuidString,
                        "name": $0.name as Any,
                        "rssi": $0.rssi,
                        "isConnectable": $0.isConnectable,
//                        "advertisementData": $0.advertisementData,
                        "advertisedServices": $0.advertisedServices.map(\.uuidString),
                        "manufacturerId": $0.manufacturerId as Any,
                        "manufacturerString": $0.manufacturerName as Any
                    ]
                }
            ])
    }
}
