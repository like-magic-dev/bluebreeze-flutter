//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../bluebreeze_authorization.dart';
import '../bluebreeze_characteristic.dart';
import '../bluebreeze_characteristic_property.dart';
import '../bluebreeze_device.dart';
import '../bluebreeze_device_connection_status.dart';
import '../bluebreeze_observable.dart';
import '../bluebreeze_scan_result.dart';
import '../bluebreeze_service.dart';
import '../bluebreeze_state.dart';
import 'bluebreeze_platform_interface.dart';

class _ValueStreamController<T> implements BBObservable<T> {
  final _controller = StreamController<T>.broadcast();
  T _value;

  _ValueStreamController({required T initialValue}) : _value = initialValue {
    // Each listener of a Stream.multi gets its own callback, so the current value can be
    // delivered to that listener alone before forwarding the shared broadcast stream.
    values = Stream<T>.multi((listener) {
      listener.add(_value);
      final subscription = _controller.stream.listen(listener.add, onError: listener.addError, onDone: listener.close);
      listener.onCancel = subscription.cancel;
    }, isBroadcast: true);
  }

  @override
  late final Stream<T> values;

  @override
  T get value => _value;

  @override
  Stream<T> get updates => _controller.stream;

  void add(T value) {
    _value = value;
    _controller.sink.add(value);
  }

  void close() {
    _controller.close();
  }
}

