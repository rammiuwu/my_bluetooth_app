import 'package:flutter/material.dart';
//import 'package:my_bluetooth_app/screens/bluetooth_screen.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainScreen(), // Ahora inicia en WelcomeScreen
    );
  }
}
