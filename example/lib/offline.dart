//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import 'package:flutter/material.dart';

class OfflineWidget extends StatefulWidget {
  const OfflineWidget({
    super.key,
  });

  @override
  State<OfflineWidget> createState() => OfflineWidgetState();
}

class OfflineWidgetState extends State<OfflineWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE Offline'),
      ),
      body: const Center(
        child: Text("Bluetooth offline"),
      ),
    );
  }
}
