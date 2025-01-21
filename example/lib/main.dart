import 'package:bluebreeze_flutter/bluebreeze_authorization.dart';
import 'package:bluebreeze_flutter/bluebreeze_manager.dart';
import 'package:bluebreeze_flutter/bluebreeze_state.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _manager = BBManager();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            children: [
              StreamBuilder(
                stream: _manager.stateStream,
                builder: (builderContext, snapshot) {
                  return Text('State: ${_manager.state.name}');
                },
              ),
              StreamBuilder(
                stream: _manager.authorizationStatusStream,
                builder: (builderContext, snapshot) {
                  return Text('Authorization: ${_manager.authorizationStatus.name}');
                },
              ),
              TextButton(
                onPressed: () => _manager.authorizationRequest(),
                child: const Text('Request Authorization'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
