import 'dart:async';

import 'package:bluebreeze_flutter/bluebreeze_authorization.dart';
import 'package:bluebreeze_flutter/bluebreeze_state.dart';

import 'impl/bluebreeze_platform_interface.dart';

class BBManager {
  // State

  BBState get state => BlueBreezePlatform.instance.state;

  Stream<BBState> get stateStream => BlueBreezePlatform.instance.stateStream;

  // Authorization

  BBAuthorization get authorizationStatus => BlueBreezePlatform.instance.authorizationStatus;

  Stream<BBAuthorization> get authorizationStatusStream => BlueBreezePlatform.instance.authorizationStatusStream;

  Future authorizationRequest() => BlueBreezePlatform.instance.authorizationRequest();
}
