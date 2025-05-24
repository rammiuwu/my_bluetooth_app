import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_bluetooth_app/screens/bluetooth_provider.dart';
import 'package:my_bluetooth_app/screens/plant_provider.dart';

enum EstadoAnimo { neutro, feliz, triste }

class MoodData {
  final String comentario;
  final String imagen;

  MoodData({required this.comentario, required this.imagen});
}

class MiauScreen extends StatefulWidget {
  @override
  _MiauScreenState createState() => _MiauScreenState();
}

class _MiauScreenState extends State<MiauScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  // Estados del gato
  EstadoAnimo _estadoActual = EstadoAnimo.neutro;
  Map<EstadoAnimo, List<MoodData>> _comentariosPorEstado = {};
  String? _imagenInicial; // Nueva variable para la imagen inicial

  String? fraseActual;
  String? imagenActual;
  bool _hasInteracted = false; // Para controlar si ya se ha interactuado
  Timer? _hideTimer;
  StreamSubscription? _sensorDataSubscription;
  bool _isDataLoaded = false; // Para saber si los datos ya se cargaron

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _loadMoodDataFromFirebase();
    _setupSensorListener();
  }

  void _initializeAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: -20.0,
    ).chain(CurveTween(curve: Curves.easeOut)).animate(_controller);
  }

  Future<void> _loadMoodDataFromFirebase() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('gato')
              .doc('Animo')
              .get();

      if (doc.exists) {
        final data = doc.data()!;

        // Cargar imagen inicial
        if (data['Inicial'] != null && data['Inicial']['imagen'] != null) {
          _imagenInicial = data['Inicial']['imagen'];
          print("🐱 Imagen inicial cargada: $_imagenInicial");
        }

        // Procesar datos para cada estado de ánimo
        _processMoodData(data, 'Feliz', EstadoAnimo.feliz);
        _processMoodData(data, 'Neutro', EstadoAnimo.neutro);
        _processMoodData(data, 'Triste', EstadoAnimo.triste);

        setState(() {
          _isDataLoaded = true;
          // Establecer imagen inicial si no se ha interactuado
          if (!_hasInteracted) {
            imagenActual = _imagenInicial;
          }
        });

        print("🐱 Datos de estados de ánimo cargados correctamente");
        _updateCurrentMood();
      }
    } catch (e) {
      print("❌ Error al cargar datos del gato: $e");
      _setDefaultMoodData();
      setState(() {
        _isDataLoaded = true;
      });
    }
  }

  void _processMoodData(
    Map<String, dynamic> data,
    String moodKey,
    EstadoAnimo estado,
  ) {
    final moodData = data[moodKey];
    if (moodData != null && moodData['Comentarios'] != null) {
      final comentarios = moodData['Comentarios'] as Map<String, dynamic>;
      List<MoodData> moodList = [];

      // Ordenar las claves numéricamente
      var sortedKeys = comentarios.keys.toList();
      sortedKeys.sort((a, b) {
        int aNum = int.tryParse(a.toString()) ?? 0;
        int bNum = int.tryParse(b.toString()) ?? 0;
        return aNum.compareTo(bNum);
      });

      // Extraer comentarios e imágenes
      for (var key in sortedKeys) {
        var comentarioData = comentarios[key];
        if (comentarioData != null) {
          String comentario = comentarioData['comentario'] ?? '';
          String imagen = comentarioData['imagen'] ?? '';

          if (comentario.isNotEmpty && imagen.isNotEmpty) {
            moodList.add(MoodData(comentario: comentario, imagen: imagen));
          }
        }
      }

      _comentariosPorEstado[estado] = moodList;
      print("🐱 Cargados ${moodList.length} comentarios para estado: $moodKey");
    }
  }

  void _setDefaultMoodData() {
    // Datos por defecto en caso de error
    _imagenInicial =
        "https://raw.githubusercontent.com/rammiuwu/my_bluetooth_app/main/Normal.png";

    _comentariosPorEstado = {
      EstadoAnimo.neutro: [
        MoodData(
          comentario: "¿Qué onda? B)",
          imagen:
              "https://raw.githubusercontent.com/rammiuwu/my_bluetooth_app/main/Sonrie.png",
        ),
        MoodData(
          comentario: "Me gusta el atún :3",
          imagen:
              "https://raw.githubusercontent.com/rammiuwu/my_bluetooth_app/main/Abrazoboca.png",
        ),
      ],
      EstadoAnimo.feliz: [
        MoodData(
          comentario: "¡¡¡Oña ñight!!! :3",
          imagen:
              "https://raw.githubusercontent.com/rammiuwu/my_bluetooth_app/main/Ultrafeliz.png",
        ),
        MoodData(
          comentario: "¡Cómprame atún! :D",
          imagen:
              "https://raw.githubusercontent.com/rammiuwu/my_bluetooth_app/main/Abrazoojosarriba.png",
        ),
      ],
      EstadoAnimo.triste: [
        MoodData(
          comentario: "Tu planta... Parece en mal estado :C",
          imagen:
              "https://raw.githubusercontent.com/rammiuwu/my_bluetooth_app/main/Tristeorejasabajo.png",
        ),
        MoodData(
          comentario: "Miauuuuu n-no cuidas a tus p-plantas",
          imagen:
              "https://raw.githubusercontent.com/rammiuwu/my_bluetooth_app/main/Tristeorejasabajo.png",
        ),
      ],
    };
  }

  void _setupSensorListener() {
    // Escuchar cambios en los datos de sensores
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bluetoothProvider = Provider.of<BluetoothProvider>(
        context,
        listen: false,
      );

      _sensorDataSubscription = bluetoothProvider.sensorDataStream.listen((
        data,
      ) {
        print("🐱 Datos de sensores recibidos: $data");
        _updateCurrentMood();
      });
    });
  }

  void _updateCurrentMood() {
    if (!_isDataLoaded)
      return; // No actualizar hasta que los datos estén cargados

    final bluetoothProvider = Provider.of<BluetoothProvider>(
      context,
      listen: false,
    );
    final plantProvider = Provider.of<PlantProvider>(context, listen: false);

    EstadoAnimo nuevoEstado;

    if (!bluetoothProvider.isConnected) {
      // Si no está conectado el Bluetooth, estado neutro
      nuevoEstado = EstadoAnimo.neutro;
      print("🐱 Bluetooth desconectado - Estado: NEUTRO");
    } else {
      // Verificar si los valores están dentro del rango ideal
      bool humedadOk = _isValueInRange(
        bluetoothProvider.humidity,
        plantProvider.humedadMin,
        plantProvider.humedadMax,
      );

      bool luzOk = _isValueInRange(
        bluetoothProvider.light,
        plantProvider.luzMin,
        plantProvider.luzMax,
      );

      bool temperaturaOk = _isValueInRange(
        bluetoothProvider.temperature,
        plantProvider.temperaturaMin,
        plantProvider.temperaturaMax,
      );

      bool phOk = _isValueInRange(
        bluetoothProvider.ph,
        plantProvider.phMin,
        plantProvider.phMax,
      );

      // Si todos los valores están bien, feliz; si no, triste
      if (humedadOk && luzOk && temperaturaOk && phOk) {
        nuevoEstado = EstadoAnimo.feliz;
        print("🐱 Todos los valores OK - Estado: FELIZ");
      } else {
        nuevoEstado = EstadoAnimo.triste;
        print("🐱 Valores fuera de rango - Estado: TRISTE");
        print("   • Humedad OK: $humedadOk");
        print("   • Luz OK: $luzOk");
        print("   • Temperatura OK: $temperaturaOk");
        print("   • Ph OK: $phOk");
      }
    }

    if (_estadoActual != nuevoEstado) {
      setState(() {
        _estadoActual = nuevoEstado;
        // Solo actualizar imagen si ya se ha interactuado
        if (_hasInteracted) {
          _updateImagenActual();
        }
      });
      print("🐱 Estado de ánimo cambiado a: ${_estadoActual.toString()}");
    }
  }

  bool _isValueInRange(String valueStr, double min, double max) {
    final value = double.tryParse(valueStr);
    if (value == null) return false;
    return value >= min && value <= max;
  }

  void _updateImagenActual() {
    final comentarios = _comentariosPorEstado[_estadoActual];
    if (comentarios != null && comentarios.isNotEmpty) {
      final randomIndex = Random().nextInt(comentarios.length);
      imagenActual = comentarios[randomIndex].imagen;
    }
  }

  void _onTap() {
    if (!_isDataLoaded)
      return; // No permitir interacción hasta que los datos estén cargados

    _controller.forward().then((_) => _controller.reverse());

    // Siempre mostrar comentarios aleatorios, incluso sin conexión
    // Si no está conectado, usar comentarios neutros
    EstadoAnimo estadoParaComentario = _estadoActual;

    final comentarios = _comentariosPorEstado[estadoParaComentario];
    if (comentarios != null && comentarios.isNotEmpty) {
      final randomIndex = Random().nextInt(comentarios.length);
      final selectedMood = comentarios[randomIndex];

      setState(() {
        _hasInteracted = true; // Marcar que ya se ha interactuado
        fraseActual = selectedMood.comentario;
        imagenActual = selectedMood.imagen;
      });

      print("🐱 Gato dice: $fraseActual");

      _hideTimer?.cancel();
      _hideTimer = Timer(Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            fraseActual = null;
          });
        }
      });
    }
  }

  String _getDefaultImageForMood() {
    // Si no se ha interactuado, mostrar imagen inicial
    if (!_hasInteracted && _imagenInicial != null) {
      return _imagenInicial!;
    }

    // Si ya se interactuó pero no hay imagen actual, usar la por defecto del estado
    switch (_estadoActual) {
      case EstadoAnimo.feliz:
        return "https://raw.githubusercontent.com/rammiuwu/my_bluetooth_app/main/Ultrafeliz.png";
      case EstadoAnimo.triste:
        return "https://raw.githubusercontent.com/rammiuwu/my_bluetooth_app/main/Tristeorejasabajo.png";
      case EstadoAnimo.neutro:
      default:
        return "https://raw.githubusercontent.com/rammiuwu/my_bluetooth_app/main/Sonrie.png";
    }
  }

  Color _getBubbleColorForMood(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    switch (_estadoActual) {
      case EstadoAnimo.feliz:
        return isDarkMode
            ? const Color.fromARGB(
              255,
              200,
              255,
              200,
            ) // Verde más oscuro para dark mode
            : const Color.fromARGB(
              255,
              200,
              255,
              200,
            ); // Verde claro para light mode
      case EstadoAnimo.triste:
        return isDarkMode
            ? const Color.fromARGB(
              255,
              200,
              210,
              255,
            ) // Azul más oscuro para dark mode
            : const Color.fromARGB(
              255,
              200,
              210,
              255,
            ); // Azul claro para light mode
      case EstadoAnimo.neutro:
      default:
        return isDarkMode
            ? const Color.fromARGB(
              255,
              255,
              253,
              153,
            ) // Amarillo más oscuro para dark mode
            : const Color.fromARGB(
              255,
              255,
              253,
              153,
            ); // Amarillo claro para light mode
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _hideTimer?.cancel();
    _sensorDataSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<BluetoothProvider, PlantProvider>(
      builder: (context, bluetoothProvider, plantProvider, child) {
        // Actualizar estado de ánimo cuando cambian los providers
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateCurrentMood();
        });

        return Center(
          child: SizedBox(
            width: 500,
            height: 500,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Burbuja de diálogo flotante
                if (fraseActual != null)
                  Positioned(
                    top: 50,
                    child: Container(
                      padding: EdgeInsets.all(12),
                      constraints: BoxConstraints(maxWidth: 250),
                      decoration: BoxDecoration(
                        color: _getBubbleColorForMood(context),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(66, 175, 175, 175),
                            blurRadius: 4,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        fraseActual!,
                        style: GoogleFonts.robotoCondensed(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color:
                              Colors
                                  .black, // Siempre negro para buena legibilidad
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                // Imagen del gato animada
                GestureDetector(
                  onTap:
                      _isDataLoaded
                          ? _onTap
                          : null, // Solo permitir tap si los datos están cargados
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _animation.value),
                        child: child,
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        imagenActual ?? _getDefaultImageForMood(),
                        height: 280,
                        fit: BoxFit.contain,
                        loadingBuilder:
                            (context, child, loadingProgress) =>
                                loadingProgress == null
                                    ? child
                                    : CircularProgressIndicator(
                                      color: Colors.orange,
                                    ),
                        errorBuilder: (context, error, stackTrace) {
                          print("❌ Error cargando imagen: $error");
                          return Container(
                            height: 280,
                            width: 280,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.pets,
                                  size: 50,
                                  color: Colors.grey[600],
                                ),
                                Text("🐱", style: TextStyle(fontSize: 40)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Indicador del estado de ánimo actual
                if (_isDataLoaded)
                  Positioned(
                    bottom: 20,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getEstadoTexto(),
                        style: GoogleFonts.robotoCondensed(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
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

  String _getEstadoTexto() {
    switch (_estadoActual) {
      case EstadoAnimo.feliz:
        return "😸 ¡Feliz!";
      case EstadoAnimo.triste:
        return "😿 Triste";
      case EstadoAnimo.neutro:
      default:
        return "😺 Neutro";
    }
  }
}
