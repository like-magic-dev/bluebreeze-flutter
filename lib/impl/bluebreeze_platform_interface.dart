import 'package:bluebreeze_flutter/bluebreeze_authorization.dart';
import 'package:bluebreeze_flutter/bluebreeze_state.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'bluebreeze_method_channel.dart';

abstract class BlueBreezePlatform extends PlatformInterface {
  BlueBreezePlatform() : super(token: _token);

  // Singleton

  static final Object _token = Object();

  static BlueBreezePlatform _instance = MethodChannelBlueBreeze();
  static BlueBreezePlatform get instance => _instance;

  static set instance(BlueBreezePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  // State

  BBState get state;

  Stream<BBState> get stateStream;

  // Authorization

  BBAuthorization get authorizationStatus;

  Stream<BBAuthorization> get authorizationStatusStream;

  Future<void> authorizationRequest();
}
