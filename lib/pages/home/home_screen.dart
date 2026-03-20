// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kalkulator_kpr/blocs/purchase_cubit/purchase_cubit.dart';
import 'package:kalkulator_kpr/core/currency_format.dart';
import 'package:kalkulator_kpr/core/helpers.dart';
import 'package:kalkulator_kpr/core/loading_overlay.dart';
import 'package:kalkulator_kpr/models/calculate_model.dart';
import 'package:kalkulator_kpr/pages/about/anuitas_description.dart';
import 'package:kalkulator_kpr/pages/about/effective_description.dart';
import 'package:kalkulator_kpr/pages/about/flat_description.dart';
import 'package:kalkulator_kpr/pages/advanced/advanced_screen.dart';
import 'package:kalkulator_kpr/pages/premiums/premium_plan_screen.dart';
import 'package:kalkulator_kpr/pages/principle/principal_table.dart';
import 'package:pattern_formatter/numeric_formatter.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

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
  InterstitialAd? _interstitialAd;

  CalculateResultModel? result;

  CalculatorType type = CalculatorType.anuitas;

  double? percentIndicator = 0;

  Future calculate() async {
    if (_formKey.currentState!.validate()) {
      percentIndicator = 0;
      setState(() {});
      // result = null;
      // setState(() {});
      LoadingOverlay.show(context);
      await Future.delayed(const Duration(seconds: 1));
      CalculateModel calculateModel = CalculateModel(
        loan: double.parse(CurrencyFormat.toNumber(_loanController.text)),
        year: double.parse(CurrencyFormat.toNumber(_yearController.text)),
        interest: double.parse(
            CurrencyFormat.toNumberComma(_interestController.text)),
      );
      if (type == CalculatorType.flat) {
        result = calculateFlat(calculateModel);
      } else if (type == CalculatorType.effective) {
        result = calculateEffective(calculateModel);
      } else {
        result = calculateAnuitas(calculateModel);
      }
      if (result != null) {
        percentIndicator = result!.principal! / result!.installmentResult!;
      }
      LoadingOverlay.hide();
      // print(result?.toJson());
      setState(() {});
    }
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url),
        mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  void initState() {
    PurchaseCubit cubit = BlocProvider.of<PurchaseCubit>(context);
    cubit.checkPremium().then((value) {
      if (!kDebugMode && !cubit.isPremium()) {
        InterstitialAd.load(
            adUnitId: kDebugMode
                ? 'ca-app-pub-3940256099942544/1033173712'
                : 'ca-app-pub-2465007971338713/3842103086',
            request: const AdRequest(),
            adLoadCallback: InterstitialAdLoadCallback(
              // Called when an ad is successfully received.
              onAdLoaded: (ad) {
                debugPrint('$ad loaded.');
                // Keep a reference to the ad so you can show it later.
                _interstitialAd = ad;
              },
              // Called when an ad request failed.
              onAdFailedToLoad: (LoadAdError error) {
                debugPrint('InterstitialAd failed to load: $error');
              },
            ));
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
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
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                          fontSize: 20),
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    Text(
                      'Simulasi Kredit',
                      style: TextStyle(),
                    ),
                  ],
                ),
              ),
              const Divider(
                thickness: 0.5,
              ),
              ListTile(
                selected: type == CalculatorType.anuitas,
                selectedColor: Colors.purple,
                title: const Text('Bunga Anuitas'),
                onTap: () {
                  type = CalculatorType.anuitas;
                  _scaffoldKey.currentState?.openEndDrawer();
                  if (!(_loanController.text == '' ||
                      _yearController.text == '' ||
                      _interestController.text == '')) {
                    calculate();
                  } else {
                    setState(() {});
                  }
                },
              ),
              ListTile(
                selected: type == CalculatorType.effective,
                selectedColor: Colors.purple,
                title: const Text('Bunga Efektif'),
                onTap: () {
                  type = CalculatorType.effective;
                  _scaffoldKey.currentState?.openEndDrawer();
                  if (!(_loanController.text == '' ||
                      _yearController.text == '' ||
                      _interestController.text == '')) {
                    calculate();
                  } else {
                    setState(() {});
                  }
                },
              ),
              ListTile(
                selected: type == CalculatorType.flat,
                selectedColor: Colors.purple,
                title: const Text('Bunga Flat'),
                onTap: () {
                  type = CalculatorType.flat;
                  _scaffoldKey.currentState?.openEndDrawer();
                  if (!(_loanController.text == '' ||
                      _yearController.text == '' ||
                      _interestController.text == '')) {
                    calculate();
                  } else {
                    setState(() {});
                  }
                },
              ),
              Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  width: double.infinity,
                  child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.purple,
                      ),
                      onPressed: () {
                        _scaffoldKey.currentState?.openEndDrawer();
                        Navigator.push(context,
                            MaterialPageRoute(builder: (builder) {
                          return AdvancedScreen(
                            type: type == CalculatorType.flat ? null : type,
                          );
                        }));
                      },
                      child: Text('Advanced'))),
              const Spacer(),
              ListTile(
                title: const Text('Beri Rating'),
                leading: const Icon(
                  Icons.star_outline,
                ),
                onTap: () => _launchUrl(
                    "https://play.google.com/store/apps/details?id=com.caraguna.kalkulator.kpr&hl=en"),
              ),
              ListTile(
                title: const Text('Reset'),
                leading: const Icon(
                  Icons.refresh,
                ),
                onTap: () {
                  _scaffoldKey.currentState?.openEndDrawer();
                  setState(() {
                    result = null;
                    _interestController.text = '';
                    _yearController.text = '';
                    _loanController.text = '';
                  });
                },
              ),
              ListTile(
                title: const Text('Privacy Policy'),
                leading: const Icon(
                  Icons.gpp_maybe_outlined,
                ),
                onTap: () => _launchUrl(
                    "https://nexadream.id/privacy-policy-kalkulator-kpr-simulasi-kredit"),
              ),
              ListTile(
                title: const Text('Versi 1.3.1'),
                leading: const Icon(
                  Icons.info_outline,
                ),
                onTap: () {},
              ),
              const SizedBox(
                height: 15,
              )
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: SizedBox(
              height: size.height,
              child: Column(
                children: [
                  AppBar(
                    title: Text(type == CalculatorType.flat
                        ? 'Flat'
                        : type == CalculatorType.effective
                            ? 'Efektif'
                            : 'Anuitas'),
                    centerTitle: true,
                    elevation: 0,
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
                          if (state is PurchaseNothing) {
                            return IconButton(
                              onPressed: () {
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (_) {
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
                      IconButton(
                        onPressed: () {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (builder) {
                            if (type == CalculatorType.flat) {
                              return const FlatDescription();
                            } else if (type == CalculatorType.effective) {
                              return const EffectiveDescription();
                            } else {
                              return const AnuitasDescription();
                            }
                          }));
                        },
                        icon: SizedBox(
                          width: 25,
                          height: 25,
                          child: Image.asset('assets/question.png'),
                        ),
                      )
                    ],
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.transparent,
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: CircularPercentIndicator(
                          radius: 120.0,
                          lineWidth: 13.0,
                          animation: true,
                          percent: percentIndicator ?? 0,
                          center: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Total Angsuran",
                                style: TextStyle(fontSize: 15.0),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              Text(
                                "Rp ${currencyId.format(result?.installmentResult ?? 0)}",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 25.0),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              Text(
                                type == CalculatorType.flat ||
                                        type == CalculatorType.anuitas
                                    ? "Per Bulan"
                                    : "Bulan Pertama",
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
                                Container(
                                  width: 15,
                                  height: 15,
                                  margin: const EdgeInsets.only(right: 5),
                                  decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.purple),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Angsuran Pokok",
                                      style: TextStyle(),
                                    ),
                                    Text(
                                      "Rp ${currencyId.format(result?.principal ?? 0)}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  width: 15,
                                ),
                                Container(
                                  width: 15,
                                  height: 15,
                                  margin: const EdgeInsets.only(right: 5),
                                  decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Bunga",
                                      style: TextStyle(),
                                    ),
                                    Text(
                                      "Rp ${currencyId.format(result?.interestResult ?? 0)}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          circularStrokeCap: CircularStrokeCap.round,
                          progressColor: Colors.purple,
                        ),
                      ),
                    ),
                  ),
                  Form(
                    key: _formKey,
                    child: Container(
                      // height: size.height * 0.4,
                      width: size.width,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.3),
                              spreadRadius: 2,
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(15))),
                      child: Column(
                        children: [
                          const SizedBox(
                            height: 10,
                          ),
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: TextFormField(
                              controller: _loanController,
                              validator: (value) {
                                if (value == '') {
                                  return "Jumlah pinjaman tidak boleh kosong";
                                }
                                return null;
                              },
                              inputFormatters: [
                                ThousandsFormatter(
                                    allowFraction: false,
                                    formatter:
                                        NumberFormat.decimalPattern('en'))
                              ],
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                // filled: true,
                                // fillColor: Colors.blue.shade100,
                                label: const Text('Jumlah Pinjaman (Rp)'),
                                enabledBorder: OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade400),
                                ),
                                border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade400)),
                                suffixIcon: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Image.asset('assets/money.png'),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _yearController,
                                    validator: (value) {
                                      if (value == '') {
                                        return "Jangka waktu tidak boleh kosong";
                                      }
                                      return null;
                                    },
                                    inputFormatters: [
                                      ThousandsFormatter(
                                          allowFraction: false,
                                          formatter:
                                              NumberFormat.decimalPattern('en'))
                                    ],
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      // filled: true,
                                      // fillColor: Colors.blue.shade100,
                                      label: const Text('Jangka Waktu (Tahun)'),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade400),
                                      ),
                                      border: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.grey.shade400)),
                                      suffixIcon: const Icon(Icons.alarm,
                                          color: Colors.black54),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                Expanded(
                                  child: TextFormField(
                                    controller: _interestController,
                                    validator: (value) {
                                      if (value == '') {
                                        return "Bunga pinjaman tidak boleh kosong";
                                      }
                                      return null;
                                    },
                                    inputFormatters: [
                                      ThousandsFormatter(
                                          allowFraction: true,
                                          formatter:
                                              NumberFormat.decimalPattern('en'))
                                    ],
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      // filled: true,
                                      // fillColor: Colors.blue.shade100,
                                      label: const Text('Bunga Pinjaman'),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade400),
                                      ),
                                      border: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.grey.shade400)),
                                      suffixIcon: const Icon(
                                        Icons.percent,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: size.width,
                            margin: const EdgeInsets.only(top: 5),
                            child: Row(
                              children: [
                                result != null
                                    ? Expanded(
                                        child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.grey.shade300,
                                              foregroundColor: Colors.black87,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(30.0),
                                              ),
                                            ),
                                            onPressed: () => calculate(),
                                            child: const Padding(
                                              padding: EdgeInsets.all(15.0),
                                              child: Text('Hitung Ulang'),
                                            )),
                                      )
                                    : Expanded(
                                        child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.purple,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(30.0),
                                              ),
                                            ),
                                            onPressed: () => calculate(),
                                            child: const Padding(
                                              padding: EdgeInsets.all(15.0),
                                              child: Text('Hitung Simulasi'),
                                            )),
                                      ),
                                SizedBox(
                                  width: result != null ? 10 : 0,
                                ),
                                result != null
                                    ? Expanded(
                                        child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.purple,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(30.0),
                                              ),
                                            ),
                                            onPressed: () async {
                                              if (_interstitialAd != null) {
                                                await _interstitialAd!.show();
                                              }

                                              if (_formKey.currentState!
                                                  .validate()) {
                                                LoadingOverlay.show(context);
                                                CalculateModel calculateModel =
                                                    CalculateModel(
                                                  loanPlafon: double.parse(
                                                      CurrencyFormat.toNumber(
                                                          _loanController
                                                              .text)),
                                                  loan: double.parse(
                                                      CurrencyFormat.toNumber(
                                                          _loanController
                                                              .text)),
                                                  year: double.parse(
                                                      CurrencyFormat.toNumber(
                                                          _yearController
                                                              .text)),
                                                  interest: double.parse(
                                                      CurrencyFormat
                                                          .toNumberComma(
                                                              _interestController
                                                                  .text)),
                                                );

                                                List<CalculateResultModel>
                                                    tables =
                                                    type == CalculatorType.flat
                                                        ? installmentTableFlat(
                                                            calculateModel)
                                                        : type ==
                                                                CalculatorType
                                                                    .effective
                                                            ? installmentTableEffective(
                                                                calculateModel)
                                                            : installmentTableAnuitas(
                                                                calculateModel);
                                                await Future.delayed(
                                                    const Duration(seconds: 1));
                                                LoadingOverlay.hide();

                                                Navigator.push(context,
                                                    MaterialPageRoute(
                                                        builder: (builder) {
                                                  return PrincipalTable(
                                                    results: tables,
                                                    type: type,
                                                    calculateModel:
                                                        CalculateModel(
                                                      loanPlafon: double.parse(
                                                          CurrencyFormat
                                                              .toNumber(
                                                                  _loanController
                                                                      .text)),
                                                      loan: double.parse(
                                                          CurrencyFormat
                                                              .toNumber(
                                                                  _loanController
                                                                      .text)),
                                                      year: double.parse(
                                                          CurrencyFormat
                                                              .toNumber(
                                                                  _yearController
                                                                      .text)),
                                                      interest: double.parse(
                                                          CurrencyFormat
                                                              .toNumberComma(
                                                                  _interestController
                                                                      .text)),
                                                    ),
                                                  );
                                                }));
                                              }
                                            },
                                            child: const Padding(
                                              padding: EdgeInsets.all(15.0),
                                              child: Text('Tabel Angsuran'),
                                            )),
                                      )
                                    : const SizedBox(),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
