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

/// Kalkulator akad **murabahah** (jual beli dengan margin).
///
/// Bank membeli rumah seharga pokok lalu menjualnya kembali kepada nasabah
/// dengan margin yang disepakati di muka. Harga jual dan angsurannya terkunci
/// sejak akad — tidak ada periode floating seperti KPR konvensional.
class MurabahahScreen extends StatefulWidget {
  const MurabahahScreen({super.key});

  @override
  State<MurabahahScreen> createState() => _MurabahahScreenState();
}

class _MurabahahScreenState extends State<MurabahahScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final LoanDpControllers _loanFields = LoanDpControllers();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _marginController = TextEditingController();

  InstallmentSummary? _preview;

  @override
  void dispose() {
    _loanFields.dispose();
    _yearController.dispose();
    _marginController.dispose();
    super.dispose();
  }

  CalculateModel _readForm() => CalculateModel(
        initialLoan: _loanFields.loanAmount,
        dpNominal: _loanFields.dpAmount,
        loanPlafon: _loanFields.totalAmount,
        loan: _loanFields.totalAmount,
        year: CurrencyFormat.parseNumber(_yearController.text),
        interest: CurrencyFormat.parseDecimal(_marginController.text),
      );

  /// Harga jual adalah angka yang paling dicari di akad ini, jadi ditampilkan
  /// begitu inputnya lengkap — tanpa menunggu tombol hitung ditekan.
  void _updatePreview() {
    final CalculateModel model = _readForm();
    final bool isComplete = (model.loanPlafon ?? 0) > 0 &&
        (model.year ?? 0) > 0 &&
        (model.interest ?? 0) > 0;

    setState(() {
      _preview = isComplete
          ? summarizeInstallments(installmentTableMurabahah(model))
          : null;
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final CalculateModel model = _readForm();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrincipalTable(
          results: installmentTableMurabahah(model),
          // Murabahah memungut margin dari harga pokok yang tidak menyusut,
          // jadi mesin hitungnya sama dengan flat.
          type: CalculatorType.flat,
          contract: FinancingContract.murabahah,
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
                      dpLabel: 'Uang Muka',
                      totalLabel: 'Harga Pokok',
                    ),
                    LabeledNumberField(
                      controller: _yearController,
                      label: 'Jangka Waktu (Tahun)',
                      validator: Validators.year,
                      suffixIcon: Icon(Icons.alarm, color: AppColors.muted),
                    ),
                    const SectionTitle('Margin Keuntungan', topPadding: 24),
                    LabeledNumberField(
                      controller: _marginController,
                      label: 'Margin per Tahun',
                      decimal: true,
                      validator: (value) =>
                          Validators.interest(value, label: 'Margin'),
                      suffixIcon: Icon(Icons.percent, color: AppColors.muted),
                    ),
                    Text(
                      'Margin dihitung dari harga pokok dan tidak berubah '
                      'sepanjang akad, sehingga angsuran tetap sampai lunas.',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    if (_preview != null) ...[
                      const SizedBox(height: 24),
                      ShariaSummaryCard(
                        rows: [
                          ShariaSummaryRow(
                            label: 'Harga Jual',
                            // Seluruh angsuran yang dibayar nasabah adalah
                            // harga jual yang disepakati di muka.
                            value: _preview!.totalPayment,
                            emphasized: true,
                          ),
                          ShariaSummaryRow(
                            label: 'Total Margin',
                            value: _preview!.totalInterest,
                          ),
                          ShariaSummaryRow(
                            label: 'Angsuran Tetap per Bulan',
                            value: _preview!.firstInstallment,
                            emphasized: true,
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
