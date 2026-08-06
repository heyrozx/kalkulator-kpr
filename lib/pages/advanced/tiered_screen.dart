import 'package:flutter/material.dart';
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

class TieredScreen extends StatefulWidget {
  final CalculatorType type;
  const TieredScreen({super.key, required this.type});

  @override
  State<TieredScreen> createState() => _TieredScreenState();
}

class _TieredScreenState extends State<TieredScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final LoanDpControllers _loanFields = LoanDpControllers();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _interestController = TextEditingController();

  final List<TextEditingController> _tierControllers = [
    TextEditingController()
  ];

  @override
  void dispose() {
    _loanFields.dispose();
    _yearController.dispose();
    _interestController.dispose();
    for (final controller in _tierControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addTier() {
    setState(() => _tierControllers.add(TextEditingController()));
  }

  void _removeTier(int index) {
    if (index == 0) return;
    final removed = _tierControllers.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  CalculateModel _readForm() => CalculateModel(
        fixYear: _tierControllers.length.floorToDouble(),
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
    if (_tierControllers.length >= year) {
      CustomSnackbar.show(
        context,
        title: 'Tahun bunga fix terlalu banyak',
        message: 'Tahun bunga fix harus lebih kecil dari jangka waktu pinjaman',
        type: SnackbarType.warning,
      );
      return;
    }

    final List<double> tieredInterest = _tierControllers
        .map((controller) => CurrencyFormat.parseDecimal(controller.text))
        .toList();

    final CalculateModel calculateModel = _readForm();
    final tables =
        installmentTableTiered(widget.type, calculateModel, tieredInterest);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrincipalTable(
          tieredInterest: tieredInterest,
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
                    SectionTitle(
                      'Bunga Fix',
                      topPadding: 24,
                      trailing: IconButton(
                        onPressed: _addTier,
                        icon: const Icon(Icons.add_circle_outline,
                            color: AppColors.primary),
                      ),
                    ),
                    for (int i = 0; i < _tierControllers.length; i++)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 18),
                              child: Text('Bunga tahun ke ${i + 1}'),
                            ),
                          ),
                          Expanded(
                            child: LabeledNumberField(
                              controller: _tierControllers[i],
                              label: 'Bunga (%)',
                              decimal: true,
                              validator: Validators.interest,
                              suffixIcon: IconButton(
                                onPressed: () => _removeTier(i),
                                tooltip: 'Hapus bunga tahun ke ${i + 1}',
                                icon: Icon(
                                  Icons.do_not_disturb_on_outlined,
                                  color:
                                      i == 0 ? Colors.grey : AppColors.primary,
                                ),
                              ),
                            ),
                          ),
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
