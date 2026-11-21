import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalkulator_kpr/core/currency_format.dart';
import 'package:kalkulator_kpr/core/helpers.dart';
import 'package:kalkulator_kpr/models/calculate_model.dart';
import 'package:kalkulator_kpr/models/financing_contract.dart';
import 'package:kalkulator_kpr/pages/principle/principal_table.dart';

import '../support/test_app.dart';

const String _loan = 'Jumlah Pinjaman (Rp)';
const String _year = 'Jangka Waktu (Tahun)';
const String _interest = 'Bunga Pinjaman';

CalculateModel _model() => CalculateModel(
      loanPlafon: 500000000,
      loan: 500000000,
      year: 15,
      interest: 7.5,
    );

final _terms = FinancingContract.conventional.terms;

String _rp(double? value) => 'Rp ${currencyId.format(value ?? 0)}';

Future<void> _fillForm(WidgetTester tester,
    {String loan = '500000000',
    String year = '15',
    String interest = '7,5'}) async {
  await enter(tester, _loan, loan);
  await enter(tester, _year, year);
  await enter(tester, _interest, interest);
}

void homeFlow() {
  group('Beranda: kalkulator utama', () {
    testWidgets('form kosong menampilkan pesan validasi, tanpa hasil',
        (tester) async {
      await pumpKprApp(tester);

      expect(find.text('Kalkulator KPR'), findsOneWidget);
      expect(find.text('Rp 0'), findsWidgets);

      await tapText(tester, 'Hitung Simulasi');

      expect(find.text('Jumlah pinjaman tidak boleh kosong'), findsOneWidget);
      expect(find.text('Jangka waktu tidak boleh kosong'), findsOneWidget);
      expect(
          find.text('Bunga pinjaman harus lebih besar dari 0'), findsOneWidget);
      // Tombol tabel angsuran baru muncul setelah ada hasil.
      expect(find.text('Tabel Angsuran'), findsNothing);
    });

    testWidgets('batas tenor dan bunga ditolak', (tester) async {
      await pumpKprApp(tester);
      await _fillForm(tester, year: '50', interest: '150');
      await tapText(tester, 'Hitung Simulasi');

      expect(find.text('Jangka waktu maksimal 40 tahun'), findsOneWidget);
      expect(find.text('Bunga pinjaman maksimal 100%'), findsOneWidget);
      expect(find.text('Hitung Ulang'), findsNothing);
    });

    testWidgets('input pinjaman otomatis diberi pemisah ribuan',
        (tester) async {
      await pumpKprApp(tester);
      await enter(tester, _loan, '500000000');
      expect(fieldText(tester, _loan), '500.000.000');

      // Field bunga menerima koma maupun titik sebagai pemisah desimal dan
      // menolak huruf.
      await enter(tester, _interest, '7,5abc');
      expect(fieldText(tester, _interest), '7,5');
    });

    testWidgets('hitung anuitas menampilkan angsuran, pokok, dan bunga',
        (tester) async {
      await pumpKprApp(tester);
      await _fillForm(tester);
      await tapText(tester, 'Hitung Simulasi');

      final CalculateResultModel expected = calculateAnuitas(_model());
      // Rumus anuitas P·r / (1 − (1 + r)^−n) dihitung terpisah: Rp4.635.061,80.
      expect(expected.installmentResult, closeTo(4635061.80, 0.01));

      expect(find.text(_rp(expected.installmentResult)), findsOneWidget);
      expect(find.text(_rp(expected.principal)), findsOneWidget);
      expect(find.text(_rp(expected.interestResult)), findsOneWidget);
      expect(find.text('Per Bulan'), findsOneWidget);
      expect(find.text('Hitung Ulang'), findsOneWidget);
      expect(find.text('Tabel Angsuran'), findsOneWidget);
    });

    testWidgets('ganti metode bunga menghitung ulang otomatis', (tester) async {
      await pumpKprApp(tester);
      await _fillForm(tester);
      await tapText(tester, 'Hitung Simulasi');

      await tapText(tester, 'Efektif');
      final CalculateResultModel effective = calculateEffective(_model());
      expect(find.text(_rp(effective.installmentResult)), findsOneWidget);
      expect(find.text('Bulan Pertama'), findsOneWidget);

      await tapText(tester, 'Flat');
      final CalculateResultModel flat = calculateFlat(_model());
      expect(find.text(_rp(flat.installmentResult)), findsOneWidget);
      expect(find.text('Per Bulan'), findsOneWidget);

      await tapText(tester, 'Anuitas');
      final CalculateResultModel anuitas = calculateAnuitas(_model());
      expect(find.text(_rp(anuitas.installmentResult)), findsOneWidget);
    });

    testWidgets('ganti metode sebelum form lengkap tidak menghitung',
        (tester) async {
      await pumpKprApp(tester);
      await enter(tester, _loan, '500000000');
      await tapText(tester, 'Efektif');

      expect(find.text('Bulan Pertama'), findsOneWidget);
      expect(find.text('Hitung Simulasi'), findsOneWidget);
      // Validasi tidak dipicu oleh pergantian metode.
      expect(find.text('Jangka waktu tidak boleh kosong'), findsNothing);
    });

    testWidgets('tabel angsuran: ringkasan, grafik, tabel, dan daya bayar',
        (tester) async {
      await pumpKprApp(tester);
      await _fillForm(tester);
      await tapText(tester, 'Hitung Simulasi');
      await tapText(tester, 'Tabel Angsuran');

      expect(find.byType(PrincipalTable), findsOneWidget);
      expect(find.text('Anuitas'), findsWidgets);
      expect(find.text('Rp. 500.000.000'), findsOneWidget);
      // Bunga memakai koma desimal ala Indonesia.
      expect(find.text('7,5%'), findsOneWidget);
      expect(find.text('7.5%'), findsNothing);

      // Tab tabel: baris pertama sama dengan hasil helper.
      await tapText(tester, 'Tabel');
      final List<CalculateResultModel> rows = installmentTableAnuitas(_model());
      expect(rows, hasLength(180));
      expect(find.text(currencyId.format(rows.first.principal)), findsWidgets);
      expect(find.text(currencyId.format(rows.first.installmentResult)),
          findsWidgets);

      // Lebar kolom mengikuti isi: jarak antar-angka di satu baris tidak
      // boleh jauh lebih lebar dari padding sel (sebelumnya ada ruang kosong
      // lebar karena tabel dipaksa minimal 700 px dan dibagi rata).
      final Finder firstPrincipal =
          find.text(currencyId.format(rows.first.principal)).first;
      final Finder firstInterest =
          find.text(currencyId.format(rows.first.interestResult)).first;
      final double gap = tester.getTopLeft(firstInterest).dx -
          tester.getTopRight(firstPrincipal).dx;
      expect(gap, lessThan(60));

      // Header kolom yang menempel berjarak dari TabBar saat tabel digulir.
      await tester.dragFrom(
          tester.getCenter(firstPrincipal), const Offset(0, -500));
      await tester.pumpAndSettle();
      final double tabBottom = tester.getBottomLeft(find.byType(TabBar)).dy;
      final double headerTop =
          tester.getTopLeft(find.text(_terms.principalColumn).hitTestable()).dy;
      expect(headerTop - tabBottom, greaterThanOrEqualTo(8));

      // Tab daya bayar memuat form penghasilan.
      await tapText(tester, 'Daya Bayar');
      expect(find.text('Cek Daya Bayar'), findsOneWidget);

      // Penjelasan daya bayar tertutup secara bawaan dan bisa dibuka-tutup.
      const String about = 'Apa itu Daya Bayar?';
      expect(find.text(about), findsOneWidget);
      expect(find.text('≤30% Aman'), findsNothing);
      await tapText(tester, about);
      expect(find.text('≤30% Aman'), findsOneWidget);
      await tapText(tester, about);
      expect(find.text('≤30% Aman'), findsNothing);
      expect(field('Penghasilan Bersih per Bulan (Rp)'), findsOneWidget);

      await tapText(tester, 'Grafik');
      await goBack(tester);
      expect(find.byType(PrincipalTable), findsNothing);
      expect(find.text('Hitung Ulang'), findsOneWidget);
    });

    testWidgets('download & bagikan PDF terkunci untuk pengguna gratis',
        (tester) async {
      await pumpKprApp(tester);
      await _fillForm(tester);
      await tapText(tester, 'Hitung Simulasi');
      await tapText(tester, 'Tabel Angsuran');

      await tester.tap(find.byTooltip('Download PDF'));
      await tester.pumpAndSettle();
      expect(find.text('Upgrade premium untuk download tabel angsuran'),
          findsOneWidget);
      await dismissSnackbars(tester);

      await tester.tap(find.byTooltip('Bagikan PDF'));
      await tester.pumpAndSettle();
      expect(find.text('Upgrade premium untuk share tabel angsuran'),
          findsOneWidget);
    });
  });
}
