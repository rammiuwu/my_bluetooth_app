import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_bluetooth_app/screens/bluetooth_provider.dart';

class DeviceScreen extends StatelessWidget {
  const DeviceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bluetoothProvider = Provider.of<BluetoothProvider>(context);
    final isConnected = bluetoothProvider.isConnected;
    final humidity = bluetoothProvider.humidity;
    final light = bluetoothProvider.light;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Datos del Dispositivo'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isConnected ? 'Dispositivo Conectado' : 'Conectando...',
              style: TextStyle(
                fontSize: 20,
                color: isConnected ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            Text('Humedad: $humidity%', style: const TextStyle(fontSize: 18)),
            Text('Luz: $light lx', style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
