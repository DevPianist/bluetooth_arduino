import 'package:bluetooth_arduino/src/pages/bluetooth_app.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Arduino bluetooth',
      theme: ThemeData(
        primaryColor: Colors.purple[900],
        primarySwatch: Colors.blue,
      ),
      home: BluetoothApp(),
    );
  }
}
