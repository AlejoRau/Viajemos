import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Capa 1: Textura de mapa sutil (stardust pattern, 5% opacidad)
        Positioned.fill(
          child: Opacity(
            opacity: 0.05,
            child: Image.network(
              'https://www.transparenttextures.com/patterns/stardust.png',
              repeat: ImageRepeat.repeat,
              color: const Color(0x1A000000), // black 10%
              colorBlendMode: BlendMode.multiply,
            ),
          ),
        ),

        // Capa 2: Degradado inferior (desvanece la textura hacia abajo)
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  const Color(0xFFF8FAFC).withValues(alpha: 0.85),
                ],
                stops: const [0.5, 1.0],
              ),
            ),
          ),
        ),

        // Capa 3: Contenido
        child,
      ],
    );
  }
}
