import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kalkulator_kpr/blocs/purchase_cubit/purchase_cubit.dart';
import 'package:kalkulator_kpr/core/error_reporter.dart';
import 'package:kalkulator_kpr/pages/premiums/payment_success.dart';
import 'package:kalkulator_kpr/utils/custom_snackbar.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

/// Menampilkan paywall premium milik RevenueCat.
///
/// Menggantikan layar langganan buatan sendiri: tampilan, daftar paket, harga,
/// dan tombol "restore" seluruhnya dirender oleh RevenueCat sesuai konfigurasi
/// paywall di dashboard, jadi perubahan penawaran tidak butuh rilis baru.
/// Paywall yang dipakai adalah yang terpasang pada offering `current`.
///
/// Setelah paywall ditutup, status premium di [PurchaseCubit] selalu
/// disinkronkan ulang supaya iklan & fitur terkunci langsung mengikuti.
Future<void> showPremiumPaywall(BuildContext context) async {
  final cubit = context.read<PurchaseCubit>();

  PaywallResult result;
  try {
    result = await RevenueCatUI.presentPaywall();
  } on PlatformException catch (error, stack) {
    ErrorReporter.report(error, stack, hint: 'presentPaywall');
    result = PaywallResult.error;
  }

  await cubit.refreshPremium();
  if (!context.mounted) return;

  switch (result) {
    case PaywallResult.purchased:
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const PaymentSuccess()),
        (route) => false,
      );
    case PaywallResult.restored:
      // Pemulihan pembelian bukan transaksi baru, cukup beri konfirmasi dan
      // biarkan pengguna tetap di layar tempat ia membuka paywall.
      CustomSnackbar.show(
        context,
        title: 'Berhasil',
        message: cubit.isPremium()
            ? 'Pembelian premium Anda berhasil dipulihkan.'
            : 'Tidak ada pembelian premium pada akun ini.',
        type: cubit.isPremium() ? SnackbarType.success : SnackbarType.warning,
      );
    case PaywallResult.error:
      CustomSnackbar.show(
        context,
        title: 'Gagal',
        message: 'Paywall tidak dapat dibuka. Periksa koneksi internet Anda '
            'lalu coba lagi.',
        type: SnackbarType.failure,
      );
    case PaywallResult.cancelled:
    case PaywallResult.notPresented:
      break;
  }
}
