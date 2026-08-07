import 'package:kalkulator_kpr/models/calculate_model.dart';

/// Akad pembiayaan yang dipakai sebuah simulasi.
///
/// Menentukan istilah yang dipakai di seluruh penyajian hasil. Ini bukan
/// kosmetik: menyebut imbalan bank sebagai "bunga" pada akad syariah keliru
/// secara akad, karena murabahah memungut **margin jual beli** dan musyarakah
/// mutanaqisah memungut **sewa (ujrah)** atas porsi yang masih dimiliki bank.
enum FinancingContract { conventional, murabahah, mmq }

extension FinancingContractInfo on FinancingContract {
  String get label => switch (this) {
        FinancingContract.conventional => 'Konvensional',
        FinancingContract.murabahah => 'Murabahah',
        FinancingContract.mmq => 'Musyarakah Mutanaqisah',
      };

  /// Versi pendek untuk chip riwayat dan judul yang ruangnya sempit.
  String get shortLabel => switch (this) {
        FinancingContract.conventional => 'Konvensional',
        FinancingContract.murabahah => 'Murabahah',
        FinancingContract.mmq => 'Musyarakah MQ',
      };

  bool get isSharia => this != FinancingContract.conventional;

  InstallmentTerms get terms => switch (this) {
        FinancingContract.conventional => InstallmentTerms.conventional,
        FinancingContract.murabahah => InstallmentTerms.murabahah,
        FinancingContract.mmq => InstallmentTerms.mmq,
      };
}

/// Pola angsuran musyarakah mutanaqisah.
///
/// Keduanya dipakai di praktik perbankan syariah dan secara perhitungan sama
/// persis dengan mesin efektif dan anuitas yang sudah ada — yang berbeda hanya
/// akad dan penamaannya.
enum MmqPattern {
  /// Porsi yang dibeli nasabah tetap tiap bulan, sewa menyusut mengikuti porsi
  /// bank yang tersisa, sehingga total angsuran menurun.
  decreasing,

  /// Total angsuran dikunci; komposisi porsi dan sewa yang bergeser.
  fixed,
}

extension MmqPatternInfo on MmqPattern {
  String get label => switch (this) {
        MmqPattern.decreasing => 'Angsuran Menurun',
        MmqPattern.fixed => 'Angsuran Tetap',
      };

  String get shortLabel => switch (this) {
        MmqPattern.decreasing => 'Menurun',
        MmqPattern.fixed => 'Tetap',
      };

  String get description => switch (this) {
        MmqPattern.decreasing =>
          'Porsi yang dibeli tetap tiap bulan; sewa mengecil seiring porsi bank '
              'menyusut.',
        MmqPattern.fixed =>
          'Total angsuran sama tiap bulan; porsi yang dibeli membesar dan sewa '
              'mengecil.',
      };

  /// Mesin perhitungan yang menghasilkan pola ini.
  CalculatorType get engine => switch (this) {
        MmqPattern.decreasing => CalculatorType.effective,
        MmqPattern.fixed => CalculatorType.anuitas,
      };
}

/// Kebalikan dari [MmqPatternInfo.engine]; dipakai saat membaca riwayat yang
/// hanya menyimpan mesin perhitungannya.
MmqPattern mmqPatternOf(CalculatorType type) =>
    type == CalculatorType.anuitas ? MmqPattern.fixed : MmqPattern.decreasing;

/// Istilah kolom dan label hasil untuk satu akad.
class InstallmentTerms {
  const InstallmentTerms({
    required this.principal,
    required this.principalShort,
    required this.principalColumn,
    required this.charge,
    required this.chargeShort,
    required this.chargeColumn,
    required this.totalCharge,
    required this.remaining,
    required this.remainingColumn,
    required this.rate,
    required this.financing,
  });

  /// Bagian angsuran yang mengurangi kewajiban pokok.
  final String principal;
  final String principalShort;

  /// Versi dua baris untuk header kolom tabel yang sempit.
  final String principalColumn;

  /// Imbalan yang diterima bank: bunga, margin, atau sewa.
  final String charge;
  final String chargeShort;
  final String chargeColumn;
  final String totalCharge;

  /// Kewajiban yang belum dibayar.
  final String remaining;
  final String remainingColumn;

  /// Label persentase pada form dan ringkasan.
  final String rate;

  /// Nilai yang dibiayai bank.
  final String financing;

  String get installment => 'Jumlah Angsuran';
  String get installmentColumn => 'Jumlah\nAngsuran';

  /// Judul grafik komposisi, mis. "Pokok vs Bunga".
  String get compositionTitle => '$principalShort vs $chargeShort';

  static const InstallmentTerms conventional = InstallmentTerms(
    principal: 'Angsuran Pokok',
    principalShort: 'Pokok',
    principalColumn: 'Angsuran\nPokok',
    charge: 'Bunga',
    chargeShort: 'Bunga',
    chargeColumn: 'Bunga',
    totalCharge: 'Total Bunga',
    remaining: 'Sisa Pinjaman',
    remainingColumn: 'Sisa\nPinjaman',
    rate: 'Bunga',
    financing: 'Total Pinjaman',
  );

  static const InstallmentTerms murabahah = InstallmentTerms(
    principal: 'Angsuran Pokok',
    principalShort: 'Pokok',
    principalColumn: 'Angsuran\nPokok',
    charge: 'Margin',
    chargeShort: 'Margin',
    chargeColumn: 'Margin',
    totalCharge: 'Total Margin',
    // Dalam murabahah utang nasabah adalah harga jual yang sudah disepakati di
    // muka, bukan pokok yang berbunga.
    remaining: 'Sisa Harga Jual',
    remainingColumn: 'Sisa Harga\nJual',
    rate: 'Margin',
    financing: 'Harga Pokok',
  );

  static const InstallmentTerms mmq = InstallmentTerms(
    principal: 'Porsi Dibeli',
    principalShort: 'Porsi',
    principalColumn: 'Porsi\nDibeli',
    charge: 'Sewa (Ujrah)',
    chargeShort: 'Sewa',
    chargeColumn: 'Sewa\n(Ujrah)',
    totalCharge: 'Total Sewa',
    remaining: 'Sisa Porsi Bank',
    remainingColumn: 'Sisa Porsi\nBank',
    rate: 'Nisbah Sewa',
    financing: 'Porsi Bank',
  );
}
