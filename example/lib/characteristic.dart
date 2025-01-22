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
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (builderContext) {
                        Uint8List? writeData;
                        return AlertDialog(
                          title: const Text('Write'),
                          content: TextField(
                            decoration: const InputDecoration(
                              hintText: 'Enter data',
                            ),
                            onChanged: (text) {
                              writeData = text.hexData;
                            },
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(builderContext).pop();
                              },
                              child: const Text('CANCEL'),
                            ),
                            TextButton(
                              onPressed: () {
                                final writeData_ = writeData;
                                if (writeData_ == null) {
                                  return;
                                }

                                widget.characteristic.write(
                                  data: writeData_,
                                  withResponse: true,
                                );

                                Navigator.of(builderContext).pop();
                              },
                              child: const Text('WRITE'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: const Text('WRITE'),
                ),
              if (widget.characteristic.properties.contains(BBCharacteristicProperty.notify))
                StreamBuilder(
                  stream: widget.characteristic.notifyEnabledStream,
                  builder: (builderContext, snapshot) {
                    if (widget.characteristic.notifyEnabled) {
                      return TextButton(
                        onPressed: () => widget.characteristic.unsubscribe(),
                        child: const Text('UNSUBSCRIBE'),
                      );
                    } else {
                      return TextButton(
                        onPressed: () => widget.characteristic.subscribe(),
                        child: const Text('SUBSCRIBE'),
                      );
                    }
                  },
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

extension on String {
  Uint8List? get hexData {
    try {
      return Uint8List.fromList(
        splitMapJoin(
          RegExp(r'[0-9A-Fa-f]{2}'),
          onMatch: (match) => String.fromCharCode(int.parse(match.group(0)!, radix: 16)),
        ).codeUnits,
      );
    } catch (e) {
      return null;
    }
  }
}
