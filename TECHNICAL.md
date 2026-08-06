# Dokumentasi Teknis — Kalkulator KPR

Dokumen ini menjelaskan arsitektur, fitur yang sudah terimplementasi, paket utama yang
dipakai, serta cara kerja skema premium (langganan) pada aplikasi **Kalkulator KPR**.

| Item | Nilai |
| --- | --- |
| Nama paket Flutter | `kalkulator_kpr` |
| applicationId / namespace | `com.caraguna.kalkulator.kpr` |
| Versi saat ini | `1.3.3+13` (lihat `pubspec.yaml`) |
| Platform | Android (utama) & iOS |
| Dart SDK | `>=3.3.4 <4.0.0` |
| Bahasa UI | Indonesia |
| Monetisasi | Google Mobile Ads (banner + interstitial) + premium bebas iklan via RevenueCat |

---

## 1. Arsitektur

Aplikasi memakai pendekatan sederhana: **layar kalkulator memakai `StatefulWidget` +
`setState`**, sedangkan **Cubit hanya dipakai untuk status pembelian premium**. Tidak ada
lapisan repository/service layer, tidak ada database lokal, dan tidak ada backend sendiri —
semua perhitungan dilakukan di device secara sinkron.

```
main.dart
  └─ Purchase().initPlatformState()   // konfigurasi RevenueCat sebelum runApp
  └─ runApp(MyApp)
       └─ MultiBlocProvider(PurchaseCubit()..checkPremium())
            └─ MaterialApp
                 └─ UpgradeAlert (package upgrader)
                      └─ MyHomePage
```

### Struktur folder `lib/`

| Path | Isi |
| --- | --- |
| `main.dart` | Entry point; pasang `ErrorReporter`, set status bar transparan, init RevenueCat, `runApp`. |
| `app.dart` | `MaterialApp` (`AppTheme.light`, Material 2) + `MultiBlocProvider` + `UpgradeAlert`. |
| `core/helpers.dart` | **Inti bisnis**: seluruh rumus angsuran, pembangkit tabel angsuran, dan `sumOf`. |
| `core/config.dart` | `AppConfig` (kunci RevenueCat, entitlement, tautan, batas input) + `AdConfig` (ad unit id per penempatan) + enum `BannerPlacement`. |
| `core/validators.dart` | Validator input bersama untuk layar utama & Advanced. |
| `core/error_reporter.dart` | Titik masuk tunggal pelaporan error; siap disambung ke Crashlytics. |
| `core/theme.dart` | `AppColors`, `AppRadius`, `AppTheme.light`. |
| `core/currency_format.dart` | `currencyId` (format Indonesia) + parser balik dari teks input. |
| `core/interstitial_ad_manager.dart` | Muat → tampilkan → muat ulang interstitial, termasuk `dispose`. |
| `core/custom_date.dart` | Utilitas tanggal (`timestamp()` dipakai di header PDF). |
| `core/loading_overlay.dart` | Wrapper `overlay_loading_progress` + `loading_animation_widget`. |
| `core/purchases.dart` | Wrapper RevenueCat: `initPlatformState`, `getOfferings`, `getPackages`. |
| `models/calculate_model.dart` | `CalculateModel` (+`copyWith`), `CalculateResultModel`, enum `CalculatorType`. |
| `blocs/purchase_cubit/` | State premium: `checkPremium`, `makePurchase`, `restorePurchase`. |
| `pages/home/` | Form input utama, ring hasil, drawer pemilih metode, interstitial ad. |
| `pages/advanced/` | Tab **Fix & Floating** dan **Berjenjang** (`advanced_screen.dart` sebagai host tab). |
| `pages/principle/principal_table.dart` | Tabel angsuran per bulan (`data_table_2`), share & download PDF, drawer detail. |
| `utils/pdf_util.dart` | Generator dokumen PDF tabel angsuran (dijalankan di isolate). |
| `pages/about/` | Penjelasan skema bunga (flat/efektif/anuitas) + disclaimer. |
| `pages/premiums/` | Paywall (`premium_plan_screen.dart`) & layar sukses (`payment_success.dart`). |
| `shared/widgets/banner_ad_widget.dart` | Banner ad dengan unit id per penempatan. |
| `shared/widgets/labeled_number_field.dart` | Field angka/persen dengan formatter & validator seragam. |
| `shared/widgets/loan_dp_fields.dart` | Blok input pinjaman + DP (persen ↔ nominal saling sinkron). |
| `shared/widgets/form_section.dart` | `SectionTitle` & `SubmitBar` untuk layar Advanced. |
| `utils/custom_snackbar.dart` | Snackbar bertipe (success/warning/error). |

