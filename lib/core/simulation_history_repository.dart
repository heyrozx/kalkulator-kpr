import 'dart:math';

import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:kalkulator_kpr/models/simulation_history.dart';

/// Satu halaman riwayat.
class SimulationHistoryPage {
  const SimulationHistoryPage({
    required this.items,
    required this.total,
    required this.hasMore,
  });

  final List<SimulationHistory> items;

  /// Jumlah seluruh riwayat tersimpan, bukan hanya halaman ini.
  final int total;
  final bool hasMore;

  static const SimulationHistoryPage empty =
      SimulationHistoryPage(items: [], total: 0, hasMore: false);
}

/// Penyimpanan riwayat simulasi di atas Hive.
///
/// Memakai [LazyBox]: isi record baru dibaca dari disk saat benar-benar
/// diminta, jadi membuka layar riwayat tidak pernah memuat seluruh database ke
/// memori — hanya satu halaman ([pageSize] record) sekali baca, berapa pun
/// banyaknya simulasi tersimpan.
class SimulationHistoryRepository {
  SimulationHistoryRepository._();

  static final SimulationHistoryRepository instance =
      SimulationHistoryRepository._();

  static const String _boxName = 'simulation_history';

  /// Batas riwayat untuk pengguna gratis; premium tanpa batas.
  static const int freeLimit = 3;

  static const int pageSize = 20;

  LazyBox<SimulationHistory>? _box;
  Future<LazyBox<SimulationHistory>>? _opening;

  /// Dipanggil sekali dari `main()` sebelum `runApp`.
  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(SimulationHistoryAdapter.id)) {
      Hive.registerAdapter(SimulationHistoryAdapter());
    }
  }

  /// Membuka box sekali saja. Panggilan yang tumpang tindih (mis. layar riwayat
  /// dibuka sementara tombol simpan sedang memeriksa kuota) berbagi satu proses
  /// buka yang sama.
  Future<LazyBox<SimulationHistory>> _open() {
    final LazyBox<SimulationHistory>? box = _box;
    if (box != null && box.isOpen) return Future.value(box);

    return _opening ??= Hive.openLazyBox<SimulationHistory>(_boxName)
        .then((opened) => _box = opened)
        .whenComplete(() => _opening = null);
  }

  Future<int> count() async => (await _open()).length;

  /// `true` kalau kuota gratis sudah penuh. Pemanggil yang premium tidak perlu
  /// memanggil ini sama sekali.
  Future<bool> isFreeQuotaFull() async => (await count()) >= freeLimit;

  /// Membaca satu halaman riwayat, terbaru lebih dulu.
  ///
  /// Kunci Hive bersifat auto-increment sehingga urutan kunci menurun sama
  /// dengan urutan waktu simpan menurun — tidak perlu membaca isi record hanya
  /// untuk mengurutkannya.
  Future<SimulationHistoryPage> load({
    int page = 0,
    int size = pageSize,
  }) async {
    final box = await _open();
    final List<int> keys = box.keys.whereType<int>().toList()
      ..sort((a, b) => b.compareTo(a));

    final int start = page * size;
    if (start >= keys.length) {
      return SimulationHistoryPage(
          items: const [], total: keys.length, hasMore: false);
    }

    final int end = min(start + size, keys.length);
    final List<SimulationHistory> items = [];
    for (var i = start; i < end; i++) {
      final SimulationHistory? entry = await box.get(keys[i]);
      if (entry == null) continue;
      entry.id = keys[i];
      items.add(entry);
    }

    return SimulationHistoryPage(
      items: items,
      total: keys.length,
      hasMore: end < keys.length,
    );
  }

  /// Menyimpan simulasi baru dan mengembalikan kuncinya.
  Future<int> save(SimulationHistory entry) async {
    final box = await _open();
    final int key = await box.add(entry);
    entry.id = key;
    return key;
  }

  Future<void> rename(SimulationHistory entry, String name) async {
    final int? key = entry.id;
    if (key == null) return;
    entry.name = name;
    await (await _open()).put(key, entry);
  }

  Future<void> delete(SimulationHistory entry) async {
    final int? key = entry.id;
    if (key == null) return;
    await (await _open()).delete(key);
  }
}
