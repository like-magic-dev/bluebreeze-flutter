//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import 'dart:typed_data';

import 'bluebreeze_characteristic_property.dart';
import 'impl/bluebreeze_platform_interface.dart';

/// A GATT characteristic belonging to one of a `BBDevice`'s discovered `BBService`s. You never
/// construct one yourself -- you get one from a `BBService`'s `characteristics` list.
/// Read/write/subscribe calls are queued onto the owning device's native operation queue, so
/// they're serialized against every other operation on that device.
class BBCharacteristic {
  BBCharacteristic({
    required this.deviceId,
    required this.serviceId,
    required this.id,
    required this.name,
    required this.properties,
  });

  /// The id of the `BBDevice` this characteristic belongs to.
  final String deviceId;

  /// The id of the `BBService` this characteristic belongs to.
  final String serviceId;

  /// This characteristic's Bluetooth UUID, as a string.
  final String id;

  /// This characteristic's human-readable name, if [id] is a Bluetooth SIG-assigned
  /// characteristic UUID.
  final String? name;

  /// The operations ([read], [write], [subscribe]) this characteristic supports, as reported
  /// by the peripheral.
  final Set<BBCharacteristicProperty> properties;

  // Data

  /// The characteristic's most recently read or notified value. Empty until [read] or
  /// [subscribe] has been called and returned/notified at least once.
  Uint8List get data => BlueBreezePlatform.instance.deviceCharacteristicData(deviceId, serviceId, id);

  /// Notifies with the characteristic's value every time it's updated by [read] or by an
  /// incoming notification while [notifyEnabled].
  Stream<Uint8List> get dataStream => BlueBreezePlatform.instance.deviceCharacteristicDataStream(deviceId, serviceId, id);

  // Notifications

  /// Whether [subscribe] has been called without a matching [unsubscribe] since.
  bool get notifyEnabled => BlueBreezePlatform.instance.deviceCharacteristicNotifyEnabled(deviceId, serviceId, id);

  /// Notifies whenever [notifyEnabled] changes, i.e. after [subscribe]/[unsubscribe] complete.
  Stream<bool> get notifyEnabledStream => BlueBreezePlatform.instance.deviceCharacteristicNotifyEnabledStream(deviceId, serviceId, id);

  // Operations

  /// Reads the characteristic's current value from the peripheral, also updating [data].
  ///
  /// Requires [BBCharacteristicProperty.read].
  Future<Uint8List> read() => BlueBreezePlatform.instance.deviceCharacteristicRead(deviceId, serviceId, id);

  /// Writes [data] to the characteristic.
  ///
  /// [withResponse] selects whether to wait for the peripheral's acknowledgement
  /// ([BBCharacteristicProperty.writeWithResponse], the default) or fire-and-forget
  /// ([BBCharacteristicProperty.writeWithoutResponse]) -- only pass `false` if [properties]
  /// contains [BBCharacteristicProperty.writeWithoutResponse].
  Future<void> write({
    required Uint8List data,
    required bool withResponse,
  }) =>
      BlueBreezePlatform.instance.deviceCharacteristicWrite(deviceId, serviceId, id, data, withResponse);

  /// Enables notifications/indications for this characteristic. Once subscribed, new values
  /// arrive via [dataStream] as the peripheral pushes them, with no need to call [read].
  ///
  /// Requires [BBCharacteristicProperty.notify].
  Future<void> subscribe() => BlueBreezePlatform.instance.deviceCharacteristicSubscribe(deviceId, serviceId, id);

  /// Disables notifications/indications previously enabled with [subscribe].
  Future<void> unsubscribe() => BlueBreezePlatform.instance.deviceCharacteristicUnsubscribe(deviceId, serviceId, id);
}
