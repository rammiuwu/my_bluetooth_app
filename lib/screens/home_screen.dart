import 'package:flutter/material.dart';
import 'bluetooth_screen.dart'; // Importa la pantalla de búsqueda

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Inicio")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BluetoothScreen()),
            );
          },
          child: Text("Buscar dispositivos Bluetooth"),
        ),
      ),
    );
  }
}
