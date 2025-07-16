import 'dart:async';

import 'package:arduinocom/control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

class ConnectPage extends StatefulWidget {
  @override
  _ConnectPageState createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  BluetoothConnection? connection;
  bool connecting = false;
  bool loading = true;

  List<BluetoothDiscoveryResult> discoveredDevices = [];
  StreamSubscription<BluetoothDiscoveryResult>? _streamSubscription;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    await _checkPermissions();
    await _ensureBluetoothIsOn();
    _startDiscovery();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
  }

  Future<void> _ensureBluetoothIsOn() async {
    final isEnabled = await FlutterBluetoothSerial.instance.isEnabled;

    if (isEnabled == null || !isEnabled) {
      await FlutterBluetoothSerial.instance.requestEnable();
    }
  }

  Future<void> _startDiscovery() async {
    setState(() {
      discoveredDevices.clear();
      loading = true;
    });

    _streamSubscription = FlutterBluetoothSerial.instance
        .startDiscovery()
        .listen(
          (result) {
            setState(() {
              final existingIndex = discoveredDevices.indexWhere(
                (d) => d.device.address == result.device.address,
              );
              if (existingIndex >= 0) {
                discoveredDevices[existingIndex] = result;
              } else {
                discoveredDevices.add(result);
              }
            });
          },
          onDone: () {
            setState(() => loading = false);
          },
          onError: (e) {
            setState(() => loading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Discovery failed: ${e.toString()}")),
            );
          },
        );
  }

  void _connectToDevice(BluetoothDevice device) async {
    try {
      setState(() => connecting = true);
      print('🔌 Trying to connect to ${device.name}');

      final conn = await BluetoothConnection.toAddress(device.address);

      print('✅ Connection established');
      if (!mounted) return;
      setState(() => connecting = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ControlPage(connection: conn, deviceName: device.name ?? 'Robot'),
        ),
      );
    } catch (e) {
      print('❌ Connection failed: $e');
      setState(() => connecting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Connection failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Discover Bluetooth Devices")),
      body: connecting
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _streamSubscription?.cancel();
                await _startDiscovery();
              },
              child: loading
                  ? Center(child: CircularProgressIndicator())
                  : discoveredDevices.isEmpty
                  ? ListView(
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(child: Text("No devices found")),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: discoveredDevices.length,
                      itemBuilder: (context, index) {
                        final device = discoveredDevices[index].device;
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          color: Colors.blueGrey[800],
                          child: ListTile(
                            title: Text(
                              (device.name != null && device.name!.isNotEmpty)
                                  ? device.name!
                                  : "Unnamed",
                              style: TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              device.address,
                              style: TextStyle(color: Colors.white70),
                            ),
                            trailing: Icon(
                              Icons.bluetooth,
                              color: Colors.white,
                            ),
                            onTap: () => _connectToDevice(device),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
