import 'package:flutter_test/flutter_test.dart';
import 'package:kalkulator_kpr/core/currency_format.dart';

void main() {
  group('currencyId', () {
    test('memakai pemisah ribuan Indonesia tanpa desimal', () {
      expect(currencyId.format(1000000), '1.000.000');
      expect(currencyId.format(5372345.678), '5.372.346');
      expect(currencyId.format(0), '0');
    });
  });

  group('toNumber', () {
    test('membuang pemisah ribuan', () {
      expect(CurrencyFormat.toNumber('1.000.000'), '1000000');
      expect(CurrencyFormat.toNumber('1,000,000'), '1000000');
      expect(CurrencyFormat.toNumber('500'), '500');
    });

    test('teks kosong menjadi nol', () {
      expect(CurrencyFormat.toNumber(''), '0');
      expect(CurrencyFormat.toNumber(null), '0');
      expect(CurrencyFormat.parseNumber('abc'), 0);
    });
  });

  group('toNumberComma', () {
    test('menerima koma maupun titik sebagai pemisah desimal', () {
      expect(CurrencyFormat.parseDecimal('7,5'), 7.5);
      expect(CurrencyFormat.parseDecimal('7.5'), 7.5);
      expect(CurrencyFormat.parseDecimal('7'), 7);
    });

    test('pemisah terakhir dianggap desimal', () {
      expect(CurrencyFormat.parseDecimal('1.234,5'), 1234.5);
      expect(CurrencyFormat.parseDecimal('1,234.5'), 1234.5);
    });

    test('input tidak wajar tidak melempar exception', () {
      expect(CurrencyFormat.parseDecimal(''), 0);
      expect(CurrencyFormat.parseDecimal(null), 0);
      expect(CurrencyFormat.parseDecimal('.'), 0);
      expect(CurrencyFormat.parseDecimal('7,'), 7);
    });
  });

  group('formatNumber', () {
    test('mengembalikan teks siap pakai untuk field input', () {
      expect(CurrencyFormat.formatNumber(1500000), '1.500.000');
      expect(CurrencyFormat.formatNumber(20.5), '20,5');
      expect(CurrencyFormat.formatNumber(20.0), '20');
    });

    test('hasil format bisa diurai kembali tanpa kehilangan nilai', () {
      const value = 987654321;
      expect(CurrencyFormat.parseNumber(CurrencyFormat.formatNumber(value)),
          value);
    });
  });
}
