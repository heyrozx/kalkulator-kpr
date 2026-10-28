import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kalkulator_kpr/blocs/purchase_cubit/purchase_cubit.dart';
import 'package:kalkulator_kpr/core/theme.dart';
import 'package:kalkulator_kpr/pages/home/home_screen.dart';

/// Layar konfirmasi setelah pembelian premium berhasil.
class PaymentSuccess extends StatefulWidget {
  const PaymentSuccess({super.key});

  @override
  State<PaymentSuccess> createState() => _PaymentSuccessState();
}

class _PaymentSuccessState extends State<PaymentSuccess> {
  late PurchaseCubit _cubit;

  /// Fitur yang terbuka setelah upgrade.
  static const List<({IconData icon, String label})> _benefits = [
    (icon: Icons.block, label: 'Bebas iklan di seluruh aplikasi'),
    (icon: Icons.picture_as_pdf_outlined, label: 'Download & bagikan PDF'),
    (icon: Icons.history, label: 'Simpan riwayat simulasi tanpa batas'),
  ];

  @override
  void initState() {
    _cubit = BlocProvider.of<PurchaseCubit>(context);
    super.initState();
  }

  void _backToHome() {
    _cubit.checkPremium();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (BuildContext context) =>
              const MyHomePage(title: 'Kalkulator KPR')),
      ModalRoute.withName('/dashboard'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.upgradeGradient,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              children: [
                const Spacer(),
                _buildBadge(),
                const SizedBox(height: 24),
                const Text(
                  'Upgrade Premium Berhasil!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 24),
                ),
                const SizedBox(height: 10),
                Text(
                  'Terima kasih! Sekarang Anda bisa menikmati Kalkulator KPR '
                  'tanpa iklan dan memakai semua fitur.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.onPrimary.withValues(alpha: 0.85),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                _buildBenefits(),
                const Spacer(flex: 2),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                    onPressed: _backToHome,
                    child: const Text(
                      'Kembali ke Beranda',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Lencana premium emas (gaya yang sama dengan tab premium di AppBar) di
  /// dalam lingkaran putih transparan.
  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.onPrimary.withValues(alpha: 0.15),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.premiumGradient,
          ),
        ),
        child: const Icon(
          Icons.workspace_premium,
          size: 64,
          color: AppColors.onPrimary,
        ),
      ),
    );
  }

  Widget _buildBenefits() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.onPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.panel),
      ),
      child: Column(
        children: [
          for (final benefit in _benefits)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Icon(benefit.icon, color: AppColors.onPrimary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      benefit.label,
                      style: const TextStyle(color: AppColors.onPrimary),
                    ),
                  ),
                  const Icon(Icons.check_circle,
                      color: AppColors.onPrimary, size: 18),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
