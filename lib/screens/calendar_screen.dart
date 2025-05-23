import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:my_bluetooth_app/screens/bluetooth_provider.dart';
import 'package:my_bluetooth_app/screens/plant_provider.dart'; // Asegúrate de que esta importación sea correcta
import 'dart:math';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _selectedPlant;
  List<String> _plantNames = [];
  bool _isGeneratingTestData = false;

  Future<void> _fetchPlantNamesForSelectedDay() async {
    if (_selectedDay == null) return;

    final provider = Provider.of<BluetoothProvider>(context, listen: false);
    final userId = provider.userId;

    final String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDay!);

    final plantSnapshot =
        await FirebaseFirestore.instance
            .collection('user')
            .doc(userId)
            .collection('date')
            .doc(formattedDate)
            .collection('plant')
            .get();

    setState(() {
      _plantNames = plantSnapshot.docs.map((doc) => doc.id).toList();
      _selectedPlant = null;
    });
  }

  Future<Map<String, dynamic>?> _fetchDataForPlant(String plantName) async {
    final provider = Provider.of<BluetoothProvider>(context, listen: false);
    final userId = provider.userId;
    final String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDay!);

    final snapshot =
        await FirebaseFirestore.instance
            .collection('user')
            .doc(userId)
            .collection('date')
            .doc(formattedDate)
            .collection('plant')
            .doc(plantName)
            .get();

    if (snapshot.exists) {
      return snapshot.data() as Map<String, dynamic>;
    } else {
      return null;
    }
  }

  // Calcular promedios semanales para la planta seleccionada
  Future<Map<String, double>?> _fetchWeeklyAverages(String plantName) async {
    if (_selectedDay == null) return null;

    final provider = Provider.of<BluetoothProvider>(context, listen: false);
    final userId = provider.userId;

    DateTime startOfWeek = _selectedDay!.subtract(
      Duration(days: _selectedDay!.weekday - 1),
    );

    Map<String, List<double>> totals = {
      'humidity': [],
      'light': [],
      'temperature': [],
      'ph': [],
    };

    for (int i = 0; i < 7; i++) {
      DateTime day = startOfWeek.add(Duration(days: i));
      String formattedDate = DateFormat('yyyy-MM-dd').format(day);

      try {
        final doc =
            await FirebaseFirestore.instance
                .collection('user')
                .doc(userId)
                .collection('date')
                .doc(formattedDate)
                .collection('plant')
                .doc(plantName)
                .get();

        if (doc.exists) {
          final data = doc.data()!;
          for (String key in totals.keys) {
            if (data[key] != null) {
              final value = data[key];
              double numValue;

              if (value is num) {
                numValue = value.toDouble();
              } else if (value is String) {
                numValue = double.tryParse(value) ?? 0.0;
              } else {
                continue;
              }

              if (numValue > 0) {
                // Solo agregar valores válidos
                totals[key]!.add(numValue);
              }
            }
          }
        }
      } catch (e) {
        print('Error fetching data for $formattedDate: $e');
      }
    }

    Map<String, double> averages = {};
    for (String key in totals.keys) {
      final list = totals[key]!;
      if (list.isNotEmpty) {
        averages[key] = list.reduce((a, b) => a + b) / list.length;
      }
    }

    print('Weekly averages calculated: $averages'); // Debug
    return averages.isEmpty ? null : averages;
  }

  // Obtener estándares usando PlantProvider
  Future<Map<String, dynamic>> _fetchStandards(String plantName) async {
    try {
      final plantProvider = Provider.of<PlantProvider>(context, listen: false);

      // Cargar estándares desde Firebase usando PlantProvider
      await plantProvider.fetchStandards(plantName);

      // Construir mapa de estándares usando los valores del provider
      Map<String, dynamic> standards = {
        'humidity': {
          'min': plantProvider.humedadMin,
          'max': plantProvider.humedadMax,
        },
        'light': {'min': plantProvider.luzMin, 'max': plantProvider.luzMax},
        'temperature': {
          'min': plantProvider.temperaturaMin,
          'max': plantProvider.temperaturaMax,
        },
        'ph': {'min': plantProvider.phMin, 'max': plantProvider.phMax},
      };

      print('Standards fetched from PlantProvider: $standards'); // Debug
      return standards;
    } catch (e) {
      print('Error fetching standards using PlantProvider: $e');
      // Si hay error, retornar estándares vacíos para evitar crashes
      return {};
    }
  }

  // Diagnóstico mejorado con más contexto
  String _getDiagnosis(double value, double min, double max) {
    if (value < min) {
      double deficit = ((min - value) / min * 100);
      if (deficit > 20) return "Muy bajo";
      return "Bajo";
    }
    if (value > max) {
      double excess = ((value - max) / max * 100);
      if (excess > 20) return "Muy alto";
      return "Alto";
    }
    return "Óptimo";
  }

  // Evaluar los promedios contra los estándares
  Map<String, dynamic> _evaluateAverages(
    Map<String, double> averages,
    Map<String, dynamic> standards,
  ) {
    final diagnoses = <String, dynamic>{};

    print(
      'Evaluating averages: $averages against standards: $standards',
    ); // Debug

    for (final sensor in ['humidity', 'light', 'temperature', 'ph']) {
      if (averages.containsKey(sensor) && standards.containsKey(sensor)) {
        final min = (standards[sensor]['min'] as num).toDouble();
        final max = (standards[sensor]['max'] as num).toDouble();
        final value = averages[sensor]!;
        final diagnosis = _getDiagnosis(value, min, max);

        diagnoses[sensor] = {
          'value': value,
          'diagnosis': diagnosis,
          'min': min,
          'max': max,
        };
      }
    }

    print('Final diagnoses: $diagnoses'); // Debug
    return diagnoses;
  }

  // Future para obtener el diagnóstico completo
  Future<Map<String, dynamic>?> _fetchWeeklyDiagnosis(String plantName) async {
    try {
      final averages = await _fetchWeeklyAverages(plantName);
      final standards = await _fetchStandards(plantName);

      print('Fetched averages: $averages'); // Debug
      print('Fetched standards: $standards'); // Debug

      if (averages != null && averages.isNotEmpty && standards.isNotEmpty) {
        final result = _evaluateAverages(averages, standards);
        print('Diagnosis result: $result'); // Debug
        return result;
      }

      return null;
    } catch (e) {
      print('Error in _fetchWeeklyDiagnosis: $e');
      return null;
    }
  }

  Widget _buildDiagnosisCard(
    String label,
    Map<String, dynamic> data,
    Color color,
  ) {
    Color cardColor;
    IconData icon;
    Color iconColor;

    // Cambiar color según diagnóstico
    switch (data['diagnosis']) {
      case 'Óptimo':
        cardColor = const Color.fromARGB(255, 140, 216, 142);
        icon = Icons.check_circle;
        iconColor = const Color.fromARGB(255, 82, 189, 73);
        break;
      case 'Alto':
      case 'Muy alto':
        cardColor = const Color.fromARGB(224, 240, 115, 106);
        icon = Icons.arrow_upward;
        iconColor = const Color.fromARGB(255, 204, 57, 57);
        break;
      case 'Bajo':
      case 'Muy bajo':
        cardColor = const Color.fromARGB(255, 255, 194, 102);
        icon = Icons.arrow_downward;
        iconColor = const Color.fromARGB(255, 255, 163, 42);
        break;
      default:
        cardColor = color;
        icon = Icons.help;
        iconColor = Colors.white; // Cambiado de Colors.grey a Colors.white
    }

    return Card(
      color: cardColor.withOpacity(1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(
          icon,
          color: iconColor,
          size: 30,
        ), // Usar iconColor en lugar de cardColor
        title: Text(
          "$label: ${data['value'].toStringAsFixed(1)}",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: cardColor.darken(0.4),
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Estado: ${data['diagnosis']}",
              style: TextStyle(
                color: cardColor.darken(0.4),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            Text(
              "Rango óptimo: ${data['min'].toStringAsFixed(1)} - ${data['max'].toStringAsFixed(1)}",
              style: TextStyle(color: cardColor.darken(0.3), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ============ FUNCIONES DE TESTING ============

  // Generar datos de prueba más realistas
  Future<void> _generateTestData() async {
    setState(() {
      _isGeneratingTestData = true;
    });

    try {
      final provider = Provider.of<BluetoothProvider>(context, listen: false);
      final userId = provider.userId;
      final random = Random();

      // Lista de plantas de prueba
      final testPlants = ['Tomate', 'Aloe Vera', 'Rosa'];

      // Generar datos para los últimos 14 días para tener más datos semanales
      for (int day = 0; day < 14; day++) {
        DateTime testDate = DateTime.now().subtract(Duration(days: day));
        String formattedDate = DateFormat('yyyy-MM-dd').format(testDate);

        for (String plantName in testPlants) {
          // Obtener estándares reales de la planta para generar datos más realistas
          final standards = await _fetchStandards(plantName);

          double baseHumidity, baseLight, baseTemp, basePh;

          if (standards.isNotEmpty) {
            // Usar estándares reales para generar datos más realistas
            baseHumidity =
                (standards['humidity']['min'] + standards['humidity']['max']) /
                2;
            baseLight =
                (standards['light']['min'] + standards['light']['max']) / 2;
            baseTemp =
                (standards['temperature']['min'] +
                    standards['temperature']['max']) /
                2;
            basePh = (standards['ph']['min'] + standards['ph']['max']) / 2;
          } else {
            // Fallback a valores por defecto
            baseHumidity = 35.0;
            baseLight = 3250.0;
            baseTemp = 22.5;
            basePh = 6.75;
          }

          // Agregar variación aleatoria
          double humidityVariation = (day * 0.5) + random.nextDouble() * 8 - 4;
          double lightVariation =
              (day * 20.0) + random.nextDouble() * 400 - 200;
          double tempVariation = (day * 0.2) + random.nextDouble() * 4 - 2;
          double phVariation = (day * 0.02) + random.nextDouble() * 0.4 - 0.2;

          Map<String, String> data = {
            'humidity': (baseHumidity + humidityVariation).toStringAsFixed(1),
            'light': (baseLight + lightVariation).toStringAsFixed(0),
            'temperature': (baseTemp + tempVariation).toStringAsFixed(1),
            'ph': (basePh + phVariation).toStringAsFixed(2),
          };

          // Guardar en Firestore
          await FirebaseFirestore.instance
              .collection('user')
              .doc(userId)
              .collection('date')
              .doc(formattedDate)
              .collection('plant')
              .doc(plantName)
              .set(data);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Datos de prueba generados exitosamente!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      if (_selectedDay != null) {
        _fetchPlantNamesForSelectedDay();
      }
    } catch (e) {
      print('Error generating test data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error generando datos: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isGeneratingTestData = false;
      });
    }
  }

  // Limpiar datos de prueba
  Future<void> _clearTestData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('⚠️ Confirmar eliminación'),
            content: Text(
              '¿Estás seguro de que quieres eliminar todos los datos de prueba de los últimos 14 días?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      final provider = Provider.of<BluetoothProvider>(context, listen: false);
      final userId = provider.userId;

      // Eliminar datos de los últimos 14 días
      for (int day = 0; day < 14; day++) {
        DateTime testDate = DateTime.now().subtract(Duration(days: day));
        String formattedDate = DateFormat('yyyy-MM-dd').format(testDate);

        final plantsSnapshot =
            await FirebaseFirestore.instance
                .collection('user')
                .doc(userId)
                .collection('date')
                .doc(formattedDate)
                .collection('plant')
                .get();

        for (var doc in plantsSnapshot.docs) {
          await doc.reference.delete();
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🧹 Datos de prueba eliminados exitosamente!'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );

      setState(() {
        _plantNames.clear();
        _selectedPlant = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error eliminando datos: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // ============ BOTONES DE TESTING ============
          Card(
            color: const Color.fromARGB(255, 255, 255, 255).withOpacity(1),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    'Modo Testing',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              _isGeneratingTestData ? null : _generateTestData,
                          icon:
                              _isGeneratingTestData
                                  ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Icon(Icons.add_chart),
                          label: Text(
                            _isGeneratingTestData
                                ? 'Generando...'
                                : 'Generar Datos',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              119,
                              228,
                              123,
                            ),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _clearTestData,
                          icon: Icon(Icons.delete_sweep),
                          label: Text('Limpiar Datos'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              233,
                              74,
                              62,
                            ),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // ============ CALENDARIO ============
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _plantNames.clear();
                _selectedPlant = null;
              });
              _fetchPlantNamesForSelectedDay();
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            _selectedDay != null
                ? "Plantas registradas el ${_selectedDay!.day}/${_selectedDay!.month}"
                : "Selecciona un día",
            style: GoogleFonts.robotoCondensed(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children:
                _plantNames.isNotEmpty
                    ? _plantNames.map((plantName) {
                      return ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedPlant = plantName;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _selectedPlant == plantName
                                  ? Theme.of(context).primaryColor
                                  : null,
                          foregroundColor:
                              _selectedPlant == plantName ? Colors.white : null,
                        ),
                        child: Text(plantName),
                      );
                    }).toList()
                    : [Text("No hay plantas registradas")],
          ),
          SizedBox(height: 10),
          if (_selectedPlant != null) ...[
            // Datos del día seleccionado
            FutureBuilder<Map<String, dynamic>?>(
              future: _fetchDataForPlant(_selectedPlant!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasData && snapshot.data != null) {
                  final data = snapshot.data!;
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            "📊 Datos del día ${_selectedDay!.day}/${_selectedDay!.month}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "🌱 ${_selectedPlant!}",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text("💧 Humedad: ${data['humidity']}%"),
                          Text("☀️ Luz: ${data['light']} lx"),
                          Text("🌡️ Temperatura: ${data['temperature']}°C"),
                          Text("⚗️ pH: ${data['ph']}"),
                        ],
                      ),
                    ),
                  );
                } else {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text("No hay datos para esta planta en ese día."),
                    ),
                  );
                }
              },
            ),
            SizedBox(height: 16),
            // Diagnóstico semanal mejorado
            FutureBuilder<Map<String, dynamic>?>(
              future: _fetchWeeklyDiagnosis(_selectedPlant!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 16),
                          Text("Calculando diagnóstico semanal..."),
                        ],
                      ),
                    ),
                  );
                } else if (snapshot.hasData &&
                    snapshot.data != null &&
                    snapshot.data!.isNotEmpty) {
                  final diagnostics = snapshot.data!;
                  return Column(
                    children: [
                      Text(
                        "Diagnóstico semanal de ${_selectedPlant!}",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      if (diagnostics.containsKey('humidity'))
                        _buildDiagnosisCard(
                          "💧 Humedad",
                          diagnostics['humidity'],
                          Colors.blue,
                        ),
                      if (diagnostics.containsKey('light'))
                        _buildDiagnosisCard(
                          "☀️ Luz",
                          diagnostics['light'],
                          Colors.orange,
                        ),
                      if (diagnostics.containsKey('temperature'))
                        _buildDiagnosisCard(
                          "🌡️ Temperatura",
                          diagnostics['temperature'],
                          Colors.red,
                        ),
                      if (diagnostics.containsKey('ph'))
                        _buildDiagnosisCard(
                          "⚗️ pH",
                          diagnostics['ph'],
                          Colors.green,
                        ),
                    ],
                  );
                } else {
                  return Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 50,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "No hay suficientes datos para generar un diagnóstico semanal.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Se necesitan al menos 3 días de datos en la semana.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

// Extensión para oscurecer color
extension ColorBrightness on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
