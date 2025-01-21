import BlueBreeze
import Flutter
import UIKit

public class BluebreezeFlutterPlugin: NSObject, FlutterPlugin {
    let manager = BBManager()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "bluebreeze_flutter", binaryMessenger: registrar.messenger())
        let instance = BluebreezeFlutterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS \(UIDevice.current.systemVersion) \(manager.authorizationStatus.value)")
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
