import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kalkulator_kpr/core/config.dart';
import 'package:kalkulator_kpr/core/error_reporter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

part 'purchase_state.dart';

class PurchaseCubit extends Cubit<PurchaseState> {
  PurchaseCubit() : super(PurchaseInitial());

  Future<void>? _pendingCheck;

  /// Status premium selalu diturunkan dari [state] supaya tidak ada dua sumber
  /// kebenaran. Sebelumnya status disimpan di field terpisah yang tidak pernah
  /// dikosongkan, sehingga langganan yang sudah berakhir tetap dianggap aktif
  /// sampai aplikasi di-restart.
  bool isPremium() {
    final current = state;
    return current is PurchaseData && current.isPremium;
  }

  /// `true` ketika status premium belum pernah selesai diperiksa.
  bool get isUnknown => state is PurchaseInitial;

  CustomerInfo? get customerInfo {
    final current = state;
    return current is PurchaseData ? current.customerInfo : null;
  }

  /// Memeriksa entitlement premium. Panggilan yang tumpang tindih (mis. beberapa
  /// banner ad sekaligus) berbagi satu request yang sama.
  Future<void> checkPremium() {
    return _pendingCheck ??= _runCheck().whenComplete(() {
      _pendingCheck = null;
    });
  }

  Future<void> _runCheck() async {
    try {
      _emitFor(await Purchases.getCustomerInfo());
    } on PlatformException catch (error, stack) {
      ErrorReporter.report(error, stack, hint: 'checkPremium');
      // Jangan biarkan state tertahan di PurchaseInitial saat offline: UI
      // menunggu status ini untuk memutuskan menampilkan ikon premium & iklan.
      if (!isClosed && state is PurchaseInitial) emit(PurchaseNothing());
    }
  }

  Future<void> makePurchase(Package package) async {
    try {
      final PurchaseResult purchaseResult =
          await Purchases.purchase(PurchaseParams.package(package));
      _emitFor(purchaseResult.customerInfo);
    } on PlatformException catch (error, stack) {
      final errorCode = PurchasesErrorHelper.getErrorCode(error);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        // Dibatalkan pengguna: bukan kegagalan, kembalikan ke status semula.
        if (!isClosed) emit(PurchaseNothing());
        return;
      }
      ErrorReporter.report(error, stack, hint: 'makePurchase');
      if (kDebugMode) debugPrint('purchase error: $errorCode');
      if (!isClosed) emit(PurchaseError());
    }
  }

  Future<void> restorePurchase() async {
    try {
      _emitFor(await Purchases.restorePurchases());
    } on PlatformException catch (error, stack) {
      ErrorReporter.report(error, stack, hint: 'restorePurchase');
      if (!isClosed) emit(PurchaseError());
    }
  }

  void _emitFor(CustomerInfo customerInfo) {
    if (isClosed) return;
    final entitlement =
        customerInfo.entitlements.all[AppConfig.premiumEntitlement];
    if (entitlement != null && entitlement.isActive) {
      emit(PurchaseData(customerInfo: customerInfo, isPremium: true));
    } else {
      emit(PurchaseNothing());
    }
  }
}
