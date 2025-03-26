import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:my_bluetooth_app/screens/device_screen.dart';
import 'package:my_bluetooth_app/screens/home_screen.dart'; // Importamos la pantalla principal

class BluetoothScreen extends StatefulWidget {
  @override
  _BluetoothScreenState createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  final flutterBlue = FlutterBluePlus();
  List<BluetoothDevice> devicesList = [];
  bool isScanning = false;

  void startScan() {
    if (isScanning) return;

    setState(() {
      isScanning = true;
      devicesList.clear();
    });

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5)).then((_) {
      setState(() => isScanning = false);
    });

    FlutterBluePlus.scanResults.listen((results) {
      for (var result in results) {
        if (!devicesList.contains(result.device)) {
          setState(() {
            devicesList.add(result.device);
          });
        }
      }
    });
  }

  void connectToDevice(BluetoothDevice device) async {
    await device.connect();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DeviceScreen(device: device)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Escaneo Bluetooth"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          },
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: startScan,
            child: Text(isScanning ? "Escaneando..." : "Iniciar Escaneo"),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: devicesList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(devicesList[index].platformName),
                  onTap: () => connectToDevice(devicesList[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
