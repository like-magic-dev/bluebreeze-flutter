//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

/// The power/availability state of the device's Bluetooth adapter, exposed via
/// `BBManager.state`. When this isn't [poweredOn], every `BBDevice`'s connection is reset.
enum BBState {
  /// The state hasn't been determined yet -- typically the initial value before the native
  /// side reports a state.
  unknown,

  /// The adapter is temporarily resetting; connections and scans are dropped and will need to
  /// be restarted once it settles into another state.
  resetting,

  /// This device doesn't support Bluetooth Low Energy.
  unsupported,

  /// The app isn't authorized to use Bluetooth. See `BBAuthorization`.
  unauthorized,

  /// Bluetooth is turned off. Scanning and connecting are unavailable until it's powered on.
  poweredOff,

  /// Bluetooth is turned on and available for scanning and connecting.
  poweredOn,
}
