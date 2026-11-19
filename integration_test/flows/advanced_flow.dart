import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalkulator_kpr/core/currency_format.dart';
import 'package:kalkulator_kpr/core/helpers.dart';
import 'package:kalkulator_kpr/models/calculate_model.dart';
import 'package:kalkulator_kpr/pages/advanced/advanced_screen.dart';
import 'package:kalkulator_kpr/pages/principle/principal_table.dart';

import '../support/test_app.dart';

const String _loan = 'Jumlah Pinjaman (Rp)';
const String _dpPercent = 'DP';
const String _dpNominal = 'DP (Rp)';
const String _total = 'Total Pinjaman (Rp)';
const String _year = 'Jangka Waktu (Tahun)';

Future<void> _openAdvanced(WidgetTester tester) async {
  await pumpKprApp(tester);
  await openDrawerItem(tester, 'Advanced');
  expect(find.byType(AdvancedScreen), findsOneWidget);
}

void advancedFlow() {
  group('Advanced: fix & floating', () {
    testWidgets('DP persen dan nominal saling sinkron', (tester) async {
      await _openAdvanced(tester);

      await enter(tester, _loan, '600000000');
      expect(fieldText(tester, _total), '600.000.000');

      await enter(tester, _dpPercent, '10');
      expect(fieldText(tester, _dpNominal), '60.000.000');
      expect(fieldText(tester, _total), '540.000.000');

      await enter(tester, _dpNominal, '150000000');
      expect(fieldText(tester, _dpPercent), '25');
      expect(fieldText(tester, _total), '450.000.000');

      // DP melebihi pinjaman dipangkas ke jumlah pinjaman.
      await enter(tester, _dpNominal, '700000000');
      expect(fieldText(tester, _dpNominal), '600.000.000');
      expect(fieldText(tester, _total), '0');
    });

    testWidgets('masa fix >= tenor ditolak dengan peringatan',
        (tester) async {
      await _openAdvanced(tester);
      await enter(tester, _loan, '500000000');
      await enter(tester, _year, '3');
      await enter(tester, 'Bunga (%)', '5');
      await enter(tester, 'Bunga Pinjaman', '11');

      await tapVisible(tester, find.text('Hitung Simulasi'));
      expect(find.text('Masa kredit fix terlalu panjang'), findsOneWidget);
      expect(find.byType(PrincipalTable), findsNothing);
    });

    testWidgets('hitung fix & floating membuka tabel dengan detail bunga',
        (tester) async {
      await _openAdvanced(tester);
      await enter(tester, _loan, '600000000');
      await enter(tester, _dpPercent, '10');
      await enter(tester, _year, '20');
      await enter(tester, 'Bunga (%)', '5');
      await enter(tester, 'Bunga Pinjaman', '11');

      expect(find.text('3 Tahun'), findsOneWidget);
      await tapVisible(tester, find.text('Hitung Simulasi'));

      expect(find.byType(PrincipalTable), findsOneWidget);
      expect(find.text('Rp. 540.000.000'), findsOneWidget);
      expect(find.text('Selengkapnya'), findsOneWidget);

      final List<CalculateResultModel> rows = installmentTableFixFloating(
        CalculatorType.anuitas,
        CalculateModel(
          fixInterest: 5,
          fixYear: 3,
          floatingInterest: 11,
          initialLoan: 600000000,
          dpNominal: 60000000,
          loanPlafon: 540000000,
          loan: 540000000,
          year: 20,
          interest: 11,
        ),
      );
      expect(rows, hasLength(240));
      // Angsuran naik saat masuk masa floating (bulan ke-37).
      expect(rows[36].installmentResult!,
          greaterThan(rows[35].installmentResult!));

      await tapText(tester, 'Tabel');
      expect(find.text(currencyId.format(rows.first.installmentResult)),
          findsWidgets);

      await tapText(tester, 'Selengkapnya');
      expect(find.text('Detail Angsuran'), findsOneWidget);
    });

    testWidgets('pilihan metode di Advanced bisa diganti', (tester) async {
      await _openAdvanced(tester);
      await tester.tap(find.text('Anuitas').hitTestable());
      await tester.pumpAndSettle();
      expect(find.text('Pilih Perhitungan'), findsOneWidget);

      await tester.tap(find.descendant(
          of: find.byType(AlertDialog), matching: find.text('Efektif')));
      await tester.pumpAndSettle();
      expect(find.text('Pilih Perhitungan'), findsNothing);
      expect(find.text('Efektif'), findsOneWidget);
    });
  });

  group('Advanced: bunga berjenjang', () {
    Future<void> openTiered(WidgetTester tester) async {
      await _openAdvanced(tester);
      await tapText(tester, 'Berjenjang');
      expect(find.text('Bunga tahun ke 1'), findsOneWidget);
    }

    testWidgets('tambah & hapus baris bunga per tahun', (tester) async {
      await openTiered(tester);

      await tapVisible(tester, find.byIcon(Icons.add_circle_outline));
      await tapVisible(tester, find.byIcon(Icons.add_circle_outline));
      expect(find.text('Bunga tahun ke 3'), findsOneWidget);

      await tapVisible(tester, find.byTooltip('Hapus bunga tahun ke 3'));
      expect(find.text('Bunga tahun ke 3'), findsNothing);

      // Baris pertama tidak bisa dihapus.
      await tapVisible(tester, find.byTooltip('Hapus bunga tahun ke 1'));
      expect(find.text('Bunga tahun ke 1'), findsOneWidget);
    });

    testWidgets('jumlah tahun fix >= tenor ditolak', (tester) async {
      await openTiered(tester);
      await tapVisible(tester, find.byIcon(Icons.add_circle_outline));

      await enter(tester, _loan, '500000000');
      await enter(tester, _year, '2');
      await enter(tester, 'Bunga (%)', '4', index: 0);
      await enter(tester, 'Bunga (%)', '5', index: 1);
      await enter(tester, 'Bunga Pinjaman', '10');

      await tapVisible(tester, find.text('Hitung Simulasi'));
      expect(find.text('Tahun bunga fix terlalu banyak'), findsOneWidget);
    });

    testWidgets('hitung berjenjang membuka tabel angsuran', (tester) async {
      await openTiered(tester);
      await tapVisible(tester, find.byIcon(Icons.add_circle_outline));

      await enter(tester, _loan, '500000000');
      await enter(tester, _year, '10');
      await enter(tester, 'Bunga (%)', '4', index: 0);
      await enter(tester, 'Bunga (%)', '6', index: 1);
      await enter(tester, 'Bunga Pinjaman', '10');

      await tapVisible(tester, find.text('Hitung Simulasi'));
      expect(find.byType(PrincipalTable), findsOneWidget);
      expect(find.text('Rp. 500.000.000'), findsOneWidget);

      final rows = installmentTableTiered(
        CalculatorType.anuitas,
        CalculateModel(
          fixYear: 2,
          floatingInterest: 10,
          initialLoan: 500000000,
          dpNominal: 0,
          loanPlafon: 500000000,
          loan: 500000000,
          year: 10,
          interest: 10,
        ),
        [4, 6],
      );
      expect(rows, hasLength(120));
      await tapText(tester, 'Tabel');
      expect(find.text(currencyId.format(rows.first.installmentResult)),
          findsWidgets);
    });
  });
}
