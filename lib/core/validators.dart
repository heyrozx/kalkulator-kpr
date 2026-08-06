import 'package:kalkulator_kpr/core/config.dart';
import 'package:kalkulator_kpr/core/currency_format.dart';

/// Validator input yang dipakai bersama oleh layar utama dan layar Advanced.
///
/// Sebelumnya tiap layar punya aturannya sendiri: layar utama hanya menolak
/// teks kosong sehingga bunga `0` lolos dan membuat rumus anuitas membagi nol
/// (menghasilkan `NaN` yang kemudian meng-crash layar tabel angsuran).
class Validators {
  const Validators._();

  static String? loan(String? value) {
    final loan = CurrencyFormat.parseNumber(value);
    if (loan <= 0) return 'Jumlah pinjaman tidak boleh kosong';
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

  static String? interest(String? value) {
    final interest = CurrencyFormat.parseDecimal(value);
    if (interest <= 0) return 'Bunga pinjaman harus lebih besar dari 0';
    if (interest > AppConfig.maxInterestPercent) {
      return 'Bunga maksimal ${AppConfig.maxInterestPercent.toInt()}%';
    }
    return null;
  }

  /// DP boleh kosong (dianggap 0), tetapi tidak boleh melebihi jumlah pinjaman
  /// karena akan membuat total pinjaman menjadi negatif.
  static String? dpNominal(String? value, {required String? loanText}) {
    final dp = CurrencyFormat.parseNumber(value);
    if (dp < 0) return 'DP tidak boleh negatif';
    final loanAmount = CurrencyFormat.parseNumber(loanText);
    if (loanAmount > 0 && dp > loanAmount) {
      return 'DP tidak boleh melebihi jumlah pinjaman';
    }
    return null;
  }

  /// Total pinjaman setelah dikurangi DP harus tetap positif.
  static String? loanAfterDp(String? value) {
    final total = CurrencyFormat.parseNumber(value);
    if (total <= 0) return 'Total pinjaman harus lebih besar dari 0';
    return null;
  }
}