### Model data

```dart
class CalculateModel {
  // Punya copyWith(); dipakai helpers agar model pemanggil tidak ikut berubah.
  double? loanPlafon;        // plafon pinjaman (basis angsuran pokok)
  double? loan;              // sisa pinjaman berjalan (dimutakhirkan pada salinan kerja)
  double? initialLoan;       // harga/pinjaman awal sebelum DP (khusus layar advanced)
  double? dpNominal;         // nominal DP (khusus layar advanced)
  double? year;              // jangka waktu (tahun)
  double? interest;          // bunga aktif (%/tahun)
  double? fixInterest;       // bunga periode fix
  double? fixYear;           // lama periode fix (tahun)
  double? floatingInterest;  // bunga periode floating
}

class CalculateResultModel {
  double? installmentResult;    // total angsuran bulan tersebut
  double? interestResult;       // komponen bunga
  double? principal;            // komponen pokok
  double? principalTotalRemain; // sisa pinjaman setelah bulan tersebut
}

enum CalculatorType { flat, effective, anuitas }
```

---

## 2. Mesin perhitungan (`core/helpers.dart`)

Seluruh angka yang dilihat pengguna berasal dari file ini. Bunga input berupa **persen per
tahun**, dikonversi ke bulanan dengan `interest * 0.01 / 12`, dan tenor dikonversi ke bulan
dengan `year * 12`.

### 2.1 Perhitungan satu bulan

| Fungsi | Rumus |
| --- | --- |
| `calculateFlat` | pokok = `plafon / n`; bunga = `pinjaman × i`; angsuran = pokok + bunga |
| `calculateEffective` | rumus per-bulan identik dengan flat, tetapi pemanggilnya memutakhirkan `loan` ke sisa pinjaman tiap bulan sehingga bunga menurun |
| `calculateAnuitas` | angsuran = `plafon × i × (1+i)ⁿ / ((1+i)ⁿ − 1)`; bunga = `sisa pinjaman × i`; pokok = angsuran − bunga |

dengan `n = year × 12`, `i = interest% / 12`, `plafon = loanPlafon ?? loan`.

Perbedaan flat vs efektif **tidak ada di level fungsi bulanan** — perbedaannya muncul pada
pembangkit tabel: `installmentTableFlat` selalu menghitung bunga dari plafon penuh (bunga
tetap sepanjang tenor), sedangkan `installmentTableEffective` memutakhirkan sisa pinjaman
pada salinan kerjanya setiap iterasi sehingga bunga menurun.

### 2.2 Pembangkit tabel angsuran

| Fungsi | Perilaku |
| --- | --- |
| `installmentTableFlat` | `n` baris, pokok & bunga konstan. |
| `installmentTableEffective` | `n` baris, pokok konstan (`plafon/n`), bunga mengikuti sisa pinjaman. |
| `installmentTableAnuitas` | `n` baris, total angsuran konstan, komposisi pokok/bunga bergeser. |
| `installmentTableFixFloating` | Periode fix `fixYear × 12` bulan memakai `fixInterest`; setelah itu `loanPlafon` di-rebase ke sisa pinjaman, `year` dikurangi `fixYear`, bunga diganti `floatingInterest`, lalu sisa bulan dihitung ulang (re-amortisasi). |
| `installmentTableTiered` | Tiap elemen `tieredInterest` = 1 tahun (12 bulan) dengan bunga sendiri; setiap akhir tahun `loanPlafon` di-rebase dan `year` dikurangi 1; sisa tenor memakai `floatingInterest`. |

