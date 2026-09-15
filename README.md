# BlueBreeze Flutter

[![pub package](https://img.shields.io/pub/v/bluebreeze.svg)](https://pub.dev/packages/bluebreeze)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20Android-lightgrey.svg)](pubspec.yaml)

BlueBreeze is a modern Bluetooth LE library for Flutter, wrapping the native
[BlueBreeze iOS](https://github.com/like-magic-dev/bluebreeze-ios) and
[BlueBreeze Android](https://github.com/like-magic-dev/bluebreeze-android) SDKs behind a single
Dart API. All the platform-specific work -- connection state machines, GATT callback
correlation, per-device request queuing -- happens natively; from Dart you just observe state
and `await` operations.

- **Reactive state** -- adapter power, authorization, discovered devices, connection status,
  services, and characteristic data are all exposed as `Stream`s you can listen to reactively.
- **`Future`-based operations** -- connect, discover services, read, write, and
  subscribe/unsubscribe are all `async` calls with a built-in timeout enforced natively, instead
  of platform callbacks you have to correlate yourself.
- **Automatic per-device request queuing** -- handled natively on both platforms, so you can
  fire off several operations on the same device without worrying about overlapping BLE
  requests.
- **Runtime permission handling built in** -- `authorizationStatus`/`authorizationRequest`/
  `authorizationOpenSettings` cover Android's runtime permissions and iOS's Bluetooth usage
  authorization behind one API.
- **Bluetooth SIG assigned numbers built in** -- known company IDs, service UUIDs, and
  characteristic UUIDs are resolved automatically by the underlying native SDKs.
- **Hot reload aware** -- `handleHotReload()` disconnects stale native connections so a Dart hot
  reload doesn't leave them orphaned during development.

## Installation

```sh
flutter pub add bluebreeze
```

## Requirements

- Flutter 3.41.0+, Dart 3.11.0+
- Android minSdk 21, compiled against API 36
- iOS 13.0+
- Declare the Bluetooth permissions each platform needs:

**Android** (`android/app/src/main/AndroidManifest.xml`):

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<uses-feature android:name="android.hardware.bluetooth_le" android:required="true" />
```

**iOS** (`ios/Runner/Info.plist`):

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app uses Bluetooth to connect to nearby devices.</string>
```

## Quick start

```dart
import 'package:bluebreeze/bluebreeze.dart';

final manager = BBManager();

// Request authorization if needed, then start scanning once the adapter is on
if (manager.authorizationStatus != BBAuthorization.authorized) {
  manager.authorizationRequest();
}

manager.stateStream.listen((state) {
  if (state == BBState.poweredOn) {
    manager.scanStart();
  }
});

// Observe scan results
manager.scanResultsStream.listen((result) {
  print('${result.name ?? 'Unknown device'} ${result.rssi}');
});

// Connect, discover, and talk to a device
Future<void> connectToFirstDevice() async {
  if (manager.devices.isEmpty) return;
  final device = manager.devices.values.first;

  await device.connect();
  await device.discoverServices();

  for (final service in device.services) {
    for (final characteristic in service.characteristics) {
      if (characteristic.properties.contains(BBCharacteristicProperty.read)) {
        final data = await characteristic.read();
        print('${characteristic.id} $data');
      }
    }
  }

  await device.disconnect();
}
```

See [`example`](example) for a full app built on top of BlueBreeze.

## Documentation

The public API is documented with dartdoc directly in the source under [`lib`](lib) -- hover
any exported member in your editor to see it, or browse it there directly.

## License

BlueBreeze is available under the MIT license. See [LICENSE](LICENSE) for details.
