//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import 'bluebreeze_device_connection_status.dart';
import 'bluebreeze_service.dart';
import 'impl/bluebreeze_platform_interface.dart';

class BBDevice {
  BBDevice({
    required this.id,
    required this.name,
  });

  final String id;
  final String? name;

  // Services

  List<BBService> get services => BlueBreezePlatform.instance.deviceServices(id);

  Stream<List<BBService>> get servicesStream => BlueBreezePlatform.instance.deviceServicesStream(id);

  // Connection status

  BBDeviceConnectionStatus get connectionStatus => BlueBreezePlatform.instance.deviceConnectionStatus(id);

  Stream<BBDeviceConnectionStatus> get connectionStatusStream => BlueBreezePlatform.instance.deviceConnectionStatusStream(id);

  // Device MTU

  int get mtu => BlueBreezePlatform.instance.deviceMtu(id);

  Stream<int> get mtuStream => BlueBreezePlatform.instance.deviceMtuStream(id);

  // Operations

  Future<void> connect() => BlueBreezePlatform.instance.deviceConnect(id);

  Future<void> disconnect() => BlueBreezePlatform.instance.deviceDisconnect(id);

  Future<void> discoverServices() => BlueBreezePlatform.instance.deviceDiscoverServices(id);

  Future<int> requestMtu(int mtu) => BlueBreezePlatform.instance.deviceRequestMtu(id, mtu);
}
