import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_bluetooth_app/screens/home_screen.dart';
import 'package:my_bluetooth_app/main.dart';

class BluetoothScreen extends StatefulWidget {
  @override
  _BluetoothScreenState createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  List<BluetoothDevice> _devicesList = [];
  bool _isScanning = false;
  bool _hasPermissions = false;
  bool _isConnected = false;
  BluetoothDevice? _connectedDevice;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses =
          await [
            Permission.bluetoothScan,
            Permission.bluetoothConnect,
            Permission.bluetoothAdvertise,
            Permission.locationWhenInUse,
          ].request();

      setState(() {
        _hasPermissions = statuses.values.every((status) => status.isGranted);
      });

      if (_hasPermissions) {
        _startScan();
      } else {
        _showStatusMessage("Se requieren permisos para usar Bluetooth");
      }
    } else {
      PermissionStatus status = await Permission.bluetooth.request();
      setState(() => _hasPermissions = status.isGranted);
      if (_hasPermissions) _startScan();
    }
  }

  Future<bool> _checkBluetoothState() async {
    try {
      BluetoothAdapterState state = await FlutterBluePlus.adapterState.first;
      if (state != BluetoothAdapterState.on) {
        await FlutterBluePlus.turnOn();
        await Future.delayed(Duration(seconds: 1));
      }
      return true;
    } catch (e) {
      _showStatusMessage("Error al activar Bluetooth");
      return false;
    }
  }

  void _startScan() async {
    if (_isScanning) return;

    bool isBluetoothOn = await _checkBluetoothState();
    if (!isBluetoothOn) {
      _showStatusMessage("Active el Bluetooth en su dispositivo");
      return;
    }

    setState(() {
      _isScanning = true;
      _devicesList.clear();
    });

    try {
      await FlutterBluePlus.stopScan();
      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: 10),
        androidScanMode: AndroidScanMode.lowLatency,
      );

      FlutterBluePlus.scanResults.listen((results) {
        if (!mounted) return;
        setState(() {
          _devicesList =
              results
                  .where((r) => r.device.platformName.isNotEmpty)
                  .map((r) => r.device)
                  .toList();
        });
      });

      await Future.delayed(Duration(seconds: 10));
    } catch (e) {
      _showStatusMessage("Error en escaneo: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
      await FlutterBluePlus.stopScan();
    }
  }

  void _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _isScanning = true;
      _statusMessage = "Conectando...";
    });

    try {
      await device.connect(autoConnect: false);
      setState(() {
        _connectedDevice = device;
        _isConnected = true;
      });
      _showStatusMessage("¡Conectado a ${device.platformName}!");
    } catch (e) {
      _showStatusMessage("Error al conectar: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  void _disconnectDevice() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      setState(() {
        _connectedDevice = null;
        _isConnected = false;
      });
      _showStatusMessage("Dispositivo desconectado");
    }
  }

  void _showStatusMessage(String message) {
    setState(() => _statusMessage = message);
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _statusMessage = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final primaryColor = isDarkMode ? Colors.teal[400] : Colors.blueGrey[800];
    final cardColor = isDarkMode ? Colors.grey[800] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Escaneo Bluetooth",
          style: GoogleFonts.robotoCondensed(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          },
        ),
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        elevation: 1,
        actions: [
          if (_isConnected)
            IconButton(
              icon: Icon(Icons.link_off, color: Colors.red),
              onPressed: _disconnectDevice,
            ),
        ],
      ),
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_statusMessage != null)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info,
                      size: 20,
                      color: _isConnected ? Colors.green : primaryColor,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: GoogleFonts.robotoCondensed(
                          color: textColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 20),
            if (_isConnected)
              _buildConnectedDeviceInfo(primaryColor, textColor)
            else if (!_hasPermissions)
              _buildPermissionWarning(context, primaryColor, textColor)
            else if (_isScanning && _devicesList.isEmpty)
              _buildScanningIndicator(textColor)
            else if (_devicesList.isEmpty)
              _buildNoDevicesFound(primaryColor, textColor)
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _devicesList.length,
                  itemBuilder: (context, index) {
                    final device = _devicesList[index];
                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.symmetric(vertical: 6),
                      color: cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color:
                              isDarkMode
                                  ? Colors.grey[700]!
                                  : Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.bluetooth, color: primaryColor),
                        title: Text(
                          device.platformName,
                          style: GoogleFonts.robotoCondensed(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          device.remoteId.toString(),
                          style: GoogleFonts.robotoCondensed(
                            fontSize: 14,
                            color:
                                isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                        onTap: () => _connectToDevice(device),
                      ),
                    );
                  },
                ),
              ),
            SizedBox(height: 20),
            if (!_isConnected)
              ElevatedButton(
                onPressed: _isScanning ? null : _startScan,
                child: Text(
                  _isScanning ? "Escaneando..." : "Iniciar Escaneo",
                  style: GoogleFonts.robotoCondensed(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedDeviceInfo(Color? primaryColor, Color textColor) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bluetooth_connected, size: 60, color: primaryColor),
            SizedBox(height: 20),
            Text(
              "Dispositivo conectado:",
              style: GoogleFonts.robotoCondensed(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: 10),
            Text(
              _connectedDevice?.platformName ?? "Desconocido",
              style: GoogleFonts.robotoCondensed(
                fontSize: 22,
                color: primaryColor,
              ),
            ),
            SizedBox(height: 10),
            Text(
              _connectedDevice?.remoteId.toString() ?? "",
              style: GoogleFonts.robotoCondensed(
                fontSize: 14,
                color:
                    Provider.of<ThemeProvider>(
                          context,
                          listen: false,
                        ).isDarkMode
                        ? Colors.grey[400]
                        : Colors.grey[600],
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _disconnectDevice,
              child: Text(
                "Desconectar",
                style: GoogleFonts.robotoCondensed(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionWarning(
    BuildContext context,
    Color? primaryColor,
    Color textColor,
  ) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber, size: 50, color: Colors.amber),
            SizedBox(height: 16),
            Text(
              "Permisos insuficientes",
              style: GoogleFonts.robotoCondensed(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "La aplicación necesita permisos para buscar dispositivos Bluetooth",
              style: GoogleFonts.robotoCondensed(color: textColor),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Otorgar permisos",
                style: GoogleFonts.robotoCondensed(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: _requestPermissions,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningIndicator(Color textColor) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              "Buscando dispositivos...",
              style: GoogleFonts.robotoCondensed(color: textColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDevicesFound(Color? primaryColor, Color textColor) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 50, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "No se encontraron dispositivos",
              style: GoogleFonts.robotoCondensed(
                fontSize: 18,
                color: textColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Asegúrese que los dispositivos están encendidos y visibles",
              style: GoogleFonts.robotoCondensed(color: textColor),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Reintentar",
                style: GoogleFonts.robotoCondensed(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: _startScan,
            ),
          ],
        ),
      ),
    );
  }
}
