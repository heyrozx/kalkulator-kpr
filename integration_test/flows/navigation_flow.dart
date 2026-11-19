import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalkulator_kpr/pages/about/anuitas_description.dart';
import 'package:kalkulator_kpr/pages/about/disclaimer.dart';
import 'package:kalkulator_kpr/pages/about/effective_description.dart';
import 'package:kalkulator_kpr/pages/about/flat_description.dart';
import 'package:kalkulator_kpr/pages/about/sharia_description.dart';
import 'package:kalkulator_kpr/pages/settings/settings_screen.dart';
import 'package:kalkulator_kpr/shared/widgets/premium_tab.dart';

import '../support/test_app.dart';

void navigationFlow() {
  group('Bantuan', () {
    final Map<String, Type> pages = {
      'Bunga Anuitas': AnuitasDescription,
      'Bunga Efektif': EffectiveDescription,
      'Bunga Flat': FlatDescription,
      'KPR Syariah': ShariaDescription,
      'Disklaimer': Disclaimer,
    };

    testWidgets('setiap halaman bantuan bisa dibuka', (tester) async {
      await pumpKprApp(tester);
      for (final MapEntry<String, Type> page in pages.entries) {
        await openDrawerItem(tester, 'Bantuan');
        expect(find.text('Bantuan'), findsWidgets);
        await tester.tap(find.widgetWithText(ListTile, page.key).last);
        await tester.pumpAndSettle();
        expect(find.byType(page.value), findsOneWidget,
            reason: '${page.key} harus membuka ${page.value}');
        await goBack(tester);
      }
    });
  });

  group('Pengaturan & premium', () {
    testWidgets('pengguna gratis: ajakan upgrade dan versi aplikasi',
        (tester) async {
      await pumpKprApp(tester);
      final PremiumTab tab = tester.widget(find.byType(PremiumTab));
      expect(tab.isPremium, isFalse);

      await openDrawerItem(tester, 'Pengaturan');
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Bebas Iklan'), findsOneWidget);
      expect(find.text('Premium Aktif'), findsNothing);
      expect(find.text('9.9.9'), findsOneWidget);

      await tapText(tester, 'Disklaimer');
      expect(find.byType(Disclaimer), findsOneWidget);
    });

    testWidgets('pulihkan pembelian berhasil mengaktifkan premium',
        (tester) async {
      FakeStore.restoreGrantsPremium = true;
      await pumpKprApp(tester);
      await openDrawerItem(tester, 'Pengaturan');

      await tapText(tester, 'Pulihkan Pembelian');
      expect(find.text('Berhasil'), findsOneWidget);
      expect(find.text('Premium Aktif'), findsOneWidget);
      expect(FakeStore.calls, contains('restorePurchases'));

      await goBack(tester);
      final PremiumTab tab = tester.widget(find.byType(PremiumTab));
      expect(tab.isPremium, isTrue);
    });

    testWidgets('pulihkan pembelian tanpa pembelian', (tester) async {
      FakeStore.restoreGrantsPremium = false;
      await pumpKprApp(tester);
      await openDrawerItem(tester, 'Pengaturan');

      await tapText(tester, 'Pulihkan Pembelian');
      expect(find.text('Tidak Ditemukan'), findsOneWidget);
      expect(find.text('Bebas Iklan'), findsOneWidget);
    });

    testWidgets('pulihkan pembelian gagal saat offline', (tester) async {
      FakeStore.restoreGrantsPremium = null;
      await pumpKprApp(tester);
      await openDrawerItem(tester, 'Pengaturan');

      await tapText(tester, 'Pulihkan Pembelian');
      expect(find.text('Gagal'), findsOneWidget);
    });

    testWidgets('pengguna premium: tanpa iklan dan tanpa kunci PDF',
        (tester) async {
      FakeStore.premium = true;
      adCalls.clear();
      await pumpKprApp(tester);

      final PremiumTab tab = tester.widget(find.byType(PremiumTab));
      expect(tab.isPremium, isTrue);

      await enter(tester, 'Jumlah Pinjaman (Rp)', '500000000');
      await enter(tester, 'Jangka Waktu (Tahun)', '15');
      await enter(tester, 'Bunga Pinjaman', '7,5');
      await tapText(tester, 'Hitung Simulasi');
      await tapText(tester, 'Tabel Angsuran');

      // Ikon premium (tab upgrade) tidak muncul di tabel angsuran.
      expect(find.byType(PremiumTab), findsNothing);
      // Tidak ada iklan yang dimuat sama sekali untuk pengguna premium.
      expect(adCalls, isEmpty);

      await goBack(tester);
      await openDrawerItem(tester, 'Pengaturan');
      expect(find.text('Premium Aktif'), findsOneWidget);
    });

    testWidgets('pengguna gratis memuat iklan banner', (tester) async {
      adCalls.clear();
      await pumpKprApp(tester);
      await openDrawerItem(tester, 'Advanced');
      expect(adCalls, isNotEmpty);
    });

    testWidgets('offline: status premium tidak tertahan', (tester) async {
      FakeStore.offline = true;
      final cubit = await pumpKprApp(tester);
      expect(cubit.isUnknown, isFalse);
      expect(cubit.isPremium(), isFalse);
      // Kalkulator tetap bisa dipakai.
      await enter(tester, 'Jumlah Pinjaman (Rp)', '100000000');
      await enter(tester, 'Jangka Waktu (Tahun)', '5');
      await enter(tester, 'Bunga Pinjaman', '6');
      await tapText(tester, 'Hitung Simulasi');
      expect(find.text('Tabel Angsuran'), findsOneWidget);
    });
  });
}
