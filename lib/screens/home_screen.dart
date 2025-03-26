import 'package:flutter/material.dart';
import 'package:my_bluetooth_app/screens/bluetooth_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<String> selectedPlants = [];

  static const List<Widget> _widgetOptions = <Widget>[
    Center(
      child: Text(
        "Miau",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    ),
    Center(
      child: Text(
        "Planta",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    ),
    Center(
      child: Text(
        "Calendario",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showCustomDialog(BuildContext context) {
    List<String> plantas = [
      "Planta Billete",
      "Lengua de Suegra",
      "Cactus",
      "Orquídea",
      "Bonsái",
    ];

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecciona una planta'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: plantas.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(plantas[index]),
                  leading: Icon(Icons.local_florist, color: Colors.green),
                  onTap: () {
                    if (selectedPlants.length < 5) {
                      setState(() {
                        selectedPlants.add(plantas[index]);
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Solo puedes agregar hasta 5 plantas"),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("PLANTTY"),
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BluetoothScreen()),
                );
              },
              child: Text("Bluetooth"),
            ),
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
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 4,
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
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
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
                      backgroundColor: Color.fromARGB(121, 57, 214, 70),
                    ),
                    child: Icon(Icons.add, color: Colors.white, size: 30),
                  ),
                  SizedBox(height: 20),
                ],
              )
              : _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
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
        selectedItemColor: const Color.fromARGB(147, 63, 180, 63),
        onTap: _onItemTapped,
      ),
    );
  }
}
