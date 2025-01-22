import 'dart:async';

import 'package:bluebreeze_flutter/bluebreeze_authorization.dart';
import 'package:bluebreeze_flutter/bluebreeze_characteristic.dart';
import 'package:bluebreeze_flutter/bluebreeze_device.dart';
import 'package:bluebreeze_flutter/bluebreeze_device_connection_status.dart';
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
            (v) => (v.name == methodCall.arguments['name']),
          ),
        );
        return;

      case 'authorizationStatusUpdate':
        _authorizationStatusStreamController.add(
          BBAuthorization.values.firstWhere(
            (v) => (v.name == methodCall.arguments['name']),
          ),
        );
        return;

      case 'scanningEnabledUpdate':
        _scanningEnabledStreamController.add(
          methodCall.arguments['value'],
        );
        return;

      case 'scanningDevicesUpdate':
        final device = _updateDevice(methodCall.arguments);
        _scanningDevicesStreamController.add(device);
        return;

      case 'devicesUpdate':
        final devices = _devicesStreamController.value;
        methodCall.arguments['devices'].forEach((data) {
          devices[data['id']] = _updateDevice(data);
        });
        _devicesStreamController.add(devices);
        return;

      case 'deviceConnectionStatusUpdate':
        final value = _deviceConnectionStatusStreamController.value;
        value[methodCall.arguments['id']] = BBDeviceConnectionStatus.values.firstWhere(
          (v) => (v.name == methodCall.arguments['connectionStatus']),
        );
        _deviceConnectionStatusStreamController.add(value);
        return;

      case 'deviceServicesUpdate':
        final value = _deviceServicesStreamController.value;
        value[methodCall.arguments['id']] = List<BBService>.from(
          methodCall.arguments['services'].map(
            (data) => BBService(
              id: data['id'],
              name: data['name'],
              characteristics: List<BBCharacteristic>.from(
                data['characteristics'].map(
                  (data) => BBCharacteristic(
                    id: data['id'],
                    name: data['name'],
                  ),
                ),
              ),
            ),
          ),
        );
        _deviceServicesStreamController.add(value);
        return;

      case 'deviceMTUUpdate':
        final value = _deviceMTUStatusStreamController.value;
        value[methodCall.arguments['id']] = methodCall.arguments['mtu'];
        _deviceMTUStatusStreamController.add(value);
        return;

      default:
        if (kDebugMode) {
          print('Unprocessed event ${methodCall.method} with payload ${methodCall.arguments}');
        }
    }
  }

  BBDevice _updateDevice(dynamic data) {
    final deviceId = data['id'];
    final device = devices[deviceId] ??
        BBDevice(
          id: deviceId,
          name: data['name'],
        );

    device.rssi = data['rssi'];
    device.isConnectable = data['isConnectable'];
    // device.advertisementData = methodCall.arguments<Uint8, Uint8List>.from(device['advertisementData']);
    device.advertisedServices = List<String>.from(data['advertisedServices']);
    device.manufacturerId = data['manufacturerId'];
    device.manufacturerName = data['manufacturerName'];

    return device;
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

  // Scanning

  final _scanningEnabledStreamController = _ValueStreamController<bool>(initialValue: false);

  @override
  bool get scanningEnabled => _scanningEnabledStreamController._value;

  @override
  Stream<bool> get scanningEnabledStream => _scanningEnabledStreamController.stream;

  final _scanningDevicesStreamController = StreamController<BBDevice>.broadcast();

  @override
  Stream<BBDevice> get scanningDevicesStream => _scanningDevicesStreamController.stream;

  @override
  Future scanningStart() async {
    methodChannel.invokeMethod('scanningStart');
  }

  @override
  Future scanningStop() async {
    methodChannel.invokeMethod('scanningStop');
  }

  // Devices

  final _devicesStreamController = _ValueStreamController<Map<String, BBDevice>>(initialValue: {});

  @override
  Map<String, BBDevice> get devices => _devicesStreamController.value;

  @override
  Stream<Map<String, BBDevice>> get devicesStream => _devicesStreamController.stream;

  // Device services

  final _deviceServicesStreamController = _ValueStreamController<Map<String, List<BBService>>>(initialValue: {});

  @override
  List<BBService> deviceServices(String id) => _deviceServicesStreamController.value[id] ?? [];

  @override
  Stream<List<BBService>> deviceServicesStream(String id) => _deviceServicesStreamController.stream.map((v) => (v[id] ?? []));

  // Device connection status

  final _deviceConnectionStatusStreamController = _ValueStreamController<Map<String, BBDeviceConnectionStatus>>(initialValue: {});

  @override
  BBDeviceConnectionStatus deviceConnectionStatus(String id) =>
      _deviceConnectionStatusStreamController.value[id] ?? BBDeviceConnectionStatus.disconnected;

  @override
  Stream<BBDeviceConnectionStatus> deviceConnectionStatusStream(String id) =>
      _deviceConnectionStatusStreamController.stream.map((v) => (v[id] ?? BBDeviceConnectionStatus.disconnected));

  // Device MTU

  final _deviceMTUStatusStreamController = _ValueStreamController<Map<String, int>>(initialValue: {});

  @override
  int deviceMTU(String id) => _deviceMTUStatusStreamController.value[id] ?? 0;

  @override
  Stream<int> deviceMTUStream(String id) => _deviceMTUStatusStreamController.stream.map((v) => (v[id] ?? 0));

  // Device operation

  @override
  Future deviceConnect(String id) async {
    methodChannel.invokeMethod(
      'deviceConnect',
      {'id': id},
    );
  }

  @override
  Future deviceDisconnect(String id) async {
    methodChannel.invokeMethod(
      'deviceDisconnect',
      {'id': id},
    );
  }

  @override
  Future deviceDiscoverServices(String id) async {
    await methodChannel.invokeMethod(
      'deviceDiscoverServices',
      {'id': id},
    );
  }

  @override
  Future<int> deviceRequestMTU(String id, int mtu) async {
    final result = await methodChannel.invokeMethod(
      'deviceRequestMTU',
      {'id': id, 'mtu': mtu},
    );
    return result;
  }

  // // Device characteristic data

  // @override
  // Uint8List deviceCharacteristicData(String id, String serviceId, String characteristicId) => throw UnimplementedError();

  // @override
  // Stream<Uint8List> deviceCharacteristicDataStream(String id, String serviceId, String characteristicId) => throw UnimplementedError();

  // // Device characteristic notify enabled

  // @override
  // bool deviceCharacteristicNotifyEnabled(String id, String serviceId, String characteristicId) => throw UnimplementedError();

  // @override
  // Stream<bool> deviceCharacteristicNotifyEnabledStream(String id, String serviceId, String characteristicId) => throw UnimplementedError();

  // // Device characteristic operations

  // @override
  // Future<Uint8List> deviceCharacteristicRead(String id, String serviceId, String characteristicId) => throw UnimplementedError();

  // @override
  // Future deviceCharacteristicWrite(String id, String serviceId, String characteristicId, Uint8List data, bool withResponse) =>
  //     throw UnimplementedError();

  // @override
  // Future deviceCharacteristicSubscribe(String id, String serviceId, String characteristicId) => throw UnimplementedError();

  // @override
  // Future deviceCharacteristicUnsubscribe(String id, String serviceId, String characteristicId) => throw UnimplementedError();
}
