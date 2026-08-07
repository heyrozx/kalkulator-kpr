import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:kalkulator_kpr/core/helpers.dart';
import 'package:kalkulator_kpr/core/simulation_history_repository.dart';
import 'package:kalkulator_kpr/models/calculate_model.dart';
import 'package:kalkulator_kpr/models/simulation_history.dart';

CalculateModel _anuitasModel() => CalculateModel(
      loanPlafon: 500000000,
      loan: 500000000,
      year: 15,
      interest: 7.5,
    );

SimulationHistory _entry(String name, {List<double>? tiers}) {
  final CalculateModel model = _anuitasModel();
  if (tiers != null) {
    model.floatingInterest = 12;
    model.initialLoan = 550000000;
    model.dpNominal = 50000000;
  }
  final results = installmentTableAnuitas(model);
  return SimulationHistory.fromCalculation(
    name: name,
    type: CalculatorType.anuitas,
    model: model,
    summary: summarizeInstallments(results),
    tieredInterest: tiers,
  );
}

void main() {
  group('ringkasan & agregasi tabel angsuran', () {
    final results = installmentTableAnuitas(_anuitasModel());

    test('ringkasan menjumlahkan seluruh 180 bulan', () {
      final summary = summarizeInstallments(results);

      expect(summary.months, 180);
      // Pokok yang diangsur habis persis sebesar plafon.
      expect(summary.totalPrincipal, closeTo(500000000, 1));
      expect(summary.totalPayment,
          closeTo(summary.totalPrincipal + summary.totalInterest, 1));
      // Anuitas: angsuran per bulan tetap dari awal sampai akhir.
      expect(summary.isVarying, isFalse);
      expect(summary.firstInstallment, closeTo(summary.lastInstallment, 1));
    });

    test('ringkasan tidak pernah menghasilkan NaN untuk tabel kosong', () {
      final summary = summarizeInstallments(const []);
      expect(summary.totalPayment, 0);
      expect(summary.interestRatio, 0);
    });

    test('agregasi per tahun menghasilkan satu titik per tahun', () {
      final years = yearlyBreakdown(results);

      expect(years.length, 15);
      expect(years.first.year, 1);
      expect(years.last.year, 15);
      // Sisa pinjaman menyusut, dan di akhir tenor habis.
      expect(years.first.remaining, greaterThan(years.last.remaining));
      expect(years.last.remaining, closeTo(0, 1));
      // Total per tahun sama dengan total keseluruhan.
      final double totalPrincipal =
          years.fold(0.0, (sum, year) => sum + year.principal);
      expect(totalPrincipal, closeTo(500000000, 1));
    });
  });

  group('record riwayat', () {
    test('bolak-balik map mempertahankan seluruh input dan ringkasan', () {
      final original = _entry('BTN 15 tahun', tiers: const [5, 6, 7]);
      final restored = SimulationHistory.fromMap(original.toMap());

      expect(restored.name, original.name);
      expect(restored.type, original.type);
      expect(restored.scheme, SimulationScheme.tiered);
      expect(restored.loanPlafon, original.loanPlafon);
      expect(restored.initialLoan, original.initialLoan);
      expect(restored.dpNominal, original.dpNominal);
      expect(restored.year, original.year);
      expect(restored.interest, original.interest);
      expect(restored.floatingInterest, original.floatingInterest);
      expect(restored.tieredInterest, const [5.0, 6.0, 7.0]);
      expect(restored.totalInterest, closeTo(original.totalInterest, 0.001));
      expect(restored.createdAt.millisecondsSinceEpoch,
          original.createdAt.millisecondsSinceEpoch);
    });

    test('field yang hilang jatuh ke nilai default, bukan melempar exception',
        () {
      final restored = SimulationHistory.fromMap({'name': 'Lama'});

      expect(restored.name, 'Lama');
      expect(restored.type, CalculatorType.anuitas);
      expect(restored.scheme, SimulationScheme.simple);
      expect(restored.loanPlafon, 0);
      expect(restored.tieredInterest, isEmpty);
    });

    test('tabel angsuran dibangun ulang persis seperti hasil aslinya', () {
      final model = _anuitasModel();
      final expected = installmentTableAnuitas(model);
      final entry = SimulationHistory.fromCalculation(
        name: 'Uji',
        type: CalculatorType.anuitas,
        model: model,
        summary: summarizeInstallments(expected),
      );

      final rebuilt = SimulationHistory.fromMap(entry.toMap()).buildTable();

      expect(rebuilt.length, expected.length);
      expect(rebuilt.first.installmentResult,
          closeTo(expected.first.installmentResult!, 0.001));
      expect(rebuilt.last.principalTotalRemain,
          closeTo(expected.last.principalTotalRemain!, 0.001));
    });
  });

  group('penyimpanan & pagination', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('kpr_history_test');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(SimulationHistoryAdapter.id)) {
        Hive.registerAdapter(SimulationHistoryAdapter());
      }
    });

    tearDown(() async {
      await Hive.deleteFromDisk();
      await Hive.close();
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('record tersimpan dan terbaca kembali lewat adapter Hive', () async {
      final repository = SimulationHistoryRepository.instance;
      await repository.save(_entry('Simulasi A'));

      final page = await repository.load();

      expect(page.total, 1);
      expect(page.items.single.name, 'Simulasi A');
      expect(page.items.single.id, isNotNull);
      expect(page.items.single.loanPlafon, 500000000);
    });

    test('halaman berisi paling banyak `size` record, terbaru lebih dulu',
        () async {
      final repository = SimulationHistoryRepository.instance;
      for (var i = 1; i <= 25; i++) {
        await repository.save(_entry('Simulasi $i'));
      }

      final first = await repository.load(page: 0, size: 10);
      expect(first.items.length, 10);
      expect(first.total, 25);
      expect(first.hasMore, isTrue);
      expect(first.items.first.name, 'Simulasi 25');
      expect(first.items.last.name, 'Simulasi 16');

      final last = await repository.load(page: 2, size: 10);
      expect(last.items.length, 5);
      expect(last.hasMore, isFalse);
      expect(last.items.last.name, 'Simulasi 1');

      // Halaman di luar jangkauan tidak melempar exception.
      final beyond = await repository.load(page: 9, size: 10);
      expect(beyond.items, isEmpty);
      expect(beyond.hasMore, isFalse);
    });

    test('ubah nama dan hapus mengubah isi box', () async {
      final repository = SimulationHistoryRepository.instance;
      final entry = _entry('Nama Lama');
      await repository.save(entry);

      await repository.rename(entry, 'Nama Baru');
      expect((await repository.load()).items.single.name, 'Nama Baru');

      await repository.delete(entry);
      final page = await repository.load();
      expect(page.items, isEmpty);
      expect(page.total, 0);
    });

    test('kuota gratis penuh tepat pada batas', () async {
      final repository = SimulationHistoryRepository.instance;
      for (var i = 0; i < SimulationHistoryRepository.freeLimit - 1; i++) {
        await repository.save(_entry('Simulasi $i'));
      }
      expect(await repository.isFreeQuotaFull(), isFalse);

      await repository.save(_entry('Terakhir'));
      expect(await repository.isFreeQuotaFull(), isTrue);
    });
  });
}
