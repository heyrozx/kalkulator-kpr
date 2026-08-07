import 'package:flutter/foundation.dart';
import 'package:kalkulator_kpr/core/config.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class Purchase {
  Future<void> initPlatformState() async {
    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.error);
    await Purchases.configure(
      PurchasesConfiguration(AppConfig.revenueCatApiKey),
    );
  }
}