`installmentTableFixFloating` dan `installmentTableTiered` menerima `CalculatorType` dan
hanya mendukung **anuitas** dan **efektif** (UI Advanced memang hanya menawarkan dua opsi
tersebut; jika pengguna masuk dari mode Flat, tipe otomatis dipaksa ke Anuitas).

> **Catatan implementasi:**
> - Fungsi tabel bekerja di atas **salinan** (`copyWith`) sehingga tidak pernah mengubah
>   `CalculateModel` milik pemanggil — satu instance cukup untuk menghitung sekaligus
>   ditampilkan di `PrincipalTable`.
> - Semua rumus punya guard: tenor 0 mengembalikan hasil nol, dan bunga 0 pada anuitas
>   dihitung sebagai pokok dibagi rata (bukan `NaN`).
> - `sumOf(results, selector)` menjumlahkan kolom tabel sambil melewati nilai non-finite.

---

## 3. Fitur yang sudah terimplementasi

### 3.1 Kalkulator utama (`pages/home/home_screen.dart`)

- Input: **Jumlah Pinjaman (Rp)**, **Jangka Waktu (Tahun)**, **Bunga Pinjaman (%)** dengan
  format ribuan otomatis (`pattern_formatter`) dan validasi rentang lewat `core/validators.dart`
  (pinjaman > 0, tenor 1–40 tahun, bunga > 0 sampai 100%).
- Pemilihan metode lewat drawer: **Anuitas** (default), **Efektif**, **Flat**. Mengganti
  metode langsung menghitung ulang bila form sudah terisi.
- Hasil ditampilkan sebagai `CircularPercentIndicator`: total angsuran di tengah
  (label "Per Bulan" untuk flat/anuitas, "Bulan Pertama" untuk efektif) dengan rincian
  angsuran pokok vs bunga di footer; porsi lingkaran = pokok / total angsuran.
- Tombol **Hitung Simulasi** / **Hitung Ulang** dan **Tabel Angsuran**.
- Drawer juga berisi: tombol **Advanced**, **Beri Rating** (buka Play Store), **Reset**,
  **Privacy Policy**, dan info versi.
- Ikon **?** di app bar membuka penjelasan metode bunga yang sedang aktif.

### 3.2 Kalkulator lanjutan (`pages/advanced/`)

Host tab `AdvancedScreen` dengan pemilih tipe perhitungan (Anuitas/Efektif) via dialog dan
banner ad di bagian atas. Dua tab:

1. **Fix & Floating** (`fix_and_floating_screen.dart`)
   - Input harga/jumlah pinjaman, **DP dalam persen dan nominal yang saling sinkron**
     (mengubah salah satu memperbarui yang lain dan menghitung total pinjaman = pinjaman − DP),
     jangka waktu, bunga fix, **masa kredit fix via slider (maks. 15 tahun)**, dan bunga floating.
   - Validasi: masa fix harus lebih kecil dari jangka waktu pinjaman.
2. **Berjenjang / Tiered** (`tiered_screen.dart`)
   - Bunga fix per tahun yang bisa **ditambah/dihapus dinamis** (baris pertama tidak bisa
     dihapus), lalu bunga floating untuk sisa tenor.
   - Validasi: jumlah tahun bunga fix harus lebih kecil dari jangka waktu pinjaman.

Keduanya bermuara ke layar tabel angsuran yang sama.

### 3.3 Tabel angsuran (`pages/principle/principal_table.dart`)

- Tabel bulan-per-bulan memakai `data_table_2`: **Bulan ke, Angsuran Pokok, Bunga, Jumlah
  Angsuran, Sisa Pinjaman**, plus baris **Total** di akhir. Sisa pinjaman < 1 ditampilkan 0.
- Drawer **Detail Angsuran** (hanya untuk hasil dari layar Advanced, dideteksi lewat
  `floatingInterest != null`) berisi ringkasan jenis, jumlah pinjaman, DP, bunga, dan tenor.
- Aksi **Download PDF** dan **Share PDF** — keduanya **fitur premium** (lihat §5).
- Banner ad pada penempatan `principalTable`.

### 3.4 Ekspor PDF (`utils/pdf_util.dart`)

