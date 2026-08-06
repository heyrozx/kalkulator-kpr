import 'package:flutter_test/flutter_test.dart';
import 'package:kalkulator_kpr/core/config.dart';
import 'package:kalkulator_kpr/core/validators.dart';

void main() {
  group('Validators.loan', () {
    test('menolak kosong dan nol', () {
      expect(Validators.loan(''), isNotNull);
      expect(Validators.loan('0'), isNotNull);
      expect(Validators.loan(null), isNotNull);
    });

    test('menerima nominal berformat', () {
      expect(Validators.loan('500.000.000'), isNull);
    });
  });

  group('Validators.year', () {
    test('menolak nol', () {
      expect(Validators.year('0'), isNotNull);
      expect(Validators.year(''), isNotNull);
    });

    test('menolak tenor di atas batas', () {
      // Regresi: tenor tanpa batas membuat tabel angsuran ratusan ribu baris.
      expect(Validators.year('${AppConfig.maxLoanYear + 1}'), isNotNull);
      expect(Validators.year('1.000'), isNotNull);
    });

    test('menerima tenor wajar', () {
      expect(Validators.year('15'), isNull);
      expect(Validators.year('${AppConfig.maxLoanYear}'), isNull);
    });
  });

  group('Validators.interest', () {
    test('menolak bunga nol', () {
      // Regresi: bunga 0 membuat rumus anuitas menghasilkan NaN.
      expect(Validators.interest('0'), isNotNull);
      expect(Validators.interest(''), isNotNull);
    });

    test('menolak bunga di atas 100%', () {
      expect(Validators.interest('101'), isNotNull);
    });

    test('menerima bunga desimal', () {
      expect(Validators.interest('7,5'), isNull);
      expect(Validators.interest('7.5'), isNull);
    });
  });

  group('Validators.dpNominal', () {
    test('menolak DP melebihi jumlah pinjaman', () {
      expect(Validators.dpNominal('600.000.000', loanText: '500.000.000'),
          isNotNull);
    });

    test('menerima DP kosong atau lebih kecil', () {
      expect(Validators.dpNominal('', loanText: '500.000.000'), isNull);
      expect(
          Validators.dpNominal('100.000.000', loanText: '500.000.000'), isNull);
    });
  });

  group('Validators.loanAfterDp', () {
    test('total pinjaman harus positif', () {
      expect(Validators.loanAfterDp('0'), isNotNull);
      expect(Validators.loanAfterDp('400.000.000'), isNull);
    });
  });
}
