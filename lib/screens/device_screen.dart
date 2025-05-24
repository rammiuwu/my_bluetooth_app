import 'dart:math';
import 'dart:async';
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

class _DeviceScreenState extends State<DeviceScreen>
    with SingleTickerProviderStateMixin {
  bool _firebaseLoaded = false;
  bool _switchValue = false;

  // 🎯 CONFIGURACIÓN DE POSICIÓN Y TAMAÑO DE LA IMAGEN
  static const double _imageAlignment = 0.2;
  static const double _imageHeight = 500.0;

  // 🆕 Variables para la animación y comentarios
  late AnimationController _animationController;
  late Animation<double> _bounceAnimation;
  String? _currentComment;
  Timer? _hideCommentTimer;

  @override
  void initState() {
    super.initState();
    _setupDevice();
    _setupAnimation();
  }

  // 🆕 Configurar la animación
  void _setupAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: -20.0,
    ).chain(CurveTween(curve: Curves.easeOut)).animate(_animationController);
  }

  // 🆕 Manejar el toque en la imagen
  void _onPlantImageTap() {
    final plantProvider = Provider.of<PlantProvider>(context, listen: false);

    // Animar la imagen
    _animationController.forward().then((_) => _animationController.reverse());

    // Mostrar comentario aleatorio
    final comments = plantProvider.plantComments;
    if (comments.isNotEmpty) {
      setState(() {
        _currentComment = comments[Random().nextInt(comments.length)];
      });

      // Ocultar el comentario después de 3 segundos
      _hideCommentTimer?.cancel();
      _hideCommentTimer = Timer(Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _currentComment = null;
          });
        }
      });
    }
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
    Color dialogColor,
  ) async {
    final bluetoothProvider = Provider.of<BluetoothProvider>(
      context,
      listen: false,
    );

    final plantProvider = Provider.of<PlantProvider>(context, listen: false);

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
          return '';
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

  // 🆕 Widget para mostrar la imagen de la planta con animación y comentarios
  Widget _buildAnimatedPlantImage(String imageUrl, bool isDarkMode) {
    // 🆕 AÑADIENDO primaryColor en los comentarios
    final primaryColor =
        isDarkMode
            ? const Color.fromARGB(255, 88, 199, 188)
            : Colors.blueGrey[800];

    if (imageUrl.isEmpty) {
      return Container(
        height: _imageHeight,
        width: double.infinity,
        child: Align(
          alignment: Alignment(_imageAlignment, 0.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_florist,
                size: _imageHeight * 0.25,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(height: 10),
              Text(
                'Imagen no disponible',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: _imageHeight,
      width: double.infinity,
      child: Stack(
        children: [
          // 🆕 Imagen animada y clickeable
          Align(
            alignment: Alignment(_imageAlignment, 0.0),
            child: GestureDetector(
              onTap: _onPlantImageTap,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _bounceAnimation.value),
                    child: child,
                  );
                },
                child: Image.network(
                  imageUrl,
                  height: _imageHeight,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: _imageHeight,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint("❌ Error cargando imagen: $error");
                    return Container(
                      height: _imageHeight,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: _imageHeight * 0.25,
                            color: Colors.red.withOpacity(0.7),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Error cargando imagen',
                            style: TextStyle(
                              color: Colors.red.withOpacity(0.7),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // 🆕 Burbuja de comentario flotante - POSICIONADA ABAJO con primaryColor
          if (_currentComment != null)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: 280),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        isDarkMode
                            ? primaryColor!.withOpacity(0.9)
                            : const Color.fromARGB(255, 253, 255, 153),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color:
                            isDarkMode
                                ? primaryColor!.withOpacity(0.3)
                                : const Color.fromARGB(255, 236, 236, 236),
                        blurRadius: 8,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    _currentComment!,
                    style: GoogleFonts.robotoCondensed(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _hideCommentTimer?.cancel();
    super.dispose();
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
            backgroundColor:
                isDarkMode
                    ? Colors.grey[900]
                    : const Color.fromARGB(255, 255, 255, 255),
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
                  : SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Switch de Interior/Exterior
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _switchValue ? 'Exterior' : 'Interior',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            Switch(
                              value: _switchValue,
                              onChanged: (bool newValue) {
                                setState(() {
                                  _switchValue = newValue;

                                  final plantProvider =
                                      Provider.of<PlantProvider>(
                                        context,
                                        listen: false,
                                      );
                                  plantProvider.setModoEstandar(
                                    newValue ? 'Exterior' : 'Estandar',
                                  );

                                  plantProvider.fetchStandards(
                                    widget.plantName,
                                  );
                                });
                              },
                              activeColor: const Color.fromARGB(
                                255,
                                253,
                                207,
                                79,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Botones de sensores
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
                                ),
                              ),
                              onPressed: () {
                                _showSensorDialog(
                                  context,
                                  'Luz',
                                  const Color.fromARGB(255, 253, 234, 64),
                                );
                              },
                              child: const Icon(
                                Icons.wb_sunny,
                                size: 35,
                                color: Colors.white,
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
                                ),
                              ),
                              onPressed: () {
                                _showSensorDialog(
                                  context,
                                  'Humedad',
                                  const Color.fromARGB(255, 33, 150, 243),
                                );
                              },
                              child: const Icon(
                                Icons.water_drop,
                                size: 35,
                                color: Colors.white,
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
                                ),
                              ),
                              onPressed: () {
                                _showSensorDialog(
                                  context,
                                  'Temperatura',
                                  const Color.fromARGB(255, 250, 100, 100),
                                );
                              },
                              child: const Icon(
                                Icons.device_thermostat,
                                size: 35,
                                color: Colors.white,
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
                                ),
                              ),
                              onPressed: () {
                                _showSensorDialog(
                                  context,
                                  'Ph',
                                  const Color.fromARGB(255, 255, 195, 235),
                                );
                              },
                              child: const Icon(
                                Icons.science,
                                size: 35,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // 🆕 Estado de conexión con primaryColor
                        Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  widget.device == null
                                      ? const Color.fromARGB(
                                        255,
                                        255,
                                        255,
                                        255,
                                      ).withOpacity(1)
                                      : (isConnected
                                          ? Colors.green.withOpacity(0.2)
                                          : Colors.orange.withOpacity(0.2)),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    widget.device == null
                                        ? primaryColor!
                                        : (isConnected
                                            ? Colors.green
                                            : Colors.orange),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.device == null
                                      ? Icons.bluetooth_disabled
                                      : (isConnected
                                          ? Icons.bluetooth_connected
                                          : Icons.bluetooth_searching),
                                  color:
                                      widget.device == null
                                          ? primaryColor
                                          : (isConnected
                                              ? Colors.green
                                              : Colors.orange),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  widget.device == null
                                      ? 'Sin dispositivo'
                                      : (isConnected
                                          ? 'Conectado'
                                          : 'Conectando...'),
                                  style: GoogleFonts.robotoCondensed(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        widget.device == null
                                            ? primaryColor
                                            : (isConnected
                                                ? Colors.green
                                                : Colors.orange),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),

                        // 🆕 Imagen animada de la planta (reemplaza _buildPlantImage)
                        _buildAnimatedPlantImage(
                          plantProvider.plantImageUrl,
                          isDarkMode,
                        ),
                      ],
                    ),
                  ),
        );
      },
    );
  }
}
