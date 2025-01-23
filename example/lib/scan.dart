//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import 'package:bluebreeze_flutter/bluebreeze_manager.dart';
import 'package:bluebreeze_flutter/bluebreeze_scan_result.dart';
import 'package:bluebreeze_flutter_example/device.dart';
import 'package:flutter/material.dart';

class ScanWidget extends StatefulWidget {
  const ScanWidget({
    required this.manager,
    super.key,
  });

  final BBManager manager;

  @override
  State<ScanWidget> createState() => ScanWidgetState();
}

class ScanWidgetState extends State<ScanWidget> {
  final Map<String, BBScanResult> _scanResults = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE Scan'),
        actions: [
          StreamBuilder(
            stream: widget.manager.scanEnabledStream,
            builder: (builderContext, snapshot) {
              if (widget.manager.scanEnabled) {
                return TextButton(
                  onPressed: () => widget.manager.scanStop(),
                  child: const Text("STOP"),
                );
              } else {
                return TextButton(
                  onPressed: () => widget.manager.scanStart(),
                  child: const Text("START"),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: widget.manager.scanResultsStream.map(
          (scanResult) {
            _scanResults[scanResult.device.id] = scanResult;
            return scanResult;
          },
        ),
        builder: (builderContext, snapshot) {
          final scanResults = _scanResults.values.toList();
          return ListView.builder(
            itemCount: scanResults.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(
                scanResults[index].device.name ?? scanResults[index].device.id,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(scanResults[index].manufacturerName ?? '-'),
                  if (scanResults[index].advertisedServices.isNotEmpty)
                    Text(
                      scanResults[index].advertisedServices.join(', '),
                      style: const TextStyle(fontSize: 14),
                    ),
                ],
              ),
              trailing: Text(
                scanResults[index].rssi.toString(),
                style: const TextStyle(fontSize: 18),
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (builderContext) => DeviceWidget(
                    device: scanResults[index].device,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
