//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import 'dart:typed_data';

import 'package:bluebreeze_flutter/bluebreeze_characteristic_property.dart';
import 'package:bluebreeze_flutter/impl/bluebreeze_platform_interface.dart';

class BBCharacteristic {
  BBCharacteristic({
    required this.deviceId,
    required this.serviceId,
    required this.id,
    required this.name,
    required this.properties,
  });

  final String deviceId;
  final String serviceId;
  final String id;
  final String? name;

  final Set<BBCharacteristicProperty> properties;

  // Data

  Uint8List get data => BlueBreezePlatform.instance.deviceCharacteristicData(deviceId, serviceId, id);

  Stream<Uint8List> get dataStream => BlueBreezePlatform.instance.deviceCharacteristicDataStream(deviceId, serviceId, id);

  // Operations

  Future read() => BlueBreezePlatform.instance.deviceCharacteristicRead(deviceId, serviceId, id);

  Future write() async {}
  Future subscribe() async {}
  Future unsubscribe() async {}
}
