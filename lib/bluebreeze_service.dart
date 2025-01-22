//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import 'package:bluebreeze_flutter/bluebreeze_characteristic.dart';

class BBService {
  BBService({
    required this.id,
    required this.name,
    required this.characteristics,
  });

  final String id;
  final String? name;
  final List<BBCharacteristic> characteristics;
}
