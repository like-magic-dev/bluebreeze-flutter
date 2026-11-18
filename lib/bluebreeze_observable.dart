//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

/// An observable value, used for every piece of state BlueBreeze exposes ([BBManager.state],
/// [BBDevice.connectionStatus], [BBCharacteristic.data], and so on).
///
/// ```dart
/// characteristic.data.value;                       // the current value
/// characteristic.data.values.listen((data) {});   // the current value, then new values
/// characteristic.data.updates.listen((data) {});  // only new values
/// ```
abstract class BBObservable<T> {
  /// The current value.
  T get value;

  /// A broadcast stream that gives each listener the current [value] first, followed by every
  /// value published from now on.
  Stream<T> get values;

  /// A broadcast stream of only the values published from now on, without the current [value].
  Stream<T> get updates;
}
