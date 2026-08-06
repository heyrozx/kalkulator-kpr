import 'package:flutter/material.dart';
import 'package:kalkulator_kpr/core/config.dart';
import 'package:kalkulator_kpr/core/currency_format.dart';
import 'package:kalkulator_kpr/core/helpers.dart';
import 'package:kalkulator_kpr/core/theme.dart';
import 'package:kalkulator_kpr/core/validators.dart';
import 'package:kalkulator_kpr/models/calculate_model.dart';
import 'package:kalkulator_kpr/pages/principle/principal_table.dart';
import 'package:kalkulator_kpr/shared/widgets/form_section.dart';
import 'package:kalkulator_kpr/shared/widgets/labeled_number_field.dart';
import 'package:kalkulator_kpr/shared/widgets/loan_dp_fields.dart';
import 'package:kalkulator_kpr/utils/custom_snackbar.dart';

class FixAndFloatingScreen extends StatefulWidget {
  final CalculatorType type;
  const FixAndFloatingScreen({super.key, required this.type});

  @override
  State<FixAndFloatingScreen> createState() => _FixAndFloatingScreenState();
}

class _FixAndFloatingScreenState extends State<FixAndFloatingScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final LoanDpControllers _loanFields = LoanDpControllers();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _interestController = TextEditingController();
  final TextEditingController _fixInterestController = TextEditingController();

  double fixedCreditPeriod = 3;

  @override
  void dispose() {
    _loanFields.dispose();
    _yearController.dispose();
    _interestController.dispose();
    _fixInterestController.dispose();
    super.dispose();
  }

  CalculateModel _readForm() => CalculateModel(
        fixInterest: CurrencyFormat.parseDecimal(_fixInterestController.text),
        fixYear: fixedCreditPeriod.floorToDouble(),
        floatingInterest: CurrencyFormat.parseDecimal(_interestController.text),
        initialLoan: _loanFields.loanAmount,
        dpNominal: _loanFields.dpAmount,
        loanPlafon: _loanFields.totalAmount,
        loan: _loanFields.totalAmount,
        year: CurrencyFormat.parseNumber(_yearController.text),
        interest: CurrencyFormat.parseDecimal(_interestController.text),
      );

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final double year = CurrencyFormat.parseNumber(_yearController.text);
    if (fixedCreditPeriod >= year) {
      CustomSnackbar.show(
        context,
        title: 'Masa kredit fix terlalu panjang',
        message: 'Masa kredit fix harus lebih kecil dari jangka waktu pinjaman',
        type: SnackbarType.warning,
      );
      return;
    }

    final CalculateModel calculateModel = _readForm();
    // `installmentTableFixFloating` tidak lagi mengubah model yang dikirim,
    // jadi satu instance cukup untuk perhitungan sekaligus tampilan.
    final tables = installmentTableFixFloating(widget.type, calculateModel);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrincipalTable(
          results: tables,
          type: widget.type,
          calculateModel: calculateModel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoanDpFields(controllers: _loanFields),
                    LabeledNumberField(
                      controller: _yearController,
                      label: 'Jangka Waktu (Tahun)',
                      validator: Validators.year,
                      suffixIcon: Icon(Icons.alarm, color: AppColors.muted),
                    ),
                    const SectionTitle('Bunga Fix', topPadding: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Text(
                              'Suku Bunga Fix',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Expanded(
                          child: LabeledNumberField(
                            controller: _fixInterestController,
                            label: 'Bunga (%)',
                            decimal: true,
                            validator: Validators.interest,
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text(
                        'Masa Kredit Fix',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        tickMarkShape: SliderTickMarkShape.noTickMark,
                      ),
                      child: Slider(
                        activeColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        value: fixedCreditPeriod,
                        divisions: AppConfig.maxFixYear.toInt(),
                        min: 1,
                        max: AppConfig.maxFixYear,
                        onChanged: (value) =>
                            setState(() => fixedCreditPeriod = value),
                      ),
                    ),
                    Row(
                      children: [
                        Text('${fixedCreditPeriod.toInt()} Tahun',
                            style: const TextStyle(fontSize: 16)),
                        const Spacer(),
                        Text('${AppConfig.maxFixYear.toInt()} Tahun',
                            style: TextStyle(
                                fontSize: 14, color: AppColors.muted)),
                      ],
                    ),
                    const SectionTitle('Bunga Floating'),
                    LabeledNumberField(
                      controller: _interestController,
                      label: 'Bunga Pinjaman',
                      decimal: true,
                      validator: Validators.interest,
                      suffixIcon: Icon(Icons.percent, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ),
            SubmitBar(onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