- Dokumen A4 multi-halaman (`maxPages: 1000`) berisi logo aplikasi, timestamp, ringkasan
  parameter simulasi (termasuk rincian bunga fix/berjenjang/floating bila ada), tabel
  lengkap, dan baris total.
- Dokumen dibangun di **isolate terpisah** (`compute`) supaya UI tetap responsif, lalu
  ditulis ke `getTemporaryDirectory()` dengan nama informatif
  (`Tabel-Angsuran-Anuitas-20260806-153000.pdf`); berkas lama dibersihkan otomatis. Setelah itu:
  - **Download** → `FlutterFileSaver().writeFileAsBytes(...)` sehingga pengguna memilih
    lokasi simpan; sukses ditandai snackbar.
  - **Share** → `SharePlus.instance.share(ShareParams(files: [XFile(...)]))`.

### 3.5 Lain-lain

- **Paksa/anjuran update** lewat `UpgradeAlert` (`upgrader`), dialog tidak bisa di-dismiss
  (`showIgnore: false`, `showLater: false`, `barrierDismissible: false`) dan muncul lagi
  paling cepat 3 jam sekali.
- **Halaman penjelasan** skema bunga flat, efektif, dan anuitas, masing-masing dengan
  banner ad sendiri.
- **Loading overlay** global saat menghitung/generate PDF (dengan delay artifisial 1 detik
  agar transisi terasa halus).

---

## 4. Monetisasi iklan

- AdMob App ID (Android): `ca-app-pub-2465007971338713~1071397727` di `AndroidManifest.xml`.
- **Interstitial** dimuat di `initState` `MyHomePage`, hanya bila **bukan debug build dan
  bukan pengguna premium**, dan ditampilkan saat menekan **Tabel Angsuran**.
- **Banner** (`BannerAdWidget`) memanggil `checkPremium()` dulu; iklan hanya dimuat kalau
  pengguna bukan premium. Widget merender `SizedBox()` sampai iklan benar-benar termuat.
- Unit id banner dipilih per `BannerPlacement`: `flatDescription`, `anuitasDescription`,
  `effectiveDescription`, `principalTable`, `advancedPage`. Saat `kDebugMode`, unit id
  otomatis diganti test unit id Google.

---

## 5. Cara kerja premium / langganan

### 5.1 Komponen

| Komponen | Peran |
| --- | --- |
| RevenueCat (`purchases_flutter`) | Menjembatani Google Play Billing, menyimpan status entitlement. |
| `core/purchases.dart` | Konfigurasi SDK dengan public API key (`goog_…`) dan mengambil offering/packages. |
| `blocs/purchase_cubit/` | Sumber kebenaran status premium di dalam aplikasi. |
| `pages/premiums/premium_plan_screen.dart` | Paywall. |
| `pages/premiums/payment_success.dart` | Konfirmasi setelah pembelian berhasil. |

Entitlement yang dicek bernama **`"premium"`**. Produk yang tampil di paywall **tidak
di-hardcode** — seluruh `availablePackages` dari `offerings.current` ditampilkan apa adanya
(judul, deskripsi, dan harga lokal diambil dari `storeProduct`), sehingga penambahan atau
perubahan paket cukup dilakukan di dashboard RevenueCat/Play Console tanpa rilis baru.
Identifier `lifetime_premium_100000` masih dirujuk untuk pewarnaan ikon (paket lifetime
sudah tidak dijual).

### 5.2 Alur

**Inisialisasi**

1. `main()` memanggil `Purchase().initPlatformState()` → `Purchases.configure(...)` sebelum
   `runApp`.
2. `MyApp` membuat `PurchaseCubit()..checkPremium()`.
3. `checkPremium()` memanggil `Purchases.getCustomerInfo()`; bila
   `entitlements.all["premium"]` ada **dan** aktif → `emit(PurchaseData(isPremium: true))`,
   selain itu `emit(PurchaseNothing())`. Panggilan yang tumpang tindih berbagi satu request,
   dan kegagalan (mis. offline) tetap meng-emit status agar UI tidak tertahan.
