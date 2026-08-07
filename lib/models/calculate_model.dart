class CalculateModel {
  double? loanPlafon, loan, year, interest, initialLoan, dpNominal;

  double? fixInterest;
  double? fixYear;
  double? floatingInterest;

  CalculateModel(
      {this.loan,
      this.initialLoan,
      this.dpNominal,
      this.loanPlafon,
      this.year,
      this.interest,
      this.fixInterest,
      this.fixYear,
      this.floatingInterest});

  /// Salinan model. Dipakai oleh `core/helpers.dart` supaya proses membangun
  /// tabel angsuran — yang perlu memutakhirkan sisa pinjaman, plafon, tenor,
  /// dan bunga di tiap iterasi — tidak pernah mengubah model milik pemanggil.
  CalculateModel copyWith({
    double? loan,
    double? initialLoan,
    double? dpNominal,
    double? loanPlafon,
    double? year,
    double? interest,
    double? fixInterest,
    double? fixYear,
    double? floatingInterest,
  }) {
    return CalculateModel(
      loan: loan ?? this.loan,
      initialLoan: initialLoan ?? this.initialLoan,
      dpNominal: dpNominal ?? this.dpNominal,
      loanPlafon: loanPlafon ?? this.loanPlafon,
      year: year ?? this.year,
      interest: interest ?? this.interest,
      fixInterest: fixInterest ?? this.fixInterest,
      fixYear: fixYear ?? this.fixYear,
      floatingInterest: floatingInterest ?? this.floatingInterest,
    );
  }
}

class CalculateResultModel {
  double? installmentResult, interestResult, principal, principalTotalRemain;

  CalculateResultModel(
      {this.installmentResult,
      this.interestResult,
      this.principal,
      this.principalTotalRemain});
}

enum CalculatorType { flat, effective, anuitas }

extension CalculatorTypeLabel on CalculatorType {
  /// Nama jenis perhitungan sebagaimana ditampilkan ke pengguna.
  String get label => switch (this) {
        CalculatorType.flat => 'Flat',
        CalculatorType.effective => 'Efektif',
        CalculatorType.anuitas => 'Anuitas',
      };
}
