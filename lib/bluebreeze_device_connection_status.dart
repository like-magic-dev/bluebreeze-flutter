//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

/// A `BBDevice`'s connection state, exposed via `BBDevice.connectionStatus`.
enum BBDeviceConnectionStatus {
  /// Not connected. The initial state, and the state after `BBDevice.disconnect` or an
  /// unexpected link loss.
  disconnected,

  /// Connected, following a successful `BBDevice.connect`.
  connected,
}
