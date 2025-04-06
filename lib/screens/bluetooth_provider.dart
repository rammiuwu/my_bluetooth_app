import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothProvider with ChangeNotifier {
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _readCharacteristic;
  bool _isConnected = false;
  String _humidity = "N/A";
  String _light = "N/A";

  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isConnected => _isConnected;
  String get humidity => _humidity;
  String get light => _light;

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      if (!(await device.isConnected)) {
        await device.connect(autoConnect: false);
      }

      _connectedDevice = device;
      _isConnected = true;
      notifyListeners();

      await _discoverServices(device);
    } catch (e) {
      print("Error al conectar al dispositivo: $e");
      rethrow;
    }
  }

  Future<void> _discoverServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();

    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.notify ||
            characteristic.properties.read) {
          _readCharacteristic = characteristic;
          await _startListening();
        }
      }
    }
  }

  Future<void> _startListening() async {
    if (_readCharacteristic == null) return;

    await _readCharacteristic!.setNotifyValue(true);

    _readCharacteristic!.value.listen((value) {
      if (value.isNotEmpty) {
        String data = String.fromCharCodes(value);
        print("📡 String recibido: $data"); // 👈 LOG IMPORTANTE

        List<String> parts = data.split(',');

        if (parts.length >= 2) {
          _humidity = parts[0];
          _light = parts[1];
          print("✅ Humedad: $_humidity, Luz: $_light"); // 👈 LOG EXTRA
          notifyListeners();
        } else {
          print("⚠️ Datos mal formateados: $data"); // 👈 Si no viene con coma
        }
      } else {
        print("❌ Valor recibido vacío");
      }
    });
  }

  Future<void> disconnectDevice() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
      _isConnected = false;
      _humidity = "N/A";
      _light = "N/A";
      notifyListeners();
    }
  }
}
