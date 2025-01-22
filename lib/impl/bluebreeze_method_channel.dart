import 'dart:async';

import 'package:bluebreeze_flutter/bluebreeze_authorization.dart';
import 'package:bluebreeze_flutter/bluebreeze_device.dart';
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

      case 'devicesUpdate':
        final devices = _devicesStreamController.value;
        methodCall.arguments['devices'].forEach((device) {
          devices[device['id']] ??= BBDevice(
            id: device['id'],
            name: device['name'],
          );
          devices[device['id']]?.rssi = device['rssi'];
          devices[device['id']]?.isConnectable = device['isConnectable'];
          // devices[device['id']]?.advertisementData = Map<Uint8, Uint8List>.from(device['advertisementData']);
          devices[device['id']]?.advertisedServices = List<String>.from(device['advertisedServices']);
          devices[device['id']]?.manufacturerId = device['manufacturerId'];
          devices[device['id']]?.manufacturerName = device['manufacturerName'];
        });
        _devicesStreamController.add(devices);
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
  Future<void> authorizationRequest() => methodChannel.invokeMethod('authorizationRequest');

  // Scanning

  final _scanningEnabledStreamController = _ValueStreamController<bool>(initialValue: false);

  @override
  bool get scanningEnabled => _scanningEnabledStreamController._value;

  @override
  Stream<bool> get scanningEnabledStream => _scanningEnabledStreamController.stream;

  @override
  Future scanningStart() => methodChannel.invokeMethod('scanningStart');

  @override
  Future scanningStop() => methodChannel.invokeMethod('scanningStop');

  // Devices

  final _devicesStreamController = _ValueStreamController<Map<String, BBDevice>>(initialValue: {});

  @override
  Map<String, BBDevice> get devices => _devicesStreamController.value;

  @override
  Stream<Map<String, BBDevice>> get devicesStream => _devicesStreamController.stream;

  // // Device services

  // @override
  // List<BBService> deviceServices(String id) => throw UnimplementedError();

  // @override
  // Stream<List<BBService>> deviceServicesStream(String id) => throw UnimplementedError();

  // // Device connection status

  // @override
  // BBDeviceConnectionStatus deviceConnectionStatus(String id) => throw UnimplementedError();

  // @override
  // Stream<BBDeviceConnectionStatus> deviceConnectionStatusStream(String id) => throw UnimplementedError();

  // // Device MTU

  // @override
  // int deviceMTU(String id) => throw UnimplementedError();

  // @override
  // Stream<int> deviceMTUStream(String id) => throw UnimplementedError();

  // // Device operation

  // @override
  // Future deviceConnect(String id) => throw UnimplementedError();

  // @override
  // Future deviceDisconnect(String id) => throw UnimplementedError();

  // @override
  // Future deviceDiscoverServices(String id) => throw UnimplementedError();

  // @override
  // Future<int> deviceRequestMTU(String id, int mtu) => throw UnimplementedError();

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
