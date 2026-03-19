import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

part 'purchase_state.dart';

class PurchaseCubit extends Cubit<PurchaseState> {
  PurchaseCubit() : super(PurchaseInitial());

  CustomerInfo? _customerInfo;

  bool isPremium() => _customerInfo != null;

  Future<void> checkPremium() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      if (customerInfo.entitlements.all["premium"] != null &&
          customerInfo.entitlements.all["premium"]!.isActive) {
        _customerInfo = customerInfo;
        emit(PurchaseData(customerInfo: customerInfo, isPremium: true));
      } else {
        emit(PurchaseNothing());
      }
    } on PlatformException catch (_) {}
  }

  Future<void> makePurchase(Package package) async {
    try {
      PurchaseResult purchaseResult =
          await Purchases.purchase(PurchaseParams.package(package));
      CustomerInfo customerInfo = purchaseResult.customerInfo;

      if (customerInfo.entitlements.all["premium"] != null &&
          customerInfo.entitlements.all["premium"]!.isActive) {
        _customerInfo = customerInfo;
        emit(PurchaseData(customerInfo: customerInfo, isPremium: true));
      } else {
        emit(PurchaseNothing());
      }
    } on PlatformException catch (e) {
      var errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        if (kDebugMode) print("purchase error");
      }
      emit(PurchaseError());
    }
  }

  Future<void> restorePurchase() async {
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      if (customerInfo.entitlements.all["premium"] != null &&
          customerInfo.entitlements.all["premium"]!.isActive) {
        _customerInfo = customerInfo;
        emit(PurchaseData(customerInfo: customerInfo, isPremium: true));
      } else {
        emit(PurchaseNothing());
      }
    } on PlatformException catch (_) {
      emit(PurchaseError());
    }
  }
}
