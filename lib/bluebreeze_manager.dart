//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import 'dart:async';

import 'bluebreeze_authorization.dart';
import 'bluebreeze_device.dart';
import 'bluebreeze_scan_result.dart';
import 'bluebreeze_state.dart';
import 'impl/bluebreeze_platform_interface.dart';

class BBManager {
  // State

  BBState get state => BlueBreezePlatform.instance.state;

  Stream<BBState> get stateStream => BlueBreezePlatform.instance.stateStream;

  // Authorization

  BBAuthorization get authorizationStatus => BlueBreezePlatform.instance.authorizationStatus;

  Stream<BBAuthorization> get authorizationStatusStream => BlueBreezePlatform.instance.authorizationStatusStream;

  Future<void> authorizationRequest() => BlueBreezePlatform.instance.authorizationRequest();

  Future<void> authorizationOpenSettings() => BlueBreezePlatform.instance.authorizationOpenSettings();

  // Capabilities

  bool get supportsExtended => BlueBreezePlatform.instance.supportsExtended;

  // Scan

  bool get scanEnabled => BlueBreezePlatform.instance.scanEnabled;

  Stream<bool> get scanEnabledStream => BlueBreezePlatform.instance.scanEnabledStream;

  Stream<BBScanResult> get scanResultsStream => BlueBreezePlatform.instance.scanResultsStream;

  Future<void> scanStart({List<String>? services}) => BlueBreezePlatform.instance.scanStart(services: services);

  Future<void> scanStop() => BlueBreezePlatform.instance.scanStop();

  // Devices

  Map<String, BBDevice> get devices => BlueBreezePlatform.instance.devices;

  Stream<Map<String, BBDevice>> get devicesStream => BlueBreezePlatform.instance.devicesStream;

  // Cleanup

  void releaseDevice(String id) => BlueBreezePlatform.instance.releaseDevice(id);

  // Developer tools

  void handleHotReload() => BlueBreezePlatform.instance.handleHotReload();
}
