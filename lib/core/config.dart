import 'package:flutter/foundation.dart';

/// Penempatan banner ad. Setiap penempatan punya ad unit id sendiri supaya
/// performa tiap layar bisa dibaca terpisah di dashboard AdMob.
enum BannerPlacement {
  flatDescription,
  anuitasDescription,
  effectiveDescription,
  principalTable,
  advancedPage,
}

/// Konfigurasi terpusat aplikasi: kunci layanan pihak ketiga, tautan, dan
/// batasan input. Sebelumnya nilai-nilai ini tersebar di dalam widget.
class AppConfig {
  const AppConfig._();

  // --- RevenueCat ---
  /// Public SDK key RevenueCat (aman berada di sisi klien).
  static const String revenueCatApiKey = 'goog_TxHpvzIsxQmjdMVokLRhsiMObAV';

  /// Nama entitlement yang menandakan pengguna premium.
  ///
  /// Tampilan & daftar paket paywall tidak lagi ditulis di kode — semuanya
  /// diatur dari dashboard RevenueCat (lihat `pages/premiums/premium_paywall.dart`).
  static const String premiumEntitlement = 'premium';

  // --- Tautan ---
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.caraguna.kalkulator.kpr&hl=en';
  static const String privacyPolicyUrl =
      'https://nexadream.id/privacy-policy-kalkulator-kpr-simulasi-kredit';
  static const String contactUrl = 'https://nexadream.id/contact';

  // --- Batasan input ---
  /// Jangka waktu maksimum. Membatasi tenor mencegah tabel angsuran raksasa
  /// (mis. salah ketik "1.000" tahun = 12.000 baris) yang membekukan UI.
  static const int maxLoanYear = 40;
  static const int minLoanYear = 1;

  /// Bunga dibatasi > 0 karena bunga 0 membuat rumus anuitas membagi nol.
  static const double maxInterestPercent = 100;

  /// Batas atas masa kredit fix pada layar Fix & Floating (slider).
  static const double maxFixYear = 15;
}

/// Ad unit id AdMob. Saat [kDebugMode] selalu memakai test unit id resmi Google
/// supaya tidak pernah ada impresi/klik palsu ke akun produksi.
class AdConfig {
  const AdConfig._();

  static const String _testBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitial =
      'ca-app-pub-3940256099942544/1033173712';

  static const String _homeInterstitial =
      'ca-app-pub-2465007971338713/3842103086';

  static const Map<BannerPlacement, String> _banners = {
    BannerPlacement.flatDescription: 'ca-app-pub-2465007971338713/7887856855',
    BannerPlacement.anuitasDescription:
        'ca-app-pub-2465007971338713/1541940350',
    BannerPlacement.effectiveDescription:
        'ca-app-pub-2465007971338713/1849062116',
    BannerPlacement.principalTable: 'ca-app-pub-2465007971338713/9945891754',
    BannerPlacement.advancedPage: 'ca-app-pub-2465007971338713/2784671586',
  };

  static String banner(BannerPlacement? placement) {
    if (kDebugMode || placement == null) return _testBanner;
    return _banners[placement] ?? _testBanner;
  }

  static String get interstitial =>
      kDebugMode ? _testInterstitial : _homeInterstitial;
}
