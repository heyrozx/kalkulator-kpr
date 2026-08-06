import 'package:intl/intl.dart';

/// Format angka untuk **ditampilkan** memakai konvensi Indonesia:
/// `1000000` menjadi `1.000.000` (dibulatkan, tanpa angka desimal).
final NumberFormat currencyId =
    NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0);

/// Formatter yang dipakai `ThousandsFormatter` pada field input nominal,
/// supaya angka yang diketik pengguna memakai pemisah ribuan yang sama dengan
/// angka yang ditampilkan aplikasi.
final NumberFormat inputNumberFormat = NumberFormat.decimalPattern('id');

/// Utilitas mengubah teks dari field input kembali menjadi angka.
///
/// Field nominal (jumlah pinjaman, DP, jangka waktu) hanya berisi digit dan
/// pemisah ribuan, sedangkan field persen (bunga, DP %) boleh memuat satu
/// pemisah desimal — koma maupun titik sama-sama diterima supaya pengguna tidak
/// tergantung pada tata letak keyboard.
class CurrencyFormat {
  const CurrencyFormat._();

  /// Ambil bilangan bulat dari teks; semua karakter selain digit dibuang.
  /// Mengembalikan `"0"` untuk teks kosong sehingga aman untuk `double.parse`.
  static String toNumber(String? number) {
    final digitsOnly = (number ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    return digitsOnly.isEmpty ? '0' : digitsOnly;
  }

  /// Ambil bilangan desimal dari teks. Pemisah desimal yang dipakai adalah
  /// karakter `,`/`.` **terakhir**; kemunculan sebelumnya dianggap pemisah
  /// ribuan. Contoh: `"1.234,5"` dan `"1,234.5"` sama-sama menjadi `1234.5`.
  static String toNumberComma(String? number) {
    final raw = (number ?? '').replaceAll(RegExp(r'[^0-9.,]'), '');
    if (raw.isEmpty) return '0';

    final lastSeparator = raw.lastIndexOf(RegExp(r'[.,]'));
    if (lastSeparator < 0) return raw;

    final intPart =
        raw.substring(0, lastSeparator).replaceAll(RegExp(r'[.,]'), '');
    final decimalPart =
        raw.substring(lastSeparator + 1).replaceAll(RegExp(r'[.,]'), '');
    if (decimalPart.isEmpty) return intPart.isEmpty ? '0' : intPart;

    return '${intPart.isEmpty ? '0' : intPart}.$decimalPart';
  }

  /// Versi aman dari `double.parse(CurrencyFormat.toNumber(...))`.
  static double parseNumber(String? number) =>
      double.tryParse(toNumber(number)) ?? 0;

  /// Versi aman dari `double.parse(CurrencyFormat.toNumberComma(...))`.
  static double parseDecimal(String? number) =>
      double.tryParse(toNumberComma(number)) ?? 0;

  /// Format angka untuk dimasukkan kembali ke `TextEditingController`.
  static String formatNumber(num value) => inputNumberFormat.format(value);
}
