import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothApp extends StatefulWidget {
  @override
  _BluetoothAppState createState() => _BluetoothAppState();
}

class _BluetoothAppState extends State<BluetoothApp> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _bluetooth = FlutterBluetoothSerial.instance;
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  BluetoothConnection connection;
  bool isDisconnecting = false;
  bool get isConnected => connection != null && connection.isConnected;
  List<BluetoothDevice> _devicesList = [];
  BluetoothDevice _device;
  bool _connected = false;
  bool _isButtonUnavailable = false;

  @override
  void initState() {
    enableBluetooth();
    listen();
    super.initState();
  }

  Future<void> getPairedDevices() async {
    if (!mounted) return;
    _devicesList = await _bluetooth.getBondedDevices();
    setState(() {});
  }

  Future<void> enableBluetooth() async {
    _bluetoothState = await FlutterBluetoothSerial.instance.state;
    if (_bluetoothState == BluetoothState.STATE_OFF) {
      await FlutterBluetoothSerial.instance.requestEnable();
      await getPairedDevices();
      return true;
    } else {
      await getPairedDevices();
    }
    return false;
  }

  Future<void> listen() async {
    FlutterBluetoothSerial.instance.onStateChanged().listen((state) {
      _bluetoothState = state;
      if (_bluetoothState == BluetoothState.STATE_OFF) {
        _isButtonUnavailable = true;
      }
      getPairedDevices();
    });
  }

  Future<void> _sendText(String text) async {
    connection.output.add(utf8.encode(text + "\r\n"));
    await connection.output.allSent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF171F24),
      key: _scaffoldKey,
      appBar: _buildAppBar(),
      body: Container(
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                const Text(
                  'Device:',
                  style: TextStyle(color: Colors.white),
                ),
                DropdownButton(
                  iconEnabledColor: Colors.white,
                  dropdownColor: Colors.black,
                  focusColor: Colors.white,
                  iconDisabledColor: Colors.white,
                  style: TextStyle(color: Colors.white),
                  items: _getDeviceItems(),
                  onChanged: (value) => setState(() => _device = value),
                  value: _devicesList.isNotEmpty ? _device : null,
                ),
                RaisedButton(
                  onPressed: _isButtonUnavailable
                      ? null
                      : _connected ? _disconnect : _connect,
                  child: Text(_connected ? 'Disconnect' : 'Connect'),
                ),
              ],
            ),
            Spacer(),
            IgnorePointer(
              ignoring: !_connected,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Transform.scale(
                    scale: 4,
                    child: IconButton(
                      icon: Icon(Icons.keyboard_arrow_up),
                      color: Colors.white,
                      onPressed: () => _sendText('W'),
                    ),
                  ),
                  SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      Transform.scale(
                        scale: 4,
                        child: IconButton(
                          icon: Icon(Icons.keyboard_arrow_left),
                          onPressed: () => _sendText('Q'),
                          color: Colors.white,
                        ),
                      ),
                      Transform.scale(
                        scale: 3,
                        child: IconButton(
                          icon: Icon(Icons.pause),
                          onPressed: () => _sendText('T'),
                          color: Colors.white,
                        ),
                      ),
                      Transform.scale(
                        scale: 4,
                        child: IconButton(
                          icon: Icon(Icons.keyboard_arrow_right),
                          onPressed: () => _sendText('E'),
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            Spacer(),
            Image.asset(
              'assets/logo.png',
              width: 120,
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Color(0xFF4BB2F9).withOpacity(0.5),
      title: const Text('Carrito por bluetooth RC1'),
      actions: <Widget>[
        IconButton(
          icon: Icon(
            Icons.refresh,
            color: Colors.white,
          ),
          onPressed: () async {
            await getPairedDevices();
            show('Device list refreshed');
          },
        ),
      ],
    );
  }

  List<DropdownMenuItem<BluetoothDevice>> _getDeviceItems() {
    List<DropdownMenuItem<BluetoothDevice>> items = [];
    if (_devicesList.isEmpty) {
      items.add(DropdownMenuItem(child: const Text('NONE')));
    } else {
      _devicesList.forEach((device) {
        items.add(DropdownMenuItem(
          child: Text(device.name),
          value: device,
        ));
      });
    }
    return items;
  }

  Future<void> _connect() async {
    _isButtonUnavailable = true;
    if (_device == null) {
      show('No device selected');
    } else {
      if (!isConnected) {
        connection = await BluetoothConnection.toAddress(_device.address);
        print('Connected to the device');
        _connected = true;
        show('Device connected');
        _isButtonUnavailable = false;
      }
    }
    setState(() {});
  }

  Future<void> _disconnect() async {
    _isButtonUnavailable = true;
    await connection.close();
    show('Device disconnected');
    if (!connection.isConnected) {
      _connected = false;
      _isButtonUnavailable = false;
    }
    setState(() {});
  }

  Future<void> show(
    String message, {
    Duration duration: const Duration(seconds: 3),
  }) async {
    await Future.delayed(Duration(milliseconds: 100));
    _scaffoldKey.currentState.showSnackBar(
      SnackBar(content: Text(message), duration: duration),
    );
  }

  @override
  void dispose() {
    if (isConnected) {
      isDisconnecting = true;
      connection.dispose();
      connection = null;
    }
    super.dispose();
  }
}
