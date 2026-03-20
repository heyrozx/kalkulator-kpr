import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kalkulator_kpr/blocs/purchase_cubit/purchase_cubit.dart';
import 'package:kalkulator_kpr/core/loading_overlay.dart';
import 'package:kalkulator_kpr/core/purchases.dart';
import 'package:kalkulator_kpr/pages/premiums/payment_success.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PremiumPlanScreen extends StatefulWidget {
  const PremiumPlanScreen({super.key});

  @override
  State<PremiumPlanScreen> createState() => _PremiumPlanScreenState();
}

class _PremiumPlanScreenState extends State<PremiumPlanScreen> {
  final Purchase purchase = Purchase();
  int _selectedIndex = 0;
  late PurchaseCubit _cubit;

  List<Package> packages = [];

  Future getPackage() async {
    packages = await purchase.getPackages();
    setState(() {});
  }

  @override
  void initState() {
    _cubit = BlocProvider.of<PurchaseCubit>(context);
    getPackage();
    super.initState();

    Purchases.addCustomerInfoUpdateListener((customerInfo) {
      if (kDebugMode) print('customer info update');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade300,
      body: BlocListener<PurchaseCubit, PurchaseState>(
        listener: (context, state) {
          if (state is PurchaseData) {
            LoadingOverlay.hide();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => const PaymentSuccess()),
              ModalRoute.withName('/payment_success'),
            );
          } else if (state is PurchaseError) {
            LoadingOverlay.hide();
            _cubit.checkPremium();
            // Fluttertoast.showToast(
            //     msg: "Oops, Something went wrong! please try again later");
          }
        },
        child: packages.isEmpty
            ? SizedBox(
                child: Center(
                    child: CircularProgressIndicator(
                  color: Colors.red.shade700,
                )),
              )
            : Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Image.asset(
                            'assets/premium_image.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                        SafeArea(
                          child: Align(
                              alignment: Alignment.topLeft,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(context),
                              )),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: double.infinity,
                            // padding: const EdgeInsets.symmetric(
                            //     horizontal: 25, vertical: 20),
                            padding: const EdgeInsets.only(
                                top: 20, left: 25, right: 25, bottom: 10),
                            decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(15),
                                    topRight: Radius.circular(15))),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  margin:
                                      const EdgeInsets.only(bottom: 5, top: 10),
                                  child: const Text('Kalkulator KPR Premium',
                                      style: TextStyle(
                                        fontSize: 25,
                                        fontWeight: FontWeight.bold,
                                      )),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(bottom: 20),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18.0),
                                    child: const Text(
                                      'Perbarui ke paket baru untuk menikmati lebih banyak manfaat',
                                      textAlign: TextAlign.center,
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(
                        left: 25, right: 25, bottom: 20, top: 10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          child: const Wrap(
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                // crossAxisAlignment: CrossAxisAlignment.center,
                                // mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check,
                                    color: Colors.purple,
                                  ),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  Text('Tanpa Iklan')
                                ],
                              ),
                              SizedBox(width: 15),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                // crossAxisAlignment: CrossAxisAlignment.center,
                                // mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check,
                                    color: Colors.purple,
                                  ),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  Text('Akses Semua Fitur')
                                ],
                              ),
                            ],
                          ),
                        ),
                        for (int index = 0; index < packages.length; index++)
                          // if (packages[index].storeProduct.identifier.contains(
                          //     'lifetime_premium_100000')) // not using lifetime anymore
                          GestureDetector(
                            onTap: () {
                              if (_selectedIndex != index) {
                                setState(() {
                                  _selectedIndex = index;
                                });
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: _selectedIndex == index
                                    ? Colors.purple.shade100
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ListTile(
                                leading: Icon(Icons.stars,
                                    color: packages[index]
                                                .storeProduct
                                                .identifier ==
                                            'lifetime_premium_100000'
                                        ? Colors.purple
                                        : Colors.amber),
                                title: Text(
                                  packages[index].storeProduct.title.replaceAll(
                                      " (Kalkulator KPR Simulasi Kredit)", ""),
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  packages[index].storeProduct.description,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Text(
                                    packages[index].storeProduct.priceString,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    )),
                              ),
                            ),
                          ),
                        Container(
                          margin: const EdgeInsets.only(bottom: 15, top: 15),
                          width: double.infinity,
                          child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 15, horizontal: 18)),
                              onPressed: () async {
                                LoadingOverlay.show(context);
                                _cubit.makePurchase(packages[_selectedIndex]);
                              },
                              child: const Text(
                                'Lanjutkan',
                                style: TextStyle(fontSize: 16),
                              )),
                        ),
                        Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          child: const Text(
                            'Pembelian ini hanya dapat digunakan di sistem Android. Pembayaran akan dibebankan ke akun Google Play Anda setelah pembelian dikonfirmasi.',
                            style: TextStyle(color: Colors.grey, fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.purple,
                            ),
                            onPressed: () {
                              LoadingOverlay.show(context);
                              _cubit.restorePurchase();
                            },
                            child: const Text('Kembalikan Pembelian'))
                      ],
                    ),
                  )
                ],
              ),
      ),
    );
  }
}