class MethodChannelBlueBreeze extends BlueBreezePlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('bluebreeze');

  MethodChannelBlueBreeze() {
    methodChannel.setMethodCallHandler(methodCallHandler);
    methodChannel
        .invokeMethod('initialize')
        .then((value) {
          _supportsExtended = (value as Map?)?['supportsExtended'] ?? false;
        })
        .catchError((Object error) {
          if (kDebugMode) {
            print('Failed to initialize BlueBreeze: $error');
          }
        });
  }

  Future<dynamic> methodCallHandler(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'stateUpdate':
        _stateStreamController.add(BBState.values.firstWhere((v) => (v.name == methodCall.arguments['value']), orElse: () => BBState.unknown));
        return;

      case 'authorizationStatusUpdate':
        _authorizationStatusStreamController.add(
          BBAuthorization.values.firstWhere((v) => (v.name == methodCall.arguments['value']), orElse: () => BBAuthorization.unknown),
        );
        return;

      case 'scanEnabledUpdate':
        _scanEnabledStreamController.add(methodCall.arguments['value']);
        return;

      case 'scanResultUpdate':
        final data = methodCall.arguments['value'];
        if (data == null) {
          return;
        }

        final device = devices.value[data['id']];
        if (device == null) {
          return;
        }

        final scanResult = BBScanResult(
          device: device,
          name: data['name'],
          rssi: data['rssi'],
          connectable: data['connectable'],
          advertisedServices: List<String>.from(data['advertisedServices']),
          manufacturerId: data['manufacturerId'],
          manufacturerName: data['manufacturerName'],
          manufacturerData: data['manufacturerData'],
        );
        _scanResultsStreamController.add(scanResult);
        return;

      case 'devicesUpdate':
        final devices = _devicesStreamController.value;
        methodCall.arguments['value'].forEach((data) {
          devices[data['id']] = BBDevice(id: data['id'], name: data['name']);
        });
        _devicesStreamController.add(devices);
        return;

      case 'deviceConnectionStatusUpdate':
        final deviceId = methodCall.arguments['deviceId'];
        final value = BBDeviceConnectionStatus.values.firstWhere(
          (v) => (v.name == methodCall.arguments['value']),
          orElse: () => BBDeviceConnectionStatus.disconnected,
        );
        _deviceConnectionStatusController(deviceId).add(value);
        return;

      case 'deviceServicesUpdate':
        final deviceId = methodCall.arguments['deviceId'];

        final value = List<BBService>.from(
          methodCall.arguments['value'].map(
            (serviceData) => BBService(
              id: serviceData['id'],
              name: serviceData['name'],
              characteristics: List<BBCharacteristic>.from(
                serviceData['characteristics'].map(
                  (characteristicData) => BBCharacteristic(
                    deviceId: deviceId,
                    serviceId: serviceData['id'],
                    id: characteristicData['id'],
                    name: characteristicData['name'],
                    properties: {
                      for (final property in characteristicData['properties']) ...BBCharacteristicProperty.values.where((v) => (v.name == property)),
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        // Prune all controllers that belong to removed characteristics
        _pruneRemovedCharacteristicControllers(_deviceCharacteristicIsNotifyingControllers, deviceId, value);
        _pruneRemovedCharacteristicControllers(_deviceCharacteristicDataControllers, deviceId, value);

        _deviceServicesController(deviceId).add(value);

        return;

      case 'deviceMTUUpdate':
        final deviceId = methodCall.arguments['deviceId'];
        final value = methodCall.arguments['value'];
        _deviceMtuController(deviceId).add(value);
        return;

      case 'deviceCharacteristicIsNotifyingUpdate':
        final deviceId = methodCall.arguments['deviceId'];
        final serviceId = methodCall.arguments['serviceId'];
        final characteristicId = methodCall.arguments['characteristicId'];
        final value = methodCall.arguments['value'];
        _deviceCharacteristicIsNotifyingController(deviceId, serviceId, characteristicId).add(value);
        return;

      case 'deviceCharacteristicDataUpdate':
        final deviceId = methodCall.arguments['deviceId'];
        final serviceId = methodCall.arguments['serviceId'];
        final characteristicId = methodCall.arguments['characteristicId'];
        final value = methodCall.arguments['value'];
        _deviceCharacteristicDataControllerGetOrCreate(deviceId, serviceId, characteristicId).add(value);
        return;

      default:
        if (kDebugMode) {
          print('Unprocessed event ${methodCall.method} with payload ${methodCall.arguments}');
        }
    }
  }

  // State

  final _stateStreamController = _ValueStreamController<BBState>(initialValue: BBState.unknown);

  @override
  BBObservable<BBState> get state => _stateStreamController;

  // Authorization

  final _authorizationStatusStreamController = _ValueStreamController<BBAuthorization>(initialValue: BBAuthorization.unknown);

  @override
  BBObservable<BBAuthorization> get authorizationStatus => _authorizationStatusStreamController;

  @override
  Future<void> authorizationRequest() => methodChannel.invokeMethod('authorizationRequest');

  @override
  Future<void> authorizationOpenSettings() => methodChannel.invokeMethod('authorizationOpenSettings');

  // Capabilities

  bool _supportsExtended = false;

  @override
  bool get supportsExtended => _supportsExtended;

  // Scan

  final _scanEnabledStreamController = _ValueStreamController<bool>(initialValue: false);

  @override
  BBObservable<bool> get scanEnabled => _scanEnabledStreamController;

  final _scanResultsStreamController = StreamController<BBScanResult>.broadcast();

  @override
  Stream<BBScanResult> get scanResultsStream => _scanResultsStreamController.stream;

  @override
  Future<void> scanStart({List<String>? services}) => methodChannel.invokeMethod('scanStart', {'services': services});

  @override
  Future<void> scanStop() => methodChannel.invokeMethod('scanStop');

  // Devices

  final _devicesStreamController = _ValueStreamController<Map<String, BBDevice>>(initialValue: {});

  @override
  BBObservable<Map<String, BBDevice>> get devices => _devicesStreamController;

  // Device services

  final _deviceServicesControllers = <String, _ValueStreamController<List<BBService>>>{};

  _ValueStreamController<List<BBService>> _deviceServicesController(String id) =>
      _deviceServicesControllers[id] ??= _ValueStreamController<List<BBService>>(initialValue: []);

  @override
  BBObservable<List<BBService>> deviceServices(String id) => _deviceServicesController(id);

  // Device connection status

  final _deviceConnectionStatusControllers = <String, _ValueStreamController<BBDeviceConnectionStatus>>{};

  _ValueStreamController<BBDeviceConnectionStatus> _deviceConnectionStatusController(String id) => _deviceConnectionStatusControllers[id] ??=
      _ValueStreamController<BBDeviceConnectionStatus>(initialValue: BBDeviceConnectionStatus.disconnected);

  @override
  BBObservable<BBDeviceConnectionStatus> deviceConnectionStatus(String id) => _deviceConnectionStatusController(id);

  // Device MTU

  final _deviceMtuControllers = <String, _ValueStreamController<int>>{};

  _ValueStreamController<int> _deviceMtuController(String id) => _deviceMtuControllers[id] ??= _ValueStreamController<int>(initialValue: 0);

  @override
  BBObservable<int> deviceMtu(String id) => _deviceMtuController(id);

  // Device operation

  @override
  Future<void> deviceConnect(String id) => methodChannel.invokeMethod('deviceConnect', {'deviceId': id});

  @override
  Future<void> deviceDisconnect(String id) => methodChannel.invokeMethod('deviceDisconnect', {'deviceId': id});

  @override
  Future<void> deviceDiscoverServices(String id) => methodChannel.invokeMethod('deviceDiscoverServices', {'deviceId': id});

  @override
  Future<int> deviceRequestMtu(String id, int value) async {
    final result = await methodChannel.invokeMethod<int>('deviceRequestMTU', {'deviceId': id, 'value': value});
    return result ?? 0;
  }

  // Characteristic-scoped controllers are keyed by the flattened "deviceId:serviceId:
  // characteristicId" triple rather than a 3-level nested map, mirroring the equivalent tracking
  // map in the React Native implementation (BlueBreezeModule.kt's `trackingKey`). Device ids
  // (Android MAC addresses, iOS UUIDs) are fixed-length, so a key can't be mistaken for another
  // device's prefix.
  String _characteristicKey(String id, String serviceId, String characteristicId) => '$id:$serviceId:$characteristicId';

  // Device characteristic notify enabled

  final _deviceCharacteristicIsNotifyingControllers = <String, _ValueStreamController<bool>>{};

  _ValueStreamController<bool> _deviceCharacteristicIsNotifyingController(String id, String serviceId, String characteristicId) =>
      _deviceCharacteristicIsNotifyingControllers[_characteristicKey(id, serviceId, characteristicId)] ??= _ValueStreamController<bool>(
        initialValue: false,
      );

  @override
  BBObservable<bool> deviceCharacteristicIsNotifying(String id, String serviceId, String characteristicId) =>
      _deviceCharacteristicIsNotifyingController(id, serviceId, characteristicId);

  // Device characteristic data

  final _deviceCharacteristicDataControllers = <String, _ValueStreamController<Uint8List>>{};

  _ValueStreamController<Uint8List> _deviceCharacteristicDataControllerGetOrCreate(String id, String serviceId, String characteristicId) =>
      _deviceCharacteristicDataControllers[_characteristicKey(id, serviceId, characteristicId)] ??= _ValueStreamController<Uint8List>(
        initialValue: Uint8List(0),
      );

  void _pruneRemovedCharacteristicControllers<T>(Map<String, _ValueStreamController<T>> controllers, String id, List<BBService> services) {
    final validDeviceKeys = <String>{
      for (final service in services)
        for (final characteristic in service.characteristics) _characteristicKey(id, service.id, characteristic.id),
    };

    final allDeviceKeys = controllers.keys.where((key) => key.startsWith('$id:')).toSet();
    for (final key in allDeviceKeys) {
      if (!validDeviceKeys.contains(key)) {
        controllers.remove(key)?.close();
      }
    }
  }

  @override
  BBObservable<Uint8List> deviceCharacteristicData(String id, String serviceId, String characteristicId) =>
      _deviceCharacteristicDataControllerGetOrCreate(id, serviceId, characteristicId);

  // Device characteristic operations

  @override
  Future<Uint8List> deviceCharacteristicRead(String id, String serviceId, String characteristicId) async {
    final result = await methodChannel.invokeMethod<Uint8List>('deviceCharacteristicRead', {
      'deviceId': id,
      'serviceId': serviceId,
      'characteristicId': characteristicId,
    });
    return result ?? Uint8List(0);
  }

  @override
  Future<void> deviceCharacteristicWrite(String id, String serviceId, String characteristicId, Uint8List value, bool withResponse) =>
      methodChannel.invokeMethod('deviceCharacteristicWrite', {
        'deviceId': id,
        'serviceId': serviceId,
        'characteristicId': characteristicId,
        'value': value,
        'withResponse': withResponse,
      });

  @override
  Future<void> deviceCharacteristicSubscribe(String id, String serviceId, String characteristicId) =>
      methodChannel.invokeMethod('deviceCharacteristicSubscribe', {'deviceId': id, 'serviceId': serviceId, 'characteristicId': characteristicId});

  @override
  Future<void> deviceCharacteristicUnsubscribe(String id, String serviceId, String characteristicId) =>
      methodChannel.invokeMethod('deviceCharacteristicUnsubscribe', {'deviceId': id, 'serviceId': serviceId, 'characteristicId': characteristicId});

  // Resource cleanup

  @override
  void releaseDevice(String id) {
    _deviceServicesControllers.remove(id)?.close();
    _deviceConnectionStatusControllers.remove(id)?.close();
    _deviceMtuControllers.remove(id)?.close();

    final devicePrefix = '$id:';
    for (final key in _deviceCharacteristicIsNotifyingControllers.keys.toList()) {
      if (key.startsWith(devicePrefix)) {
        _deviceCharacteristicIsNotifyingControllers.remove(key)?.close();
      }
    }
    for (final key in _deviceCharacteristicDataControllers.keys.toList()) {
      if (key.startsWith(devicePrefix)) {
        _deviceCharacteristicDataControllers.remove(key)?.close();
      }
    }
  }

  // Developer tools

  @override
  void handleHotReload() {
    methodChannel.invokeMethod('handleHotReload');
  }
}
