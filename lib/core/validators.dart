import 'package:kalkulator_kpr/core/config.dart';
import 'package:kalkulator_kpr/core/currency_format.dart';

/// Validator input yang dipakai bersama oleh layar utama dan layar Advanced.
///
/// Sebelumnya tiap layar punya aturannya sendiri: layar utama hanya menolak
/// teks kosong sehingga bunga `0` lolos dan membuat rumus anuitas membagi nol
/// (menghasilkan `NaN` yang kemudian meng-crash layar tabel angsuran).
class Validators {
  const Validators._();

  // Parameter [label] membuat pesan galat ikut memakai istilah layar yang
  // memanggilnya — layar syariah tidak menyebut "pinjaman" atau "bunga".
  // Semuanya punya nilai default sehingga tetap bisa dipakai sebagai tear-off
  // (`validator: Validators.loan`) seperti sebelumnya.

  static String? loan(String? value, {String label = 'Jumlah pinjaman'}) {
    final loan = CurrencyFormat.parseNumber(value);
    if (loan <= 0) return '$label tidak boleh kosong';
    return null;
  }

  static String? year(String? value) {
    final year = CurrencyFormat.parseNumber(value);
    if (year <= 0) return 'Jangka waktu tidak boleh kosong';
    if (year < AppConfig.minLoanYear) {
      return 'Jangka waktu minimal ${AppConfig.minLoanYear} tahun';
    }
    if (year > AppConfig.maxLoanYear) {
      return 'Jangka waktu maksimal ${AppConfig.maxLoanYear} tahun';
    }
    return null;
  }

  static String? interest(String? value, {String label = 'Bunga pinjaman'}) {
    final interest = CurrencyFormat.parseDecimal(value);
    if (interest <= 0) return '$label harus lebih besar dari 0';
    if (interest > AppConfig.maxInterestPercent) {
      return '$label maksimal ${AppConfig.maxInterestPercent.toInt()}%';
    }
    return null;
  }

  /// DP boleh kosong (dianggap 0), tetapi tidak boleh melebihi jumlah pinjaman
  /// karena akan membuat total pinjaman menjadi negatif.
  static String? dpNominal(
    String? value, {
    required String? loanText,
    String label = 'DP',
    String ofLabel = 'jumlah pinjaman',
  }) {
    final dp = CurrencyFormat.parseNumber(value);
    if (dp < 0) return '$label tidak boleh negatif';
    final loanAmount = CurrencyFormat.parseNumber(loanText);
    if (loanAmount > 0 && dp > loanAmount) {
      return '$label tidak boleh melebihi $ofLabel';
    }
    return null;
  }

  /// Total pinjaman setelah dikurangi DP harus tetap positif.
  static String? loanAfterDp(String? value, {String label = 'Total pinjaman'}) {
    final total = CurrencyFormat.parseNumber(value);
    if (total <= 0) return '$label harus lebih besar dari 0';
    return null;
  }
}
