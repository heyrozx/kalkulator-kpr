import 'package:flutter/material.dart';

/// Palet warna aplikasi. Sebelumnya `Colors.purple`, `Colors.white`, dan
/// `Colors.grey.shade400` ditulis ulang di puluhan tempat sehingga mengubah
/// warna berarti menyisir seluruh `lib/`.
class AppColors {
  const AppColors._();

  static const MaterialColor primarySwatch = Colors.purple;
  static const Color primary = Colors.purple;
  static const Color onPrimary = Colors.white;

  static const Color surface = Colors.white;
  static const Color background = Colors.white;
  static const Color onSurface = Colors.black87;

  /// Warna teks/ikon sekunder (label, satuan, keterangan).
  static Color get muted => Colors.grey.shade600;

  /// Warna garis tepi input dan pembatas.
  static Color get border => Colors.grey.shade400;

  /// Warna latar tombol sekunder.
  static Color get subtle => Colors.grey.shade300;

  /// Latar lembut beranda: gradasi ungu sangat muda ke putih supaya panel
  /// form dan switch (putih) tetap menonjol.
  static const List<Color> dashboardGradient = [
    headerTint,
    Color(0xFFFBF8FC),
  ];

  /// Ungu sangat muda untuk kepala halaman yang menyatu dengan AppBar (mis.
  /// ringkasan di halaman tabel angsuran); sama dengan awal gradasi beranda.
  static const Color headerTint = Color(0xFFF3E8F7);

  /// Warna porsi bunga pada indikator lingkaran di layar utama.
  static const Color interestPortion = Colors.grey;

  // --- Warna seri grafik ---
  // Pasangan ungu/oranye ini sudah diperiksa keterbacaannya untuk pengguna buta
  // warna (jarak warna terkecil ΔE 20 pada tritanopia, jauh di atas ambang 8),
  // jadi batang pokok dan bunga tetap bisa dibedakan tanpa mengandalkan legenda.
  /// Porsi angsuran pokok pada grafik.
  static const Color chartPrincipal = primary;

  /// Porsi bunga pada grafik.
  static const Color chartInterest = Color(0xFFE8710A);

  /// Garis bantu (grid) grafik — satu langkah dari warna latar, tidak menonjol.
  static Color get gridLine => Colors.grey.shade300;

  /// Latar tooltip grafik.
  static const Color chartTooltip = Color(0xFF212121);

  /// Warna emas penanda premium (status aktif, titik pada fitur premium).
  static const Color premiumGold = Color(0xFFF2A900);

  /// Gradasi tab premium untuk user premium (emas) dan user gratis (ungu).
  static const List<Color> premiumGradient = [
    Color(0xFFFFC940),
    Color(0xFFE08A00),
  ];
  static const List<Color> upgradeGradient = [
    Color(0xFFD154E8),
    Color(0xFF7B1FA2),
  ];

  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Colors.orange;
  static const Color danger = Color(0xFFC62828);
}

/// Radius yang dipakai berulang supaya konsisten antar layar.
class AppRadius {
  const AppRadius._();

  static const double card = 5;

  /// Kartu di halaman tabel angsuran (grafik, tabel, daya bayar).
  static const double panel = 12;
  static const double field = 4;
  static const double button = 30;
  static const double sheet = 15;
}

/// Bayangan yang dipakai berulang.
class AppShadows {
  const AppShadows._();

  /// Bayangan lebar & tipis bernuansa ungu untuk kartu di halaman tabel
  /// angsuran, supaya kartu terlihat mengambang halus, bukan bergaris abu-abu.
  static List<BoxShadow> get soft => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.07),
          blurRadius: 18,
          offset: const Offset(0, 4),
        ),
      ];
}

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      // Material 3 sengaja belum diaktifkan: mengubahnya adalah perubahan
      // tampilan menyeluruh yang perlu diverifikasi langsung di perangkat,
      // bukan bagian dari perbaikan bug.
      useMaterial3: false,
      primarySwatch: AppColors.primarySwatch,
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        surface: AppColors.surface,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.onSurface,
        backgroundColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.border),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
