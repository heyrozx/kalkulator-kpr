import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_file_saver/flutter_file_saver.dart';
import 'package:kalkulator_kpr/blocs/purchase_cubit/purchase_cubit.dart';
import 'package:kalkulator_kpr/core/currency_format.dart';
import 'package:kalkulator_kpr/core/error_reporter.dart';
import 'package:kalkulator_kpr/core/helpers.dart';
import 'package:kalkulator_kpr/core/loading_overlay.dart';
import 'package:kalkulator_kpr/core/simulation_history_repository.dart';
import 'package:kalkulator_kpr/core/theme.dart';
import 'package:kalkulator_kpr/models/calculate_model.dart';
import 'package:kalkulator_kpr/models/financing_contract.dart';
import 'package:kalkulator_kpr/models/simulation_history.dart';
import 'package:kalkulator_kpr/pages/premiums/premium_paywall.dart';
import 'package:kalkulator_kpr/pages/principle/affordability_tab.dart';
import 'package:kalkulator_kpr/pages/principle/installment_chart.dart';
import 'package:kalkulator_kpr/pages/principle/installment_table_view.dart';
import 'package:kalkulator_kpr/shared/widgets/banner_ad_widget.dart';
import 'package:kalkulator_kpr/shared/widgets/name_input_dialog.dart';
import 'package:kalkulator_kpr/shared/widgets/premium_tab.dart';
import 'package:kalkulator_kpr/utils/custom_snackbar.dart';
import 'package:kalkulator_kpr/utils/pdf_util.dart';
import 'package:share_plus/share_plus.dart';

class PrincipalTable extends StatefulWidget {
  final List<double>? tieredInterest;
  final List<CalculateResultModel>? results;
  final CalculateModel? calculateModel;
  final CalculatorType? type;

  /// Terisi kalau layar ini dibuka dari riwayat, supaya simulasi yang sama
  /// tidak bisa tersimpan dua kali.
  final int? savedHistoryId;

  /// Menentukan istilah yang dipakai tabel, grafik, dan PDF.
  final FinancingContract contract;

  const PrincipalTable(
      {super.key,
      this.results,
      this.calculateModel,
      this.type,
      this.tieredInterest,
      this.savedHistoryId,
      this.contract = FinancingContract.conventional});

  @override
  State<PrincipalTable> createState() => _PrincipalTableState();
}

