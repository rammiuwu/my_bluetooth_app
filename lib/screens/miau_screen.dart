import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MiauScreen extends StatefulWidget {
  @override
  _MiauScreenState createState() => _MiauScreenState();
}

class _MiauScreenState extends State<MiauScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final List<String> frases = [
    "¡Miau! No me toques ahí.",
    "Otra vez tú...",
    "Te estoy juzgando humano.",
    "¡Comida!",
    "Déjame dormir.",
  ];

  final String imageUrl =
      "https://i.pinimg.com/736x/10/bc/bd/10bcbdc51fdacda178fbf70267e19251.jpg";

  String? fraseActual;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: -20.0,
    ).chain(CurveTween(curve: Curves.easeOut)).animate(_controller);
  }

  void _onTap() {
    _controller.forward().then((_) => _controller.reverse());

    setState(() {
      fraseActual = frases[Random().nextInt(frases.length)];
    });

    _hideTimer?.cancel();
    _hideTimer = Timer(Duration(seconds: 3), () {
      setState(() {
        fraseActual = null;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 500,
        height: 500,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Burbuja de diálogo flotante (no afecta layout)
            if (fraseActual != null)
              Positioned(
                top: 20,
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 253, 255, 153),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(66, 175, 175, 175),
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    fraseActual!,
                    style: GoogleFonts.robotoCondensed(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // Imagen del gato animada
            GestureDetector(
              onTap: _onTap,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _animation.value),
                    child: child,
                  );
                },
                child: Image.network(
                  imageUrl,
                  height: 200,
                  fit: BoxFit.contain,
                  loadingBuilder:
                      (context, child, loadingProgress) =>
                          loadingProgress == null
                              ? child
                              : CircularProgressIndicator(),
                  errorBuilder:
                      (context, error, stackTrace) => Icon(Icons.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
