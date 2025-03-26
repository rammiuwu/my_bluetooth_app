import 'package:flutter/material.dart';
import 'package:my_bluetooth_app/screens/home_screen.dart';
//import 'package:my_bluetooth_app/screens/bluetooth__screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(), // Ahora inicia en WelcomeScreen
    );
  }
}
