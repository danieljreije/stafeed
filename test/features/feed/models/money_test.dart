import 'package:flutter_test/flutter_test.dart';
import 'package:stafeed/app/features/feed/models/money.dart';

void main() {
  group('Money.format', () {
    test('formats US dollars from cents with the dollar sign', () {
      expect(const Money(12900, 'USD').format(), r'$129.00');
    });

    test('formats British pounds with the pound sign', () {
      expect(const Money(8550, 'GBP').format(), '£85.50');
    });

    test('keeps leading zeros in the minor units', () {
      expect(const Money(1205, 'USD').format(), r'$12.05');
      expect(const Money(7, 'USD').format(), r'$0.07');
    });

    test('groups thousands', () {
      expect(const Money(129900, 'USD').format(), r'$1,299.00');
      expect(const Money(123456789, 'GBP').format(), '£1,234,567.89');
    });

    test('prefixes the ISO code for currencies without a symbol', () {
      expect(const Money(12900, 'AED').format(), 'AED 129.00');
    });

    test('is case-insensitive about the currency code', () {
      expect(const Money(500, 'usd').format(), r'$5.00');
    });
  });

  test('two Money values with the same amount and currency are equal', () {
    expect(const Money(100, 'USD'), const Money(100, 'USD'));
    expect(const Money(100, 'USD'), isNot(const Money(100, 'GBP')));
  });
}
