//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import 'package:bluebreeze_flutter/bluebreeze_authorization.dart';
import 'package:bluebreeze_flutter/bluebreeze_device.dart';
import 'package:bluebreeze_flutter/bluebreeze_device_connection_status.dart';
import 'package:bluebreeze_flutter/bluebreeze_service.dart';
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

  Future authorizationRequest();

  // Scanning

  bool get scanningEnabled;

  Stream<bool> get scanningEnabledStream;

  Stream<BBDevice> get scanningDevicesStream;

  Future scanningStart();

  Future scanningStop();

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

  int deviceMTU(String id);

  Stream<int> deviceMTUStream(String id);

  // Device operation

  Future deviceConnect(String id);

  Future deviceDisconnect(String id);

  Future deviceDiscoverServices(String id);

  Future<int> deviceRequestMTU(String id, int mtu);

  // // Device characteristic data

  // Uint8List deviceCharacteristicData(String id, String serviceId, String characteristicId);

  // Stream<Uint8List> deviceCharacteristicDataStream(String id, String serviceId, String characteristicId);

  // // Device characteristic notify enabled

  // bool deviceCharacteristicNotifyEnabled(String id, String serviceId, String characteristicId);

  // Stream<bool> deviceCharacteristicNotifyEnabledStream(String id, String serviceId, String characteristicId);

  // // Device characteristic operations

  // Future<Uint8List> deviceCharacteristicRead(String id, String serviceId, String characteristicId);

  // Future deviceCharacteristicWrite(
  //     String id, String serviceId, String characteristicId, Uint8List data, bool withResponse);

  // Future deviceCharacteristicSubscribe(String id, String serviceId, String characteristicId);

  // Future deviceCharacteristicUnsubscribe(String id, String serviceId, String characteristicId);
}
