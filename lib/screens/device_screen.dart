import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_bluetooth_app/screens/bluetooth_provider.dart';
import 'package:my_bluetooth_app/screens/plant_provider.dart';
import 'package:my_bluetooth_app/screens/bluetooth_screen.dart';
import 'package:my_bluetooth_app/main.dart'; // para ThemeProvider

class DeviceScreen extends StatefulWidget {
  final String plantName;
  final BluetoothDevice? device;

  const DeviceScreen({Key? key, required this.plantName, this.device})
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

    String originalName = widget.plantName;
    debugPrint("🌱 Nombre original recibido: $originalName");

    if (widget.device != null) {
      try {
        await bluetoothProvider.connectToDevice(widget.device!);
        await bluetoothProvider.fetchSensorData();
      } catch (e) {
        debugPrint("❌ Error conectando al dispositivo: $e");
      }
    } else {
      debugPrint("⚠️ No se recibió un dispositivo Bluetooth.");
    }

    await plantProvider.fetchStandards(originalName);

    setState(() {
      _firebaseLoaded = true;
    });
  }

  void _showSensorDialog(
    BuildContext context,
    String sensorName,
    Color dialogColor, // Parámetro para el color dinámico
  ) async {
    final bluetoothProvider = Provider.of<BluetoothProvider>(
      context,
      listen: false,
    );

    final plantProvider = Provider.of<PlantProvider>(context, listen: false);

    // Recuperar los valores actualizados de los sensores
    final sensorValue =
        {
          'Luz': bluetoothProvider.light.toString(),
          'Humedad': bluetoothProvider.humidity.toString(),
          'Ph': bluetoothProvider.ph.toString(),
          'Temperatura': bluetoothProvider.temperature.toString(),
        }[sensorName] ??
        '0';

    String _sensorRecommendationMessage = '';
    if (sensorName == 'Luz') {
      _sensorRecommendationMessage = plantProvider.getMensajeLuz(sensorValue);
    } else if (sensorName == 'Humedad') {
      _sensorRecommendationMessage = plantProvider.getMensajeHumedad(
        sensorValue,
      );
    } else if (sensorName == 'Ph') {
      _sensorRecommendationMessage = plantProvider.getMensajePh(sensorValue);
    } else if (sensorName == 'Temperatura') {
      _sensorRecommendationMessage = plantProvider.getMensajeTemperatura(
        sensorValue,
      );
    }

    String _getUnidad(String sensorName) {
      switch (sensorName) {
        case 'Luz':
          return 'lx';
        case 'Humedad':
          return '%';
        case 'Temperatura':
          return '°C';
        case 'Ph':
          return ''; // Sin unidad
        default:
          return '';
      }
    }

    showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: dialogColor,
          title: Text(
            '$sensorName',
            style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, setState) {
              return Consumer<BluetoothProvider>(
                builder: (context, bluetoothProvider, child) {
                  return StreamBuilder<Map<String, String>>(
                    stream: bluetoothProvider.sensorDataStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$sensorValue\n${_getUnidad(sensorName)}',
                              style: const TextStyle(
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _sensorRecommendationMessage,
                              style: const TextStyle(
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                            ),
                          ],
                        );
                      }

                      if (snapshot.hasError) {
                        return const Text(
                          'Error al obtener los datos',
                          style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                        );
                      }

                      if (snapshot.hasData) {
                        final data = snapshot.data!;
                        String? updatedValueString;

                        // Asignar el valor correcto según el sensor
                        switch (sensorName) {
                          case 'Luz':
                            updatedValueString = data['light'];
                            break;
                          case 'Humedad':
                            updatedValueString = data['humidity'];
                            break;
                          case 'Temperatura':
                            updatedValueString = data['temperature'];
                            break;
                          case 'Ph':
                            updatedValueString = data['ph'];
                            break;
                        }

                        final updatedValue = double.tryParse(
                          updatedValueString ?? '',
                        );

                        if (updatedValue != null) {
                          String updatedRecommendation = '';

                          switch (sensorName) {
                            case 'Luz':
                              updatedRecommendation = plantProvider
                                  .getMensajeLuz(updatedValue.toString());
                              break;
                            case 'Humedad':
                              updatedRecommendation = plantProvider
                                  .getMensajeHumedad(updatedValue.toString());
                              break;
                            case 'Temperatura':
                              updatedRecommendation = plantProvider
                                  .getMensajeTemperatura(
                                    updatedValue.toString(),
                                  );
                              break;
                            case 'Ph':
                              updatedRecommendation = plantProvider
                                  .getMensajePh(updatedValue.toString());
                              break;
                          }

                          return SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$updatedValue ${_getUnidad(sensorName)}',
                                  style: const TextStyle(
                                    color: Color.fromARGB(255, 0, 0, 0),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  updatedRecommendation,
                                  style: const TextStyle(
                                    color: Color.fromARGB(255, 0, 0, 0),
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          return const Text(
                            'Datos no válidos',
                            style: TextStyle(
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                          );
                        }
                      }

                      return const Text(
                        'Datos no disponibles',
                        style: TextStyle(color: Color.fromARGB(255, 3, 3, 3)),
                      );
                    },
                  );
                },
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 'Cancelar'),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'OK'),
              child: const Text(
                'OK',
                style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
              ),
            ),
          ],
          scrollable: true,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final primaryColor = isDarkMode ? Colors.teal[400] : Colors.blueGrey[800];

    return Consumer2<BluetoothProvider, PlantProvider>(
      builder: (context, bluetoothProvider, plantProvider, child) {
        final isConnected = bluetoothProvider.isConnected;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.plantName,
              style: GoogleFonts.robotoCondensed(
                fontWeight: FontWeight.bold,
                color: primaryColor,
                fontSize: 22,
              ),
            ),
            backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: primaryColor),
            actions: [
              IconButton(
                icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
                color: primaryColor,
                onPressed: () => themeProvider.toggleTheme(),
              ),
              IconButton(
                icon: Icon(Icons.bluetooth),
                color: primaryColor,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BluetoothScreen()),
                  );
                },
              ),
            ],
          ),
          body:
              !_firebaseLoaded
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        // Botones con contorno y fondo de colores
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color.fromARGB(255, 255, 205, 42),
                                  width: 2,
                                ),
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(20),
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  253,
                                  234,
                                  64,
                                ), // fondo amarillo
                              ),
                              onPressed: () {
                                _showSensorDialog(
                                  context,
                                  'Luz',
                                  const Color.fromARGB(
                                    255,
                                    253,
                                    234,
                                    64,
                                  ), // Mostrar el mensaje de recomendación
                                );
                              },
                              child: const Icon(
                                Icons.wb_sunny,
                                size: 35,
                                color: Color.fromARGB(
                                  255,
                                  255,
                                  255,
                                  255,
                                ), // ícono blanco
                              ),
                            ),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color.fromARGB(255, 91, 124, 255),
                                  width: 2,
                                ),
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(20),
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  94,
                                  192,
                                  228,
                                ), // fondo azul
                              ),
                              onPressed: () {
                                _showSensorDialog(
                                  context,
                                  'Humedad',
                                  const Color.fromARGB(
                                    255,
                                    33,
                                    150,
                                    243,
                                  ), // Mostrar el mensaje de recomendación
                                );
                              },
                              child: const Icon(
                                Icons.water_drop,
                                size: 35,
                                color: Colors.white, // ícono blanco
                              ),
                            ),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color.fromARGB(255, 192, 26, 26),
                                  width: 2,
                                ),
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(20),
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  250,
                                  100,
                                  100,
                                ), // fondo azul
                              ),
                              onPressed: () {
                                _showSensorDialog(
                                  context,
                                  'Temperatura',
                                  const Color.fromARGB(
                                    255,
                                    250,
                                    100,
                                    100,
                                  ), // Mostrar el mensaje de recomendación
                                );
                              },
                              child: const Icon(
                                Icons.device_thermostat,
                                size: 35,
                                color: Colors.white, // ícono blanco
                              ),
                            ),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color.fromARGB(255, 242, 140, 204),
                                  width: 2,
                                ),
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(20),
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  255,
                                  195,
                                  235,
                                ), // fondo azul
                              ),
                              onPressed: () {
                                _showSensorDialog(
                                  context,
                                  'Ph',
                                  const Color.fromARGB(
                                    255,
                                    255,
                                    195,
                                    235,
                                  ), // Mostrar el mensaje de recomendación
                                );
                              },
                              child: const Icon(
                                Icons.science,
                                size: 35,
                                color: Colors.white, // ícono blanco
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        // Estado de conexión
                        Center(
                          child: Text(
                            widget.device == null
                                ? 'No hay dispositivo conectado...'
                                : (isConnected
                                    ? 'Dispositivo Conectado'
                                    : 'Conectando...'),
                            style: TextStyle(
                              fontSize: 18,
                              color:
                                  widget.device == null
                                      ? const Color.fromARGB(255, 0, 0, 0)
                                      : (isConnected
                                          ? Colors.green
                                          : Colors.red),
                            ),
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
