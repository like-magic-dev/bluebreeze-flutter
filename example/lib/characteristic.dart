//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import 'dart:typed_data';

import 'package:bluebreeze_flutter/bluebreeze_characteristic.dart';
import 'package:bluebreeze_flutter/bluebreeze_characteristic_property.dart';
import 'package:flutter/material.dart';

class CharacteristicWidget extends StatefulWidget {
  const CharacteristicWidget({
    required this.characteristic,
    super.key,
  });

  final BBCharacteristic characteristic;

  @override
  State<CharacteristicWidget> createState() => CharacteristicWidgetState();
}

class CharacteristicWidgetState extends State<CharacteristicWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.characteristic.name ?? widget.characteristic.id,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                StreamBuilder(
                  stream: widget.characteristic.dataStream,
                  builder: (builderContext, snapshot) {
                    final data = widget.characteristic.data;
                    return Text(data.isEmpty ? '-' : data.hexString);
                  },
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.characteristic.properties.contains(BBCharacteristicProperty.read))
                TextButton(
                  onPressed: () => widget.characteristic.read(),
                  child: const Text('READ'),
                ),
              if (widget.characteristic.properties.contains(BBCharacteristicProperty.writeWithResponse) ||
                  widget.characteristic.properties.contains(BBCharacteristicProperty.writeWithoutResponse))
                TextButton(
                  onPressed: () => widget.characteristic.write(),
                  child: const Text('WRITE'),
                ),
              if (widget.characteristic.properties.contains(BBCharacteristicProperty.notify))
                TextButton(
                  onPressed: () => widget.characteristic.subscribe(),
                  child: const Text('SUBSCRIBE'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

extension on Uint8List {
  String get hexString => map(
        (byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase(),
      ).join();
}
