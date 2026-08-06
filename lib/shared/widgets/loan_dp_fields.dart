import 'package:flutter/material.dart';
import 'package:kalkulator_kpr/core/currency_format.dart';
import 'package:kalkulator_kpr/core/validators.dart';
import 'package:kalkulator_kpr/shared/widgets/labeled_number_field.dart';

/// Kumpulan controller untuk blok input "jumlah pinjaman + DP + total pinjaman"
/// yang dipakai layar Fix & Floating dan layar Berjenjang.
///
/// Logika sinkronisasi DP persen ↔ DP nominal sebelumnya disalin di kedua layar
/// dengan isi yang sama persis.
class LoanDpControllers {
  final TextEditingController loan = TextEditingController();
  final TextEditingController dpPercent = TextEditingController();
  final TextEditingController dpNominal = TextEditingController();
  final TextEditingController loanTotal = TextEditingController();

  double get loanAmount => CurrencyFormat.parseNumber(loan.text);
  double get dpAmount => CurrencyFormat.parseNumber(dpNominal.text);
  double get totalAmount => CurrencyFormat.parseNumber(loanTotal.text);

  void onLoanChanged(String _) {
    final double loanAmount = this.loanAmount;
    if (dpPercent.text.isEmpty) {
      dpNominal.clear();
      _updateTotal(loanAmount, 0);
      return;
    }
    final double dp = loanAmount * (_percentValue() / 100);
    dpNominal.text = CurrencyFormat.formatNumber(dp.floor());
    _updateTotal(loanAmount, dp);
  }

  void onDpPercentChanged(String _) {
    double percent = _percentValue();
    if (percent > 100) {
      percent = 100;
      dpPercent.text = '100';
    }

    final double loanAmount = this.loanAmount;
    if (loanAmount <= 0) {
      dpNominal.clear();
      _updateTotal(loanAmount, 0);
      return;
    }

    final double dp = loanAmount * (percent / 100);
    dpNominal.text = CurrencyFormat.formatNumber(dp.floor());
    _updateTotal(loanAmount, dp);
  }

  void onDpNominalChanged(String _) {
    final double loanAmount = this.loanAmount;
    double dp = dpAmount;

    // DP tidak boleh melebihi jumlah pinjaman — sebelumnya hanya dibatasi agar
    // tidak negatif sehingga total pinjaman bisa menjadi minus.
    if (loanAmount > 0 && dp > loanAmount) {
      dp = loanAmount;
      dpNominal.text = CurrencyFormat.formatNumber(dp);
    }

    if (loanAmount <= 0) {
      dpPercent.clear();
      _updateTotal(loanAmount, 0);
      return;
    }

    final double percent = (dp / loanAmount) * 100;
    dpPercent.text =
        CurrencyFormat.formatNumber(double.parse(percent.toStringAsFixed(2)));
    _updateTotal(loanAmount, dp);
  }

  double _percentValue() => CurrencyFormat.parseDecimal(dpPercent.text);

  void _updateTotal(double loanAmount, double dp) {
    final double total = loanAmount - dp;
    loanTotal.text = CurrencyFormat.formatNumber(total > 0 ? total.floor() : 0);
  }

  void dispose() {
    loan.dispose();
    dpPercent.dispose();
    dpNominal.dispose();
    loanTotal.dispose();
  }
}

class LoanDpFields extends StatelessWidget {
  const LoanDpFields({super.key, required this.controllers});

  final LoanDpControllers controllers;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabeledNumberField(
          controller: controllers.loan,
          label: 'Jumlah Pinjaman (Rp)',
          validator: Validators.loan,
          onChanged: controllers.onLoanChanged,
          suffixIcon: SizedBox(
            width: 20,
            height: 20,
            child: Image.asset('assets/money.png'),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: LabeledNumberField(
                controller: controllers.dpPercent,
                label: 'DP',
                decimal: true,
                onChanged: controllers.onDpPercentChanged,
                suffixIcon: const Icon(Icons.percent, color: Colors.black54),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: LabeledNumberField(
                controller: controllers.dpNominal,
                label: 'DP (Rp)',
                onChanged: controllers.onDpNominalChanged,
                validator: (value) => Validators.dpNominal(value,
                    loanText: controllers.loan.text),
              ),
            ),
          ],
        ),
        LabeledNumberField(
          controller: controllers.loanTotal,
          label: 'Total Pinjaman (Rp)',
          readOnly: true,
          validator: Validators.loanAfterDp,
          suffixIcon: SizedBox(
            width: 20,
            height: 20,
            child: Image.asset('assets/money.png'),
          ),
        ),
      ],
    );
  }
}
