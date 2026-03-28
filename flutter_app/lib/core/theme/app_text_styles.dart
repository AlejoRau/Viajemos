import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract class AppTextStyles {
  static TextStyle get _base => GoogleFonts.plusJakartaSans(
        color: AppColors.textPrimary,
      );

  // Headings
  static TextStyle get h1 => _base.copyWith(fontSize: 24, fontWeight: FontWeight.w600);
  static TextStyle get h2 => _base.copyWith(fontSize: 20, fontWeight: FontWeight.w600);
  static TextStyle get h3 => _base.copyWith(fontSize: 18, fontWeight: FontWeight.w600);
  static TextStyle get h4 => _base.copyWith(fontSize: 16, fontWeight: FontWeight.w600);

  // Body
  static TextStyle get bodyLarge => _base.copyWith(fontSize: 16, fontWeight: FontWeight.w400);
  static TextStyle get bodyMedium => _base.copyWith(fontSize: 14, fontWeight: FontWeight.w400);
  static TextStyle get bodySmall => _base.copyWith(fontSize: 12, fontWeight: FontWeight.w400);

  // Labels
  static TextStyle get labelMedium => _base.copyWith(fontSize: 14, fontWeight: FontWeight.w500);
  static TextStyle get labelSmall => _base.copyWith(fontSize: 12, fontWeight: FontWeight.w500);
  static TextStyle get labelXSmall => _base.copyWith(fontSize: 10, fontWeight: FontWeight.w500);

  // Button
  static TextStyle get button => _base.copyWith(fontSize: 16, fontWeight: FontWeight.w600);
}
