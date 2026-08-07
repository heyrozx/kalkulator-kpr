import 'package:flutter_test/flutter_test.dart';
import 'package:kalkulator_kpr/core/helpers.dart';
import 'package:kalkulator_kpr/models/calculate_model.dart';
import 'package:kalkulator_kpr/models/financing_contract.dart';
import 'package:kalkulator_kpr/models/simulation_history.dart';

/// Harga pokok 500 jt, 15 tahun, imbalan 7% per tahun.
CalculateModel _model() => CalculateModel(
      initialLoan: 550000000,
      dpNominal: 50000000,
      loanPlafon: 500000000,
      loan: 500000000,
      year: 15,
      interest: 7.5,
    );

void main() {
  group('murabahah', () {
    final table = installmentTableMurabahah(_model());
    final summary = summarizeInstallments(table);

    test('harga jual = harga pokok + margin, dan itulah total pembayaran', () {
      // Margin dihitung dari harga pokok yang tidak menyusut:
      // 500.000.000 x 7,5% x 15 tahun = 562.500.000.
      expect(summary.totalInterest, closeTo(562500000, 1));
      expect(summary.totalPrincipal, closeTo(500000000, 1));
      expect(summary.totalPayment, closeTo(1062500000, 1));
      expect(summary.months, 180);
    });

    test('angsuran terkunci sejak akad sampai lunas', () {
      expect(summary.isVarying, isFalse);
      expect(summary.firstInstallment, closeTo(1062500000 / 180, 1));
      for (final row in table) {
        expect(row.installmentResult, closeTo(summary.firstInstallment, 0.001));
      }
    });

    test('kolom sisa menampilkan sisa harga jual, bukan sisa pokok', () {
      // Setelah satu angsuran, yang tersisa adalah harga jual dikurangi satu
      // angsuran — bukan pokok dikurangi porsi pokok (497.222.222).
      expect(table.first.principalTotalRemain,
          closeTo(1062500000 - summary.firstInstallment, 1));
      expect(table.last.principalTotalRemain, closeTo(0, 1));
    });

    test('istilahnya tidak pernah menyebut bunga', () {
      const terms = InstallmentTerms.murabahah;
      expect(terms.charge, 'Margin');
      expect(terms.remaining, 'Sisa Harga Jual');
      expect(terms.rate, 'Margin');
      expect(terms.financing, 'Harga Pokok');
    });
  });

  group('musyarakah mutanaqisah', () {
    test('pola menurun: porsi tetap, sewa menyusut, total angsuran turun', () {
      final table = installmentTableEffective(_model());
      final summary = summarizeInstallments(table);

      // Sewa bulan pertama dihitung dari seluruh porsi bank.
      expect(table.first.interestResult, closeTo(500000000 * 0.075 / 12, 1));
      // Porsi yang dibeli sama tiap bulan.
      expect(table.first.principal, closeTo(500000000 / 180, 1));
      expect(table.last.principal, closeTo(500000000 / 180, 1));
      // Sewa mengecil seiring porsi bank menyusut.
      expect(table.last.interestResult!, lessThan(table.first.interestResult!));
      expect(summary.lastInstallment, lessThan(summary.firstInstallment));
      expect(summary.totalPrincipal, closeTo(500000000, 1));
    });

    test('pola tetap: total angsuran sama tiap bulan', () {
      final table = installmentTableAnuitas(_model());
      final summary = summarizeInstallments(table);

      expect(summary.isVarying, isFalse);
      // Komposisinya yang bergeser: porsi membesar, sewa mengecil.
      expect(table.last.principal!, greaterThan(table.first.principal!));
      expect(table.last.interestResult!, lessThan(table.first.interestResult!));
      expect(summary.totalPrincipal, closeTo(500000000, 1));
    });

    test('pola angsuran dipetakan ke mesin perhitungan yang benar', () {
      expect(MmqPattern.decreasing.engine, CalculatorType.effective);
      expect(MmqPattern.fixed.engine, CalculatorType.anuitas);
      expect(mmqPatternOf(CalculatorType.effective), MmqPattern.decreasing);
      expect(mmqPatternOf(CalculatorType.anuitas), MmqPattern.fixed);
    });

    test('istilahnya memakai porsi dan sewa', () {
      const terms = InstallmentTerms.mmq;
      expect(terms.principal, 'Porsi Dibeli');
      expect(terms.charge, 'Sewa (Ujrah)');
      expect(terms.remaining, 'Sisa Porsi Bank');
      expect(terms.financing, 'Porsi Bank');
    });
  });

  group('riwayat simulasi syariah', () {
    SimulationHistory entry(FinancingContract contract, CalculatorType type,
        List<CalculateResultModel> table) {
      return SimulationHistory.fromCalculation(
        name: 'Uji',
        type: type,
        model: _model(),
        summary: summarizeInstallments(table),
        contract: contract,
      );
    }

    test('murabahah dibangun ulang sebagai murabahah, bukan bunga flat', () {
      final expected = installmentTableMurabahah(_model());
      final restored = SimulationHistory.fromMap(
        entry(FinancingContract.murabahah, CalculatorType.flat, expected)
            .toMap(),
      );

      expect(restored.contract, FinancingContract.murabahah);

      final rebuilt = restored.buildTable();
      // Pembeda pentingnya ada di kolom sisa: tabel flat biasa akan
      // menghasilkan sisa pokok, bukan sisa harga jual.
      expect(rebuilt.first.principalTotalRemain,
          closeTo(expected.first.principalTotalRemain!, 0.001));
      expect(rebuilt.last.principalTotalRemain, closeTo(0, 1));
      expect(
          rebuilt.first.principalTotalRemain!,
          isNot(closeTo(
              installmentTableFlat(_model()).first.principalTotalRemain!, 1)));
    });

    test('MMQ mempertahankan pola angsurannya', () {
      for (final pattern in MmqPattern.values) {
        final table = pattern == MmqPattern.decreasing
            ? installmentTableEffective(_model())
            : installmentTableAnuitas(_model());
        final restored = SimulationHistory.fromMap(
          entry(FinancingContract.mmq, pattern.engine, table).toMap(),
        );

        expect(restored.contract, FinancingContract.mmq);
        expect(mmqPatternOf(restored.type), pattern);
        expect(restored.buildTable().last.installmentResult,
            closeTo(table.last.installmentResult!, 0.001));
      }
    });

    test('record lama tanpa kunci akad terbaca sebagai konvensional', () {
      final restored = SimulationHistory.fromMap({
        'name': 'Simulasi lama',
        'type': 'anuitas',
        'scheme': 'simple',
        'loanPlafon': 500000000,
        'year': 15,
        'interest': 7.5,
      });

      expect(restored.contract, FinancingContract.conventional);
      expect(restored.badges, ['Anuitas', 'Bunga Tetap', '15 thn']);
    });

    test('chip riwayat menampilkan akad, bukan jenis bunga', () {
      final murabahah = entry(FinancingContract.murabahah, CalculatorType.flat,
          installmentTableMurabahah(_model()));
      expect(murabahah.badges, ['Murabahah', '15 thn']);

      final mmq = entry(FinancingContract.mmq, CalculatorType.effective,
          installmentTableEffective(_model()));
      expect(mmq.badges, ['Musyarakah MQ', 'Menurun', '15 thn']);
    });

    test('usulan nama memakai nama akad', () {
      expect(
        SimulationHistory.suggestName(CalculatorType.flat, _model(),
            contract: FinancingContract.murabahah),
        'Murabahah 500 jt · 15 thn',
      );
      expect(
        SimulationHistory.suggestName(CalculatorType.anuitas, _model()),
        'Anuitas 500 jt · 15 thn',
      );
    });
  });
}
