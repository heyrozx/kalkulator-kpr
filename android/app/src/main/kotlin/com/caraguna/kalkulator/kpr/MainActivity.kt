package com.caraguna.kalkulator.kpr

import io.flutter.embedding.android.FlutterFragmentActivity

/**
 * Harus tetap turunan FlutterFragmentActivity — bukan FlutterActivity.
 *
 * Paywall RevenueCat (purchases_ui_flutter) ditampilkan sebagai fragment di atas
 * activity ini. Kalau diturunkan lagi ke FlutterActivity, membuka paywall gagal
 * dengan PlatformException(PAYWALLS_MISSING_WRONG_ACTIVITY).
 */
class MainActivity: FlutterFragmentActivity() {
}
