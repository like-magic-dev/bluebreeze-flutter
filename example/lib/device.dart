import 'package:bluebreeze_flutter/bluebreeze_device.dart';
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name ?? widget.device.id),
        actions: const [
          // StreamBuilder(
          //   stream: widget.device.scanningEnabledStream,
          //   builder: (builderContext, snapshot) {
          //     if (widget.manager.scanningEnabled) {
          //       return TextButton(
          //         onPressed: () => widget.manager.scanningStop(),
          //         child: const Text("STOP"),
          //       );
          //     } else {
          //       return TextButton(
          //         onPressed: () => widget.manager.scanningStart(),
          //         child: const Text("START"),
          //       );
          //     }
          //   },
          // ),
        ],
      ),
      body: Container(),
      // StreamBuilder(
      //   stream: widget.manager.devicesStream,
      //   builder: (builderContext, snapshot) {
      //     final devices = widget.manager.devices.values.toList();
      //     return ListView.builder(
      //       itemCount: devices.length,
      //       itemBuilder: (context, index) => ListTile(
      //         title: Expanded(
      //           child: Text(
      //             devices[index].name ?? devices[index].id,
      //             maxLines: 1,
      //             overflow: TextOverflow.ellipsis,
      //           ),
      //         ),
      //         subtitle: Column(
      //           crossAxisAlignment: CrossAxisAlignment.start,
      //           children: [
      //             Text(devices[index].manufacturerName ?? '-'),
      //             if (devices[index].advertisedServices.isNotEmpty)
      //               Text(
      //                 devices[index].advertisedServices.join(', '),
      //                 style: const TextStyle(fontSize: 14),
      //               ),
      //           ],
      //         ),
      //         trailing: Text(
      //           devices[index].rssi.toString(),
      //           style: const TextStyle(fontSize: 18),
      //         ),
      //       ),
      //     );
      //   }),
    );
  }
}
