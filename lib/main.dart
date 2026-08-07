import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kalkulator_kpr/app.dart';
import 'package:kalkulator_kpr/core/error_reporter.dart';
import 'package:kalkulator_kpr/core/purchases.dart';
import 'package:kalkulator_kpr/core/simulation_history_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Dipasang sedini mungkin supaya error saat inisialisasi pun ikut terlaporkan.
  ErrorReporter.install();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  // Kegagalan konfigurasi RevenueCat (mis. perangkat tanpa Play Services) tidak
  // boleh membuat aplikasi gagal terbuka — kalkulatornya tetap bisa dipakai.
  await ErrorReporter.guard(() => Purchase().initPlatformState(),
      hint: 'Purchases.configure');

  // Sama halnya dengan penyimpanan riwayat: kalau gagal disiapkan, layar
  // riwayat yang menampilkan pesan galat, bukan aplikasi yang gagal terbuka.
  await ErrorReporter.guard(() => SimulationHistoryRepository.init(),
      hint: 'Hive.init');

  runApp(const MyApp());
}
