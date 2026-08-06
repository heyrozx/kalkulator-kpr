import 'dart:math';

import 'package:kalkulator_kpr/models/calculate_model.dart';

const int monthsPerYear = 12;

/// Jumlah bulan dari jangka waktu (tahun). Selalu bilangan bulat supaya
/// eksponen anuitas dan jumlah baris tabel tidak pernah berbeda.
int totalMonthsOf(double? year) {
  final months = ((year ?? 0) * monthsPerYear).round();
  return months > 0 ? months : 0;
}

/// Bunga per bulan dari bunga tahunan dalam persen.
double monthlyRateOf(double? annualInterestPercent) {
  final rate = (annualInterestPercent ?? 0) * 0.01 / monthsPerYear;
  return rate.isFinite && rate > 0 ? rate : 0;
}

CalculateResultModel _zeroResult() =>
    CalculateResultModel(installmentResult: 0, principal: 0, interestResult: 0);

double _plafonOf(CalculateModel model) => model.loanPlafon ?? model.loan ?? 0;

// Jumlah pinjaman yang dihitung adalah pinjaman awal (plafon)
CalculateResultModel calculateFlat(CalculateModel calculateModel) {
  final int month = totalMonthsOf(calculateModel.year);
  if (month == 0) return _zeroResult();

  final double principal = _plafonOf(calculateModel) / month;
  final double interestResult =
      (calculateModel.loan ?? 0) * monthlyRateOf(calculateModel.interest);

  return CalculateResultModel(
      installmentResult: principal + interestResult,
      principal: principal,
      interestResult: interestResult);
}

// Jumlah pinjaman yang dihitung adalah sisa pinjaman
CalculateResultModel calculateEffective(CalculateModel calculateModel) {
  final int month = totalMonthsOf(calculateModel.year);
  if (month == 0) return _zeroResult();

  final double principal = _plafonOf(calculateModel) / month;
  final double interestResult =
      (calculateModel.loan ?? 0) * monthlyRateOf(calculateModel.interest);

  return CalculateResultModel(
      installmentResult: principal + interestResult,
      principal: principal,
      interestResult: interestResult);
}

CalculateResultModel calculateAnuitas(CalculateModel calculateModel) {
  final int month = totalMonthsOf(calculateModel.year);
  if (month == 0) return _zeroResult();

  final double plafon = _plafonOf(calculateModel);
  final double monthlyRate = monthlyRateOf(calculateModel.interest);

  // Bunga 0 membuat pembagi ((1+i)^n - 1) menjadi nol. Secara matematis
  // angsurannya adalah pokok dibagi rata, jadi tangani terpisah agar tidak
  // menghasilkan NaN yang menjalar ke seluruh tabel angsuran.
  if (monthlyRate == 0) {
    final double principal = plafon / month;
    return CalculateResultModel(
        installmentResult: principal, principal: principal, interestResult: 0);
  }

  final double growth = pow(1 + monthlyRate, month).toDouble();
  final double installmentResult =
      (plafon * monthlyRate * growth) / (growth - 1);
  final double interestResult = (calculateModel.loan ?? 0) * monthlyRate;
  final double principal = installmentResult - interestResult;

  if (!installmentResult.isFinite) return _zeroResult();

  return CalculateResultModel(
      installmentResult: installmentResult,
      principal: principal,
      interestResult: interestResult);
}

CalculateResultModel _calculateBy(
    CalculatorType type, CalculateModel calculateModel) {
  switch (type) {
    case CalculatorType.flat:
      return calculateFlat(calculateModel);
    case CalculatorType.effective:
      return calculateEffective(calculateModel);
    case CalculatorType.anuitas:
      return calculateAnuitas(calculateModel);
  }
}

List<CalculateResultModel> installmentTableFlat(CalculateModel calculateModel) {
  final int month = totalMonthsOf(calculateModel.year);
  double loan = calculateModel.loan ?? 0;

  final List<CalculateResultModel> data = [];
  for (var i = 0; i < month; i++) {
    // Bunga flat tidak mengikuti sisa pinjaman, jadi model tidak dimutakhirkan.
    final CalculateResultModel result = calculateFlat(calculateModel);
    loan = loan - (result.principal ?? 0);
    result.principalTotalRemain = loan;
    data.add(result);
  }
  return data;
}

