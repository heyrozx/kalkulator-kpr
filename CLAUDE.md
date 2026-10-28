# CLAUDE.md

Panduan untuk Claude Code saat bekerja di repository ini.

## Project

**Kalkulator KPR** — aplikasi Flutter (Android & iOS) untuk simulasi cicilan Kredit
Pemilikan Rumah. Bahasa UI: Indonesia. Monetisasi: Google Mobile Ads (banner +
interstitial) dengan opsi premium bebas iklan lewat RevenueCat.

Package/applicationId: `com.caraguna.kalkulator.kpr`

## Aturan wajib: selalu update CHANGELOG

**Setiap kali melakukan perubahan pada project ini, tambahkan entri ke `CHANGELOG.md`.**

- Entri terbaru selalu di paling atas, format heading: `## <versionName> (<versionCode>)`.
- Isi berupa bullet singkat berbahasa Indonesia yang menjelaskan perubahan dari sudut
  pandang pengguna/rilis, bukan detail implementasi baris per baris.
- Kalau perubahan akan dirilis ke store, naikkan juga `version:` di `pubspec.yaml`
  (`versionName+versionCode`, contoh `1.3.2+12`) dan pakai angka yang sama di heading
  changelog. Untuk perubahan kecil yang belum dirilis, tambahkan bullet ke heading
  versi teratas yang belum dirilis.
- `android/local.properties` (berisi `flutter.versionName`/`flutter.versionCode`)
  digenerate oleh Flutter dan tidak di-commit — cukup ubah `pubspec.yaml`.

## Struktur kode (`lib/`)

- `main.dart` — entry point; init RevenueCat (`Purchase.initPlatformState()`) sebelum `runApp`.
- `app.dart` — `MaterialApp` + `MultiBlocProvider` (`PurchaseCubit`) + `UpgradeAlert` (package `upgrader`).
- `core/helpers.dart` — **inti bisnis**: seluruh rumus perhitungan angsuran
  (`calculateFlat/Effective/Anuitas`) dan pembangkit tabel angsuran per bulan
  (`installmentTable*`, termasuk skema fix-and-floating dan tiered). Perubahan di sini
  langsung memengaruhi angka yang dilihat pengguna — periksa ulang dengan teliti.
- `core/` lain — `currency_format.dart` (format Rupiah + parsing balik), `custom_date.dart`,
  `loading_overlay.dart`, `purchases.dart` (wrapper RevenueCat: offerings & packages).
- `models/calculate_model.dart` — `CalculateModel` (input), `CalculateResultModel` (output
  per bulan), enum `CalculatorType { flat, effective, anuitas }`.
- `blocs/purchase_cubit/` — status premium (`checkPremium`, `makePurchase`, `restorePurchase`),
  entitlement RevenueCat bernama `"premium"`.
- `pages/home/` — form input utama + hasil ringkas + interstitial ad. Metode bunga
  dipilih lewat `SegmentedSwitch` (`shared/widgets/segmented_switch.dart`) di bagian bawah AppBar (anuitas/efektif/flat, state `type`);
  drawer berisi navigasi layar lain, `Bantuan` (bottom sheet daftar halaman
  penjelasan di `pages/about/`), dan `Pengaturan`.
- `pages/settings/settings_screen.dart` — premium & pulihkan pembelian, beri rating,
  disclaimer, privacy policy, versi aplikasi (dulu menumpuk di bawah drawer).
- `pages/advanced/` — kalkulator lanjutan: fix & floating (`fix_and_floating_screen.dart`)
  dan bunga berjenjang (`tiered_screen.dart`).
- `pages/principle/principal_table.dart` — tabel angsuran (`data_table_2`), share & download PDF.
- `pages/pdf/` + `utils/pdf_util.dart` — generate PDF tabel angsuran (package `pdf`),
  disimpan via `getDownloadsDirectory()` lalu `FlutterFileSaver` untuk download.
- `pages/about/` — penjelasan skema bunga & disclaimer; `pages/premiums/` — paywall.
- `shared/widgets/banner_ad_widget.dart` — banner ad; unit id dipilih per `BannerPlacement`,
  dan otomatis pakai test unit id saat `kDebugMode`. Banner/interstitial tidak dimuat
  kalau user premium.

Catatan gaya: state pakai `StatefulWidget` + `setState` untuk layar kalkulator, Cubit
hanya untuk status pembelian. Ikuti pola yang sudah ada, jangan memperkenalkan state
management baru tanpa diminta.

## Android

- `android/app/build.gradle`: `compileSdkVersion 36`, `targetSdkVersion 36` (wajib API 36
  untuk Google Play mulai 31 Agustus 2026), `minSdkVersion` mengikuti `flutter.minSdkVersion`.
- Signing release membaca `android/key.properties` (tidak di-commit).
- `multiDexEnabled true`.
- **`MainActivity` wajib turunan `FlutterFragmentActivity`** (bukan `FlutterActivity`):
  paywall RevenueCat (`purchases_ui_flutter`) ditampilkan sebagai fragment di atas
  activity ini. Kalau diubah, `RevenueCatUI.presentPaywall()` gagal dengan
  `PlatformException(PAYWALLS_MISSING_WRONG_ACTIVITY)`.
- `purchases_ui_flutter` menuntut `minSdkVersion` ≥ 24 (`flutter.minSdkVersion`
  saat ini 24) — jangan diturunkan.
- **Google Play Billing Library**: `com.android.billingclient:billing` dipin manual di
  `android/app/build.gradle`. Google Play mewajibkan minimal **8.0.0** mulai
  31 Agustus 2026 — jangan pernah menurunkan versinya. RevenueCat
  (`purchases_flutter` → `purchases-hybrid-common` → `purchases`) juga membawa
  Billing 8.x secara transitif, dan Gradle memakai versi tertinggi. Cek versi efektif
  yang benar-benar masuk ke AAB dengan:
  `cd android && ./gradlew :app:dependencies --configuration releaseRuntimeClasspath | grep billingclient`.
- AGP `8.9.1` / Kotlin `2.1.0` di `android/settings.gradle`, Gradle wrapper `8.11.1`.
- Saat menaikkan target SDK, cek behavior change Android terbaru yang relevan:
  edge-to-edge dipaksa aktif di API 36 (pastikan `SafeArea`/inset di layar dengan
  tabel & tombol bawah masih benar) dan predictive back.

## Perintah

Build/run dijalankan manual oleh pemilik project — **jangan** menjalankan `flutter run`,
`flutter build`, atau `gradlew` kecuali diminta secara eksplisit.

```bash
flutter pub get
flutter analyze          # lint: package:flutter_lints
flutter test             # test/widget_test.dart masih kosong
flutter build appbundle  # rilis Play Store
```

## Konvensi commit

Prefix ala conventional commits yang sudah dipakai: `chore:`, `fix:`, `wip:`.
Commit hanya kalau diminta.
