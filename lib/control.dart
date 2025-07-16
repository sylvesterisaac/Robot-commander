import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class ControlPage extends StatefulWidget {
  final BluetoothConnection connection;
  final String deviceName;

  ControlPage({required this.connection, required this.deviceName});

  @override
  _ControlPageState createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  void _sendCommand(String cmd) {
    widget.connection.output.add(Uint8List.fromList(cmd.codeUnits));
    widget.connection.output.allSent;
  }

  Widget _buildControlButton(
    String label,
    IconData icon,
    String command, {
    Color color = Colors.blueGrey,
  }) {
    return ElevatedButton.icon(
      onPressed: () => _sendCommand(command),
      icon: Icon(icon, size: 24),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 5,
      ),
    );
  }

  @override
  void dispose() {
    widget.connection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Control: ${widget.deviceName}"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              "Use the buttons to control your robot",
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
            SizedBox(height: 40),
            _buildControlButton(
              "Forward",
              Icons.arrow_upward,
              'F',
              color: Colors.green,
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  "Left",
                  Icons.arrow_back,
                  'L',
                  color: Colors.orange,
                ),
                _buildControlButton(
                  "Right",
                  Icons.arrow_forward,
                  'R',
                  color: Colors.orange,
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildControlButton(
              "Backward",
              Icons.arrow_downward,
              'B',
              color: Colors.red,
            ),
            SizedBox(height: 20),
            _buildControlButton("Stop", Icons.stop, 'S', color: Colors.black),
          ],
        ),
      ),
    );
  }
}
