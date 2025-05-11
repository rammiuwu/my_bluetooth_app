import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:my_bluetooth_app/screens/bluetooth_provider.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _selectedPlant;
  List<String> _plantNames = [];

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
      _selectedPlant = null; // Reiniciar selección anterior
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
        Wrap(
          spacing: 8,
          children:
              _plantNames.map((plantName) {
                return ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedPlant = plantName;
                    });
                  },
                  child: Text(plantName),
                );
              }).toList(),
        ),
        SizedBox(height: 16),
        if (_selectedPlant != null)
          FutureBuilder<Map<String, dynamic>?>(
            future: _fetchDataForPlant(_selectedPlant!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasData && snapshot.data != null) {
                final data = snapshot.data!;
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        "🌱 ${_selectedPlant!}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text("Humedad: ${data['humidity']}%"),
                      Text("Luz: ${data['light']} lx"),
                      Text("Temperatura: ${data['temperature'] ?? 'N/D'}°C"),
                      Text("pH: ${data['ph'] ?? 'N/D'}"),
                    ],
                  ),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text("No hay datos para esta planta en ese día."),
                );
              }
            },
          ),
      ],
    );
  }
}
