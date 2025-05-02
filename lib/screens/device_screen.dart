import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:my_bluetooth_app/screens/bluetooth_provider.dart';
import 'package:my_bluetooth_app/screens/plant_provider.dart';

class DeviceScreen extends StatefulWidget {
  final String plantName;
  final BluetoothDevice device;

  const DeviceScreen({Key? key, required this.plantName, required this.device})
    : super(key: key);

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  bool _firebaseLoaded = false;

  @override
  void initState() {
    super.initState();
    _setupDevice();
  }

  Future<void> _setupDevice() async {
    final bluetoothProvider = Provider.of<BluetoothProvider>(
      context,
      listen: false,
    );
    final plantProvider = Provider.of<PlantProvider>(context, listen: false);

    // Paso 1: Conectar al dispositivo
    await bluetoothProvider.connectToDevice(widget.device);

    // Paso 2: Normalizar y verificar el nombre de la planta
    String originalName = widget.plantName;
    debugPrint("🌱 Nombre original recibido: $originalName");

    // Paso 3: Cargar estándares de Firebase para esta planta
    await plantProvider.fetchStandards(originalName);

    // Paso 4: Obtener los datos del sensor
    await bluetoothProvider.fetchSensorData();

    setState(() {
      _firebaseLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<BluetoothProvider, PlantProvider>(
      builder: (context, bluetoothProvider, plantProvider, child) {
        final isConnected = bluetoothProvider.isConnected;
        final humidity = bluetoothProvider.humidity;
        final light = bluetoothProvider.light;
        final mensajeHumedad = plantProvider.getMensajeHumedad(humidity);
        final mensajeLuz = plantProvider.getMensajeLuz(light);

        return Scaffold(
          appBar: AppBar(
            title: Text('Datos de ${widget.plantName}'),
            backgroundColor: Colors.green,
          ),
          body:
              !_firebaseLoaded
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            isConnected
                                ? 'Dispositivo Conectado'
                                : 'Conectando...',
                            style: TextStyle(
                              fontSize: 20,
                              color: isConnected ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          '🌿 Humedad: $humidity%',
                          style: const TextStyle(fontSize: 18),
                        ),
                        Text(
                          mensajeHumedad,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '💡 Luz: $light lx',
                          style: const TextStyle(fontSize: 18),
                        ),
                        Text(
                          mensajeLuz,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
        );
      },
    );
  }
}
