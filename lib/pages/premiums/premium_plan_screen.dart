import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kalkulator_kpr/blocs/purchase_cubit/purchase_cubit.dart';
import 'package:kalkulator_kpr/core/config.dart';
import 'package:kalkulator_kpr/core/loading_overlay.dart';
import 'package:kalkulator_kpr/core/purchases.dart';
import 'package:kalkulator_kpr/core/theme.dart';
import 'package:kalkulator_kpr/pages/premiums/payment_success.dart';
import 'package:kalkulator_kpr/utils/custom_snackbar.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PremiumPlanScreen extends StatefulWidget {
  const PremiumPlanScreen({super.key});

  @override
  State<PremiumPlanScreen> createState() => _PremiumPlanScreenState();
}

class _PremiumPlanScreenState extends State<PremiumPlanScreen> {
  final Purchase purchase = Purchase();
  int _selectedIndex = 0;
  bool _isLoadingPackages = true;
  late PurchaseCubit _cubit;

  List<Package> packages = [];

  @override
  void initState() {
    _cubit = BlocProvider.of<PurchaseCubit>(context);
    getPackage();
    super.initState();
  }

  Future<void> getPackage() async {
    final result = await purchase.getPackages();
    // Tanpa cek `mounted`, menutup paywall sebelum offering selesai dimuat
    // memicu "setState() called after dispose()".
    if (!mounted) return;
    setState(() {
      packages = result;
      _isLoadingPackages = false;
    });
  }

  void _onPurchaseState(BuildContext context, PurchaseState state) {
    if (state is PurchaseData) {
      LoadingOverlay.hide();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const PaymentSuccess()),
        ModalRoute.withName('/payment_success'),
      );
    } else if (state is PurchaseError) {
      LoadingOverlay.hide();
      CustomSnackbar.show(context,
          title: 'Gagal',
          message: 'Pembelian tidak dapat diproses. Silakan coba lagi.',
          type: SnackbarType.failure);
    } else if (state is PurchaseNothing) {
      LoadingOverlay.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade300,
      body: BlocListener<PurchaseCubit, PurchaseState>(
        listener: _onPurchaseState,
        child: _isLoadingPackages
            ? const Center(child: CircularProgressIndicator())
            : packages.isEmpty
                ? _buildEmptyState()
                : _buildContent(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Paket premium sedang tidak tersedia. Periksa koneksi internet '
              'Anda lalu coba lagi.',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              setState(() => _isLoadingPackages = true);
              getPackage();
            },
            child: const Text('Coba Lagi'),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
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
                  padding: const EdgeInsets.only(
                      top: 20, left: 25, right: 25, bottom: 10),
                  decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(AppRadius.sheet),
                          topRight: Radius.circular(AppRadius.sheet))),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: 5, top: 10),
                        child: Text('Kalkulator KPR Premium',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            )),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(18, 0, 18, 20),
                        child: Text(
                          'Perbarui ke paket baru untuk menikmati lebih banyak manfaat',
                          textAlign: TextAlign.center,
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
          padding:
              const EdgeInsets.only(left: 25, right: 25, bottom: 20, top: 10),
          decoration: const BoxDecoration(color: AppColors.surface),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: const Wrap(
                    children: [
                      _Benefit('Tanpa Iklan'),
                      SizedBox(width: 15),
                      _Benefit('Download & Share PDF'),
                    ],
                  ),
                ),
                for (int index = 0; index < packages.length; index++)
                  _buildPackageTile(index),
                Container(
                  margin: const EdgeInsets.only(bottom: 15, top: 15),
                  width: double.infinity,
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 15, horizontal: 18)),
                      onPressed: () {
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
                  child: Text(
                    'Pembelian ini hanya dapat digunakan di sistem Android. Pembayaran akan dibebankan ke akun Google Play Anda setelah pembelian dikonfirmasi.',
                    style: TextStyle(color: AppColors.muted, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ),
                TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                    onPressed: () {
                      LoadingOverlay.show(context);
                      _cubit.restorePurchase();
                    },
                    child: const Text('Kembalikan Pembelian'))
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildPackageTile(int index) {
    final package = packages[index];
    final isSelected = _selectedIndex == index;
    final isLifetime =
        package.storeProduct.identifier == AppConfig.legacyLifetimeProductId;

    return GestureDetector(
      onTap: () {
        if (_selectedIndex != index) setState(() => _selectedIndex = index);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(AppRadius.sheet),
        ),
        child: ListTile(
          leading: Icon(Icons.stars,
              color: isLifetime ? AppColors.primary : Colors.amber),
          title: Text(
            package.storeProduct.title
                .replaceAll(AppConfig.storeTitleSuffix, ''),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            package.storeProduct.description,
            style: const TextStyle(fontSize: 12),
          ),
          trailing: Text(package.storeProduct.priceString,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Icon(Icons.check, color: AppColors.primary),
        const SizedBox(width: 5),
        Text(label),
      ],
    );
  }
}
