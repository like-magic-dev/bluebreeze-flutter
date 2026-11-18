//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import 'package:bluebreeze/impl/bluebreeze_method_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MethodChannelBlueBreeze platform;

  Future<void> sendScanEnabled(bool value) => platform.methodCallHandler(MethodCall('scanEnabledUpdate', {'value': value}));

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('bluebreeze'),
      (call) async => null,
    );
    platform = MethodChannelBlueBreeze();
  });

  test('value reflects the latest published value', () async {
    await sendScanEnabled(true);

    expect(platform.scanEnabled.value, isTrue);
  });

  test('updates only emits values published after listening', () async {
    await sendScanEnabled(true);

    final received = <bool>[];
    final subscription = platform.scanEnabled.updates.listen(received.add);

    await sendScanEnabled(false);
    await sendScanEnabled(true);
    await pumpEventQueue();
    await subscription.cancel();

    expect(received, [false, true]);
  });

  test('values emits the current value first', () async {
    await sendScanEnabled(true);

    final received = <bool>[];
    final subscription = platform.scanEnabled.values.listen(received.add);

    await sendScanEnabled(false);
    await pumpEventQueue();
    await subscription.cancel();

    expect(received, [true, false]);
  });

  test('values replays to every listener independently', () async {
    final observable = platform.scanEnabled;
    final first = <bool>[];
    final second = <bool>[];

    final firstSubscription = observable.values.listen(first.add);
    await sendScanEnabled(true);
    await pumpEventQueue();

    final secondSubscription = observable.values.listen(second.add);
    await pumpEventQueue();

    await firstSubscription.cancel();
    await secondSubscription.cancel();

    expect(first, [false, true]);
    expect(second, [true]);
  });
}
