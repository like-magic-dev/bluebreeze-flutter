//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import 'bluebreeze_characteristic.dart';

/// A single GATT service discovered on a `BBDevice`, populated by `BBDevice.discoverServices`
/// and exposed via `BBDevice.services`. You never construct one yourself.
class BBService {
  BBService({
    required this.id,
    required this.name,
    required this.characteristics,
  });

  /// This service's Bluetooth UUID, as a string -- the short 4-character form (e.g. `"180F"`)
  /// for a standard 16-bit UUID, or the full UUID string otherwise.
  final String id;

  /// The service's human-readable name, if [id] is a Bluetooth SIG-assigned service UUID.
  final String? name;

  /// The characteristics discovered for this service.
  final List<BBCharacteristic> characteristics;
}
