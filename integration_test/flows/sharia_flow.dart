import 'package:flutter_test/flutter_test.dart';
import 'package:kalkulator_kpr/core/currency_format.dart';
import 'package:kalkulator_kpr/core/helpers.dart';
import 'package:kalkulator_kpr/models/calculate_model.dart';
import 'package:kalkulator_kpr/pages/about/sharia_description.dart';
import 'package:kalkulator_kpr/pages/principle/principal_table.dart';
import 'package:kalkulator_kpr/pages/sharia/sharia_screen.dart';

import '../support/test_app.dart';

const String _year = 'Jangka Waktu (Tahun)';

CalculateModel _model() => CalculateModel(
      initialLoan: 550000000,
      dpNominal: 50000000,
      loanPlafon: 500000000,
      loan: 500000000,
      year: 15,
      interest: 7.5,
    );

String _rp(double value) => 'Rp ${currencyId.format(value)}';

Future<void> _openSharia(WidgetTester tester) async {
  await pumpKprApp(tester);
  await openDrawerItem(tester, 'KPR Syariah');
  expect(find.byType(ShariaScreen), findsOneWidget);
}

void shariaFlow() {
  group('KPR Syariah', () {
    testWidgets('murabahah: pratinjau harga jual lalu buka tabel',
        (tester) async {
      await _openSharia(tester);

      await enter(tester, 'Harga Rumah (Rp)', '550000000');
      await enter(tester, 'Uang Muka (Rp)', '50000000');
      expect(fieldText(tester, 'Harga Pokok (Rp)'), '500.000.000');
      expect(find.text('Harga Jual'), findsNothing);

      await enter(tester, _year, '15');
      await enter(tester, 'Margin per Tahun', '7,5');

      final InstallmentSummary summary =
          summarizeInstallments(installmentTableMurabahah(_model()));
      // 500 jt + margin 7,5% x 15 th = 1,0625 M.
      expect(summary.totalPayment, closeTo(1062500000, 1));

      expect(find.text('Harga Jual'), findsOneWidget);
      expect(find.text(_rp(summary.totalPayment)), findsOneWidget);
      expect(find.text(_rp(summary.totalInterest)), findsOneWidget);
      expect(find.text(_rp(summary.firstInstallment)), findsOneWidget);
      expect(find.text('180 kali angsuran'), findsOneWidget);

      await tapVisible(tester, find.text('Hitung Simulasi'));
      expect(find.byType(PrincipalTable), findsOneWidget);
      expect(find.text('Akad'), findsOneWidget);
    });

    testWidgets('murabahah: validasi memakai istilah akad', (tester) async {
      await _openSharia(tester);
      await tapVisible(tester, find.text('Hitung Simulasi'));

      expect(find.text('Harga Rumah tidak boleh kosong'), findsOneWidget);
      expect(find.text('Margin harus lebih besar dari 0'), findsOneWidget);
      expect(find.byType(PrincipalTable), findsNothing);
    });

    testWidgets('MMQ: pratinjau angsuran menurun lalu buka tabel',
        (tester) async {
      await _openSharia(tester);
      await tapText(tester, 'Musyarakah MQ');

      await enter(tester, 'Harga Rumah (Rp)', '550000000');
      await enter(tester, 'Porsi Nasabah (Rp)', '50000000');
      expect(fieldText(tester, 'Porsi Bank (Rp)'), '500.000.000');
      await enter(tester, _year, '15');
      await enter(tester, 'Nisbah Sewa per Tahun', '7,5');

      final InstallmentSummary summary =
          summarizeInstallments(installmentTableEffective(_model()));
      expect(find.text('Angsuran Bulan Pertama'), findsOneWidget);
      expect(find.text(_rp(summary.firstInstallment)), findsOneWidget);
      expect(find.text(_rp(summary.lastInstallment)), findsOneWidget);
      expect(summary.firstInstallment, greaterThan(summary.lastInstallment));

      await tapVisible(tester, find.text('Hitung Simulasi'));
      expect(find.byType(PrincipalTable), findsOneWidget);
    });

    testWidgets('penjelasan akad bisa dibuka', (tester) async {
      await _openSharia(tester);
      await tester.tap(find.byTooltip('Penjelasan akad'));
      await tester.pumpAndSettle();
      expect(find.byType(ShariaDescription), findsOneWidget);
    });
  });
}
