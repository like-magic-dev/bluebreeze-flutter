//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import 'bluebreeze_device_connection_status.dart';
import 'bluebreeze_service.dart';
import 'impl/bluebreeze_platform_interface.dart';

/// A single BLE peripheral discovered by a `BBManager` scan.
///
/// `BBDevice` instances are created and owned by `BBManager` -- you never construct one
/// yourself, you get one from `BBManager.devices` or `BBScanResult.device`. The same instance
/// is reused across repeated discoveries, connects, and disconnects of the same physical
/// peripheral.
///
/// All BLE operations ([connect], [disconnect], [discoverServices], [requestMtu], and the
/// read/write/subscribe methods on `BBCharacteristic`) are queued and executed one at a time
/// per device by the native SDK -- you don't need to serialize calls yourself.
///
/// Typical flow: connect, discover services, then read/write/subscribe to the characteristics
/// that appear in [services].
class BBDevice {
  BBDevice({
    required this.id,
    required this.name,
  });

  /// The system-assigned identifier for this peripheral. Stable for the lifetime of the app,
  /// but not guaranteed to match across different installations of the same peripheral.
  final String id;

  /// The peripheral's name, if it has advertised or reported one. May be `null`, and may
  /// change (e.g. once connected, some peripherals report a more specific name than they
  /// advertised).
  final String? name;

  // Services

  /// Services discovered so far. Empty until [discoverServices] has been called and completed.
  List<BBService> get services => BlueBreezePlatform.instance.deviceServices(id);

  /// Notifies with the updated [services] list every time it changes.
  Stream<List<BBService>> get servicesStream => BlueBreezePlatform.instance.deviceServicesStream(id);

  // Connection status

  /// The device's current connection state. Updates automatically on connect, disconnect, and
  /// unexpected link loss -- you don't need to poll it after calling [connect]/[disconnect].
  BBDeviceConnectionStatus get connectionStatus => BlueBreezePlatform.instance.deviceConnectionStatus(id);

  /// Notifies with the updated [connectionStatus] every time it changes.
  Stream<BBDeviceConnectionStatus> get connectionStatusStream => BlueBreezePlatform.instance.deviceConnectionStatusStream(id);

  // Device MTU

  /// The negotiated ATT MTU (Maximum Transmission Unit) in bytes, i.e. the largest amount of
  /// data that can be sent in a single read/write. Defaults to the BLE minimum until
  /// [requestMtu] is called and awaited.
  int get mtu => BlueBreezePlatform.instance.deviceMtu(id);

  /// Notifies with the updated [mtu] every time it changes.
  Stream<int> get mtuStream => BlueBreezePlatform.instance.deviceMtuStream(id);

  // Operations

  /// Connects to the peripheral. Updates [connectionStatus] to
  /// [BBDeviceConnectionStatus.connected] on success.
  Future<void> connect() => BlueBreezePlatform.instance.deviceConnect(id);

  /// Disconnects from the peripheral. Updates [connectionStatus] to
  /// [BBDeviceConnectionStatus.disconnected] on success.
  Future<void> disconnect() => BlueBreezePlatform.instance.deviceDisconnect(id);

  /// Discovers all of the peripheral's services and their characteristics, populating
  /// [services]. Requires an active connection.
  Future<void> discoverServices() => BlueBreezePlatform.instance.deviceDiscoverServices(id);

  /// Requests a larger ATT MTU and returns the negotiated size.
  ///
  /// Android honors [mtu] as the requested size. iOS has no CoreBluetooth API to request a
  /// specific MTU -- it's negotiated automatically as part of connecting -- so on iOS this
  /// only re-reads whatever was already negotiated and [mtu] is ignored.
  Future<int> requestMtu(int mtu) => BlueBreezePlatform.instance.deviceRequestMtu(id, mtu);
}
