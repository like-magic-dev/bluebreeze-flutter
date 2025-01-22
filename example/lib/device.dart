//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import 'package:bluebreeze_flutter/bluebreeze_device.dart';
import 'package:bluebreeze_flutter/bluebreeze_device_connection_status.dart';
import 'package:flutter/material.dart';

class DeviceWidget extends StatefulWidget {
  const DeviceWidget({
    required this.device,
    super.key,
  });

  final BBDevice device;

  @override
  State<DeviceWidget> createState() => DeviceWidgetState();
}

class DeviceWidgetState extends State<DeviceWidget> {
  Future connect() async {
    await widget.device.connect();
    await widget.device.discoverServices();
    await widget.device.requestMTU(255);
  }

  Future disconnect() async {
    await widget.device.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name ?? widget.device.id),
        actions: [
          StreamBuilder(
            stream: widget.device.connectionStatusStream,
            builder: (builderContext, snapshot) {
              if (widget.device.connectionStatus == BBDeviceConnectionStatus.connected) {
                return TextButton(
                  onPressed: () => disconnect(),
                  child: const Text("DISCONNECT"),
                );
              } else {
                return TextButton(
                  onPressed: () => connect(),
                  child: const Text("CONNECT"),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder(
          stream: widget.device.servicesStream,
          builder: (builderContext, snapshot) {
            final services = widget.device.services;
            return ListView.builder(
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                return ListTile(
                  title: Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name ?? service.id,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          itemCount: service.characteristics.length,
                          itemBuilder: (context, index) {
                            final characteristic = service.characteristics[index];
                            return Text(
                              characteristic.name ?? characteristic.id,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          }),
    );
  }
}
