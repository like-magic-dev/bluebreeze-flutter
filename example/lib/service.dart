//
// Copyright (c) Like Magic e.U. and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

import 'package:bluebreeze/bluebreeze.dart';
import 'package:bluebreeze_example/characteristic.dart';
import 'package:flutter/material.dart';

class ServiceView extends StatelessWidget {
  const ServiceView({
    super.key,
    required this.service,
  });

  final BBService service;

  @override
  Widget build(BuildContext context) {
    final characteristics = service.characteristics;
    characteristics.sort((a, b) => a.id.compareTo(b.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            service.name ?? service.id,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          itemCount: characteristics.length,
          itemBuilder: (context, index) {
            final characteristic = characteristics[index];
            return CharacteristicWidget(characteristic: characteristic);
          },
        )
      ],
    );
  }
}
