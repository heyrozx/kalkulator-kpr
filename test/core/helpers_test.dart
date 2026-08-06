import 'package:flutter_test/flutter_test.dart';
import 'package:kalkulator_kpr/core/helpers.dart';
import 'package:kalkulator_kpr/models/calculate_model.dart';

/// Angka acuan: plafon Rp500.000.000, 15 tahun (180 bulan), bunga 10%/tahun.
CalculateModel baseModel({
  double loan = 500000000,
  double year = 15,
  double interest = 10,
  double? plafon,
}) =>
    CalculateModel(
      loan: loan,
      loanPlafon: plafon ?? loan,
      year: year,
      interest: interest,
    );

void main() {
  group('konversi dasar', () {
    test('totalMonthsOf membulatkan ke bilangan bulat', () {
      expect(totalMonthsOf(15), 180);
      expect(totalMonthsOf(1.5), 18);
      expect(totalMonthsOf(0), 0);
      expect(totalMonthsOf(null), 0);
      expect(totalMonthsOf(-5), 0);
    });

    test('monthlyRateOf mengubah persen tahunan menjadi rasio bulanan', () {
      expect(monthlyRateOf(12), closeTo(0.01, 1e-12));
      expect(monthlyRateOf(0), 0);
      expect(monthlyRateOf(null), 0);
    });
  });

  group('perhitungan satu bulan', () {
    test('flat: pokok rata dan bunga dari plafon penuh', () {
      final result = calculateFlat(baseModel());
      expect(result.principal, closeTo(2777777.78, 0.01));
      expect(result.interestResult, closeTo(4166666.67, 0.01));
      expect(result.installmentResult, closeTo(6944444.44, 0.01));
    });

    test('efektif bulan pertama sama dengan flat', () {
      final flat = calculateFlat(baseModel());
      final effective = calculateEffective(baseModel());
      expect(effective.installmentResult, flat.installmentResult);
    });

    test('anuitas memakai rumus angsuran tetap', () {
      final result = calculateAnuitas(baseModel());
      expect(result.installmentResult, closeTo(5373025.59, 0.01));
      expect(result.interestResult, closeTo(4166666.67, 0.01));
      expect(result.principal, closeTo(1206358.92, 0.01));
    });

    test('anuitas dengan bunga 0 membagi pokok rata, bukan NaN', () {
      // Regresi: pembagi (1+i)^n - 1 menjadi nol saat bunga 0 sehingga hasilnya
      // NaN dan meng-crash layar tabel angsuran.
      final result = calculateAnuitas(baseModel(interest: 0));
      expect(result.installmentResult, closeTo(2777777.78, 0.01));
      expect(result.interestResult, 0);
      expect(result.installmentResult!.isNaN, isFalse);
    });

    test('jangka waktu 0 tidak membagi nol', () {
      for (final result in [
        calculateFlat(baseModel(year: 0)),
        calculateEffective(baseModel(year: 0)),
        calculateAnuitas(baseModel(year: 0)),
      ]) {
        expect(result.installmentResult, 0);
        expect(result.principal, 0);
        expect(result.interestResult, 0);
      }
    });
  });

  group('tabel angsuran', () {
    test('flat: jumlah baris, bunga tetap, pokok lunas', () {
      final rows = installmentTableFlat(baseModel());
      expect(rows.length, 180);
      expect(rows.first.interestResult, rows.last.interestResult);
      expect(sumOf(rows, (e) => e.principal), closeTo(500000000, 1));
      expect(rows.last.principalTotalRemain, closeTo(0, 1));
    });

    test('efektif: bunga menurun dan pokok tetap', () {
      final rows = installmentTableEffective(baseModel());
      expect(rows.length, 180);
      expect(rows.first.principal, closeTo(rows.last.principal!, 0.01));
      expect(rows.last.interestResult, lessThan(rows.first.interestResult!));
      expect(rows.last.principalTotalRemain, closeTo(0, 1));
    });

    test('anuitas: total angsuran tetap dan pinjaman lunas di bulan terakhir',
        () {
      final rows = installmentTableAnuitas(baseModel());
      expect(rows.length, 180);
      expect(rows.first.installmentResult,
          closeTo(rows.last.installmentResult!, 0.01));
      expect(rows.first.principal, lessThan(rows.last.principal!));
      expect(rows.last.principalTotalRemain, closeTo(0, 1));
      expect(sumOf(rows, (e) => e.interestResult), closeTo(467144605.94, 1));
    });

    test('tabel tidak mengubah model yang dikirim', () {
      // Regresi: sebelumnya fungsi tabel memutasi loan/plafon/tenor/bunga milik
      // pemanggil sehingga tiap layar harus membuat dua instance identik.
      final model = baseModel();
      installmentTableAnuitas(model);
      installmentTableEffective(model);
      installmentTableFixFloating(CalculatorType.anuitas,
          model.copyWith(fixInterest: 7, fixYear: 3, floatingInterest: 12));

      expect(model.loan, 500000000);
      expect(model.loanPlafon, 500000000);
      expect(model.year, 15);
      expect(model.interest, 10);
    });

    test('bunga 0 menghasilkan tabel yang tetap bisa dijumlahkan', () {
      final rows = installmentTableAnuitas(baseModel(interest: 0));
      expect(rows.length, 180);
      expect(sumOf(rows, (e) => e.principal), closeTo(500000000, 1));
      expect(sumOf(rows, (e) => e.interestResult), 0);
    });
  });

  group('fix & floating', () {
    final model = baseModel().copyWith(
      fixInterest: 7,
      fixYear: 3,
      floatingInterest: 12,
    );

    test('jumlah baris sesuai tenor', () {
      final rows = installmentTableFixFloating(CalculatorType.anuitas, model);
      expect(rows.length, 180);
    });

    test('bunga naik saat masuk periode floating', () {
      final rows = installmentTableFixFloating(CalculatorType.anuitas, model);
      final lastFix = rows[35];
      final firstFloating = rows[36];
      expect(firstFloating.installmentResult,
          greaterThan(lastFix.installmentResult!));
      expect(rows.last.principalTotalRemain, closeTo(0, 1));
    });

    test('masa fix lebih panjang dari tenor tidak membuat baris berlebih', () {
      final rows = installmentTableFixFloating(
          CalculatorType.anuitas, model.copyWith(fixYear: 20));
      expect(rows.length, 180);
    });
  });

  group('bunga berjenjang', () {
    final model = baseModel().copyWith(floatingInterest: 12);

    test('tiap tarif berlaku satu tahun lalu lanjut ke floating', () {
      final rows =
          installmentTableTiered(CalculatorType.anuitas, model, [5, 7, 9]);
      expect(rows.length, 180);
      // Bunga bulan pertama tiap tahun mengikuti tarif tahun tersebut.
      expect(rows[0].interestResult, closeTo(500000000 * 0.05 / 12, 1));
      // Bunga bulan ke-13 dihitung dari sisa pinjaman akhir bulan ke-12
      // memakai tarif tahun kedua.
      expect(rows[12].interestResult,
          closeTo(rows[11].principalTotalRemain! * 0.07 / 12, 1));
      expect(rows.last.principalTotalRemain, closeTo(0, 1));
    });

    test('jumlah tingkat melebihi tenor tetap aman', () {
      final rows = installmentTableTiered(
          CalculatorType.anuitas, model.copyWith(year: 2), [5, 7, 9, 11]);
      expect(rows.length, 24);
    });
  });

  group('sumOf', () {
    test('melewati nilai non-finite', () {
      final rows = [
        CalculateResultModel(principal: 100),
        CalculateResultModel(principal: double.nan),
        CalculateResultModel(principal: double.infinity),
        CalculateResultModel(principal: null),
        CalculateResultModel(principal: 50),
      ];
      expect(sumOf(rows, (e) => e.principal), 150);
    });
  });
}
