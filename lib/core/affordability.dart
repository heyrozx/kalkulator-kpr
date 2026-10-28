import 'package:kalkulator_kpr/models/calculate_model.dart';

/// Tingkat beban cicilan terhadap penghasilan.
enum AffordabilityLevel {
  /// Rasio cicilan ≤ 30%: batas yang umum dipakai bank untuk menyetujui KPR.
  safe('Aman'),

  /// 30% < rasio ≤ 40%: masih mungkin disetujui, tapi ruang keuangan sempit.
  caution('Waspada'),

  /// Rasio > 40%: umumnya ditolak bank dan berisiko mengganggu keuangan.
  heavy('Berat');

  const AffordabilityLevel(this.label);
  final String label;
}

/// Hasil cek kemampuan bayar untuk satu simulasi.
class Affordability {
  const Affordability({
    required this.income,
    required this.otherDebt,
    required this.installment,
  });

  /// Batas rasio cicilan yang dianggap aman.
  static const double safeRatio = 0.30;

  /// Batas atas rasio sebelum dianggap berat.
  static const double cautionRatio = 0.40;

  /// Penghasilan bersih per bulan.
  final double income;

  /// Cicilan lain yang sudah berjalan per bulan (kendaraan, kartu kredit, dll).
  final double otherDebt;

  /// Angsuran KPR yang dinilai: angsuran tertinggi selama tenor, karena bank
  /// menilai kemampuan bayar pada bulan terberat.
  final double installment;

  double get totalDebt => installment + otherDebt;

  /// Porsi penghasilan yang habis untuk seluruh cicilan, 0..∞.
  double get ratio {
    if (income <= 0) return 0;
    final double value = totalDebt / income;
    return value.isFinite ? value : 0;
  }

  AffordabilityLevel get level {
    if (ratio <= safeRatio) return AffordabilityLevel.safe;
    if (ratio <= cautionRatio) return AffordabilityLevel.caution;
    return AffordabilityLevel.heavy;
  }

  /// Penghasilan minimal supaya rasio cicilan tetap di batas aman.
  double get minimumIncome => totalDebt / safeRatio;

  /// Sisa penghasilan setelah semua cicilan dibayar. Bisa negatif.
  double get remainingIncome => income - totalDebt;
}

/// Angsuran tertinggi selama tenor. Pada anuitas semua bulan sama; pada bunga
/// efektif bulan pertama yang terberat; pada fix & floating bisa bulan setelah
/// masa fix berakhir.
double highestInstallment(List<CalculateResultModel> results) {
  double highest = 0;
  for (final row in results) {
    final double value = row.installmentResult ?? 0;
    if (value.isFinite && value > highest) highest = value;
  }
  return highest;
}
