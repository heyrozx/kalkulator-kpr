import 'package:flutter/material.dart';
import 'package:kalkulator_kpr/core/currency_format.dart';
import 'package:kalkulator_kpr/core/helpers.dart';
import 'package:kalkulator_kpr/core/theme.dart';
import 'package:kalkulator_kpr/core/validators.dart';
import 'package:kalkulator_kpr/models/calculate_model.dart';
import 'package:kalkulator_kpr/models/financing_contract.dart';
import 'package:kalkulator_kpr/pages/principle/principal_table.dart';
import 'package:kalkulator_kpr/pages/sharia/sharia_summary_card.dart';
import 'package:kalkulator_kpr/shared/widgets/form_section.dart';
import 'package:kalkulator_kpr/shared/widgets/labeled_number_field.dart';
import 'package:kalkulator_kpr/shared/widgets/loan_dp_fields.dart';

/// Kalkulator akad **musyarakah mutanaqisah** (kepemilikan bersama menurun).
///
/// Bank dan nasabah memiliki rumah bersama. Tiap bulan nasabah membeli sebagian
/// porsi bank sekaligus membayar sewa atas porsi yang masih dimiliki bank —
/// sehingga sewanya ikut menyusut seiring porsi bank mengecil.
class MmqScreen extends StatefulWidget {
  const MmqScreen({super.key});

  @override
  State<MmqScreen> createState() => _MmqScreenState();
}

class _MmqScreenState extends State<MmqScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final LoanDpControllers _loanFields = LoanDpControllers();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();

  MmqPattern _pattern = MmqPattern.decreasing;
  InstallmentSummary? _preview;

  @override
  void dispose() {
    _loanFields.dispose();
    _yearController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  CalculateModel _readForm() => CalculateModel(
        initialLoan: _loanFields.loanAmount,
        dpNominal: _loanFields.dpAmount,
        loanPlafon: _loanFields.totalAmount,
        loan: _loanFields.totalAmount,
        year: CurrencyFormat.parseNumber(_yearController.text),
        interest: CurrencyFormat.parseDecimal(_rateController.text),
      );

  List<CalculateResultModel> _buildTable(CalculateModel model) =>
      switch (_pattern) {
        MmqPattern.decreasing => installmentTableEffective(model),
        MmqPattern.fixed => installmentTableAnuitas(model),
      };

  void _updatePreview() {
    final CalculateModel model = _readForm();
    final bool isComplete = (model.loanPlafon ?? 0) > 0 &&
        (model.year ?? 0) > 0 &&
        (model.interest ?? 0) > 0;

    setState(() {
      _preview = isComplete ? summarizeInstallments(_buildTable(model)) : null;
    });
  }

  void _selectPattern(MmqPattern pattern) {
    setState(() => _pattern = pattern);
    _updatePreview();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final CalculateModel model = _readForm();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrincipalTable(
          results: _buildTable(model),
          // Sewa dihitung dari porsi bank yang tersisa, persis seperti bunga
          // efektif; pola angsuran tetap memakai mesin anuitas.
          type: _pattern.engine,
          contract: FinancingContract.mmq,
          calculateModel: model,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        onChanged: _updatePreview,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoanDpFields(
                      controllers: _loanFields,
                      loanLabel: 'Harga Rumah',
                      dpLabel: 'Porsi Nasabah',
                      totalLabel: 'Porsi Bank',
                    ),
                    LabeledNumberField(
                      controller: _yearController,
                      label: 'Jangka Waktu (Tahun)',
                      validator: Validators.year,
                      suffixIcon: Icon(Icons.alarm, color: AppColors.muted),
                    ),
                    const SectionTitle('Nisbah Sewa', topPadding: 24),
                    LabeledNumberField(
                      controller: _rateController,
                      label: 'Nisbah Sewa per Tahun',
                      decimal: true,
                      validator: (value) =>
                          Validators.interest(value, label: 'Nisbah sewa'),
                      suffixIcon: Icon(Icons.percent, color: AppColors.muted),
                    ),
                    Text(
                      'Sewa dihitung dari porsi bank yang masih tersisa, jadi '
                      'ikut mengecil setiap nasabah membeli porsi bank.',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    const SectionTitle('Pola Angsuran'),
                    Row(
                      children: [
                        for (final pattern in MmqPattern.values) ...[
                          if (pattern != MmqPattern.values.first)
                            const SizedBox(width: 10),
                          Expanded(
                            child: _PatternOption(
                              pattern: pattern,
                              selected: _pattern == pattern,
                              onTap: () => _selectPattern(pattern),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _pattern.description,
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    if (_preview != null) ...[
                      const SizedBox(height: 24),
                      ShariaSummaryCard(
                        rows: [
                          ShariaSummaryRow(
                            label: 'Angsuran Bulan Pertama',
                            value: _preview!.firstInstallment,
                            emphasized: true,
                          ),
                          ShariaSummaryRow(
                            label: 'Angsuran Bulan Terakhir',
                            value: _preview!.lastInstallment,
                            emphasized: _preview!.isVarying,
                          ),
                          ShariaSummaryRow(
                            label: 'Total Sewa',
                            value: _preview!.totalInterest,
                          ),
                          ShariaSummaryRow(
                            label: 'Total Pembayaran',
                            value: _preview!.totalPayment,
                          ),
                        ],
                        note: '${_preview!.months} kali angsuran',
                      ),
                    ],
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

class _PatternOption extends StatelessWidget {
  const _PatternOption({
    required this.pattern,
    required this.selected,
    required this.onTap,
  });

  final MmqPattern pattern;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.card),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
              color: selected ? AppColors.primary : AppColors.muted,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                pattern.shortLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: selected ? AppColors.primary : AppColors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