4. `PurchaseCubit.isPremium()` **diturunkan dari `state`**, jadi hanya ada satu sumber
   kebenaran untuk gating fitur maupun tampilan ikon premium.

**Pembelian**

1. Paywall memuat paket lewat `Purchase().getPackages()` (spinner selama kosong).
2. Pengguna memilih paket → tombol **Lanjutkan** → `LoadingOverlay.show` +
   `PurchaseCubit.makePurchase(package)`.
3. `Purchases.purchase(PurchaseParams.package(package))` menjalankan dialog Google Play.
4. Bila entitlement `premium` aktif pada `CustomerInfo` hasil pembelian → `PurchaseData`;
   `BlocListener` di paywall menutup overlay dan mendorong ke `PaymentSuccess`.
5. Pembatalan pengguna (`purchaseCancelledError`) tidak dilaporkan sebagai kegagalan; error
   lain meng-emit `PurchaseError`, menutup overlay, dan memicu `checkPremium()` ulang.
6. Dari `PaymentSuccess`, tombol kembali memanggil `checkPremium()` lalu mereset navigasi ke
   home sehingga UI langsung dalam mode premium.

**Restore**

Tombol **Kembalikan Pembelian** memanggil `Purchases.restorePurchases()` dan mengevaluasi
entitlement dengan logika yang sama seperti `checkPremium()`.

### 5.3 Apa yang didapat pengguna premium

| Fitur | Gratis | Premium |
| --- | --- | --- |
| Kalkulator flat/efektif/anuitas | ✅ | ✅ |
| Tabel angsuran | ✅ | ✅ |
| Kalkulator Advanced (fix & floating, berjenjang) | ✅ | ✅ |
| Banner & interstitial ad | Muncul | Tidak dimuat |
| Download PDF tabel angsuran | ❌ (snackbar ajakan upgrade) | ✅ |
| Share PDF tabel angsuran | ❌ (snackbar ajakan upgrade) | ✅ |

Gating dilakukan lewat `PurchaseCubit.isPremium()` di `principal_table.dart`; ikon premium
di app bar hanya dirender ketika state `PurchaseNothing`.

> Paywall menuliskan benefit "Akses Semua Fitur", padahal saat ini satu-satunya fitur yang
> benar-benar terkunci adalah download & share PDF — layar Advanced bisa diakses gratis.

### 5.4 Catatan teknis yang perlu diperhatikan

- Banner ad hanya dimuat setelah status premium **selesai** diperiksa (state bukan lagi
  `PurchaseInitial`), dan otomatis dilepas kalau status berubah menjadi premium.
- Pembelian saat ini hanya diuji/di-support untuk Android (disclaimer di paywall menyebut
  hal ini secara eksplisit).

---

## 6. Paket utama

| Paket | Versi | Dipakai untuk |
| --- | --- | --- |
| `purchases_flutter` | ^9.1.0 | RevenueCat: offering, pembelian, entitlement premium. |
| `google_mobile_ads` | ^7.0.0 | Banner & interstitial AdMob. |
| `flutter_bloc` / `bloc` | ^9.1.1 / ^9.0.0 | `PurchaseCubit` (satu-satunya state management di luar `setState`). |
| `data_table_2` | ^2.6.0 | Tabel angsuran yang bisa di-scroll dua arah dengan header tetap. |
| `pdf` | ^3.11.3 | Membangun dokumen PDF tabel angsuran. |
| `path_provider` | ^2.1.1 | Menentukan direktori penulisan file PDF sementara. |
| `flutter_file_saver` | ^0.9.0 | Menyimpan PDF ke lokasi pilihan pengguna. |
| `share_plus` | ^12.0.1 | Membagikan PDF ke aplikasi lain. |
| `intl` | ^0.20.2 | Format angka/mata uang (`currencyId`) dan tanggal. |
| `pattern_formatter` | ^4.0.0 | `ThousandsFormatter` pada input nominal & bunga. |
| `percent_indicator` | ^4.2.2 | Ring hasil di layar utama. |
| `upgrader` | ^12.5.0 | Dialog wajib update versi. |
| `url_launcher` | ^6.1.8 | Buka Play Store & halaman privacy policy. |
| `package_info_plus` | ^9.0.1 | Membaca nomor versi aplikasi untuk ditampilkan di menu. |
| `overlay_loading_progress` + `loading_animation_widget` | ^1.0.1 / ^1.2.0+3 | Loading overlay global. |
| `flutter_lints` (dev) | ^6.0.0 | Aturan lint `flutter analyze`. |
| `change_app_package_name` (dev) | ^1.1.0 | Utilitas ganti applicationId. |

