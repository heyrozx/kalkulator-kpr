import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kalkulator_kpr/blocs/purchase_cubit/purchase_cubit.dart';
import 'package:kalkulator_kpr/core/config.dart';
import 'package:kalkulator_kpr/core/error_reporter.dart';
import 'package:kalkulator_kpr/core/loading_overlay.dart';
import 'package:kalkulator_kpr/core/theme.dart';
import 'package:kalkulator_kpr/pages/about/disclaimer.dart';
import 'package:kalkulator_kpr/pages/premiums/premium_paywall.dart';
import 'package:kalkulator_kpr/utils/custom_snackbar.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Kumpulan menu sekunder yang sebelumnya menumpuk di bagian bawah drawer.
///
/// Drawer sekarang hanya berisi navigasi kalkulator, sisanya (premium, tautan,
/// info aplikasi) dipindah ke sini supaya penambahan menu baru tidak lagi
/// menggeser isi drawer.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    // Nomor versi dibaca dari paket, bukan ditulis manual — teks versi yang
    // ditulis tangan sempat tertinggal satu rilis di belakang pubspec.yaml.
    final info = await ErrorReporter.guard(() => PackageInfo.fromPlatform(),
        hint: 'PackageInfo');
    if (!mounted || info == null) return;
    setState(() => _appVersion = info.version);
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

  Future<void> _restorePurchase() async {
    final cubit = context.read<PurchaseCubit>();
    LoadingOverlay.show(context);

    bool restored;
    try {
      restored = await cubit.restorePurchase();
    } on PlatformException {
      LoadingOverlay.hide();
      if (!mounted) return;
      CustomSnackbar.show(context,
          title: 'Gagal',
          message: 'Pembelian tidak dapat dipulihkan. Periksa koneksi '
              'internet Anda lalu coba lagi.',
          type: SnackbarType.failure);
      return;
    }

    LoadingOverlay.hide();
    if (!mounted) return;
    CustomSnackbar.show(context,
        title: restored ? 'Berhasil' : 'Tidak Ditemukan',
        message: restored
            ? 'Pembelian premium Anda berhasil dipulihkan.'
            : 'Tidak ada pembelian premium pada akun ini.',
        type: restored ? SnackbarType.success : SnackbarType.warning);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan', style: TextStyle(fontSize: 16)),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            _sectionTitle('Premium'),
            BlocBuilder<PurchaseCubit, PurchaseState>(
              builder: (context, state) {
                final bool isPremium = state is PurchaseData && state.isPremium;
                if (isPremium) {
                  return const ListTile(
                    leading: Icon(Icons.verified, color: AppColors.primary),
                    title: Text('Premium Aktif'),
                    subtitle: Text('Terima kasih, aplikasi Anda bebas iklan.'),
                  );
                }
                return ListTile(
                  leading: const Icon(Icons.workspace_premium_outlined),
                  title: const Text('Bebas Iklan'),
                  subtitle: const Text('Hilangkan iklan & buka fitur premium.'),
                  onTap: () => showPremiumPaywall(context),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('Pulihkan Pembelian'),
              subtitle: const Text('Sudah pernah membeli di perangkat lain?'),
              onTap: _restorePurchase,
            ),
            const Divider(thickness: 0.5),
            _sectionTitle('Lainnya'),
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: const Text('Beri Rating'),
              onTap: () => _launchUrl(AppConfig.playStoreUrl),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Disklaimer'),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const Disclaimer())),
            ),
            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text('Hubungi Kami'),
              onTap: () => _launchUrl(AppConfig.contactUrl),
            ),
            ListTile(
              leading: const Icon(Icons.gpp_maybe_outlined),
              title: const Text('Kebijakan Privasi'),
              onTap: () => _launchUrl(AppConfig.privacyPolicyUrl),
            ),
            ListTile(
              leading: const Icon(Icons.smartphone_outlined),
              title: const Text('Versi Aplikasi'),
              trailing: Text(
                _appVersion.isEmpty ? '-' : _appVersion,
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
