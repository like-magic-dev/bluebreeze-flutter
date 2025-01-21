import 'package:flutter_test/flutter_test.dart';
import 'package:bluebreeze_flutter/bluebreeze_flutter.dart';
import 'package:bluebreeze_flutter/bluebreeze_flutter_platform_interface.dart';
import 'package:bluebreeze_flutter/bluebreeze_flutter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockBluebreezeFlutterPlatform
    with MockPlatformInterfaceMixin
    implements BluebreezeFlutterPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final BluebreezeFlutterPlatform initialPlatform = BluebreezeFlutterPlatform.instance;

  test('$MethodChannelBluebreezeFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelBluebreezeFlutter>());
  });

  test('getPlatformVersion', () async {
    BluebreezeFlutter bluebreezeFlutterPlugin = BluebreezeFlutter();
    MockBluebreezeFlutterPlatform fakePlatform = MockBluebreezeFlutterPlatform();
    BluebreezeFlutterPlatform.instance = fakePlatform;

    expect(await bluebreezeFlutterPlugin.getPlatformVersion(), '42');
  });
}
