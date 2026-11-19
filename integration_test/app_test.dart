// Integration test end-to-end Kalkulator KPR.
//
// Jalankan di perangkat/emulator Android:
//   flutter test integration_test/app_test.dart
// atau di Linux desktop (perlu folder `linux/` hasil `flutter create
// --platforms=linux .` dan display, mis. lewat xvfb-run):
//   xvfb-run flutter test integration_test/app_test.dart -d linux
//
// Semua alur digabung ke satu file supaya aplikasi hanya di-build sekali.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'flows/advanced_flow.dart';
import 'flows/history_flow.dart';
import 'flows/home_flow.dart';
import 'flows/navigation_flow.dart';
import 'flows/sharia_flow.dart';
import 'support/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(setUpIntegration);
  setUp(FakeStore.reset);

  homeFlow();
  advancedFlow();
  shariaFlow();
  historyFlow();
  navigationFlow();
}
