import 'dart:async';

import 'package:bluebreeze_flutter/bluebreeze_authorization.dart';
import 'package:bluebreeze_flutter/bluebreeze_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'bluebreeze_platform_interface.dart';

class MethodChannelBlueBreeze extends BlueBreezePlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('bluebreeze');

  MethodChannelBlueBreeze() {
    methodChannel.setMethodCallHandler(methodCallHandler);
    methodChannel.invokeMethod('initialize');
  }

  Future<dynamic> methodCallHandler(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'stateUpdate':
        state = BBState.values.firstWhere(
          (v) => (v.name == methodCall.arguments['name']),
        );
        _stateStreamController.sink.add(state);
        return;

      case 'authorizationStatusUpdate':
        authorizationStatus = BBAuthorization.values.firstWhere(
          (v) => (v.name == methodCall.arguments['name']),
        );
        _authorizationStatusStreamController.sink.add(authorizationStatus);
        return;

      default:
        if (kDebugMode) {
          print('Unprocessed event ${methodCall.method} with payload ${methodCall.arguments}');
        }
    }
  }

  // State

  final _stateStreamController = StreamController<BBState>.broadcast();

  @override
  BBState state = BBState.unknown;

  @override
  Stream<BBState> get stateStream => _stateStreamController.stream;

  // Authorization

  final _authorizationStatusStreamController = StreamController<BBAuthorization>.broadcast();

  @override
  BBAuthorization authorizationStatus = BBAuthorization.unknown;

  @override
  Stream<BBAuthorization> get authorizationStatusStream => _authorizationStatusStreamController.stream;

  @override
  Future<void> authorizationRequest() => methodChannel.invokeMethod('authorizationRequest');
  // methodChannel.invokeMethod('permissionsCheck').cast<String>();
}
