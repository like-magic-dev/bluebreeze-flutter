//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

/// The app's authorization to use Bluetooth, exposed via `BBManager.authorizationStatus`.
enum BBAuthorization {
  /// The user hasn't been asked yet. Call `BBManager.authorizationRequest` (or start a scan)
  /// to trigger the system permission prompt.
  unknown,

  /// The user denied permission, or it's restricted by policy (e.g. parental controls). Direct
  /// the user to `BBManager.authorizationOpenSettings` to change it.
  denied,

  /// The app is authorized to use Bluetooth.
  authorized,
}
