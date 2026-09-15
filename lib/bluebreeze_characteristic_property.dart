//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

/// An operation a `BBCharacteristic` supports, as reported by the peripheral. See
/// `BBCharacteristic.properties`. A characteristic can have more than one of these at once.
enum BBCharacteristicProperty {
  /// Supports `BBCharacteristic.read`.
  read,

  /// Supports `BBCharacteristic.write` with `withResponse: true` (acknowledged writes).
  writeWithResponse,

  /// Supports `BBCharacteristic.write` with `withResponse: false` (unacknowledged writes).
  writeWithoutResponse,

  /// Supports `BBCharacteristic.subscribe`/`BBCharacteristic.unsubscribe`.
  notify,
}
