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
        print("📡 String recibido: $data");

        List<String> parts = data.split(',');

        if (parts.length >= 2) {
          _humidity = parts[0];
          _light = parts[1];
          print("✅ Humedad: $_humidity, Luz: $_light");

          // Aquí puedes notificar al PlantProvider si es necesario
          notifyListeners();
        } else {
          print("⚠️ Datos mal formateados: $data");
        }
      } else {
        print("❌ Valor recibido vacío");
      }
    });
  }

  // Nueva función para obtener los datos de los sensores
  Future<void> fetchSensorData() async {
    if (_readCharacteristic == null) {
      print("❌ Característica no disponible para leer los datos.");
      return;
    }

    // Llama a la función que empieza a escuchar las características
    await _startListening(); // Esto asegura que los datos sean escuchados y procesados

    // En este punto, los valores de _humidity y _light ya están siendo actualizados
    // por los datos recibidos del dispositivo.
    notifyListeners(); // Asegura que la UI se actualice con los nuevos datos
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
