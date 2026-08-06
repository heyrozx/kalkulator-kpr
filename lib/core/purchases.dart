import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kalkulator_kpr/core/config.dart';
import 'package:kalkulator_kpr/core/error_reporter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class Purchase {
  Future<void> initPlatformState() async {
    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.error);
    await Purchases.configure(
      PurchasesConfiguration(AppConfig.revenueCatApiKey),
    );
  }

  Future<List<Offering>> getOfferings() async {
    try {
      final Offerings offerings = await Purchases.getOfferings();
      final Offering? offering = offerings.current;
      return offering != null ? [offering] : [];
    } on PlatformException catch (error, stack) {
      ErrorReporter.report(error, stack, hint: 'getOfferings');
      return [];
    }
  }

  Future<List<Package>> getPackages() async {
    final List<Offering> offerings = await getOfferings();
    return offerings
        .map((offer) => offer.availablePackages)
        .expand((packages) => packages)
        .toList();
  }
}
