import 'package:flutter/foundation.dart';

/// An amount of money in integer minor units (e.g. cents) plus an ISO 4217
/// currency code. Never stored as a floating-point number.
@immutable
class Money {
  const Money(this.minorUnits, this.currencyCode);

  final int minorUnits;
  final String currencyCode;

  static const Map<String, String> _symbols = {
    'USD': r'$',
    'GBP': '£',
    'EUR': '€',
  };

  /// Currencies whose minor unit isn't hundredths.
  static const Map<String, int> _decimalsOverride = {'JPY': 0, 'KWD': 3};

  /// Formats for display, e.g. `$1,299.00`, `£85.50` or `AED 129.00`.
  String format() {
    final code = currencyCode.toUpperCase();
    final decimals = _decimalsOverride[code] ?? 2;

    var divisor = 1;
    for (var i = 0; i < decimals; i++) {
      divisor *= 10;
    }

    final absolute = minorUnits.abs();
    final whole = _groupThousands((absolute ~/ divisor).toString());
    final fraction = decimals == 0
        ? ''
        : '.${(absolute % divisor).toString().padLeft(decimals, '0')}';
    final sign = minorUnits < 0 ? '-' : '';

    final symbol = _symbols[code];
    return symbol != null
        ? '$sign$symbol$whole$fraction'
        : '$sign$code $whole$fraction';
  }

  static String _groupThousands(String digits) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.minorUnits == minorUnits &&
      other.currencyCode == currencyCode;

  @override
  int get hashCode => Object.hash(minorUnits, currencyCode);

  @override
  String toString() => 'Money($minorUnits $currencyCode)';
}