---

## 7. Konfigurasi build

### Android (`android/`)

- `compileSdkVersion 36`, `targetSdkVersion 36` (wajib API 36 untuk Google Play mulai
  31 Agustus 2026), `minSdkVersion` mengikuti `flutter.minSdkVersion`.
- `multiDexEnabled true`; Java/Kotlin target 1.8.
- AGP `8.9.1`, Kotlin `2.1.0`, Gradle wrapper `8.11.1`.
- **Google Play Billing** dipin eksplisit ke `com.android.billingclient:billing:8.0.0`
  sebagai batas bawah — Play mewajibkan ≥ 8.0.0 mulai 31 Agustus 2026 dan RevenueCat juga
  membawa Billing 8.x secara transitif. Verifikasi versi efektif dengan:
  ```bash
  cd android && ./gradlew :app:dependencies --configuration releaseRuntimeClasspath | grep billingclient
  ```
- Signing release membaca `android/key.properties` (tidak di-commit). `local.properties`
  (`flutter.versionName`/`flutter.versionCode`) digenerate Flutter — cukup ubah `pubspec.yaml`.
- Permission: `INTERNET`, `com.android.vending.BILLING`, dan `WRITE_EXTERNAL_STORAGE`
  dibatasi `maxSdkVersion="28"`.
- Saat menaikkan target SDK, cek behavior change Android terbaru — edge-to-edge dipaksa
  aktif di API 36 (periksa `SafeArea`/inset pada layar tabel dan tombol bawah) dan
  predictive back.

### iOS (`ios/`)

Proyek Runner standar Flutter tanpa konfigurasi khusus; versi mengikuti
`$(FLUTTER_BUILD_NAME)` / `$(FLUTTER_BUILD_NUMBER)`. Pembelian premium saat ini dinyatakan
hanya untuk Android.

---

## 8. Perintah & pengujian

Build/run dijalankan manual oleh pemilik project.

```bash
flutter pub get
flutter analyze          # lint: package:flutter_lints
flutter test             # unit test rumus, validator, dan format angka
flutter build appbundle  # rilis Play Store
```

Test berada di `test/core/`:

| Berkas | Cakupan |
| --- | --- |
| `helpers_test.dart` | Angka acuan tiap metode, jumlah baris tabel, pelunasan di bulan terakhir, skema fix & floating dan berjenjang, kasus tepi (bunga 0, tenor 0), serta jaminan fungsi tabel tidak memutasi model. |
| `validators_test.dart` | Batasan input: pinjaman, tenor 1–40 tahun, bunga 0–100%, DP ≤ pinjaman. |
| `currency_format_test.dart` | Format Rupiah Indonesia dan parsing balik (koma maupun titik sebagai desimal). |

CI (`.github/workflows/ci.yml`) menjalankan `dart format --set-exit-if-changed`,
`flutter analyze`, dan `flutter test` pada setiap push/PR ke `master`.

## 9. Konvensi kontribusi

- **Setiap perubahan wajib menambah entri di `CHANGELOG.md`** (entri terbaru di paling atas,
  heading `## <versionName> (<versionCode>)`, bullet berbahasa Indonesia dari sudut pandang
  pengguna). Bila akan dirilis, naikkan juga `version:` di `pubspec.yaml`.
- Prefix commit yang dipakai: `chore:`, `fix:`, `wip:`.
- Ikuti pola state yang ada (`StatefulWidget` + `setState` untuk kalkulator, Cubit hanya
  untuk pembelian). Jangan memperkenalkan state management baru tanpa diminta.
- Perubahan di `core/helpers.dart` langsung memengaruhi angka yang dilihat pengguna —
  periksa ulang dengan teliti.
