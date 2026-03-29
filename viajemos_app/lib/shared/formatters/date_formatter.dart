import 'package:flutter/services.dart';

class DayMonthFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll('/', '');
    if (digits.length > 4) return oldValue;
    if (!RegExp(r'^\d*$').hasMatch(digits)) return oldValue;

    String formatted = '';
    for (int i = 0; i < digits.length; i++) {
      if (i == 2) formatted += '/';
      formatted += digits[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class TimeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(':', '');
    if (digits.length > 4) return oldValue;
    if (!RegExp(r'^\d*$').hasMatch(digits)) return oldValue;

    String formatted = '';
    for (int i = 0; i < digits.length; i++) {
      if (i == 2) formatted += ':';
      formatted += digits[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
