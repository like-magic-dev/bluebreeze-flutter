import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'bluebreeze_flutter_platform_interface.dart';

/// An implementation of [BluebreezeFlutterPlatform] that uses method channels.
class MethodChannelBluebreezeFlutter extends BluebreezeFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('bluebreeze_flutter');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
