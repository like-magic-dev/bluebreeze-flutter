import BlueBreeze
import Flutter
import UIKit
import Combine

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
            result([:])
        case "authorizationRequest":
            manager.authorizationRequest()
            result([:])
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func reportState(_ state: BBState) {
        channel.invokeMethod("stateUpdate", arguments: ["name": "\(state)"])
    }
    
    private func reportAuthorizationStatus(_ authorizationStatus: BBAuthorization) {
        channel.invokeMethod("authorizationStatusUpdate", arguments: ["name": "\(authorizationStatus)"])
    }
}
