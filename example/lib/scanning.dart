import 'package:bluebreeze_flutter/bluebreeze_manager.dart';
import 'package:flutter/material.dart';

class ScanningWidget extends StatefulWidget {
  const ScanningWidget({
    required this.manager,
    super.key,
  });

  final BBManager manager;

  @override
  State<ScanningWidget> createState() => ScanningWidgetState();
}

class ScanningWidgetState extends State<ScanningWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE Scanning'),
        actions: [
          StreamBuilder(
            stream: widget.manager.scanningEnabledStream,
            builder: (builderContext, snapshot) {
              if (widget.manager.scanningEnabled) {
                return TextButton(
                  onPressed: () => widget.manager.scanningStop(),
                  child: const Text("STOP"),
                );
              } else {
                return TextButton(
                  onPressed: () => widget.manager.scanningStart(),
                  child: const Text("START"),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder(
          stream: widget.manager.devicesStream,
          builder: (builderContext, snapshot) {
            final devices = widget.manager.devices.values.toList();
            return ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) => ListTile(
                title: Expanded(
                  child: Text(
                    devices[index].name ?? devices[index].id,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(devices[index].manufacturerName ?? '-'),
                    if (devices[index].advertisedServices.isNotEmpty)
                      Text(
                        devices[index].advertisedServices.join(', '),
                        style: const TextStyle(fontSize: 14),
                      ),
                  ],
                ),
                trailing: Text(
                  devices[index].rssi.toString(),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            );
          }),
    );
  }
}