class _PrincipalTableState extends State<PrincipalTable> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isBusy = false;
  bool _isSaving = false;

  /// Terisi setelah simulasi ini disimpan ke riwayat, supaya tombol simpan
  /// berubah bentuk dan simulasi yang sama tidak tersimpan dua kali.
  int? _savedId;
  late PurchaseCubit _cubit;

  List<CalculateResultModel> get _results => widget.results ?? const [];

  /// Dihitung sekali: dipakai footer tabel, tab grafik, dan record riwayat.
  late final InstallmentSummary _summary = summarizeInstallments(_results);

  InstallmentTerms get _terms => widget.contract.terms;

  /// Label skema pada kartu ringkas: jenis bunga untuk konvensional, nama akad
  /// (berikut pola angsurannya) untuk syariah.
  String get _schemeLabel => switch (widget.contract) {
        FinancingContract.conventional =>
          widget.type?.label ?? CalculatorType.anuitas.label,
        FinancingContract.murabahah => FinancingContract.murabahah.label,
        FinancingContract.mmq => '${FinancingContract.mmq.shortLabel} · '
            '${mmqPatternOf(widget.type ?? CalculatorType.effective).shortLabel}',
      };

  /// Saldo yang dilunasi selama tenor — titik awal kurva sisa kewajiban.
  ///
  /// Untuk murabahah yang dilunasi adalah harga jual (pokok + seluruh margin),
  /// bukan pokoknya saja seperti pada akad lain.
  double get _openingBalance => widget.contract == FinancingContract.murabahah
      ? _summary.totalPayment
      : _summary.totalPrincipal;

  /// Menjumlahkan satu kolom. Memakai [sumOf] yang melewati nilai non-finite —
  /// sebelumnya `NaN.toInt()` di sini melempar `UnsupportedError` dan
  /// meng-crash layar begitu ada satu saja hasil perhitungan yang tidak wajar.
  int getTotal(String type) {
    final double total = switch (type) {
      "principal" => _summary.totalPrincipal,
      "interest" => _summary.totalInterest,
      "installment" => _summary.totalPayment,
      "principal_remain" => sumOf(_results, (e) => e.principalTotalRemain),
      _ => 0,
    };
    return total.isFinite ? total.round() : 0;
  }

  Future<File> _generatePdf() => PdfUtil.generatePrincipalPDF(
        _results,
        totalPrincipal: getTotal("principal"),
        totalInstallment: getTotal("installment"),
        totalInterest: getTotal("interest"),
        tieredInterest: widget.tieredInterest,
        type: widget.type,
        calculateModel: widget.calculateModel,
        contract: widget.contract,
        schemeLabel: _schemeLabel,
      );

  Future<void> sharePDF() async {
    if (_isBusy) return;
    _isBusy = true;
    LoadingOverlay.show(context);
    try {
      final File filePdf = await _generatePdf();
      LoadingOverlay.hide();

      await SharePlus.instance.share(ShareParams(
        title: 'Tabel Angsuran',
        text: 'Tabel Angsuran Kalkulator KPR',
        files: [XFile(filePdf.path)],
      ));
    } catch (error, stack) {
      LoadingOverlay.hide();
      ErrorReporter.report(error, stack, hint: 'sharePDF');
      _showFailure('Gagal membagikan tabel angsuran. Silakan coba lagi.');
    } finally {
      _isBusy = false;
    }
  }

  Future<void> downloadPDF() async {
    if (_isBusy) return;
    _isBusy = true;
    // Sebelumnya proses ini berjalan tanpa indikator apa pun sehingga layar
    // terlihat membeku saat PDF dibuat.
    LoadingOverlay.show(context);
    try {
      final File filePdf = await _generatePdf();
      await FlutterFileSaver().writeFileAsBytes(
        fileName:
            PdfUtil.suggestedFileName(widget.type, contract: widget.contract),
        bytes: await filePdf.readAsBytes(),
      );
      LoadingOverlay.hide();

      if (!mounted) return;
      CustomSnackbar.show(context,
          title: "Download Berhasil",
          message: "Silahkan cek folder download.",
          type: SnackbarType.success);
    } catch (error, stack) {
      LoadingOverlay.hide();
      ErrorReporter.report(error, stack, hint: 'downloadPDF');
      // Kegagalan tidak lagi ditelan diam-diam.
      _showFailure('Gagal menyimpan tabel angsuran. Silakan coba lagi.');
    } finally {
      _isBusy = false;
    }
  }

  void _showFailure(String message) {
    if (!mounted) return;
    CustomSnackbar.show(context,
        title: 'Gagal', message: message, type: SnackbarType.failure);
  }

  // ===========================================================================
  // Simpan ke riwayat (F-5)
  // ===========================================================================

  Future<void> _saveSimulation() async {
    final CalculateModel? model = widget.calculateModel;
    final CalculatorType? type = widget.type;
    if (model == null || type == null || _isSaving) return;

    if (_savedId != null) {
      CustomSnackbar.show(context,
          title: 'Sudah Tersimpan',
          message: 'Simulasi ini sudah ada di riwayat.',
          type: SnackbarType.warning);
      return;
    }

    _isSaving = true;
    try {
      final repository = SimulationHistoryRepository.instance;

      // Kuota hanya berlaku untuk pengguna gratis.
      if (!_cubit.isPremium() && await repository.isFreeQuotaFull()) {
        if (!mounted) return;
        await _showQuotaDialog();
        return;
      }

      if (!mounted) return;
      final String? name = await _askSimulationName(
        SimulationHistory.suggestName(type, model, contract: widget.contract),
      );
      if (name == null || !mounted) return;

      final SimulationHistory entry = SimulationHistory.fromCalculation(
        name: name,
        type: type,
        model: model,
        summary: _summary,
        tieredInterest: widget.tieredInterest,
        contract: widget.contract,
      );
      final int id = await repository.save(entry);

      if (!mounted) return;
      setState(() => _savedId = id);
      CustomSnackbar.show(context,
          title: 'Tersimpan',
          message: 'Simulasi disimpan sebagai "$name".',
          type: SnackbarType.success);
    } catch (error, stack) {
      ErrorReporter.report(error, stack, hint: 'saveSimulation');
      _showFailure('Gagal menyimpan simulasi. Silakan coba lagi.');
    } finally {
      _isSaving = false;
    }
  }

  Future<String?> _askSimulationName(String suggestion) {
    return NameInputDialog.show(
      context,
      title: 'Simpan Simulasi',
      initialValue: suggestion,
      hintText: 'Mis. BTN 15 tahun',
      allowEmpty: true,
    );
  }

  Future<void> _showQuotaDialog() {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Riwayat Penuh'),
        content: Text(
          'Pengguna gratis dapat menyimpan '
          '${SimulationHistoryRepository.freeLimit} simulasi. Hapus salah satu '
          'lewat menu Riwayat Simulasi, atau upgrade premium untuk menyimpan '
          'tanpa batas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Nanti'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(dialogContext);
              showPremiumPaywall(context);
            },
            child: const Text('Upgrade Premium'),
          ),
        ],
      ),
    );
  }

  void _requirePremium(String action, VoidCallback onGranted) {
    if (!_cubit.isPremium()) {
      CustomSnackbar.show(context,
          title: "Premium",
          message: "Upgrade premium untuk $action tabel angsuran",
          type: SnackbarType.warning);
      return;
    }
    onGranted();
  }

  /// Warna kepala halaman (AppBar + ringkasan), sama dengan nada latar beranda.
  static const Color _headerColor = AppColors.headerTint;

  Widget _premiumDot(bool visible, Widget icon) => Badge(
        isLabelVisible: visible,
        smallSize: 8,
        backgroundColor: AppColors.premiumGold,
        child: icon,
      );

  @override
  void initState() {
    _cubit = BlocProvider.of<PurchaseCubit>(context);
    _savedId = widget.savedHistoryId;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        // Judul dipindah ke ringkasan di bawah AppBar; AppBar hanya berisi
        // tombol kembali dan aksi, sewarna dengan ringkasan supaya keduanya
        // terlihat sebagai satu bagian kepala halaman.
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _headerColor,
        actions: [
          if (widget.calculateModel != null && widget.type != null)
            IconButton(
                // Ringkas supaya judul tidak terpotong saat tab premium tampil.
                visualDensity: VisualDensity.compact,
                tooltip: _savedId == null
                    ? 'Simpan ke riwayat'
                    : 'Sudah tersimpan di riwayat',
                onPressed: _saveSimulation,
                icon: Icon(_savedId == null
                    ? Icons.bookmark_add_outlined
                    : Icons.bookmark)),
          // Download & share khusus premium: titik emas di ikonnya memberi
          // tahu user gratis sebelum mereka menekan tombolnya.
          BlocBuilder<PurchaseCubit, PurchaseState>(
            builder: (context, state) {
              // Hanya saat status "bukan premium" sudah pasti, supaya user
              // premium tidak sempat melihat titik saat status masih dicek.
              final bool locked = state is PurchaseNothing;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Download PDF',
                      onPressed: () => _requirePremium('download', downloadPDF),
                      icon: _premiumDot(
                          locked, const Icon(Icons.download_outlined))),
                  IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Bagikan PDF',
                      onPressed: () => _requirePremium('share', sharePDF),
                      icon: _premiumDot(
                          locked, const Icon(Icons.share_outlined))),
                  if (locked)
                    PremiumTab(
                      isPremium: false,
                      onTap: () => showPremiumPaywall(context),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      drawer: widget.calculateModel?.floatingInterest == null
          ? null
          : Drawer(
              child: SafeArea(
                child: Column(
                  children: [
                    ListTile(
                      visualDensity: VisualDensity(vertical: -4),
                      contentPadding: EdgeInsets.only(left: 16, right: 4),
                      selectedColor: AppColors.primary,
                      title: const Text(
                        'Detail Angsuran',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      // subtitle: const Text(''),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.primary,
                        ),
                        onPressed: () {
                          _scaffoldKey.currentState?.openEndDrawer();
                        },
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(top: 16),
                        child: Column(
                          children: [
                            ListTile(
                              visualDensity: VisualDensity(vertical: -4),
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 16),
                              selectedColor: AppColors.primary,
                              title: const Text('Jenis'),
                              trailing: Icon(Icons.category_outlined),
                              subtitle: Text(
                                widget.type == CalculatorType.flat
                                    ? 'Flat'
                                    : widget.type == CalculatorType.effective
                                        ? 'Efektif'
                                        : 'Anuitas',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary),
                              ),
                            ),
                            Divider(),
                            ListTile(
                              visualDensity: VisualDensity(vertical: -4),
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 16),
                              selectedColor: AppColors.primary,
                              title: const Text('Jumlah Pinjaman'),
                              trailing: Icon(Icons.attach_money),
                              subtitle: Text(
                                "Rp${currencyId.format(widget.calculateModel!.initialLoan)}",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary),
                              ),
                            ),
                            Divider(),
                            ListTile(
                              visualDensity: VisualDensity(vertical: -4),
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 16),
                              selectedColor: AppColors.primary,
                              title: const Text('DP (Down Payment)'),
                              trailing: Icon(Icons.attach_money),
                              subtitle: Text(
                                "Rp${currencyId.format(widget.calculateModel!.dpNominal)}",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary),
                              ),
                            ),
                            Divider(),
                            ListTile(
                              visualDensity: VisualDensity(vertical: -4),
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 16),
                              selectedColor: AppColors.primary,
                              title: const Text('Total Pinjaman'),
                              trailing: Icon(Icons.attach_money),
                              subtitle: Text(
                                "Rp${currencyId.format(widget.calculateModel!.loan)}",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary),
                              ),
                            ),
                            Divider(),
                            ListTile(
                              visualDensity: VisualDensity(vertical: -4),
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 16),
                              selectedColor: AppColors.primary,
                              title: const Text('Total Waktu Pinjaman'),
                              trailing: Icon(Icons.timer_outlined),
                              subtitle: Text(
                                '${currencyId.format(widget.calculateModel!.year)} Tahun',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary),
                              ),
                            ),
                            if (widget.calculateModel?.fixInterest != null)
                              Column(
                                children: [
                                  Divider(),
                                  ListTile(
                                    visualDensity: VisualDensity(vertical: -4),
                                    contentPadding:
                                        EdgeInsets.symmetric(horizontal: 16),
                                    title: const Text('Bunga Fix'),
                                    trailing: Icon(Icons.percent),
                                    subtitle: Text(
                                      '${widget.calculateModel?.fixInterest ?? '0'}%',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary),
                                    ),
                                  ),
                                ],
                              ),
                            if (widget.calculateModel?.fixYear != null &&
                                widget.tieredInterest == null)
                              Column(
                                children: [
                                  Divider(),
                                  ListTile(
                                    visualDensity: VisualDensity(vertical: -4),
                                    contentPadding:
                                        EdgeInsets.symmetric(horizontal: 16),
                                    selectedColor: AppColors.primary,
                                    title: const Text('Masa Bunga Fix'),
                                    trailing: Icon(Icons.date_range),
                                    subtitle: Text(
                                      '${(widget.calculateModel?.fixYear ?? 0).toInt()} Tahun',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary),
                                    ),
                                  ),
                                ],
                              ),
                            for (int i = 0;
                                i < (widget.tieredInterest ?? []).length;
                                i++)
                              Column(
                                children: [
                                  Divider(),
                                  ListTile(
                                    visualDensity: VisualDensity(vertical: -4),
                                    contentPadding:
                                        EdgeInsets.symmetric(horizontal: 16),
                                    selectedColor: AppColors.primary,
                                    title: Text('Bunga Fix Tahun ke ${i + 1}'),
                                    trailing: Icon(Icons.date_range),
                                    subtitle: Text(
                                      '${widget.tieredInterest![i]}%',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary),
                                    ),
                                  ),
                                ],
                              ),
                            if (widget.calculateModel?.floatingInterest != null)
                              Column(
                                children: [
                                  Divider(),
                                  ListTile(
                                    visualDensity: VisualDensity(vertical: -4),
                                    contentPadding:
                                        EdgeInsets.symmetric(horizontal: 16),
                                    trailing: Icon(Icons.percent),
                                    selectedColor: AppColors.primary,
                                    title: const Text('Bunga Floating'),
                                    subtitle: Text(
                                      '${widget.calculateModel?.floatingInterest ?? '0'}%',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary),
                                    ),
                                  ),
                                ],
                              ),
                            Divider(),
                            Card(
                              color: AppColors.primary,
                              child: ListTile(
                                visualDensity: VisualDensity(vertical: -4),
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 16),
                                trailing: Icon(
                                  Icons.attach_money,
                                  color: Colors.white,
                                ),
                                selectedColor: AppColors.primary,
                                title: const Text(
                                  'Total Angsuran',
                                  style: TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  'Rp${currencyId.format(getTotal("installment"))}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      body: SafeArea(
        top: false,
        child: DefaultTabController(
          length: 3,
          // Ringkasan & banner ikut tergulung ke atas, sedangkan TabBar
          // menempel di bawah AppBar. Absorber/injector mencegah isi tab
          // tertutup TabBar yang menempel.
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Judul + ringkasan input menyambung langsung dari AppBar
                    // (warna sama, rata tanpa kartu maupun sudut membulat).
                    Container(
                      width: size.width,
                      color: _headerColor,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(bottom: 14),
                            child: Text(
                              'Tabel Angsuran',
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(widget.contract.isSharia
                                      ? 'Akad'
                                      : 'Jenis'),
                                ),
                                Text(
                                  _schemeLabel,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary),
                                )
                              ],
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(_terms.financing),
                                ),
                                Text(
                                  "Rp. ${currencyId.format(widget.calculateModel!.loan)}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                )
                              ],
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text('Jangka Waktu (Tahun)'),
                                ),
                                Text(
                                  currencyId
                                      .format(widget.calculateModel!.year),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                )
                              ],
                            ),
                          ),
                          if (widget.calculateModel?.floatingInterest == null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(_terms.rate),
                                  ),
                                  Text(
                                    '${widget.calculateModel!.interest!}%',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  )
                                ],
                              ),
                            ),
                          if (widget.calculateModel?.floatingInterest != null)
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(
                                        color: AppColors.primary),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                  onPressed: () {
                                    _scaffoldKey.currentState?.openDrawer();
                                  },
                                  child: Text('Selengkapnya')),
                            ),
                        ],
                      ),
                    ),
                    Center(
                      child: BannerAdWidget(
                        margin:
                            const EdgeInsets.only(left: 15, right: 15, top: 15),
                        placement: BannerPlacement.principalTable,
                      ),
                    ),
                  ],
                ),
              ),
              SliverOverlapAbsorber(
                handle:
                    NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                sliver: SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarHeader(),
                ),
              ),
            ],
            body: TabBarView(
              children: [
                InstallmentChart(
                  results: _results,
                  summary: _summary,
                  terms: _terms,
                  openingBalance: _openingBalance,
                ),
                InstallmentTableView(
                  results: _results,
                  terms: _terms,
                  totalPrincipal: getTotal("principal"),
                  totalInterest: getTotal("interest"),
                  totalInstallment: getTotal("installment"),
                ),
                AffordabilityTab(results: _results),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// TabBar yang menempel di bawah AppBar saat ringkasan tergulung ke atas.
class _TabBarHeader extends SliverPersistentHeaderDelegate {
  static const double _height = 48;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.gridLine)),
      ),
      child: const TabBar(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.onSurface,
        indicatorColor: AppColors.primary,
        // Tiga tab harus muat di layar 360dp tanpa label terpotong.
        labelPadding: EdgeInsets.symmetric(horizontal: 4),
        labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 13),
        tabs: [
          Tab(text: 'Grafik'),
          Tab(text: 'Tabel'),
          Tab(text: 'Kemampuan Bayar'),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarHeader oldDelegate) => false;
}
