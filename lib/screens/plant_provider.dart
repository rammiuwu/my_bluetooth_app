import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlantProvider with ChangeNotifier {
  // Estándares desde Firebase
  double luzMin = 0;
  double luzMax = 10000;
  double humedadMin = 0;
  double humedadMax = 100;
  double temperaturaMin = 0;
  double temperaturaMax = 50;
  double phMin = 0;
  double phMax = 4095;

  String mensajeLuzIdeal = '';
  String mensajeLuzBaja = '';
  String mensajeLuzAlta = '';

  String mensajeHumedadIdeal = '';
  String mensajeHumedadBaja = '';
  String mensajeHumedadAlta = '';

  String mensajeTemperaturaIdeal = '';
  String mensajeTemperaturaBaja = '';
  String mensajeTemperaturaAlta = '';

  String mensajePhIdeal = '';
  String mensajePhBaja = '';
  String mensajePhAlta = '';

  String _modoEstandar = 'Estandar'; // o 'Exterior'

  // 🆕 Variable para almacenar la URL de la imagen
  String _plantImageUrl = '';

  // 🆕 Variable para almacenar los comentarios de la planta
  List<String> _plantComments = [];

  // 🆕 Getters
  String get plantImageUrl => _plantImageUrl;
  List<String> get plantComments => _plantComments;

  void setModoEstandar(String modo) {
    _modoEstandar = modo;
    notifyListeners();
  }

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

        // 🆕 Extraer la URL de la imagen
        _plantImageUrl = data?['Imagen'] ?? '';
        debugPrint("🖼️ URL de imagen extraída: $_plantImageUrl");

        // 🆕 Extraer los comentarios de la planta
        final comentarios = data?['Comentarios'];
        if (comentarios != null && comentarios is Map) {
          debugPrint("💬 Procesando ${comentarios.length} comentarios...");

          _plantComments = [];

          // Ordenar las claves numéricamente
          var sortedKeys = comentarios.keys.toList();
          sortedKeys.sort((a, b) {
            int aNum = int.tryParse(a.toString()) ?? 0;
            int bNum = int.tryParse(b.toString()) ?? 0;
            return aNum.compareTo(bNum);
          });

          // Extraer los comentarios en orden
          for (var key in sortedKeys) {
            var value = comentarios[key];
            if (value != null && value.toString().isNotEmpty) {
              _plantComments.add(value.toString());
            }
          }

          debugPrint("💬 Comentarios extraídos: ${_plantComments.length}");
        } else {
          _plantComments = [];
          debugPrint("⚠️ No se encontraron comentarios para esta planta");
        }

        final estandar = data?[_modoEstandar];
        if (estandar != null) {
          debugPrint("📦 Estándar extraído: $estandar");

          final luz = estandar['Luz'];
          final humedad = estandar['Humedad'];
          final temperatura = estandar['Temperatura'];
          final ph = estandar['Ph'];

          debugPrint("💡 Datos de Luz: $luz");
          debugPrint("💧 Datos de Humedad: $humedad");
          debugPrint("🌡️ Datos de Temperatura: $temperatura");
          debugPrint("🧪 Datos de Ph: $ph");

          luzMin = luz['min']?.toDouble() ?? 0;
          luzMax = luz['max']?.toDouble() ?? 10000;
          humedadMin = humedad['min']?.toDouble() ?? 0;
          humedadMax = humedad['max']?.toDouble() ?? 100;
          temperaturaMin = temperatura['min']?.toDouble() ?? 0;
          temperaturaMax = temperatura['max']?.toDouble() ?? 50;
          phMin = ph['min']?.toDouble() ?? 0;
          phMax = ph['max']?.toDouble() ?? 4095;

          final consejosLuz = luz['consejos'];
          final consejosHumedad = humedad['consejos'];
          final consejosTemperatura = temperatura['consejos'];
          final consejosPh = ph['consejos'];

          debugPrint("📋 Consejos Luz: $consejosLuz");
          debugPrint("📋 Consejos Humedad: $consejosHumedad");
          debugPrint("📋 Consejos Temperatura: $consejosTemperatura");
          debugPrint("📋 Consejos Ph: $consejosPh");

          mensajeLuzIdeal = consejosLuz['ideal'] ?? '';
          mensajeLuzBaja = consejosLuz['bajo'] ?? '';
          mensajeLuzAlta = consejosLuz['alto'] ?? '';

          mensajeHumedadIdeal = consejosHumedad['ideal'] ?? '';
          mensajeHumedadBaja = consejosHumedad['bajo'] ?? '';
          mensajeHumedadAlta = consejosHumedad['alto'] ?? '';

          mensajeTemperaturaIdeal = consejosTemperatura['ideal'] ?? '';
          mensajeTemperaturaBaja = consejosTemperatura['bajo'] ?? '';
          mensajeTemperaturaAlta = consejosTemperatura['alto'] ?? '';

          mensajePhIdeal = consejosPh['ideal'] ?? '';
          mensajePhBaja = consejosPh['bajo'] ?? '';
          mensajePhAlta = consejosPh['alto'] ?? '';

          debugPrint("✅ Estándares cargados correctamente:");
          debugPrint("   • Imagen: $_plantImageUrl");
          debugPrint("   • Comentarios: ${_plantComments.length} disponibles");
          debugPrint("   • Luz: [$luzMin - $luzMax]");
          debugPrint("   • Humedad: [$humedadMin - $humedadMax]");
          debugPrint("   • Temperatura: [$temperaturaMin - $temperaturaMax]");
          debugPrint("   • Ph: [$phMin - $phMax]");

          notifyListeners();
        } else {
          debugPrint("⚠️ El campo '$_modoEstandar' no existe en el documento.");
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

  // 🆕 Función para obtener un comentario aleatorio
  String getRandomComment() {
    if (_plantComments.isEmpty) {
      return "¡Hola! Soy tu planta favorita 🌱";
    }
    final random =
        DateTime.now().millisecondsSinceEpoch % _plantComments.length;
    return _plantComments[random];
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

  String getMensajeTemperatura(String temperatura) {
    final temperaturaActual = double.tryParse(temperatura) ?? -1;
    debugPrint(
      "Temperatura recibida: $temperatura, valor convertido: $temperaturaActual",
    );

    if (temperaturaActual < 0) {
      return 'Sensor no válido';
    }

    if (temperaturaActual < temperaturaMin) {
      debugPrint("🔵 Temperatura baja: $temperaturaActual < $temperaturaMin");
      return mensajeTemperaturaBaja;
    }
    if (temperaturaActual > temperaturaMax) {
      debugPrint("🔴 Temperatura alta: $temperaturaActual > $temperaturaMax");
      return mensajeTemperaturaAlta;
    }
    debugPrint(
      "🟢 Temperatura ideal: $temperaturaActual entre $temperaturaMin y $temperaturaMax",
    );
    return mensajeTemperaturaIdeal;
  }

  String getMensajePh(String ph) {
    final phActual = double.tryParse(ph) ?? -1;
    debugPrint("Ph recibido: $ph, valor convertido: $phActual");

    if (phActual < 0) {
      return 'Sensor no válido';
    }

    if (phActual < phMin) {
      debugPrint("🔵 Ph bajo: $phActual < $phMin");
      return mensajePhBaja;
    }
    if (phActual > phMax) {
      debugPrint("🔴 Ph alto: $phActual > $phMax");
      return mensajePhAlta;
    }
    debugPrint("🟢 Ph ideal: $phActual entre $phMin y $phMax");
    return mensajePhIdeal;
  }
}
