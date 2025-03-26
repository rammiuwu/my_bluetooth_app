import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DeviceScreen extends StatefulWidget {
  final BluetoothDevice device;
  const DeviceScreen({Key? key, required this.device}) : super(key: key);

  @override
  _DeviceScreenState createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  BluetoothCharacteristic? writeCharacteristic;
  BluetoothCharacteristic? readCharacteristic;
  bool isConnected = false;
  double humidity = 0.0;
  double light = 0.0;

  @override
  void initState() {
    super.initState();
    connectToDevice();
  }

  void connectToDevice() async {
    await widget.device.connect();
    List<BluetoothService> services = await widget.device.discoverServices();

    for (var service in services) {
      for (var char in service.characteristics) {
        if (char.properties.write) {
          setState(() {
            writeCharacteristic = char;
          });
        }
        if (char.properties.notify || char.properties.read) {
          setState(() {
            readCharacteristic = char;
            startListening();
          });
        }
      }
    }
    setState(() {
      isConnected = true;
    });
  }

  void startListening() {
    if (readCharacteristic != null) {
      readCharacteristic!.setNotifyValue(true);
      readCharacteristic!.value.listen((value) {
        String rawData = String.fromCharCodes(value).trim();
        parseSensorData(rawData);
      });
    }
  }

  void parseSensorData(String data) {
    try {
      List<String> parts = data.split(",");
      if (parts.length == 2) {
        setState(() {
          humidity = double.tryParse(parts[0]) ?? humidity;
          light = double.tryParse(parts[1]) ?? light;
        });
      }
    } catch (e) {
      print("Error al parsear datos: $e");
    }
  }

  @override
  void dispose() {
    widget.device.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.device.localName)),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          isConnected
              ? Text(
                "Conectado a ${widget.device.localName}",
                style: TextStyle(fontSize: 18),
              )
              : Text("Conectando..."),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              sensorBubble("Humedad", humidity, Colors.blue),
              sensorBubble("Luz", light, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget sensorBubble(String label, double value, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "${value.toStringAsFixed(1)} ${label == 'Humedad' ? '%' : 'lx'}",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
