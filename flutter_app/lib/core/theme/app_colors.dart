import 'package:flutter/material.dart';

abstract class AppColors {
  // Primary palette
  static const Color primary = Color(0xFF1B6B3A);
  static const Color primaryLight = Color(0xFF4CAF7D);
  static const Color accent = Color(0xFFF4A228);

  // Backgrounds & surfaces
  static const Color background = Color(0xFFF9FAF7);
  static const Color surface = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);

  // States
  static const Color muted = Color(0xFFE5E7EB);
  static const Color destructive = Color(0xFFEF4444);
  static const Color border = Color(0x1A000000); // rgba(0,0,0,0.1)

  // Semantic helpers
  static const Color primarySubtle = Color(0x1A4CAF7D); // 10% primaryLight
  static const Color accentSubtle = Color(0x33F4A228); // 20% accent
}
