import 'package:bluebreeze_flutter/bluebreeze_characteristic.dart';

class BBService {
  BBService({
    required this.id,
    required this.name,
    required this.characteristics,
  });

  final String id;
  final String? name;
  final List<BBCharacteristic> characteristics;
}
