import 'package:flutter/material.dart';

/// Encabezado estándar para bottom sheets: flecha volver + píldora de drag.
/// Uso: ponelo como primer hijo del Column del sheet, luego agregá el espaciado
/// inferior específico de cada sheet.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key, this.bottomSpacing = 20.0});
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 16, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                color: const Color(0xFF1E293B),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
        SizedBox(height: bottomSpacing),
      ],
    );
  }
}
