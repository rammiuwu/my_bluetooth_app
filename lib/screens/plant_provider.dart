import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlantProvider with ChangeNotifier {
  // Estándares desde Firebase
  double luzMin = 0;
  double luzMax = 10000;
  double humedadMin = 0;
  double humedadMax = 100;

  String mensajeLuzIdeal = '';
  String mensajeLuzBaja = '';
  String mensajeLuzAlta = '';

  String mensajeHumedadIdeal = '';
  String mensajeHumedadBaja = '';
  String mensajeHumedadAlta = '';

  // Cargar estándares de la planta desde Firestore
  Future<void> fetchStandards(String planta) async {
    try {
      debugPrint("🌱 Nombre original recibido: $planta");
      final doc =
          await FirebaseFirestore.instance
              .collection('planta')
              .doc(planta)
              .get();

      if (doc.exists) {
        final data = doc.data();
        debugPrint("📄 Documento Firestore obtenido: $data");

        final estandar = data?['Estandar'];
        if (estandar != null) {
          debugPrint("📦 Estandar extraído: $estandar");

          final luz = estandar['Luz'];
          final humedad = estandar['Humedad'];

          debugPrint("💡 Datos de Luz: $luz");
          debugPrint("💧 Datos de Humedad: $humedad");

          luzMin = luz['min']?.toDouble() ?? 0;
          luzMax = luz['max']?.toDouble() ?? 10000;
          humedadMin = humedad['min']?.toDouble() ?? 0;
          humedadMax = humedad['max']?.toDouble() ?? 100;

          final consejosLuz = luz['consejos'];
          final consejosHumedad = humedad['consejos'];

          debugPrint("📋 Consejos Luz: $consejosLuz");
          debugPrint("📋 Consejos Humedad: $consejosHumedad");

          mensajeLuzIdeal = consejosLuz['ideal'] ?? '';
          mensajeLuzBaja = consejosLuz['bajo'] ?? '';
          mensajeLuzAlta = consejosLuz['alto'] ?? '';

          mensajeHumedadIdeal = consejosHumedad['ideal'] ?? '';
          mensajeHumedadBaja = consejosHumedad['bajo'] ?? '';
          mensajeHumedadAlta = consejosHumedad['alto'] ?? '';

          debugPrint("✅ Estándares cargados correctamente:");
          debugPrint("   • Luz: [$luzMin - $luzMax]");
          debugPrint("   • Humedad: [$humedadMin - $humedadMax]");
          debugPrint(
            "   • Msg Luz: $mensajeLuzIdeal | $mensajeLuzBaja | $mensajeLuzAlta",
          );
          debugPrint(
            "   • Msg Humedad: $mensajeHumedadIdeal | $mensajeHumedadBaja | $mensajeHumedadAlta",
          );

          notifyListeners();
        } else {
          debugPrint("⚠️ El campo 'Estandar' no existe en el documento.");
        }
      } else {
        debugPrint(
          "❌ Documento de planta '$planta' no encontrado en Firebase.",
        );
      }
    } catch (e) {
      debugPrint("❌ Error al obtener estándares de Firebase: $e");
    }
  }

  // Función para obtener el mensaje de humedad basado en los valores
  String getMensajeHumedad(String humedad) {
    final humedadActual = double.tryParse(humedad) ?? -1;
    debugPrint("Humedad recibida: $humedad, valor convertido: $humedadActual");

    if (humedadActual < 0) {
      return 'Sensor no válido';
    }

    if (humedadActual < humedadMin) {
      debugPrint("🔵 Humedad baja: $humedadActual < $humedadMin");
      return mensajeHumedadBaja;
    }
    if (humedadActual > humedadMax) {
      debugPrint("🔴 Humedad alta: $humedadActual > $humedadMax");
      return mensajeHumedadAlta;
    }
    debugPrint(
      "🟢 Humedad ideal: $humedadActual entre $humedadMin y $humedadMax",
    );
    return mensajeHumedadIdeal;
  }

  // Función para obtener el mensaje de luz basado en los valores
  String getMensajeLuz(String luz) {
    final luzActual = double.tryParse(luz) ?? -1;
    debugPrint("Luz recibida: $luz, valor convertido: $luzActual");

    if (luzActual < 0) {
      return 'Sensor no válido';
    }

    if (luzActual < luzMin) {
      debugPrint("🔵 Luz baja: $luzActual < $luzMin");
      return mensajeLuzBaja;
    }
    if (luzActual > luzMax) {
      debugPrint("🔴 Luz alta: $luzActual > $luzMax");
      return mensajeLuzAlta;
    }
    debugPrint("🟢 Luz ideal: $luzActual entre $luzMin y $luzMax");
    return mensajeLuzIdeal;
  }
}
