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

/// Formats input as HH:mm and rejects values that would produce
/// invalid hours (00–23) or minutes (00–59).
///
/// Rules applied digit by digit:
///   pos 0 (H tens): 0–2
///   pos 1 (H units): 0–9 normally; if tens==2, only 0–3 (→ max 23)
///   pos 2 (M tens): 0–5  (→ max 5x, i.e. 59)
///   pos 3 (M units): 0–9
class TimeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(':', '');
    if (digits.length > 4) return oldValue;
    if (!RegExp(r'^\d*$').hasMatch(digits)) return oldValue;

    // Validate each digit position.
    for (int i = 0; i < digits.length; i++) {
      final d = int.parse(digits[i]);
      switch (i) {
        case 0: // hour tens: 0–2
          if (d > 2) return oldValue;
        case 1: // hour units: 0–3 when tens==2, else 0–9
          if (digits[0] == '2' && d > 3) return oldValue;
        case 2: // minute tens: 0–5
          if (d > 5) return oldValue;
        case 3: // minute units: 0–9 (always valid)
          break;
      }
    }

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
