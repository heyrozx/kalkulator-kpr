import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:kalkulator_kpr/blocs/purchase_cubit/purchase_cubit.dart';
import 'package:kalkulator_kpr/core/theme.dart';
import 'package:kalkulator_kpr/models/simulation_history.dart';
import 'package:kalkulator_kpr/pages/home/home_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Status RevenueCat palsu yang dipakai seluruh integration test.
///
/// Semua plugin native (RevenueCat, AdMob) diganti mock di level channel supaya
/// test bisa berjalan deterministik di perangkat mana pun — termasuk Linux
/// desktop yang tidak punya implementasi plugin tersebut — dan tidak pernah
/// memicu pembelian atau impresi iklan sungguhan.
class FakeStore {
  /// Entitlement premium aktif saat `getCustomerInfo` dipanggil.
  static bool premium = false;

  /// Kalau `true`, `getCustomerInfo` gagal seperti saat perangkat offline.
  static bool offline = false;

  /// Hasil `restorePurchases`: `null` = gagal menghubungi store.
  static bool? restoreGrantsPremium = false;

  /// Nama method RevenueCat yang dipanggil, untuk diperiksa test.
  static final List<String> calls = [];

  static void reset() {
    premium = false;
    offline = false;
    restoreGrantsPremium = false;
    calls.clear();
  }
}

/// Nama method AdMob yang dipanggil (mis. `loadBannerAd`).
final List<String> adCalls = [];

const String _purchasesChannel = 'purchases_flutter';
const String _adsChannel = 'plugins.flutter.io/google_mobile_ads';

Map<String, dynamic> customerInfoJson({required bool premium}) {
  const String date = '2026-01-01T00:00:00Z';
  final Map<String, dynamic> entitlement = {
    'identifier': 'premium',
    'isActive': true,
    'willRenew': true,
    'latestPurchaseDate': date,
    'originalPurchaseDate': date,
    'productIdentifier': 'kpr_premium',
    'isSandbox': true,
    'ownershipType': 'PURCHASED',
    'store': 'PLAY_STORE',
    'periodType': 'NORMAL',
    'verification': 'NOT_REQUESTED',
  };
  final Map<String, dynamic> entitlements =
      premium ? {'premium': entitlement} : <String, dynamic>{};

  return {
    'entitlements': {
      'all': entitlements,
      'active': entitlements,
      'verification': 'NOT_REQUESTED',
    },
    'allPurchaseDates': <String, dynamic>{},
    'activeSubscriptions': <String>[],
    'allPurchasedProductIdentifiers':
        premium ? <String>['kpr_premium'] : <String>[],
    'nonSubscriptionTransactions': <dynamic>[],
    'firstSeen': date,
    'originalAppUserId': 'integration-test-user',
    'allExpirationDates': <String, dynamic>{},
    'requestDate': date,
  };
}

void _installPlatformMocks() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  messenger.setMockMethodCallHandler(
    const MethodChannel(_purchasesChannel),
    (call) async {
      FakeStore.calls.add(call.method);
      switch (call.method) {
        case 'getCustomerInfo':
          if (FakeStore.offline) {
            throw PlatformException(code: '10', message: 'Network error');
          }
          return customerInfoJson(premium: FakeStore.premium);
        case 'restorePurchases':
          final bool? grants = FakeStore.restoreGrantsPremium;
          if (grants == null) {
            throw PlatformException(code: '10', message: 'Network error');
          }
          if (grants) FakeStore.premium = true;
          return customerInfoJson(premium: grants);
        default:
          return null;
      }
    },
  );

  // AdMob memakai codec khusus. Pesannya tidak perlu dibaca: cukup balas
  // "sukses tanpa nilai" sehingga iklan tidak pernah selesai dimuat dan alur
  // aplikasi berjalan seperti saat iklan belum tersedia.
  const StandardMethodCodec codec = StandardMethodCodec();
  messenger.setMockMessageHandler(_adsChannel, (ByteData? message) async {
    try {
      adCalls.add(codec.decodeMethodCall(message).method);
    } catch (_) {
      // Argumen berisi objek khusus AdMob yang tidak bisa didekode codec baku.
      adCalls.add('<ads>');
    }
    return codec.encodeSuccessEnvelope(null);
  });
}

