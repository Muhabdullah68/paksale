import 'package:flutter/services.dart';

/// Centralised input restrictions and validators.
///
/// On the web `keyboardType` is ignored, so the only reliable way to stop
/// invalid characters and unbounded length is `inputFormatters` plus
/// `maxLength`. These helpers are pure Dart and depend only on `flutter/services`.
class InputRules {
  InputRules._();

  // ── Formatting rules ─────────────────────────────────────────────────────

  /// Digits only, capped to [max] characters.
  static List<TextInputFormatter> digits(int max) => <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(max),
      ];

  /// Phone numbers: digits plus `+ - ( )` and single spaces.
  ///
  /// Accepts `+92XXXXXXXXXX`, `03XXXXXXXXX` and bare national numbers, but
  /// blocks letters, symbols and doubled/leading spaces. When [maxDigits] is
  /// given the total number of digits is capped too (so symbols cannot be used
  /// to inflate the length).
  static List<TextInputFormatter> phone({int max = 15, int? maxDigits}) =>
      <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-() ]')),
        FilteringTextInputFormatter.deny(RegExp(r'^\s')),
        FilteringTextInputFormatter.deny(RegExp(r'\s{2,}')),
        if (maxDigits != null) MaxDigitsFormatter(maxDigits),
        LengthLimitingTextInputFormatter(max),
      ];

  /// Person / business names: letters (including Urdu and Arabic ranges),
  /// spaces and the punctuation `. ' -`. Blocks digits and stray whitespace.
  static List<TextInputFormatter> name({int max = 60}) => <TextInputFormatter>[
        FilteringTextInputFormatter.allow(
            RegExp(r"[a-zA-Z\u00C0-\u024F\u0600-\u06FF\u0750-\u077F .'\-]")),
        FilteringTextInputFormatter.deny(RegExp(r'^\s')),
        FilteringTextInputFormatter.deny(RegExp(r'\s{2,}')),
        LengthLimitingTextInputFormatter(max),
      ];

  /// Email addresses: no whitespace, length-capped.
  static List<TextInputFormatter> email({int max = 100}) => <TextInputFormatter>[
        FilteringTextInputFormatter.deny(RegExp(r'\s')),
        LengthLimitingTextInputFormatter(max),
      ];

  /// Free text: no leading or doubled spaces, length-capped.
  static List<TextInputFormatter> text({int max = 100}) => <TextInputFormatter>[
        FilteringTextInputFormatter.deny(RegExp(r'^\s')),
        FilteringTextInputFormatter.deny(RegExp(r'\s{2,}')),
        LengthLimitingTextInputFormatter(max),
      ];

  // ── Validators ───────────────────────────────────────────────────────────

  static final RegExp _emailRe =
      RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  /// Simple, permissive email check.
  static bool isValidEmail(String value) =>
      _emailRe.hasMatch(value.trim());

  /// Extract just the digits from a phone-ish string.
  static String phoneDigits(String value) =>
      value.replaceAll(RegExp(r'[^0-9]'), '');

  /// Returns an error message, or `null` when valid.
  ///
  /// Rules: 10–11 digits after stripping non-digits. `+92XXXXXXXXXX` (12
  /// digits, 92 country code) and `03XXXXXXXXX` / `3XXXXXXXXX` are accepted.
  static String? validatePhone(String? value, {String label = 'Phone number'}) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return '$label is required';
    var d = phoneDigits(raw);
    if (d.length > 11 && d.startsWith('92')) {
      d = d.substring(2);
    }
    if (d.length < 10 || d.length > 11) {
      return '$label must be 10–11 digits';
    }
    return null;
  }

  /// Password length check (Firebase Auth requires at least 6).
  static String? validatePassword(String? value, {int min = 6}) {
    final v = (value ?? '');
    if (v.isEmpty) return 'Password is required';
    if (v.length < min) return 'Password must be at least $min characters';
    return null;
  }

  /// Amount check with sane bounds (defaults: 50 – 1,000,000,000).
  static String? validateAmount(
    String? value, {
    double min = 0,
    double max = 1000000000,
    bool required = false,
    String label = 'Amount',
  }) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return required ? '$label is required' : null;
    final n = double.tryParse(v);
    if (n == null) return 'Enter a valid $label';
    if (n < min) return '$label must be at least ${min.toStringAsFixed(0)}';
    if (n > max) return '$label cannot exceed ${max.toStringAsFixed(0)}';
    return null;
  }
}

/// Rejects an edit that would push the number of digits above [maxDigits],
/// while still allowing separators such as `+`, spaces, `-`, `(`, `)`.
class MaxDigitsFormatter extends TextInputFormatter {
  final int maxDigits;

  const MaxDigitsFormatter(this.maxDigits);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '').length;
    return digits > maxDigits ? oldValue : newValue;
  }
}
