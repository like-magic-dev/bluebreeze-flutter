import 'dart:ffi';

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
}
