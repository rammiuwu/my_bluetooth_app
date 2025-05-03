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
        sensorName == 'Luz'
            ? bluetoothProvider.light.toString()
            : bluetoothProvider.humidity.toString();

    // Obtener el mensaje de consejos según el tipo de sensor utilizando los valores actuales
    String _sensorRecommendationMessage = '';

    if (sensorName == 'Luz') {
      _sensorRecommendationMessage = plantProvider.getMensajeLuz(
        sensorValue,
      ); // Consejos de luz
    } else if (sensorName == 'Humedad') {
      _sensorRecommendationMessage = plantProvider.getMensajeHumedad(
        sensorValue,
      ); // Consejos de humedad
    }

    // Mostrar el pop-up con los valores y consejos actuales
    showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: dialogColor, // Color dinámico para el fondo
          title: Text(
            '$sensorName',
            style: const TextStyle(color: Colors.white), // Título en blanco
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ), // Ajuste de padding
          content: StatefulBuilder(
            builder: (BuildContext context, setState) {
              return Consumer<BluetoothProvider>(
                builder: (context, bluetoothProvider, child) {
                  return StreamBuilder<Map<String, String>>(
                    stream: bluetoothProvider.sensorDataStream,
                    builder: (context, snapshot) {
                      // Muestra el valor actual y los consejos en cuanto se abre el pop-up
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$sensorValue\n${sensorName == 'Luz' ? 'lx' : '%'}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _sensorRecommendationMessage, // Consejos iniciales
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        );
                      }

                      if (snapshot.hasError) {
                        return const Text(
                          'Error al obtener los datos',
                          style: TextStyle(color: Colors.white),
                        );
                      }

                      if (snapshot.hasData) {
                        final data = snapshot.data!;
                        final updatedValueString =
                            sensorName == 'Luz'
                                ? data['light']
                                : data['humidity'];

                        // Asegurarse de convertir el valor de los sensores correctamente
                        final updatedValue = double.tryParse(
                          updatedValueString ?? '',
                        );

                        // Verifica si la conversión fue exitosa
                        if (updatedValue != null) {
                          String updatedRecommendation = '';
                          if (sensorName == 'Luz') {
                            updatedRecommendation = plantProvider.getMensajeLuz(
                              updatedValue.toString(),
                            );
                          } else if (sensorName == 'Humedad') {
                            updatedRecommendation = plantProvider
                                .getMensajeHumedad(updatedValue.toString());
                          }

                          return SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$updatedValue\n${sensorName == 'Luz' ? 'lx' : '%'}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  updatedRecommendation, // Consejos actualizados
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          );
                        } else {
                          return const Text(
                            'Datos no válidos',
                            style: TextStyle(color: Colors.white),
                          );
                        }
                      }

                      return const Text(
                        'Datos no disponibles',
                        style: TextStyle(color: Colors.white),
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
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'OK'),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
          // Limitar el tamaño máximo del contenido del pop-up
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
        final mensajeHumedad = plantProvider.getMensajeHumedad(
          bluetoothProvider.humidity,
        );
        final mensajeLuz = plantProvider.getMensajeLuz(bluetoothProvider.light);

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
                                  color: Color.fromARGB(255, 255, 156, 7),
                                  width: 2,
                                ),
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(25),
                                backgroundColor: const Color.fromRGBO(
                                  255,
                                  193,
                                  7,
                                  1,
                                ), // fondo amarillo
                              ),
                              onPressed: () {
                                _showSensorDialog(
                                  context,
                                  'Luz',
                                  const Color.fromRGBO(
                                    255,
                                    193,
                                    7,
                                    1,
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
                                  color: Color.fromARGB(255, 33, 72, 243),
                                  width: 2,
                                ),
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(25),
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  33,
                                  150,
                                  243,
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
                          ],
                        ),
                        const SizedBox(height: 30),
                        // Estado de conexión
                        Center(
                          child: Text(
                            widget.device == null
                                ? '⚠️ No hay dispositivo conectado'
                                : (isConnected
                                    ? '✅ Dispositivo Conectado'
                                    : '⏳ Conectando...'),
                            style: TextStyle(
                              fontSize: 20,
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
