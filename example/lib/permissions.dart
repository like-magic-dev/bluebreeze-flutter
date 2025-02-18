//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import 'package:bluebreeze_flutter/bluebreeze_authorization.dart';
import 'package:bluebreeze_flutter/bluebreeze_manager.dart';
import 'package:flutter/material.dart';

class PermissionsWidget extends StatefulWidget {
  const PermissionsWidget({
    required this.manager,
    super.key,
  });

  final BBManager manager;

  @override
  State<PermissionsWidget> createState() => PermissionsWidgetState();
}

class PermissionsWidgetState extends State<PermissionsWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE Permissions'),
      ),
      body: Center(
        child: Column(
          children: [
            const Text('The app is not authorized'),
            if (widget.manager.authorizationStatus == BBAuthorization.unknown)
              TextButton(
                onPressed: () => widget.manager.authorizationRequest(),
                child: const Text('Request Authorization'),
              ),
            if (widget.manager.authorizationStatus == BBAuthorization.denied)
              TextButton(
                onPressed: () => widget.manager.authorizationOpenSettings(),
                child: const Text('Open Settings'),
              ),
          ],
        ),
      ),
    );
  }
}
