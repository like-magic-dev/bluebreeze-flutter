//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import 'package:flutter/foundation.dart';

import 'bluebreeze_device.dart';

/// A single parsed BLE advertisement, delivered on `BBManager.scanResultsStream` for every
/// advertising packet seen while scanning -- including repeats from the same peripheral,
/// BlueBreeze doesn't de-duplicate scan results, only `BBManager.devices`. You never construct
/// one yourself.
class BBScanResult {
  BBScanResult({
    required this.device,
    required this.name,
    required this.rssi,
    required this.connectable,
    required this.advertisedServices,
    required this.manufacturerId,
    required this.manufacturerName,
    required this.manufacturerData,
  });

  /// The device that sent this advertisement. The same [BBDevice] instance is reused across
  /// repeated sightings of the same physical peripheral.
  final BBDevice device;

  /// The advertised name, if any.
  final String? name;

  /// The received signal strength, in dBm.
  final int rssi;

  /// Whether the peripheral is currently connectable.
  final bool connectable;

  /// The service UUIDs advertised by this peripheral, as strings.
  final List<String> advertisedServices;

  /// The Bluetooth SIG-assigned company identifier decoded from [manufacturerData]'s first two
  /// bytes, or `null` if none was advertised or it's too short to contain one.
  final int? manufacturerId;

  /// The manufacturer's name, if [manufacturerId] is a known Bluetooth SIG-assigned company
  /// identifier.
  final String? manufacturerName;

  /// The raw manufacturer-specific data field, if advertised: a 2-byte company ID followed by
  /// arbitrary payload bytes.
  final Uint8List? manufacturerData;
}
