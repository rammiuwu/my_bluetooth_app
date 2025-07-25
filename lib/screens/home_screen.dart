import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_bluetooth_app/screens/bluetooth_screen.dart';
import 'package:my_bluetooth_app/screens/calendar_screen.dart';
import 'package:my_bluetooth_app/screens/miau_screen.dart';
import 'package:my_bluetooth_app/screens/device_screen.dart';
import 'package:my_bluetooth_app/main.dart';
import 'package:my_bluetooth_app/screens/bluetooth_provider.dart'; // Asegúrate de tener este import

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<String> selectedPlants = [];

  static List<Widget> get _widgetOptions => <Widget>[
    MiauScreen(),
    Container(), // Este se reemplaza dinámicamente en `body`
    CalendarScreen(), // Aquí va la vista de calendario real
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showCustomDialog(BuildContext context) {
    final Map<String, List<String>> plantasPorTipo = {
      "Medicinales": ["Aloe Vera", "Manzanilla"],
      "Alimenticias": ["Tomate Cherry", "Zanahoria"],
      "Ornamentales": [
        "Planta Billete",
        "Lengua de Suegra",
        "Cactus",
        "Orquídea",
        "Bonsái",
        "Rosa",
        "Suculenta",
      ],
    };

    List<String> tiposPlantas = plantasPorTipo.keys.toList();
    String? tipoSeleccionado;

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        final themeProvider = Provider.of<ThemeProvider>(
          context,
          listen: false,
        );

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor:
                  themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
              title: Text(
                tipoSeleccionado == null
                    ? 'Selecciona una categoría'
                    : 'Selecciona una planta',
                style: GoogleFonts.robotoCondensed(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount:
                      tipoSeleccionado == null
                          ? tiposPlantas.length
                          : plantasPorTipo[tipoSeleccionado]!.length,
                  itemBuilder: (context, index) {
                    if (tipoSeleccionado == null) {
                      return ListTile(
                        title: Text(
                          tiposPlantas[index],
                          style: GoogleFonts.robotoCondensed(
                            color:
                                themeProvider.isDarkMode
                                    ? Colors.white
                                    : Colors.black,
                            fontSize: 16,
                          ),
                        ),
                        leading: Icon(
                          Icons.category,
                          color:
                              themeProvider.isDarkMode
                                  ? Colors.teal[400]
                                  : Colors.blueGrey[800],
                        ),
                        onTap: () {
                          setStateDialog(() {
                            tipoSeleccionado = tiposPlantas[index];
                          });
                        },
                      );
                    } else {
                      String planta = plantasPorTipo[tipoSeleccionado]![index];
                      return ListTile(
                        title: Text(
                          planta,
                          style: GoogleFonts.robotoCondensed(
                            color:
                                themeProvider.isDarkMode
                                    ? Colors.white
                                    : Colors.black,
                            fontSize: 16,
                          ),
                        ),
                        leading: Icon(
                          Icons.local_florist,
                          color:
                              themeProvider.isDarkMode
                                  ? Colors.teal[400]
                                  : Colors.blueGrey[800],
                        ),
                        onTap: () {
                          if (!selectedPlants.contains(planta)) {
                            if (selectedPlants.length < 5) {
                              setState(() {
                                selectedPlants.add(planta);
                              });
                              Navigator.of(context).pop();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Solo puedes agregar hasta 5 plantas",
                                    style: GoogleFonts.robotoCondensed(),
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                      );
                    }
                  },
                ),
              ),
              actions: <Widget>[
                if (tipoSeleccionado != null)
                  TextButton(
                    child: Text(
                      'Atrás',
                      style: GoogleFonts.robotoCondensed(
                        color:
                            themeProvider.isDarkMode
                                ? Colors.teal[400]
                                : Colors.blueGrey[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      setStateDialog(() {
                        tipoSeleccionado = null;
                      });
                    },
                  ),
                TextButton(
                  child: Text(
                    'Cancelar',
                    style: GoogleFonts.robotoCondensed(
                      color:
                          themeProvider.isDarkMode
                              ? Colors.teal[400]
                              : Colors.blueGrey[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final primaryColor =
        isDarkMode ? Colors.teal[400] : const Color.fromARGB(255, 82, 155, 115);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "PLANTTY",
          style: GoogleFonts.robotoCondensed(
            fontWeight: FontWeight.bold,
            color: primaryColor,
            fontSize: 22,
          ),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        elevation: 0,
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
                MaterialPageRoute(builder: (context) => BluetoothScreen()),
              );
            },
            tooltip: 'Conexión Bluetooth',
          ),
        ],
      ),
      body:
          _selectedIndex == 1
              ? Column(
                children: [
                  SizedBox(height: 20),
                  Expanded(
                    child: GridView.builder(
                      padding: EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: selectedPlants.length,
                      itemBuilder: (context, index) {
                        return InkWell(
                          onTap: () {
                            final bluetoothProvider =
                                Provider.of<BluetoothProvider>(
                                  context,
                                  listen: false,
                                );
                            final bluetoothDevice =
                                bluetoothProvider.connectedDevice;

                            // Actualizar el BluetoothProvider antes de la navegación
                            bluetoothProvider.setPlantName(
                              selectedPlants[index],
                            );

                            // Ir a DeviceScreen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => DeviceScreen(
                                      plantName: selectedPlants[index],
                                      device: bluetoothDevice,
                                    ),
                              ),
                            );
                          },
                          child: Card(
                            color:
                                isDarkMode
                                    ? const Color.fromARGB(255, 137, 238, 213)
                                    : const Color.fromARGB(255, 253, 255, 153),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color:
                                    isDarkMode
                                        ? const Color.fromARGB(255, 71, 71, 71)!
                                        : const Color.fromARGB(
                                          255,
                                          236,
                                          236,
                                          236,
                                        )!,
                                width: 1,
                              ),
                            ),
                            elevation: 0,
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        selectedPlants[index],
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.robotoCondensed(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              isDarkMode
                                                  ? Colors.white
                                                  : Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.remove,
                                        color: Colors.redAccent,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          selectedPlants.removeAt(index);
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _showCustomDialog(context),
                    style: ElevatedButton.styleFrom(
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(15),
                      backgroundColor: primaryColor,
                    ),
                    child: Icon(Icons.add, color: Colors.white, size: 30),
                  ),
                  SizedBox(height: 20),
                ],
              )
              : _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Gato'),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_florist),
            label: 'Planta',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendario',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: primaryColor,
        unselectedItemColor: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        selectedLabelStyle: GoogleFonts.robotoCondensed(),
        unselectedLabelStyle: GoogleFonts.robotoCondensed(),
        onTap: _onItemTapped,
      ),
    );
  }
}
