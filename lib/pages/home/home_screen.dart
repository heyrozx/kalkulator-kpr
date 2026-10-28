import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kalkulator_kpr/blocs/purchase_cubit/purchase_cubit.dart';
import 'package:kalkulator_kpr/core/currency_format.dart';
import 'package:kalkulator_kpr/core/helpers.dart';
import 'package:kalkulator_kpr/core/interstitial_ad_manager.dart';
import 'package:kalkulator_kpr/core/theme.dart';
import 'package:kalkulator_kpr/core/validators.dart';
import 'package:kalkulator_kpr/models/calculate_model.dart';
import 'package:kalkulator_kpr/pages/about/anuitas_description.dart';
import 'package:kalkulator_kpr/pages/about/disclaimer.dart';
import 'package:kalkulator_kpr/pages/about/effective_description.dart';
import 'package:kalkulator_kpr/pages/about/flat_description.dart';
import 'package:kalkulator_kpr/pages/about/sharia_description.dart';
import 'package:kalkulator_kpr/pages/advanced/advanced_screen.dart';
import 'package:kalkulator_kpr/pages/history/history_screen.dart';
import 'package:kalkulator_kpr/pages/premiums/premium_paywall.dart';
import 'package:kalkulator_kpr/pages/principle/principal_table.dart';
import 'package:kalkulator_kpr/pages/settings/settings_screen.dart';
import 'package:kalkulator_kpr/pages/sharia/sharia_screen.dart';
import 'package:kalkulator_kpr/shared/widgets/labeled_number_field.dart';
import 'package:kalkulator_kpr/shared/widgets/segmented_switch.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  /// Tinggi area switch metode bunga di bawah judul AppBar.
  static const double _switchAreaHeight = 46;

  static const TextStyle _buttonStyle = TextStyle(fontSize: 14);

  /// Urutan pilihan metode bunga di beranda. Anuitas paling depan karena skema itu
  /// yang paling umum dipakai bank untuk KPR.
  static const List<({CalculatorType value, String label})> _methods = [
    (value: CalculatorType.anuitas, label: 'Anuitas'),
    (value: CalculatorType.effective, label: 'Efektif'),
    (value: CalculatorType.flat, label: 'Flat'),
  ];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final _loanController = TextEditingController();
  final _yearController = TextEditingController();
  final _interestController = TextEditingController();
  final InterstitialAdManager _interstitialAd = InterstitialAdManager();

  CalculateResultModel? result;
  CalculatorType type = CalculatorType.anuitas;
  double percentIndicator = 0;

  @override
  void initState() {
    super.initState();
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

  void _onTypeChanged(CalculatorType selected) {
    if (selected == type) return;
    type = selected;
    _recalculateIfFilled();
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

  void _openPage(Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  /// Daftar halaman bantuan yang bisa dibuka dari menu samping. Dulu hanya
  /// penjelasan metode yang sedang aktif lewat ikon tanda tanya di AppBar.
  static const List<
          ({IconData icon, String title, String subtitle, Widget page})>
      _helpItems = [
    (
      icon: Icons.trending_down,
      title: 'Bunga Anuitas',
      subtitle: 'Angsuran tetap, porsi pokok makin besar',
      page: AnuitasDescription(),
    ),
    (
      icon: Icons.stacked_line_chart,
      title: 'Bunga Efektif',
      subtitle: 'Bunga dihitung dari sisa pokok',
      page: EffectiveDescription(),
    ),
    (
      icon: Icons.horizontal_rule,
      title: 'Bunga Flat',
      subtitle: 'Bunga dihitung dari pokok awal',
      page: FlatDescription(),
    ),
    (
      icon: Icons.mosque_outlined,
      title: 'KPR Syariah',
      subtitle: 'Akad murabahah & musyarakah mutanaqisah',
      page: ShariaDescription(),
    ),
    (
      icon: Icons.gavel_outlined,
      title: 'Disklaimer',
      subtitle: 'Batasan hasil simulasi',
      page: Disclaimer(),
    ),
  ];

  void _openHelp() {
    Navigator.pop(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Bantuan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            for (final item in _helpItems)
              ListTile(
                leading: Icon(item.icon, color: AppColors.primary),
                title: Text(item.title),
                subtitle: Text(item.subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                      context, MaterialPageRoute(builder: (_) => item.page));
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: AppColors.dashboardGradient,
        ),
      ),
      child: _buildScaffold(),
    );
  }

  Widget _buildScaffold() {
    return Scaffold(
      key: _scaffoldKey,
      // Transparan supaya gradasi latar dari DecoratedBox di atas terlihat.
      backgroundColor: Colors.transparent,
      drawer: _buildDrawer(),
      // AppBar harus lewat slot `appBar` Scaffold, bukan menumpang di dalam
      // Column body: AppBar dengan `bottom` (switch metode) memakai Flexible di
      // dalamnya, dan Column memberi tinggi tak terbatas ke anak non-flex
      // sehingga layout-nya gagal.
      appBar: _buildAppBar(),
      body: SafeArea(
        // Inset bawah tidak dipotong di sini supaya panel form ikut mengisi
        // area navigation bar (edge-to-edge di API 36) dan tidak terlihat
        // "mengambang"; jaraknya ditambahkan sebagai padding di dalam panel.
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: SizedBox(
                height: math.max(constraints.maxHeight, 430),
                child: Column(
                  children: [
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Kalkulator KPR',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
      leading: IconButton(
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        icon: SizedBox(
          width: 25,
          height: 25,
          child: Image.asset('assets/menu.png'),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(_switchAreaHeight),
        child: Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 10),
          child: SegmentedSwitch<CalculatorType>(
            segments: _methods,
            selected: type,
            onChanged: _onTypeChanged,
          ),
        ),
      ),
      actions: [
        BlocBuilder<PurchaseCubit, PurchaseState>(
          builder: (context, state) {
            // Premium: lencana emas terisi, membuka Pengaturan untuk melihat
            // status langganan. Free: lencana garis ungu yang membuka paywall.
            // Selama status belum diketahui ikon disembunyikan supaya user
            // premium tidak sempat melihat ajakan upgrade.
            if (state is PurchaseData && state.isPremium) {
              return IconButton(
                tooltip: 'Premium aktif',
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen())),
                icon: const Icon(Icons.workspace_premium,
                    color: AppColors.premiumGold, size: 28),
              );
            }
            if (state is! PurchaseNothing) return const SizedBox();
            return IconButton(
              tooltip: 'Upgrade ke Premium',
              onPressed: () => showPremiumPaywall(context),
              icon: const Icon(Icons.workspace_premium_outlined,
                  color: AppColors.primary, size: 28),
            );
          },
        ),
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
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Form(
      key: _formKey,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(14, 12, 14, 12 + bottomInset),
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
            const SizedBox(height: 4),
            LabeledNumberField(
              controller: _loanController,
              label: 'Jumlah Pinjaman (Rp)',
              validator: Validators.loan,
              margin: const EdgeInsets.only(bottom: 8),
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
                    margin: const EdgeInsets.only(bottom: 8),
                    suffixIcon:
                        Icon(Icons.alarm, size: 20, color: AppColors.muted),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: LabeledNumberField(
                    controller: _interestController,
                    label: 'Bunga Pinjaman',
                    decimal: true,
                    validator: Validators.interest,
                    margin: const EdgeInsets.only(bottom: 8),
                    suffixIcon:
                        Icon(Icons.percent, size: 20, color: AppColors.muted),
                  ),
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.only(top: 2),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
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
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          result != null ? 'Hitung Ulang' : 'Hitung Simulasi',
                          style: _buttonStyle,
                        ),
                      ),
                    ),
                  ),
                  if (result != null) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.button),
                          ),
                        ),
                        onPressed: _openInstallmentTable,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Tabel Angsuran', style: _buttonStyle),
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
            ListTile(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 10),
                    child: Image.asset('assets/ic_launcher.png',
                        width: 56, height: 56),
                  ),
                  const Text(
                    'Kalkulator KPR',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
                  const SizedBox(height: 5),
                  const Text('Simulasi Kredit'),
                ],
              ),
            ),
            const Divider(thickness: 0.5),
            // Metode bunga sekarang dipilih lewat switch di beranda, jadi drawer
            // hanya menyisakan layar-layar lain.
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Advanced'),
              subtitle: const Text('Fix & floating, bunga berjenjang'),
              onTap: () => _openPage(
                AdvancedScreen(type: type == CalculatorType.flat ? null : type),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.mosque_outlined),
              title: const Text('KPR Syariah'),
              subtitle: const Text('Murabahah & MMQ'),
              onTap: () => _openPage(const ShariaScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Riwayat Simulasi'),
              subtitle: const Text('Simulasi yang Anda simpan'),
              onTap: () => _openPage(const HistoryScreen()),
            ),
            const Spacer(),
            const Divider(thickness: 0.5),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Bantuan'),
              onTap: _openHelp,
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Pengaturan'),
              onTap: () => _openPage(const SettingsScreen()),
            ),
            const SizedBox(height: 15)
          ],
        ),
      ),
    );
  }
}
