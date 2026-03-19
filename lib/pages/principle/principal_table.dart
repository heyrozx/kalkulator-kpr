// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:math';

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_file_saver/flutter_file_saver.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kalkulator_kpr/blocs/purchase_cubit/purchase_cubit.dart';
import 'package:kalkulator_kpr/core/currency_format.dart';
import 'package:kalkulator_kpr/core/loading_overlay.dart';
import 'package:kalkulator_kpr/models/calculate_model.dart';
import 'package:kalkulator_kpr/pages/premiums/premium_plan_screen.dart';
import 'package:kalkulator_kpr/utils/custom_snackbar.dart';
import 'package:kalkulator_kpr/utils/pdf_util.dart';
import 'package:share_plus/share_plus.dart';

enum StatusAd { initial, loaded }

class PrincipalTable extends StatefulWidget {
  final List<double>? tieredInterest;
  final List<CalculateResultModel>? results;
  final CalculateModel? calculateModel;
  final CalculatorType? type;
  const PrincipalTable(
      {super.key,
      this.results,
      this.calculateModel,
      this.type,
      this.tieredInterest});

  @override
  State<PrincipalTable> createState() => _PrincipalTableState();
}

class _PrincipalTableState extends State<PrincipalTable> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int month = 0;
  List<DataRow> rows = [];
  late PurchaseCubit _cubit;

  List<DataRow> setRowValue() {
    return (widget.results ?? []).map((e) {
      month++;
      return DataRow(
        cells: <DataCell>[
          DataCell(GestureDetector(
            onTap: () {},
            child: Text(
              month.toString(),
            ),
          )),
          DataCell(Text(currencyId.format(e.principal))),
          DataCell(Text(currencyId.format(e.interestResult))),
          DataCell(Text(
            currencyId.format(e.installmentResult),
            style: TextStyle(fontWeight: FontWeight.bold),
          )),
          DataCell(Text(currencyId.format(
              e.principalTotalRemain! < 1 ? 0 : e.principalTotalRemain!))),
        ],
      );
    }).toList();
  }

  void addFooter() {
    rows.add(DataRow(
      cells: <DataCell>[
        DataCell(const Text(
          "Total",
          style: TextStyle(fontWeight: FontWeight.bold),
        )),
        DataCell(Text(
          currencyId.format(getTotal("principal")),
          style: const TextStyle(fontWeight: FontWeight.bold),
        )),
        DataCell(Text(currencyId.format(getTotal("interest")),
            style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(currencyId.format(getTotal("installment")),
            style: const TextStyle(fontWeight: FontWeight.bold))),
        const DataCell(
            Text("--", style: TextStyle(fontWeight: FontWeight.bold))),
      ],
    ));
  }

  int getTotal(String type) {
    int data = 0;
    for (var i = 0; i < (widget.results ?? []).length; i++) {
      if (type == "principal") {
        data = data + widget.results![i].principal!.toInt();
      } else if (type == "interest") {
        data = data + widget.results![i].interestResult!.toInt();
      } else if (type == "installment") {
        data = data + widget.results![i].installmentResult!.toInt();
      } else if (type == "principal_remain") {
        data = data + widget.results![i].principalTotalRemain!.toInt();
      }
    }
    return data;
  }

  BannerAd? myBanner;

  StatusAd statusAd = StatusAd.initial;

  BannerAdListener listener() => BannerAdListener(
        onAdLoaded: (Ad ad) {
          setState(() {
            statusAd = StatusAd.loaded;
          });
        },
      );

  Future<void> sharePDF() async {
    LoadingOverlay.show(context);
    try {
      File filePdf = await PdfUtil.generatePrincipalPDF(widget.results ?? [],
          totalPrincipal: getTotal("principal"),
          totalInstallment: getTotal("installment"),
          totalInterest: getTotal("interest"),
          tieredInterest: widget.tieredInterest,
          type: widget.type,
          calculateModel: widget.calculateModel);
      LoadingOverlay.hide();

      SharePlus.instance.share(ShareParams(
        title: 'Tabel Angsuran',
        text: 'Tabel Angsuran Kalkulator KPR',
        files: [XFile(filePdf.path)],
      ));
    } catch (e) {
      LoadingOverlay.hide();
    }
  }

  Future<void> downloadPDF() async {
    try {
      File filePdf = await PdfUtil.generatePrincipalPDF(widget.results ?? [],
          totalPrincipal: getTotal("principal"),
          totalInstallment: getTotal("installment"),
          totalInterest: getTotal("interest"),
          tieredInterest: widget.tieredInterest,
          type: widget.type,
          calculateModel: widget.calculateModel);

      await FlutterFileSaver().writeFileAsBytes(
        fileName:
            "Tabel-angsuran-kalkulator-kpr-${Random().nextInt(10000)}.pdf",
        bytes: await filePdf.readAsBytes(),
      );
      LoadingOverlay.hide();

      CustomSnackbar.show(context,
          title: "Download Berhasil",
          message: "Silahkan cek folder download.",
          type: SnackbarType.success);
    } catch (e) {
      LoadingOverlay.hide();
    }
  }

  @override
  void initState() {
    _cubit = BlocProvider.of<PurchaseCubit>(context);

    rows = setRowValue();
    addFooter();

    if (!kDebugMode && !_cubit.isPremium()) {
      myBanner = BannerAd(
        adUnitId: kDebugMode
            ? 'ca-app-pub-3940256099942544/6300978111'
            : 'ca-app-pub-2465007971338713/9945891754',
        size: AdSize.fullBanner,
        request: const AdRequest(),
        listener: listener(),
      );
      myBanner!.load();
    }

    super.initState();
  }

  @override
  void dispose() {
    if (myBanner != null) {
      myBanner!.dispose();
    }
    super.dispose();
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
        title: const Text(
          'Tabel Angsuran',
          style: TextStyle(fontSize: 16),
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
              onPressed: () {
                if (!_cubit.isPremium()) {
                  CustomSnackbar.show(context,
                      title: "Premium",
                      message: "Upgrade premium untuk download tabel angsuran",
                      type: SnackbarType.warning);
                  return;
                }

                downloadPDF();
              },
              icon: Icon(Icons.download_outlined)),
          IconButton(
              onPressed: () {
                if (!_cubit.isPremium()) {
                  CustomSnackbar.show(context,
                      title: "Premium",
                      message: "Upgrade premium untuk share tabel angsuran",
                      type: SnackbarType.warning);
                  return;
                }
                sharePDF();
              },
              icon: Icon(Icons.share_outlined)),
          BlocBuilder<PurchaseCubit, PurchaseState>(
            builder: (context, state) {
              if (state is PurchaseNothing) {
                return IconButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) {
                      return const PremiumPlanScreen();
                    }));
                  },
                  icon: SizedBox(
                    width: 30,
                    child: Image.asset('assets/premium.png'),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
          const SizedBox(
            width: 7,
          )
        ],
        foregroundColor: Colors.black,
        backgroundColor: Colors.transparent,
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
                      selectedColor: Colors.purple,
                      title: const Text(
                        'Detail Angsuran',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      // subtitle: const Text(''),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.purple,
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
                              selectedColor: Colors.purple,
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
                                    color: Colors.purple),
                              ),
                            ),
                            Divider(),
                            ListTile(
                              visualDensity: VisualDensity(vertical: -4),
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 16),
                              selectedColor: Colors.purple,
                              title: const Text('Jumlah Pinjaman'),
                              trailing: Icon(Icons.attach_money),
                              subtitle: Text(
                                "Rp${currencyId.format(widget.calculateModel!.initialLoan)}",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple),
                              ),
                            ),
                            Divider(),
                            ListTile(
                              visualDensity: VisualDensity(vertical: -4),
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 16),
                              selectedColor: Colors.purple,
                              title: const Text('DP (Down Payment)'),
                              trailing: Icon(Icons.attach_money),
                              subtitle: Text(
                                "Rp${currencyId.format(widget.calculateModel!.dpNominal)}",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple),
                              ),
                            ),
                            Divider(),
                            ListTile(
                              visualDensity: VisualDensity(vertical: -4),
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 16),
                              selectedColor: Colors.purple,
                              title: const Text('Total Pinjaman'),
                              trailing: Icon(Icons.attach_money),
                              subtitle: Text(
                                "Rp${currencyId.format(widget.calculateModel!.loan)}",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple),
                              ),
                            ),
                            Divider(),
                            ListTile(
                              visualDensity: VisualDensity(vertical: -4),
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 16),
                              selectedColor: Colors.purple,
                              title: const Text('Total Waktu Pinjaman'),
                              trailing: Icon(Icons.timer_outlined),
                              subtitle: Text(
                                '${currencyId.format(widget.calculateModel!.year)} Tahun',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple),
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
                                          color: Colors.purple),
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
                                    selectedColor: Colors.purple,
                                    title: const Text('Masa Bunga Fix'),
                                    trailing: Icon(Icons.date_range),
                                    subtitle: Text(
                                      '${(widget.calculateModel?.fixYear ?? 0).toInt()} Tahun',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.purple),
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
                                    selectedColor: Colors.purple,
                                    title: Text('Bunga Fix Tahun ke ${i + 1}'),
                                    trailing: Icon(Icons.date_range),
                                    subtitle: Text(
                                      '${widget.tieredInterest![i]}%',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.purple),
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
                                    selectedColor: Colors.purple,
                                    title: const Text('Bunga Floating'),
                                    subtitle: Text(
                                      '${widget.calculateModel?.floatingInterest ?? '0'}%',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.purple),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                width: size.width,
                margin: const EdgeInsets.only(top: 15, left: 15, right: 15),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 5,
                      blurRadius: 3,
                      offset: const Offset(0, 1), // changes position of shadow
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text('Jenis'),
                          ),
                          Text(
                            widget.type == CalculatorType.flat
                                ? 'Flat'
                                : widget.type == CalculatorType.effective
                                    ? 'Efektif'
                                    : 'Anuitas',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.purple),
                          )
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text('Jumlah Pinjaman'),
                          ),
                          Text(
                            "Rp. ${currencyId.format(widget.calculateModel!.loan)}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
                            currencyId.format(widget.calculateModel!.year),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )
                        ],
                      ),
                    ),
                    if (widget.calculateModel?.floatingInterest == null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text('Bunga'),
                            ),
                            Text(
                              '${widget.calculateModel!.interest!}%',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            )
                          ],
                        ),
                      ),
                    if (widget.calculateModel?.floatingInterest != null)
                      GestureDetector(
                        onTap: () {
                          _scaffoldKey.currentState?.openDrawer();
                        },
                        child: Container(
                          padding: const EdgeInsets.only(top: 8),
                          child: const Text(
                            'Selengkapnya',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.purple),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              statusAd == StatusAd.loaded
                  ? Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: size.width,
                        margin:
                            const EdgeInsets.only(top: 15, left: 15, right: 15),
                        // padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          // borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.1),
                              spreadRadius: 5,
                              blurRadius: 3,
                              offset: const Offset(
                                  0, 1), // changes position of shadow
                            ),
                          ],
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          width: myBanner!.size.width.toDouble(),
                          height: myBanner!.size.height.toDouble(),
                          child: AdWidget(ad: myBanner!),
                        ),
                      ),
                    )
                  : const SizedBox(),
              Expanded(
                child: Container(
                    width: size.width,
                    margin: const EdgeInsets.only(
                        top: 15, left: 15, right: 15, bottom: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.2),
                          spreadRadius: 4,
                          blurRadius: 3,
                          offset:
                              const Offset(0, 1), // changes position of shadow
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: DataTable2(
                        headingRowColor: WidgetStateColor.resolveWith(
                          (states) {
                            return Colors.purple;
                          },
                        ),
                        minWidth: 700,
                        headingTextStyle:
                            const TextStyle(fontWeight: FontWeight.bold),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5)),
                        columns: const [
                          DataColumn2(
                            size: ColumnSize.S,
                            label: Text(
                              'Bulan\nke',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          DataColumn2(
                            label: Text(
                              'Angsuran\nPokok',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          DataColumn2(
                            size: ColumnSize.L,
                            label: Text(
                              'Bunga',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white),
                            ),
                            // onSort: sortColumn,
                          ),
                          DataColumn2(
                            label: Text(
                              'Jumlah\nAngsuran',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          DataColumn2(
                            label: Text(
                              'Sisa\nPinjaman',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                        rows: rows,
                      ),
                    )),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
