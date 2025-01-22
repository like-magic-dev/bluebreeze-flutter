//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import 'package:bluebreeze_flutter/bluebreeze_authorization.dart';
import 'package:bluebreeze_flutter/bluebreeze_manager.dart';
import 'package:bluebreeze_flutter/bluebreeze_state.dart';
import 'package:bluebreeze_flutter_example/offline.dart';
import 'package:bluebreeze_flutter_example/permissions.dart';
import 'package:bluebreeze_flutter_example/scanning.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp({super.key});

  final manager = BBManager();

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: StreamBuilder(
        stream: widget.manager.authorizationStatusStream,
        builder: (builderContext, snapshot) {
          if (widget.manager.authorizationStatus != BBAuthorization.authorized) {
            return PermissionsWidget(manager: widget.manager);
          } else {
            return StreamBuilder(
              stream: widget.manager.stateStream,
              builder: (builderContext, snapshot) {
                if (widget.manager.state != BBState.poweredOn) {
                  return const OfflineWidget();
                } else {
                  return ScanningWidget(manager: widget.manager);
                }
              },
            );
          }
        },
      ),
    );
  }
}
