import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalkulator_kpr/core/helpers.dart';
import 'package:kalkulator_kpr/core/simulation_history_repository.dart';
import 'package:kalkulator_kpr/models/calculate_model.dart';
import 'package:kalkulator_kpr/models/simulation_history.dart';
import 'package:kalkulator_kpr/pages/history/history_screen.dart';
import 'package:kalkulator_kpr/pages/principle/principal_table.dart';

import '../support/test_app.dart';

Future<void> _seedHistory(int count) async {
  for (var i = 0; i < count; i++) {
    final model = CalculateModel(
      loanPlafon: 300000000,
      loan: 300000000,
      year: 10,
      interest: 8,
    );
    await SimulationHistoryRepository.instance.save(
      SimulationHistory.fromCalculation(
        name: 'Seed ${i + 1}',
        type: CalculatorType.anuitas,
        model: model,
        summary: summarizeInstallments(installmentTableAnuitas(model)),
      ),
    );
  }
}

Future<void> _openTableFromHome(WidgetTester tester) async {
  await enter(tester, 'Jumlah Pinjaman (Rp)', '500000000');
  await enter(tester, 'Jangka Waktu (Tahun)', '15');
  await enter(tester, 'Bunga Pinjaman', '7,5');
  await tapText(tester, 'Hitung Simulasi');
  await tapText(tester, 'Tabel Angsuran');
  expect(find.byType(PrincipalTable), findsOneWidget);
}

Future<void> _saveWithName(WidgetTester tester, String name) async {
  await tester.tap(find.byTooltip('Simpan ke riwayat'));
  await tester.pumpAndSettle();
  expect(find.text('Simpan Simulasi'), findsOneWidget);
  await tester.enterText(
      find.descendant(
          of: find.byType(AlertDialog), matching: find.byType(TextField)),
      name);
  await tester.tap(find.widgetWithText(FilledButton, 'Simpan'));
  await tester.pumpAndSettle();
}

void historyFlow() {
  group('Riwayat simulasi', () {
    setUp(clearHistory);

    testWidgets('riwayat kosong menampilkan petunjuk', (tester) async {
      await pumpKprApp(tester);
      await openDrawerItem(tester, 'Riwayat Simulasi');
      expect(find.byType(HistoryScreen), findsOneWidget);
      expect(find.text('Belum ada simulasi tersimpan'), findsOneWidget);
    });

    testWidgets('simpan dari tabel angsuran lalu tampil di riwayat',
        (tester) async {
      await pumpKprApp(tester);
      await _openTableFromHome(tester);

      await _saveWithName(tester, 'KPR Rumah Pertama');
      expect(find.text('Tersimpan'), findsOneWidget);
      expect(find.byTooltip('Sudah tersimpan di riwayat'), findsOneWidget);
      await dismissSnackbars(tester);

      // Simpan dua kali tidak menduplikasi.
      await tester.tap(find.byTooltip('Sudah tersimpan di riwayat'));
      await tester.pumpAndSettle();
      expect(find.text('Sudah Tersimpan'), findsOneWidget);
      expect(await SimulationHistoryRepository.instance.count(), 1);
      await dismissSnackbars(tester);

      await goBack(tester);
      await openDrawerItem(tester, 'Riwayat Simulasi');
      expect(find.text('KPR Rumah Pertama'), findsOneWidget);
      expect(find.text('1 dari 3 simulasi tersimpan'), findsOneWidget);

      // Membuka kembali simulasi tersimpan.
      await tester.tap(find.text('KPR Rumah Pertama'));
      await tester.pumpAndSettle();
      expect(find.byType(PrincipalTable), findsOneWidget);
      expect(find.text('Rp. 500.000.000'), findsOneWidget);
      expect(find.byTooltip('Sudah tersimpan di riwayat'), findsOneWidget);
    });

    testWidgets('nama kosong diganti nama usulan', (tester) async {
      await pumpKprApp(tester);
      await _openTableFromHome(tester);
      await _saveWithName(tester, '   ');

      final page = await SimulationHistoryRepository.instance.load();
      expect(page.items.single.name, startsWith('Anuitas'));
      expect(page.items.single.name, contains('15 thn'));
    });

    testWidgets('ubah nama dan hapus simulasi', (tester) async {
      await _seedHistory(2);
      await pumpKprApp(tester);
      await openDrawerItem(tester, 'Riwayat Simulasi');

      // Terbaru di atas.
      final double y1 = tester.getTopLeft(find.text('Seed 1')).dy;
      final double y2 = tester.getTopLeft(find.text('Seed 2')).dy;
      expect(y2, lessThan(y1));

      await tester.tap(find.byTooltip('Menu simulasi').first);
      await tester.pumpAndSettle();
      await tapText(tester, 'Ubah Nama');
      await tester.enterText(
          find.descendant(
              of: find.byType(AlertDialog), matching: find.byType(TextField)),
          'Rumah Impian');
      await tester.tap(find.widgetWithText(FilledButton, 'Simpan'));
      await tester.pumpAndSettle();
      expect(find.text('Rumah Impian'), findsOneWidget);
      expect(find.text('Seed 2'), findsNothing);
      await dismissSnackbars(tester);

      await tester.tap(find.byTooltip('Menu simulasi').first);
      await tester.pumpAndSettle();
      await tapText(tester, 'Hapus');
      expect(find.text('Hapus Simulasi'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Hapus'));
      await tester.pumpAndSettle();

      expect(find.text('Rumah Impian'), findsNothing);
      expect(find.text('Seed 1'), findsOneWidget);
      expect(find.text('1 dari 3 simulasi tersimpan'), findsOneWidget);
      expect(await SimulationHistoryRepository.instance.count(), 1);
    });

    testWidgets('kuota gratis penuh menampilkan dialog', (tester) async {
      await _seedHistory(SimulationHistoryRepository.freeLimit);
      await pumpKprApp(tester);
      await _openTableFromHome(tester);

      await tester.tap(find.byTooltip('Simpan ke riwayat'));
      await tester.pumpAndSettle();
      expect(find.text('Riwayat Penuh'), findsOneWidget);

      await tapText(tester, 'Nanti');
      expect(find.text('Riwayat Penuh'), findsNothing);
      expect(await SimulationHistoryRepository.instance.count(),
          SimulationHistoryRepository.freeLimit);
    });

    testWidgets('pengguna premium bisa menyimpan melewati kuota',
        (tester) async {
      FakeStore.premium = true;
      await _seedHistory(SimulationHistoryRepository.freeLimit);
      await pumpKprApp(tester);
      await _openTableFromHome(tester);

      await _saveWithName(tester, 'Simulasi Premium');
      expect(find.text('Tersimpan'), findsOneWidget);
      await dismissSnackbars(tester);

      await goBack(tester);
      await openDrawerItem(tester, 'Riwayat Simulasi');
      expect(find.text('4 simulasi tersimpan'), findsOneWidget);
      expect(find.text('Tanpa batas'), findsNothing);
    });
  });
}
