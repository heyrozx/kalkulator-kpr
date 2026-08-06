import 'dart:async';

import 'package:flutter/foundation.dart';

/// Titik masuk tunggal untuk semua error yang tertangkap.
///
/// Saat ini error hanya dicetak ke log. Bagian yang penting adalah **semua
/// `catch` di aplikasi memanggil [report]**, sehingga saat crash reporting
/// (mis. Firebase Crashlytics) dipasang nanti, cukup mengisi [onReport] satu
/// kali di `main()` tanpa menyentuh ulang seluruh call site:
///
/// ```dart
/// ErrorReporter.onReport = (error, stack, {hint}) =>
///     FirebaseCrashlytics.instance.recordError(error, stack, reason: hint);
/// ```
class ErrorReporter {
  const ErrorReporter._();

  /// Sink opsional untuk meneruskan error ke layanan crash reporting.
  static void Function(Object error, StackTrace? stack, {String? hint})?
      onReport;

  static void report(Object error, StackTrace? stack, {String? hint}) {
    if (kDebugMode) {
      debugPrint('[ErrorReporter]${hint == null ? '' : ' ($hint)'} $error');
      if (stack != null) debugPrint(stack.toString());
    }
    onReport?.call(error, stack, hint: hint);
  }

  /// Menangkap error framework dan error async yang tidak tertangani.
  /// Dipanggil sekali dari `main()`.
  static void install() {
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      report(details.exception, details.stack, hint: details.library);
      previousOnError?.call(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      report(error, stack, hint: 'PlatformDispatcher');
      return true;
    };
  }

  /// Menjalankan [body] dan melaporkan error tanpa membuat pemanggil crash.
  static Future<T?> guard<T>(Future<T> Function() body, {String? hint}) async {
    try {
      return await body();
    } catch (error, stack) {
      report(error, stack, hint: hint);
      return null;
    }
  }
}