Directory? _hiveDir;

/// Dipanggil sekali per file test: mock plugin dan Hive di folder sementara.
Future<void> setUpIntegration() async {
  _installPlatformMocks();
  PackageInfo.setMockInitialValues(
    appName: 'Kalkulator KPR',
    packageName: 'com.caraguna.kalkulator.kpr',
    version: '9.9.9',
    buildNumber: '99',
    buildSignature: '',
  );

  _hiveDir ??= await Directory.systemTemp.createTemp('kpr_integration_');
  Hive.init(_hiveDir!.path);
  if (!Hive.isAdapterRegistered(SimulationHistoryAdapter.id)) {
    Hive.registerAdapter(SimulationHistoryAdapter());
  }
}

/// Mengosongkan riwayat simulasi supaya tiap test mulai dari kondisi bersih.
Future<void> clearHistory() async {
  final box = await Hive.openLazyBox<SimulationHistory>('simulation_history');
  await box.clear();
}

/// Ukuran layar ponsel umum (1080x2340 @3x) supaya layout sama dengan yang
/// dilihat pengguna, apa pun ukuran jendela/perangkat tempat test berjalan.
void usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Menyusun pohon widget yang sama dengan `MyApp` (provider + tema + beranda)
/// tanpa `UpgradeAlert`, yang memeriksa versi terbaru ke Play Store lewat
/// internet.
Future<PurchaseCubit> pumpKprApp(WidgetTester tester) async {
  usePhoneScreen(tester);
  final PurchaseCubit cubit = PurchaseCubit()..checkPremium();
  await tester.pumpWidget(
    BlocProvider<PurchaseCubit>.value(
      value: cubit,
      child: MaterialApp(
        title: 'Kalkulator KPR',
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        home: const MyHomePage(title: 'Kalkulator KPR'),
      ),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(cubit.close);
  return cubit;
}

// ---------------------------------------------------------------------------
// Helper interaksi
// ---------------------------------------------------------------------------

/// Field input berdasarkan teks labelnya.
Finder field(String label) => find.widgetWithText(TextFormField, label);

Future<void> enter(WidgetTester tester, String label, String text,
    {int index = 0}) async {
  final Finder target = field(label).at(index);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.enterText(target, text);
  await tester.pumpAndSettle();
}

/// Teks yang sedang tertulis di field berlabel [label].
String fieldText(WidgetTester tester, String label, {int index = 0}) {
  final TextFormField widget =
      tester.widget<TextFormField>(field(label).at(index));
  return widget.controller!.text;
}

Future<void> tapText(WidgetTester tester, String text) async {
  final Finder target = find.text(text).hitTestable().first;
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> openDrawer(WidgetTester tester) async {
  tester.state<ScaffoldState>(find.byType(Scaffold).first).openDrawer();
  await tester.pumpAndSettle();
}

Future<void> openDrawerItem(WidgetTester tester, String title) async {
  await openDrawer(tester);
  await tester.tap(find.widgetWithText(ListTile, title));
  await tester.pumpAndSettle();
}

Future<void> goBack(WidgetTester tester) async {
  final NavigatorState navigator =
      tester.state<NavigatorState>(find.byType(Navigator).first);
  navigator.pop();
  await tester.pumpAndSettle();
}

/// Menunggu snackbar hilang supaya tidak bertumpuk dengan langkah berikutnya.
Future<void> dismissSnackbars(WidgetTester tester) async {
  ScaffoldMessenger.of(tester.element(find.byType(Scaffold).last))
      .clearSnackBars();
  await tester.pumpAndSettle();
}
