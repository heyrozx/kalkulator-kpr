import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kalkulator_kpr/core/config.dart';
import 'package:kalkulator_kpr/core/error_reporter.dart';

/// Mengelola satu slot interstitial ad: memuat, menampilkan, lalu **memuat
/// ulang** setelah iklan ditutup.
///
/// Sebelumnya iklan hanya dimuat sekali di `initState` dan tidak pernah
/// di-dispose maupun diisi ulang, sehingga paling banyak satu impresi per sesi
/// dan objek iklannya bocor.
class InterstitialAdManager {
  InterstitialAd? _ad;
  bool _isLoading = false;
  bool _isShowing = false;
  bool _disposed = false;

  bool get isReady => _ad != null;

  /// Batas percobaan saat id iklan bentrok. Hot restart biasanya hanya
  /// menyisakan satu-dua iklan lama, jadi beberapa percobaan sudah cukup.
  static const int _maxLoadAttempts = 4;

  Future<void> load() async {
    if (_disposed || _isLoading || _ad != null) return;
    _isLoading = true;
    await _loadAttempt(1);
  }

  Future<void> _loadAttempt(int attempt) async {
    try {
      await InterstitialAd.load(
        adUnitId: AdConfig.interstitial,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _isLoading = false;
            if (_disposed) {
              ad.dispose();
              return;
            }
            _ad = ad;
          },
          onAdFailedToLoad: (error) {
            _isLoading = false;
            ErrorReporter.report(error, null, hint: 'InterstitialAd.load');
          },
        ),
      );
    } on PlatformException catch (error, stack) {
      // Panggilan platform-nya sendiri bisa gagal sebelum callback di atas
      // pernah dipanggil. Kasus yang paling sering: "Ad for following adId
      // already exists" saat hot restart — sisi native masih memegang iklan
      // lama sementara penghitung id di sisi Dart kembali ke 0. Percobaan
      // berikutnya memakai objek iklan baru dengan id berikutnya, jadi
      // bentrokannya hilang sendiri setelah id lama terlewati.
      if (!_disposed && attempt < _maxLoadAttempts) {
        return _loadAttempt(attempt + 1);
      }
      _isLoading = false;
      ErrorReporter.report(error, stack, hint: 'InterstitialAd.load');
    }
  }

  /// Menampilkan iklan bila siap, lalu menjalankan [onDone] **setelah** iklan
  /// ditutup. Kalau iklan belum siap, [onDone] langsung dijalankan sehingga
  /// alur pengguna tidak pernah tertahan oleh iklan.
  void showThen(void Function() onDone) {
    final ad = _ad;
    if (_disposed || ad == null || _isShowing) {
      onDone();
      return;
    }

    _isShowing = true;
    _ad = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isShowing = false;
        onDone();
        load();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _isShowing = false;
        ErrorReporter.report(error, null, hint: 'InterstitialAd.show');
        onDone();
        load();
      },
    );

    ad.show();
  }

  void dispose() {
    _disposed = true;
    _ad?.dispose();
    _ad = null;
  }
}
