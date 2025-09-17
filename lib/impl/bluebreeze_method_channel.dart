//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import 'dart:async';

import 'package:bluebreeze_flutter/bluebreeze_authorization.dart';
import 'package:bluebreeze_flutter/bluebreeze_characteristic.dart';
import 'package:bluebreeze_flutter/bluebreeze_characteristic_property.dart';
import 'package:bluebreeze_flutter/bluebreeze_device.dart';
import 'package:bluebreeze_flutter/bluebreeze_device_connection_status.dart';
import 'package:bluebreeze_flutter/bluebreeze_scan_result.dart';
import 'package:bluebreeze_flutter/bluebreeze_service.dart';
import 'package:bluebreeze_flutter/bluebreeze_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'bluebreeze_platform_interface.dart';

class _ValueStreamController<T> {
  final _controller = StreamController<T>.broadcast();
  T _value;

  _ValueStreamController({
    required T initialValue,
  }) : _value = initialValue;

  T get value => _value;
  Stream<T> get stream => _controller.stream;

  void add(T value) {
    this._value = value;
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
    methodChannel.invokeMethod('initialize');
  }

  Future<dynamic> methodCallHandler(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'stateUpdate':
        _stateStreamController.add(
          BBState.values.firstWhere(
            (v) => (v.name == methodCall.arguments['value']),
          ),
        );
        return;

      case 'authorizationStatusUpdate':
        _authorizationStatusStreamController.add(
          BBAuthorization.values.firstWhere(
            (v) => (v.name == methodCall.arguments['value']),
          ),
        );
        return;

      case 'scanEnabledUpdate':
        _scanEnabledStreamController.add(
          methodCall.arguments['value'],
        );
        return;

      case 'scanResultUpdate':
        final data = methodCall.arguments['value'];
        if (data == null) {
          return;
        }

        final device = devices[data['id']];
        if (device == null) {
          return;
        }

        final scanResult = BBScanResult(
          device: device,
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
        methodCall.arguments['value'].forEach(
          (data) {
            devices[data['id']] ??= BBDevice(
              id: data['id'],
              name: data['name'],
            );
          },
        );
        _devicesStreamController.add(devices);
        return;

      case 'deviceConnectionStatusUpdate':
        final deviceId = methodCall.arguments['deviceId'];
        final value = BBDeviceConnectionStatus.values.firstWhere(
          (v) => (v.name == methodCall.arguments['value']),
        );
        _deviceConnectionStatusStreamController(deviceId).add(value);
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
                    properties: Set<BBCharacteristicProperty>.from(
                      characteristicData['properties'].map(
                        (property) => BBCharacteristicProperty.values.firstWhere(
                          (v) => (v.name == property),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        _deviceServicesStreamController(deviceId).add(value);
        return;

      case 'deviceMTUUpdate':
        final deviceId = methodCall.arguments['deviceId'];
        final value = methodCall.arguments['value'];
        _deviceMTUStatusStreamController(deviceId).add(value);
        return;

      case 'deviceCharacteristicIsNotifyingUpdate':
        final deviceId = methodCall.arguments['deviceId'];
        final serviceId = methodCall.arguments['serviceId'];
        final characteristicId = methodCall.arguments['characteristicId'];
        final value = methodCall.arguments['value'];
        _deviceCharacteristicNotifyEnabledStreamController(deviceId, serviceId, characteristicId).add(value);
        return;

      case 'deviceCharacteristicDataUpdate':
        final deviceId = methodCall.arguments['deviceId'];
        final serviceId = methodCall.arguments['serviceId'];
        final characteristicId = methodCall.arguments['characteristicId'];
        final value = methodCall.arguments['value'];
        _deviceCharacteristicDataStreamController(deviceId, serviceId, characteristicId).add(value);
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
  BBState get state => _stateStreamController.value;

  @override
  Stream<BBState> get stateStream => _stateStreamController.stream;

  // Authorization

  final _authorizationStatusStreamController = _ValueStreamController<BBAuthorization>(initialValue: BBAuthorization.unknown);

  @override
  BBAuthorization get authorizationStatus => _authorizationStatusStreamController.value;

  @override
  Stream<BBAuthorization> get authorizationStatusStream => _authorizationStatusStreamController.stream;

  @override
  Future<void> authorizationRequest() async {
    methodChannel.invokeMethod('authorizationRequest');
  }

  @override
  Future<void> authorizationOpenSettings() async {
    methodChannel.invokeMethod('authorizationOpenSettings');
  }

  // Scan

  final _scanEnabledStreamController = _ValueStreamController<bool>(initialValue: false);

  @override
  bool get scanEnabled => _scanEnabledStreamController._value;

  @override
  Stream<bool> get scanEnabledStream => _scanEnabledStreamController.stream;

  final _scanResultsStreamController = StreamController<BBScanResult>.broadcast();

  @override
  Stream<BBScanResult> get scanResultsStream => _scanResultsStreamController.stream;

  @override
  Future scanStart({List<String>? services}) async {
    methodChannel.invokeMethod(
      'scanStart',
      {
        'services': services,
      },
    );
  }

  @override
  Future scanStop() async {
    methodChannel.invokeMethod('scanStop');
  }

  // Devices

  final _devicesStreamController = _ValueStreamController<Map<String, BBDevice>>(initialValue: {});

  @override
  Map<String, BBDevice> get devices => _devicesStreamController.value;

  @override
  Stream<Map<String, BBDevice>> get devicesStream => _devicesStreamController.stream;

  // Device services

  final __deviceServicesStreamController = <String, _ValueStreamController<List<BBService>>>{};

  _ValueStreamController<List<BBService>> _deviceServicesStreamController(String id) =>
      __deviceServicesStreamController[id] ??= _ValueStreamController<List<BBService>>(initialValue: []);

  @override
  List<BBService> deviceServices(String id) => _deviceServicesStreamController(id).value;

  @override
  Stream<List<BBService>> deviceServicesStream(String id) => _deviceServicesStreamController(id).stream;

  // Device connection status

  final __deviceConnectionStatusStreamController = <String, _ValueStreamController<BBDeviceConnectionStatus>>{};

  _ValueStreamController<BBDeviceConnectionStatus> _deviceConnectionStatusStreamController(String id) =>
      __deviceConnectionStatusStreamController[id] ??=
          _ValueStreamController<BBDeviceConnectionStatus>(initialValue: BBDeviceConnectionStatus.disconnected);

  @override
  BBDeviceConnectionStatus deviceConnectionStatus(String id) => _deviceConnectionStatusStreamController(id).value;

  @override
  Stream<BBDeviceConnectionStatus> deviceConnectionStatusStream(String id) => _deviceConnectionStatusStreamController(id).stream;

  // Device MTU

  final __deviceMTUStatusStreamController = <String, _ValueStreamController<int>>{};

  _ValueStreamController<int> _deviceMTUStatusStreamController(String id) =>
      __deviceMTUStatusStreamController[id] ??= _ValueStreamController<int>(initialValue: 0);

  @override
  int deviceMTU(String id) => _deviceMTUStatusStreamController(id).value;

  @override
  Stream<int> deviceMTUStream(String id) => _deviceMTUStatusStreamController(id).stream;

  // Device operation

  @override
  Future deviceConnect(String id) => methodChannel.invokeMethod(
        'deviceConnect',
        {
          'deviceId': id,
        },
      );

  @override
  Future deviceDisconnect(String id) => methodChannel.invokeMethod(
        'deviceDisconnect',
        {
          'deviceId': id,
        },
      );

  @override
  Future deviceDiscoverServices(String id) => methodChannel.invokeMethod(
        'deviceDiscoverServices',
        {
          'deviceId': id,
        },
      );

  @override
  Future<int> deviceRequestMTU(String id, int value) async {
    final result = await methodChannel.invokeMethod(
      'deviceRequestMTU',
      {
        'deviceId': id,
        'value': value,
      },
    );
    return result;
  }

  // Device characteristic notify enabled

  final __deviceCharacteristicNotifyEnabledStreamController = <String, Map<String, Map<String, _ValueStreamController<bool>>>>{};

  _ValueStreamController<bool> _deviceCharacteristicNotifyEnabledStreamController(String id, String serviceId, String characteristicId) {
    __deviceCharacteristicNotifyEnabledStreamController[id] ??= {};
    __deviceCharacteristicNotifyEnabledStreamController[id]![serviceId] ??= {};
    return __deviceCharacteristicNotifyEnabledStreamController[id]![serviceId]![characteristicId] ??=
        _ValueStreamController<bool>(initialValue: false);
  }

  @override
  bool deviceCharacteristicNotifyEnabled(String id, String serviceId, String characteristicId) =>
      _deviceCharacteristicNotifyEnabledStreamController(id, serviceId, characteristicId).value;

  @override
  Stream<bool> deviceCharacteristicNotifyEnabledStream(String id, String serviceId, String characteristicId) =>
      _deviceCharacteristicNotifyEnabledStreamController(id, serviceId, characteristicId).stream;

  // Device characteristic data

  final __deviceCharacteristicDataStreamController = <String, Map<String, Map<String, _ValueStreamController<Uint8List>>>>{};

  _ValueStreamController<Uint8List> _deviceCharacteristicDataStreamController(String id, String serviceId, String characteristicId) {
    __deviceCharacteristicDataStreamController[id] ??= {};
    __deviceCharacteristicDataStreamController[id]![serviceId] ??= {};
    return __deviceCharacteristicDataStreamController[id]![serviceId]![characteristicId] ??=
        _ValueStreamController<Uint8List>(initialValue: Uint8List(0));
  }

  @override
  Uint8List deviceCharacteristicData(String id, String serviceId, String characteristicId) =>
      _deviceCharacteristicDataStreamController(id, serviceId, characteristicId).value;

  @override
  Stream<Uint8List> deviceCharacteristicDataStream(String id, String serviceId, String characteristicId) =>
      _deviceCharacteristicDataStreamController(id, serviceId, characteristicId).stream;

  // Device characteristic operations

  @override
  Future<Uint8List> deviceCharacteristicRead(String id, String serviceId, String characteristicId) async {
    final result = await methodChannel.invokeMethod(
      'deviceCharacteristicRead',
      {
        'deviceId': id,
        'serviceId': serviceId,
        'characteristicId': characteristicId,
      },
    );
    return result;
  }

  @override
  Future deviceCharacteristicWrite(String id, String serviceId, String characteristicId, Uint8List value, bool withResponse) =>
      methodChannel.invokeMethod(
        'deviceCharacteristicWrite',
        {
          'deviceId': id,
          'serviceId': serviceId,
          'characteristicId': characteristicId,
          'value': value,
          'withResponse': withResponse,
        },
      );

  @override
  Future deviceCharacteristicSubscribe(String id, String serviceId, String characteristicId) => methodChannel.invokeMethod(
        'deviceCharacteristicSubscribe',
        {
          'deviceId': id,
          'serviceId': serviceId,
          'characteristicId': characteristicId,
        },
      );

  @override
  Future deviceCharacteristicUnsubscribe(String id, String serviceId, String characteristicId) => methodChannel.invokeMethod(
        'deviceCharacteristicUnsubscribe',
        {
          'deviceId': id,
          'serviceId': serviceId,
          'characteristicId': characteristicId,
        },
      );

  // Developer tools

  @override
  void handleHotReload() {
    methodChannel.invokeMethod('handleHotReload');
  }
}
