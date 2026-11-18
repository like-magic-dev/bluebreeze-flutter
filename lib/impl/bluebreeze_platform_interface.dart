//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../bluebreeze_authorization.dart';
import '../bluebreeze_device.dart';
import '../bluebreeze_device_connection_status.dart';
import '../bluebreeze_observable.dart';
import '../bluebreeze_scan_result.dart';
import '../bluebreeze_service.dart';
import '../bluebreeze_state.dart';
import 'bluebreeze_method_channel.dart';

/// The federated-plugin extension point BlueBreeze's public API (`BBManager`, `BBDevice`,
/// `BBCharacteristic`) delegates to. [MethodChannelBlueBreeze] is the default implementation,
/// talking to the native Android/iOS SDKs over a `MethodChannel`.
///
/// Most apps never touch this directly -- it exists so alternative implementations (other
/// platform packages, or a mock for testing) can be swapped in via [instance].
abstract class BlueBreezePlatform extends PlatformInterface {
  BlueBreezePlatform() : super(token: _token);

  // Singleton

  static final Object _token = Object();

  static BlueBreezePlatform _instance = MethodChannelBlueBreeze();

  /// The active implementation every `BBManager`/`BBDevice`/`BBCharacteristic` call delegates
  /// to. Defaults to [MethodChannelBlueBreeze]; set this to a different implementation (e.g.
  /// a mock) before exercising the public API in tests.
  static BlueBreezePlatform get instance => _instance;

  static set instance(BlueBreezePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  // State

  BBObservable<BBState> get state;

  // Authorization

  BBObservable<BBAuthorization> get authorizationStatus;

  Future<void> authorizationRequest();

  Future<void> authorizationOpenSettings();

  // Capabilities

  bool get supportsExtended;

  // Scan

  BBObservable<bool> get scanEnabled;

  Stream<BBScanResult> get scanResultsStream;

  Future<void> scanStart({List<String>? services});

  Future<void> scanStop();

  // Devices

  BBObservable<Map<String, BBDevice>> get devices;

  // Device services

  BBObservable<List<BBService>> deviceServices(String id);

  // Device connection status

  BBObservable<BBDeviceConnectionStatus> deviceConnectionStatus(String id);

  // Device MTU

  BBObservable<int> deviceMtu(String id);

  // Device operations

  Future<void> deviceConnect(String id);

  Future<void> deviceDisconnect(String id);

  Future<void> deviceDiscoverServices(String id);

  Future<int> deviceRequestMtu(String id, int value);

  // Device characteristic data

  BBObservable<Uint8List> deviceCharacteristicData(String id, String serviceId, String characteristicId);

  // Device characteristic notify enabled

  BBObservable<bool> deviceCharacteristicIsNotifying(String id, String serviceId, String characteristicId);

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
