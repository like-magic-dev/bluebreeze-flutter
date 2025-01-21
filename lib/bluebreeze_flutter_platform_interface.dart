import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'bluebreeze_flutter_method_channel.dart';

abstract class BluebreezeFlutterPlatform extends PlatformInterface {
  /// Constructs a BluebreezeFlutterPlatform.
  BluebreezeFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static BluebreezeFlutterPlatform _instance = MethodChannelBluebreezeFlutter();

  /// The default instance of [BluebreezeFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelBluebreezeFlutter].
  static BluebreezeFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [BluebreezeFlutterPlatform] when
  /// they register themselves.
  static set instance(BluebreezeFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
