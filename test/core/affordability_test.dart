import 'package:flutter_test/flutter_test.dart';
import 'package:kalkulator_kpr/core/affordability.dart';
import 'package:kalkulator_kpr/core/helpers.dart';
import 'package:kalkulator_kpr/models/calculate_model.dart';

void main() {
  group('Affordability', () {
    test('rasio = (angsuran + cicilan lain) / penghasilan', () {
      const a = Affordability(
          income: 15000000, otherDebt: 1000000, installment: 3500000);
      expect(a.ratio, closeTo(0.3, 1e-9));
      expect(a.remainingIncome, 10500000);
    });

    test('ambang tingkat: <=30% aman, <=40% waspada, sisanya berat', () {
      Affordability of(double installment) =>
          Affordability(income: 10000000, otherDebt: 0, installment: installment);
      expect(of(3000000).level, AffordabilityLevel.safe);
      expect(of(3000001).level, AffordabilityLevel.caution);
      expect(of(4000000).level, AffordabilityLevel.caution);
      expect(of(4000001).level, AffordabilityLevel.heavy);
    });

    test('penghasilan minimal menjaga rasio di 30%', () {
      const a =
          Affordability(income: 0, otherDebt: 500000, installment: 4000000);
      expect(a.minimumIncome, closeTo(15000000, 1e-6));
    });

    test('penghasilan nol tidak menghasilkan rasio tak hingga', () {
      const a = Affordability(income: 0, otherDebt: 0, installment: 4000000);
      expect(a.ratio, 0);
    });
  });

  group('highestInstallment', () {
    final model = CalculateModel(
      loanPlafon: 500000000,
      loan: 500000000,
      year: 15,
      interest: 7.5,
    );

    test('bunga efektif: bulan pertama yang terberat', () {
      final table = installmentTableEffective(model);
      expect(highestInstallment(table), table.first.installmentResult);
    });

    test('anuitas: sama dengan angsuran tetap', () {
      final table = installmentTableAnuitas(model);
      expect(highestInstallment(table),
          closeTo(table.first.installmentResult!, 0.001));
    });

    test('melewati nilai tidak wajar', () {
      expect(
        highestInstallment([
          CalculateResultModel(installmentResult: double.nan),
          CalculateResultModel(installmentResult: 100),
        ]),
        100,
      );
    });
  });
}
