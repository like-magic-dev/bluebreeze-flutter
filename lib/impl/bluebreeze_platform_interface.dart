//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../bluebreeze_authorization.dart';
import '../bluebreeze_device.dart';
import '../bluebreeze_device_connection_status.dart';
import '../bluebreeze_scan_result.dart';
import '../bluebreeze_service.dart';
import '../bluebreeze_state.dart';
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

  Future<void> authorizationOpenSettings();

  // Capabilities

  bool get supportsExtended;

  // Scan

  bool get scanEnabled;

  Stream<bool> get scanEnabledStream;

  Stream<BBScanResult> get scanResultsStream;

  Future<void> scanStart({List<String>? services});

  Future<void> scanStop();

  // Devices

  Map<String, BBDevice> get devices;

  Stream<Map<String, BBDevice>> get devicesStream;

  // Device services

  List<BBService> deviceServices(String id);

  Stream<List<BBService>> deviceServicesStream(String id);

  // Device connection status

  BBDeviceConnectionStatus deviceConnectionStatus(String id);

  Stream<BBDeviceConnectionStatus> deviceConnectionStatusStream(String id);

  // Device MTU

  int deviceMtu(String id);

  Stream<int> deviceMtuStream(String id);

  // Device operations

  Future<void> deviceConnect(String id);

  Future<void> deviceDisconnect(String id);

  Future<void> deviceDiscoverServices(String id);

  Future<int> deviceRequestMtu(String id, int value);

  // Device characteristic data

  Uint8List deviceCharacteristicData(String id, String serviceId, String characteristicId);

  Stream<Uint8List> deviceCharacteristicDataStream(String id, String serviceId, String characteristicId);

  // Device characteristic notify enabled

  bool deviceCharacteristicNotifyEnabled(String id, String serviceId, String characteristicId);

  Stream<bool> deviceCharacteristicNotifyEnabledStream(String id, String serviceId, String characteristicId);

  // Device characteristic operations

  Future<Uint8List> deviceCharacteristicRead(String id, String serviceId, String characteristicId);

  Future<void> deviceCharacteristicWrite(String id, String serviceId, String characteristicId, Uint8List value, bool withResponse);

  Future<void> deviceCharacteristicSubscribe(String id, String serviceId, String characteristicId);

  Future<void> deviceCharacteristicUnsubscribe(String id, String serviceId, String characteristicId);

  // Resource cleanup

  void releaseDevice(String id);

  // Developer tools

  void handleHotReload();
}
