//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import 'dart:ffi';

import 'package:bluebreeze_flutter/bluebreeze_device_connection_status.dart';
import 'package:bluebreeze_flutter/bluebreeze_service.dart';
import 'package:bluebreeze_flutter/impl/bluebreeze_platform_interface.dart';
import 'package:flutter/foundation.dart';

class BBDevice {
  BBDevice({
    required this.id,
    required this.name,
  });

  final String id;
  final String? name;

  int rssi = 0;
  var isConnectable = false;

  Map<Uint8, Uint8List> advertisementData = {};

  List<String> advertisedServices = [];

  int? manufacturerId;
  String? manufacturerName;

  // Services

  List<BBService> get services => BlueBreezePlatform.instance.deviceServices(id);

  Stream<List<BBService>> get servicesStream => BlueBreezePlatform.instance.deviceServicesStream(id);

  // Connection status

  BBDeviceConnectionStatus get connectionStatus => BlueBreezePlatform.instance.deviceConnectionStatus(id);

  Stream<BBDeviceConnectionStatus> get connectionStatusStream => BlueBreezePlatform.instance.deviceConnectionStatusStream(id);

  // Device MTU

  int get mtu => BlueBreezePlatform.instance.deviceMTU(id);

  Stream<int> get mtuStream => BlueBreezePlatform.instance.deviceMTUStream(id);

  // Operations

  Future connect() => BlueBreezePlatform.instance.deviceConnect(id);

  Future disconnect() => BlueBreezePlatform.instance.deviceDisconnect(id);

  Future discoverServices() => BlueBreezePlatform.instance.deviceDiscoverServices(id);

  Future<int> requestMTU(int mtu) => BlueBreezePlatform.instance.deviceRequestMTU(id, mtu);
}
