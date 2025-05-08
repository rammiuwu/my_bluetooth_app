import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_bluetooth_app/screens/home_screen.dart';
import 'package:my_bluetooth_app/screens/bluetooth_provider.dart';
import 'package:my_bluetooth_app/screens/plant_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'firebase_options.dart'; // Importa el archivo generado por FlutterFire CLI

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización de Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase inicializado correctamente");
  } catch (e) {
    print("❌ Error inicializando Firebase: $e");
    runApp(const ErrorScreen());
    return;
  }

  // Obtener o crear userId en SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  String? userId = prefs.getString('userId');
  if (userId == null) {
    userId = const Uuid().v4();
    await prefs.setString('userId', userId);
  }
  print("👤 Usuario ID asignado: $userId");

  // Iniciar la app con los providers
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => BluetoothProvider(userId: userId),
        ), // ← AQUÍ SE PASA userId
        ChangeNotifierProvider(create: (_) => PlantProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            'Error al inicializar la aplicación. Intenta nuevamente.',
            style: TextStyle(fontSize: 20, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeData get themeData => _isDarkMode ? _darkTheme : _lightTheme;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  static final ThemeData _lightTheme = ThemeData(
    primaryColor: Colors.blueGrey[800],
    colorScheme: ColorScheme.light(
      primary: Colors.blueGrey[800]!,
      secondary: Colors.teal[400]!,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Colors.teal[400]!,
      unselectedItemColor: Colors.grey[600]!,
    ),
    scaffoldBackgroundColor: Colors.grey[50],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.blueGrey[800],
      elevation: 1,
    ),
  );

  static final ThemeData _darkTheme = ThemeData(
    primaryColor: Colors.teal[400],
    colorScheme: ColorScheme.dark(
      primary: Colors.teal[400]!,
      secondary: Colors.teal[200]!,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.grey[900],
      selectedItemColor: Colors.teal[400]!,
      unselectedItemColor: Colors.grey[400]!,
    ),
    scaffoldBackgroundColor: Colors.grey[900],
    appBarTheme: AppBarTheme(backgroundColor: Colors.grey[900], elevation: 1),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeProvider.themeData,
      home: HomeScreen(),
    );
  }
}
