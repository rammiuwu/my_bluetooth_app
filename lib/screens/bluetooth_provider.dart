import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BluetoothProvider with ChangeNotifier {
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _readCharacteristic;
  bool _isConnected = false;
  String _humidity = "N/A";
  String _light = "N/A";

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final StreamController<Map<String, String>> _sensorDataController =
      StreamController<Map<String, String>>.broadcast();

  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isConnected => _isConnected;
  String get humidity => _humidity;
  String get light => _light;

  Stream<Map<String, String>> get sensorDataStream =>
      _sensorDataController.stream;

  String? _userId;

  // Constructor que recibe el userId
  BluetoothProvider({String? userId}) {
    if (userId != null) {
      setUserId(userId);
    }
  }

  void setUserId(String userId) {
    _userId = userId;
    print("🆔 userId establecido: $_userId");
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      print("🔌 Intentando conectar al dispositivo...");
      if (!(await device.isConnected)) {
        await device.connect(autoConnect: false);
      }

      _connectedDevice = device;
      _isConnected = true;
      notifyListeners();

      print("✅ Dispositivo conectado: ${device.name}");
      await _discoverServices(device);
    } catch (e) {
      print("❌ Error al conectar al dispositivo: $e");
      rethrow;
    }
  }

  Future<void> _discoverServices(BluetoothDevice device) async {
    print("🔍 Buscando servicios del dispositivo...");
    List<BluetoothService> services = await device.discoverServices();

    for (var service in services) {
      for (var characteristic in service.characteristics) {
        print("🧬 Característica encontrada: ${characteristic.uuid}");
        if (characteristic.properties.notify ||
            characteristic.properties.read) {
          print("📲 Característica válida encontrada para lectura/escucha.");
          _readCharacteristic = characteristic;
          await _startListening();
        }
      }
    }
  }

  Future<void> _startListening() async {
    print("🎧 Iniciando escucha de datos...");
    print("🆔 userId actual: $_userId");

    if (_readCharacteristic == null) {
      print("❌ _readCharacteristic es null. No se puede escuchar.");
      return;
    }

    await _readCharacteristic!.setNotifyValue(true);

    _readCharacteristic!.value.listen((value) {
      print("📥 Valor crudo recibido: $value");

      if (value.isNotEmpty) {
        String data = String.fromCharCodes(value);
        print("📡 String recibido: $data");

        List<String> parts = data.split(',');

        if (parts.length >= 2) {
          _humidity = parts[0];
          _light = parts[1];
          print("✅ Humedad: $_humidity, Luz: $_light");

          _sensorDataController.add({'humidity': _humidity, 'light': _light});

          notifyListeners();

          if (_userId != null) {
            print("💾 Guardando datos en Firebase...");
            saveSensorDataToFirebase();
          } else {
            print("⚠️ userId es null. No se guardarán los datos.");
          }
        } else {
          print("⚠️ Datos mal formateados: $data");
        }
      } else {
        print("❌ Valor recibido vacío");
      }
    });
  }

  Future<void> saveSensorDataToFirebase() async {
    try {
      if (_userId == null) {
        print("⚠️ userId no está definido.");
        return;
      }

      String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      print(
        "🚀 Guardando en Firebase: humidity=$_humidity, light=$_light, date=$formattedDate",
      );

      await _firestore
          .collection('plants')
          .doc(_userId)
          .collection('plantData')
          .doc(formattedDate)
          .set({'humidity': _humidity, 'light': _light, 'date': formattedDate});

      print("✅ Datos de sensores guardados exitosamente en Firebase.");
    } catch (e) {
      print("❌ Error al guardar datos en Firebase: $e");
    }
  }

  Future<void> fetchSensorData() async {
    if (_readCharacteristic == null) {
      print("❌ Característica no disponible para leer los datos.");
      return;
    }

    print("🔄 Reanudando escucha de datos...");
    await _startListening();
    notifyListeners();
  }

  Future<void> disconnectDevice() async {
    if (_connectedDevice != null) {
      print("🔌 Desconectando el dispositivo...");
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
      _isConnected = false;
      _humidity = "N/A";
      _light = "N/A";
      notifyListeners();
      print("✅ Dispositivo desconectado.");
    }
  }

  @override
  void dispose() {
    _sensorDataController.close();
    super.dispose();
    print("🧹 BluetoothProvider eliminado y recursos liberados.");
  }
}
