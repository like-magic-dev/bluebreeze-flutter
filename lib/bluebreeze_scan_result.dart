//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import 'package:bluebreeze_flutter/bluebreeze_device.dart';
import 'package:flutter/foundation.dart';

class BBScanResult {
  BBScanResult({
    required this.device,
    required this.rssi,
    required this.connectable,
    required this.advertisedServices,
    required this.manufacturerId,
    required this.manufacturerName,
    required this.manufacturerData,
  });

  final BBDevice device;
  final int rssi;
  final bool connectable;
  final List<String> advertisedServices;
  final int? manufacturerId;
  final String? manufacturerName;
  final Uint8List? manufacturerData;
}
