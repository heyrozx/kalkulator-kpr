import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kalkulator_kpr/blocs/purchase_cubit/purchase_cubit.dart';
import 'package:kalkulator_kpr/core/config.dart';
import 'package:kalkulator_kpr/core/currency_format.dart';
import 'package:kalkulator_kpr/core/error_reporter.dart';
import 'package:kalkulator_kpr/core/helpers.dart';
import 'package:kalkulator_kpr/core/interstitial_ad_manager.dart';
import 'package:kalkulator_kpr/core/theme.dart';
import 'package:kalkulator_kpr/core/validators.dart';
import 'package:kalkulator_kpr/models/calculate_model.dart';
import 'package:kalkulator_kpr/pages/about/anuitas_description.dart';
import 'package:kalkulator_kpr/pages/about/disclaimer.dart';
import 'package:kalkulator_kpr/pages/about/effective_description.dart';
import 'package:kalkulator_kpr/pages/about/flat_description.dart';
import 'package:kalkulator_kpr/pages/advanced/advanced_screen.dart';
import 'package:kalkulator_kpr/pages/premiums/premium_plan_screen.dart';
import 'package:kalkulator_kpr/pages/principle/principal_table.dart';
import 'package:kalkulator_kpr/shared/widgets/labeled_number_field.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final _loanController = TextEditingController();
  final _yearController = TextEditingController();
  final _interestController = TextEditingController();
  final InterstitialAdManager _interstitialAd = InterstitialAdManager();

  CalculateResultModel? result;
  CalculatorType type = CalculatorType.anuitas;
  double percentIndicator = 0;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _preloadInterstitial();
  }

  @override
  void dispose() {
    _loanController.dispose();
    _yearController.dispose();
    _interestController.dispose();
    _interstitialAd.dispose();
    super.dispose();
  }

  Future<void> _loadAppVersion() async {
    // Nomor versi dibaca dari paket, bukan ditulis manual — sebelumnya teks di
    // drawer tertinggal satu rilis di belakang pubspec.yaml.
    final info = await ErrorReporter.guard(() => PackageInfo.fromPlatform(),
        hint: 'PackageInfo');
    if (!mounted || info == null) return;
    setState(() => _appVersion = info.version);
  }

  Future<void> _preloadInterstitial() async {
    final cubit = context.read<PurchaseCubit>();
    await cubit.checkPremium();
    if (!mounted || cubit.isPremium()) return;
    _interstitialAd.load();
  }

  CalculateModel _readForm() => CalculateModel(
        loanPlafon: CurrencyFormat.parseNumber(_loanController.text),
        loan: CurrencyFormat.parseNumber(_loanController.text),
        year: CurrencyFormat.parseNumber(_yearController.text),
        interest: CurrencyFormat.parseDecimal(_interestController.text),
      );

  void calculate() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final CalculateModel calculateModel = _readForm();
    final CalculateResultModel calculated = switch (type) {
      CalculatorType.flat => calculateFlat(calculateModel),
      CalculatorType.effective => calculateEffective(calculateModel),
      CalculatorType.anuitas => calculateAnuitas(calculateModel),
    };

    setState(() {
      result = calculated;
      percentIndicator = _safePercent(calculated);
    });
  }

  /// Porsi pokok terhadap total angsuran. `CircularPercentIndicator` melempar
  /// exception kalau nilainya di luar 0..1, jadi nilai tak wajar diamankan.
  double _safePercent(CalculateResultModel value) {
    final installment = value.installmentResult ?? 0;
    final principal = value.principal ?? 0;
    if (installment <= 0) return 0;
    final percent = principal / installment;
    if (!percent.isFinite) return 0;
    return percent.clamp(0.0, 1.0);
  }

  void _recalculateIfFilled() {
    final isFilled = _loanController.text.isNotEmpty &&
        _yearController.text.isNotEmpty &&
        _interestController.text.isNotEmpty;
    if (isFilled) {
      calculate();
    } else {
      setState(() {});
    }
  }

  void _openInstallmentTable() {
    // Validasi dulu, baru iklan: sebelumnya iklan tetap tampil walaupun form
    // belum lengkap sehingga pengguna melihat iklan tanpa mendapat hasil.
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final CalculateModel calculateModel = _readForm();
    final List<CalculateResultModel> tables = switch (type) {
      CalculatorType.flat => installmentTableFlat(calculateModel),
      CalculatorType.effective => installmentTableEffective(calculateModel),
      CalculatorType.anuitas => installmentTableAnuitas(calculateModel),
    };

    _interstitialAd.showThen(() {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PrincipalTable(
            results: tables,
            type: type,
            calculateModel: _readForm(),
          ),
        ),
      );
    });
  }

  Future<void> _launchUrl(String url) async {
    try {
      final launched =
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!launched) throw Exception('Could not launch $url');
    } catch (error, stack) {
      ErrorReporter.report(error, stack, hint: 'launchUrl');
    }
  }

  void _selectType(CalculatorType selected) {
    type = selected;
    Navigator.pop(context);
    _recalculateIfFilled();
  }

  String get _typeLabel => switch (type) {
        CalculatorType.flat => 'Flat',
        CalculatorType.effective => 'Efektif',
        CalculatorType.anuitas => 'Anuitas',
      };

  Widget get _typeDescriptionPage => switch (type) {
        CalculatorType.flat => const FlatDescription(),
        CalculatorType.effective => const EffectiveDescription(),
        CalculatorType.anuitas => const AnuitasDescription(),
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: SafeArea(
        // API 36 memaksa edge-to-edge; tanpa SafeArea judul dan tombol menu
        // bisa tertimpa status bar.
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: SizedBox(
                height: math.max(constraints.maxHeight, 480),
                child: Column(
                  children: [
                    _buildAppBar(),
                    Expanded(child: Center(child: _buildResultRing())),
                    _buildForm(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return AppBar(
      title: Text(_typeLabel),
      leading: IconButton(
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        icon: SizedBox(
          width: 25,
          height: 25,
          child: Image.asset('assets/menu.png'),
        ),
      ),
      actions: [
        BlocBuilder<PurchaseCubit, PurchaseState>(
          builder: (context, state) {
            if (state is! PurchaseNothing) return const SizedBox();
            return IconButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PremiumPlanScreen())),
              icon: SizedBox(
                width: 30,
                child: Image.asset('assets/premium.png'),
              ),
            );
          },
        ),
        IconButton(
          onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => _typeDescriptionPage)),
          icon: SizedBox(
            width: 25,
            height: 25,
            child: Image.asset('assets/question.png'),
          ),
        )
      ],
    );
  }

  Widget _buildResultRing() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 10),
      child: CircularPercentIndicator(
        radius: 120.0,
        lineWidth: 13.0,
        animation: true,
        percent: percentIndicator,
        circularStrokeCap: CircularStrokeCap.round,
        progressColor: AppColors.primary,
        center: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Total Angsuran", style: TextStyle(fontSize: 15.0)),
            const SizedBox(height: 5),
            Text(
              "Rp ${currencyId.format(result?.installmentResult ?? 0)}",
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 25.0),
            ),
            const SizedBox(height: 5),
            Text(
              type == CalculatorType.effective ? "Bulan Pertama" : "Per Bulan",
              style: const TextStyle(fontSize: 15.0),
            ),
          ],
        ),
        footer: Container(
          margin: const EdgeInsets.only(top: 30),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legend('Angsuran Pokok', result?.principal, AppColors.primary),
              const SizedBox(width: 15),
              _legend(
                  'Bunga', result?.interestResult, AppColors.interestPortion),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legend(String label, double? value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 15,
          height: 15,
          margin: const EdgeInsets.only(right: 5),
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            Text(
              "Rp ${currencyId.format(value ?? 0)}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.sheet)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.3),
              spreadRadius: 2,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            LabeledNumberField(
              controller: _loanController,
              label: 'Jumlah Pinjaman (Rp)',
              validator: Validators.loan,
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
                  child: LabeledNumberField(
                    controller: _yearController,
                    label: 'Jangka Waktu (Tahun)',
                    validator: Validators.year,
                    suffixIcon: Icon(Icons.alarm, color: AppColors.muted),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: LabeledNumberField(
                    controller: _interestController,
                    label: 'Bunga Pinjaman',
                    decimal: true,
                    validator: Validators.interest,
                    suffixIcon: Icon(Icons.percent, color: AppColors.muted),
                  ),
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.only(top: 5),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: result != null
                            ? AppColors.subtle
                            : AppColors.primary,
                        foregroundColor:
                            result != null ? Colors.black87 : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                      ),
                      onPressed: calculate,
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Text(result != null
                            ? 'Hitung Ulang'
                            : 'Hitung Simulasi'),
                      ),
                    ),
                  ),
                  if (result != null) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.button),
                          ),
                        ),
                        onPressed: _openInstallmentTable,
                        child: const Padding(
                          padding: EdgeInsets.all(15.0),
                          child: Text('Tabel Angsuran'),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const ListTile(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kalkulator KPR',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
                  SizedBox(height: 5),
                  Text('Simulasi Kredit'),
                ],
              ),
            ),
            const Divider(thickness: 0.5),
            for (final entry in const {
              CalculatorType.anuitas: 'Bunga Anuitas',
              CalculatorType.effective: 'Bunga Efektif',
              CalculatorType.flat: 'Bunga Flat',
            }.entries)
              ListTile(
                selected: type == entry.key,
                selectedColor: AppColors.primary,
                title: Text(entry.value),
                onTap: () => _selectType(entry.key),
              ),
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              width: double.infinity,
              child: FilledButton(
                style:
                    FilledButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdvancedScreen(
                        type: type == CalculatorType.flat ? null : type,
                      ),
                    ),
                  );
                },
                child: const Text('Advanced'),
              ),
            ),
            const Spacer(),
            ListTile(
              title: const Text('Beri Rating'),
              leading: const Icon(Icons.star_outline),
              onTap: () => _launchUrl(AppConfig.playStoreUrl),
            ),
            ListTile(
              title: const Text('Reset'),
              leading: const Icon(Icons.refresh),
              onTap: () {
                Navigator.pop(context);
                _formKey.currentState?.reset();
                _loanController.clear();
                _yearController.clear();
                _interestController.clear();
                setState(() {
                  result = null;
                  percentIndicator = 0;
                });
              },
            ),
            ListTile(
              title: const Text('Disclaimer'),
              leading: const Icon(Icons.info_outline),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const Disclaimer()));
              },
            ),
            ListTile(
              title: const Text('Privacy Policy'),
              leading: const Icon(Icons.gpp_maybe_outlined),
              onTap: () => _launchUrl(AppConfig.privacyPolicyUrl),
            ),
            ListTile(
              title: Text(_appVersion.isEmpty ? 'Versi' : 'Versi $_appVersion'),
              leading: const Icon(Icons.smartphone_outlined),
            ),
            const SizedBox(height: 15)
          ],
        ),
      ),
    );
  }
}
