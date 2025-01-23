//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import 'dart:async';

import 'package:bluebreeze_flutter/bluebreeze_authorization.dart';
import 'package:bluebreeze_flutter/bluebreeze_device.dart';
import 'package:bluebreeze_flutter/bluebreeze_scan_result.dart';
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

  // Scan

  bool get scanEnabled => BlueBreezePlatform.instance.scanEnabled;

  Stream<bool> get scanEnabledStream => BlueBreezePlatform.instance.scanEnabledStream;

  Stream<BBScanResult> get scanResultsStream => BlueBreezePlatform.instance.scanResultsStream;

  Future scanStart() => BlueBreezePlatform.instance.scanStart();

  Future scanStop() => BlueBreezePlatform.instance.scanStop();

  // Devices

  Map<String, BBDevice> get devices => BlueBreezePlatform.instance.devices;

  Stream<Map<String, BBDevice>> get devicesStream => BlueBreezePlatform.instance.devicesStream;
}
