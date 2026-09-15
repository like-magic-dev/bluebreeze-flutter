//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import 'dart:async';

import 'bluebreeze_authorization.dart';
import 'bluebreeze_device.dart';
import 'bluebreeze_scan_result.dart';
import 'bluebreeze_state.dart';
import 'impl/bluebreeze_platform_interface.dart';

/// The entry point for BlueBreeze: tracks Bluetooth authorization and power state, and
/// discovers peripherals as [BBDevice] instances.
///
/// Create and retain a single `BBManager` for the lifetime of your app (or feature). All of
/// its state is exposed as `Stream`s so your UI can observe it reactively:
///
/// ```dart
/// final manager = BBManager();
///
/// manager.stateStream.listen((state) {
///   if (state == BBState.poweredOn) {
///     manager.scanStart();
///   }
/// });
///
/// manager.scanResultsStream.listen((result) {
///   print('${result.name ?? 'Unknown device'} ${result.rssi}');
/// });
/// ```
class BBManager {
  // State

  /// The Bluetooth adapter's current power state. Scanning and connecting require
  /// [BBState.poweredOn].
  BBState get state => BlueBreezePlatform.instance.state;

  /// Notifies with the updated [state] every time it changes.
  Stream<BBState> get stateStream => BlueBreezePlatform.instance.stateStream;

  // Authorization

  /// The app's current authorization status for the Bluetooth permissions BlueBreeze needs.
  /// Call [authorizationRequest] to request them if this isn't [BBAuthorization.authorized].
  BBAuthorization get authorizationStatus => BlueBreezePlatform.instance.authorizationStatus;

  /// Notifies with the updated [authorizationStatus] every time it changes.
  Stream<BBAuthorization> get authorizationStatusStream => BlueBreezePlatform.instance.authorizationStatusStream;

  /// Requests every permission BlueBreeze needs, updating [authorizationStatus] with the
  /// result.
  Future<void> authorizationRequest() => BlueBreezePlatform.instance.authorizationRequest();

  /// Opens the app's system settings screen -- the only way to recover once a permission has
  /// been permanently denied ([BBAuthorization.denied]), since the system will no longer show
  /// its own request dialog for it.
  Future<void> authorizationOpenSettings() => BlueBreezePlatform.instance.authorizationOpenSettings();

  // Capabilities

  /// Whether this device's Bluetooth adapter supports extended LE advertising (larger/longer
  /// advertisements, secondary advertising channels).
  bool get supportsExtended => BlueBreezePlatform.instance.supportsExtended;

  // Scan

  /// Whether a scan is currently active. Reflects [scanStart]/[scanStop], and flips to `false`
  /// on its own if the adapter powers off or the system stops the scan for another reason.
  bool get scanEnabled => BlueBreezePlatform.instance.scanEnabled;

  /// Notifies with the updated [scanEnabled] every time it changes.
  Stream<bool> get scanEnabledStream => BlueBreezePlatform.instance.scanEnabledStream;

  /// Every advertisement seen while scanning, including repeats from the same peripheral.
  /// Only delivered to listeners while they're actively listening -- there's no replay, unlike
  /// [devicesStream]/[stateStream].
  Stream<BBScanResult> get scanResultsStream => BlueBreezePlatform.instance.scanResultsStream;

  /// Starts scanning for BLE advertisements, updating [scanEnabled] and delivering results on
  /// [scanResultsStream]. Returns immediately if already scanning.
  ///
  /// [services] restricts results to peripherals advertising at least one of these service
  /// UUIDs (as strings), or `null`/omitted to see every advertisement.
  Future<void> scanStart({List<String>? services}) => BlueBreezePlatform.instance.scanStart(services: services);

  /// Stops an active scan. Returns immediately if not currently scanning.
  Future<void> scanStop() => BlueBreezePlatform.instance.scanStop();

  // Devices

  /// Every [BBDevice] discovered by a scan so far, keyed by id. A device is added here the
  /// first time it's seen in a scan result and then reused for every subsequent sighting,
  /// connect, and disconnect -- use this (or [BBScanResult.device]) rather than constructing
  /// your own.
  Map<String, BBDevice> get devices => BlueBreezePlatform.instance.devices;

  /// Notifies with the updated [devices] map every time a new device is discovered.
  Stream<Map<String, BBDevice>> get devicesStream => BlueBreezePlatform.instance.devicesStream;

  // Cleanup

  /// Releases locally cached stream state for the device with this [id] (services, connection
  /// status, MTU, characteristic data/notify state). Call this once you're done with a device
  /// you no longer expect to reconnect to, to bound memory use across long scanning sessions --
  /// state is recreated automatically if the device is seen or connected to again.
  void releaseDevice(String id) => BlueBreezePlatform.instance.releaseDevice(id);

  // Developer tools

  /// Disconnects every known device. Intended to be called from a Flutter `reassemble()` hook
  /// so a hot reload doesn't leave native connections open with no Dart-side listener left to
  /// manage them.
  void handleHotReload() => BlueBreezePlatform.instance.handleHotReload();
}