List<CalculateResultModel> installmentTableEffective(
    CalculateModel calculateModel) {
  final int month = totalMonthsOf(calculateModel.year);
  // Bekerja di atas salinan supaya model milik pemanggil tidak ikut berubah.
  final CalculateModel work = calculateModel.copyWith();
  double loan = work.loan ?? 0;

  final List<CalculateResultModel> data = [];
  for (var i = 0; i < month; i++) {
    final CalculateResultModel result = calculateEffective(work);
    loan = loan - (result.principal ?? 0);
    result.principalTotalRemain = loan;
    data.add(result);

    work.loan = loan;
  }

  return data;
}

List<CalculateResultModel> installmentTableAnuitas(
    CalculateModel calculateModel) {
  final int month = totalMonthsOf(calculateModel.year);
  final CalculateModel work = calculateModel.copyWith();
  double loan = work.loan ?? 0;

  final List<CalculateResultModel> data = [];
  for (var i = 0; i < month; i++) {
    final CalculateResultModel result = calculateAnuitas(work);
    loan = loan - (result.principal ?? 0);
    result.principalTotalRemain = loan;
    data.add(result);

    work.loan = loan;
  }

  return data;
}

List<CalculateResultModel> installmentTableFixFloating(
    CalculatorType type, CalculateModel calculateModel) {
  final List<CalculateResultModel> data = [];
  final CalculateModel work = calculateModel.copyWith();

  final int totalMonths = totalMonthsOf(work.year);
  final int fixMonths = min(totalMonthsOf(work.fixYear), totalMonths);
  final int floatingMonths = totalMonths - fixMonths;

  double loan = work.loan ?? 0;

  // === Periode FIX ===
  work.interest = work.fixInterest;
  for (int i = 0; i < fixMonths; i++) {
    final CalculateResultModel result = _calculateBy(type, work);
    loan = loan - (result.principal ?? 0);
    result.principalTotalRemain = loan;
    data.add(result);

    work.loan = loan;
  }

  // Sisa pinjaman menjadi plafon baru dan tenor dihitung ulang (re-amortisasi).
  work.loanPlafon = loan;
  work.year = (work.year ?? 0) - (fixMonths / monthsPerYear);
  work.interest = work.floatingInterest;

  // === Periode FLOATING ===
  for (int i = 0; i < floatingMonths; i++) {
    final CalculateResultModel result = _calculateBy(type, work);
    loan = loan - (result.principal ?? 0);
    result.principalTotalRemain = loan;
    data.add(result);

    work.loan = loan;
  }

  return data;
}

List<CalculateResultModel> installmentTableTiered(CalculatorType type,
    CalculateModel calculateModel, List<double> tieredInterest) {
  final List<CalculateResultModel> data = [];
  final CalculateModel work = calculateModel.copyWith();
  work.fixYear = tieredInterest.length.toDouble();

  final int totalMonths = totalMonthsOf(work.year);
  final int fixMonths = min(tieredInterest.length * monthsPerYear, totalMonths);
  final int floatingMonths = totalMonths - fixMonths;

  double loan = work.loan ?? 0;
  int monthsDone = 0;

  // === Periode FIX (satu tarif bunga untuk tiap tahun) ===
  for (var tier = 0; tier < tieredInterest.length; tier++) {
    work.interest = tieredInterest[tier];
    for (int i = 0; i < monthsPerYear && monthsDone < fixMonths; i++) {
      final CalculateResultModel result = _calculateBy(type, work);
      loan = loan - (result.principal ?? 0);
      result.principalTotalRemain = loan;
      data.add(result);

      work.loan = loan;
      monthsDone++;
    }
    // Re-amortisasi tiap pergantian tahun bunga.
    work.loanPlafon = loan;
    work.year = (work.year ?? 0) - 1;
  }

  work.loanPlafon = loan;
  work.interest = work.floatingInterest;

  // === Periode FLOATING ===
  for (int i = 0; i < floatingMonths; i++) {
    final CalculateResultModel result = _calculateBy(type, work);
    loan = loan - (result.principal ?? 0);
    result.principalTotalRemain = loan;
    data.add(result);

    work.loan = loan;
  }

  return data;
}

/// Menjumlahkan salah satu kolom tabel angsuran dengan aman.
///
/// Nilai non-finite (`NaN`/`Infinity`) dilewati — `NaN.toInt()` melempar
/// `UnsupportedError` dan sebelumnya meng-crash layar tabel angsuran.
double sumOf(List<CalculateResultModel> results,
    double? Function(CalculateResultModel) select) {
  double total = 0;
  for (final result in results) {
    final value = select(result);
    if (value != null && value.isFinite) total += value;
  }
  return total;
}
