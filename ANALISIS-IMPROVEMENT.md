# Analisis Improvement & Potensi Bug — Kalkulator KPR

Dokumen ini berisi hasil telaah kode pada versi `1.3.2+12`: potensi bug yang ditemukan,
usulan perbaikan teknis, dan ide fitur baru yang bisa menambah manfaat untuk pengguna.

Referensi arsitektur dan cara kerja fitur saat ini ada di [TECHNICAL.md](TECHNICAL.md).

---

## Ringkasan eksekutif

**5 hal paling mendesak:**

1. **Crash saat bunga diisi `0`** pada metode anuitas (metode default) — perhitungan
   menghasilkan `NaN` dan layar Tabel Angsuran melempar `UnsupportedError`. Lihat [B-1](#b-1).
2. **Tidak ada crash reporting/analytics sama sekali** — bug seperti di atas tidak akan
   pernah terlihat sampai ada pengguna yang menulis review 1 bintang.
3. **`isPremium()` tidak pernah kembali ke `false`** dalam satu sesi walaupun entitlement
   sudah tidak aktif. Lihat [B-4](#b-4).
4. **Nol test** padahal seluruh nilai jual aplikasi ada di `core/helpers.dart`. Satu file
   unit test dengan angka acuan akan mengunci perilaku rumus selamanya.
5. **Fitur pembeda masih tipis** — pesaing juga menampilkan tabel angsuran. Yang benar-benar
   dicari calon debitur tapi belum ada: **simulasi pelunasan dipercepat**, **rincian biaya
   awal KPR (provisi, BPHTB, notaris, asuransi)**, dan **bandingkan penawaran antar bank**.
   Lihat [F-1](#f-1), [F-2](#f-2), [F-4](#f-4).

---

## 1. Potensi bug

Severity: 🔴 tinggi (crash / angka salah / kehilangan uang) · 🟠 sedang (UX rusak, leak) ·
🟡 rendah (kosmetik, teknis).

| ID | Severity | Ringkasan | Lokasi |
| --- | --- | --- | --- |
| [B-1](#b-1) | 🔴 | Bunga `0` → `NaN` → crash di layar Tabel Angsuran | `core/helpers.dart`, `home_screen.dart` |
| [B-2](#b-2) | 🔴 | Jangka waktu `0` → pembagian nol, hasil `Infinity`/`NaN`, tabel kosong | `core/helpers.dart` |
| [B-3](#b-3) | 🔴 | Tenor sangat besar (typo) → ratusan ribu baris dibangun di UI thread → ANR/OOM | `helpers.dart`, `principal_table.dart` |
| [B-4](#b-4) | 🔴 | Status premium tidak pernah dicabut dalam satu sesi | `purchase_cubit.dart:13` |
| [B-5](#b-5) | 🟠 | Kegagalan download/share PDF ditelan diam-diam tanpa pesan | `principal_table.dart:148` |
| [B-6](#b-6) | 🟠 | Download PDF tanpa loading indicator (UI seolah membeku) | `principal_table.dart:127` |
| [B-7](#b-7) | 🟠 | `setState()` setelah `await` tanpa cek `mounted` | banner, paywall, dll. |
| [B-8](#b-8) | 🟠 | `BannerAd`, `InterstitialAd`, controller, dan listener tidak pernah di-dispose | beberapa file |
| [B-9](#b-9) | 🟠 | Interstitial tampil sebelum validasi form & tidak pernah dimuat ulang | `home_screen.dart:608` |
| [B-10](#b-10) | 🟠 | DP nominal boleh melebihi jumlah pinjaman → total pinjaman negatif | `fix_and_floating_screen.dart` |
| [B-11](#b-11) | 🟠 | `checkPremium()` menelan exception → state macet di `PurchaseInitial` saat offline | `purchase_cubit.dart:25` |
| [B-12](#b-12) | 🟠 | Layar utama tanpa `SafeArea` — berisiko tertimpa status bar di API 36 (edge-to-edge) | `home_screen.dart:255` |
| [B-13](#b-13) | 🟡 | Nomor versi di drawer di-hardcode `1.3.1` padahal app `1.3.2` | `home_screen.dart:242` |
| [B-14](#b-14) | 🟡 | File PDF sementara menumpuk, tidak pernah dihapus | `pdf_util.dart:244` |
| [B-15](#b-15) | 🟡 | `Future.delayed(1 detik)` artifisial di 4 tempat | 4 file |
| [B-16](#b-16) | 🟡 | Format angka memakai locale `EN` (`1,000,000`), bukan konvensi Indonesia | `currency_format.dart:23` |
| [B-17](#b-17) | 🟡 | Drawer "Detail Angsuran" praktis tidak bisa dibuka dari UI | `principal_table.dart:168` |
| [B-18](#b-18) | 🟡 | `openEndDrawer()` dipakai untuk menutup drawer (bekerja karena efek samping) | `home_screen.dart`, `principal_table.dart` |
| [B-19](#b-19) | 🟡 | Disclaimer & halaman "aplikasi lain" ada di kode tapi tidak pernah ditampilkan | `pages/about/` |

---

### B-1 · Bunga `0` menghasilkan `NaN` dan crash 🔴 {#b-1}

**Penyebab.** Validator bunga di layar utama hanya menolak string kosong, bukan nilai nol:

```dart
// lib/pages/home/home_screen.dart:523-528
validator: (value) {
  if (value == '') return "Bunga pinjaman tidak boleh kosong";
  return null;
},
```

Ketika bunga = 0, `calculateAnuitas` membagi dengan nol:

```dart
// lib/core/helpers.dart:36-41
final interestIncrease = pow((1 + annualInterest), month); // = 1.0
double installmentResult = (plafon * 0 * 1.0) / (1.0 - 1.0);  // 0 / 0 = NaN
```

**Dampak berantai** (sudah diverifikasi menjalankan rumusnya di Dart):

1. Layar utama menampilkan `Rp NaN`.
2. Menekan **Tabel Angsuran** memanggil `PrincipalTable` → `initState` → `addFooter()` →
   `getTotal()` yang menjalankan `NaN.toInt()` → **`Unsupported operation: Infinity or NaN
   toInt`** → layar crash.

```dart
// lib/pages/principle/principal_table.dart:89-103
data = data + widget.results![i].principal!.toInt();   // NaN.toInt() melempar exception
```

Anuitas adalah metode **default**, jadi jalur ini gampang tersentuh (mis. pengguna
mengetik `0` lalu berniat mengganti, atau bunga promo 0%).

**Saran perbaikan:**
- Samakan validator dengan layar Advanced yang sudah menolak `'0'`, dan tambahkan batas
  wajar (mis. `0 < bunga <= 100`).
- Tambahkan guard di `calculateAnuitas`: kalau `annualInterest == 0`, angsuran = `plafon / n`
  dan bunga = 0 (secara matematis benar, sekaligus mendukung skenario bunga 0%).
- Buat `getTotal()` tahan banting: `.toInt()` hanya untuk nilai `isFinite`.

### B-2 · Jangka waktu `0` → pembagian nol 🔴 {#b-2}

`month = year * 12 = 0` membuat `principal = plafon / 0 = Infinity` (flat/efektif) atau
`NaN` (anuitas), sementara loop pembangun tabel tidak berjalan sama sekali sehingga
pengguna mendapat tabel yang hanya berisi baris **Total** bernilai 0. Validator tahun juga
hanya menolak string kosong. Perbaikannya sama: validasi rentang di UI **dan** guard di
`helpers.dart`.

### B-3 · Tenor sangat besar membuat aplikasi hang 🔴 {#b-3}

Tidak ada batas atas untuk jangka waktu. Mengetik `500` tahun (atau salah ketik `1,000`)
menghasilkan 6.000–12.000 baris; `installmentTable*` membangun seluruh `List` secara
sinkron di UI thread, `data_table_2` menerima `List<DataRow>` yang sudah terbentuk semua,
dan `PdfUtil` merangkai tabel dengan `maxPages: 1000`. Hasilnya freeze/ANR, dan pada angka
lebih besar berujung OOM.

**Saran:** batasi tenor (mis. maksimal 40 tahun) di validator, dan untuk PDF yang panjang
jalankan generate lewat `compute()`/isolate supaya UI tetap responsif.

### B-4 · Status premium tidak pernah dicabut 🔴 {#b-4}

```dart
// lib/blocs/purchase_cubit/purchase_cubit.dart:13
bool isPremium() => _customerInfo != null;
```

`_customerInfo` diisi saat entitlement aktif, tetapi **tidak pernah dikembalikan ke `null`**
ketika `checkPremium()`/`restorePurchase()` berikutnya menemukan entitlement sudah tidak
aktif — cabang `else` hanya `emit(PurchaseNothing())`.

**Dampak:** langganan yang berakhir/refund tetap dianggap premium sampai proses aplikasi
di-restart; gating download & share PDF tetap terbuka. Kebalikannya juga tidak konsisten:
`BlocBuilder` (ikon premium) memakai state, sedangkan gating tombol memakai `isPremium()` —
dua sumber kebenaran yang bisa berbeda.

**Saran:** set `_customerInfo = null` di cabang `else`, atau lebih baik hapus getter itu dan
baca status premium hanya dari `state` (`context.select`), sehingga hanya ada satu sumber
kebenaran.

### B-5 · Error PDF ditelan diam-diam 🟠 {#b-5}

```dart
// lib/pages/principle/principal_table.dart:148-150
} catch (e) {
  LoadingOverlay.hide();
}
```

Kalau `getDownloadsDirectory()` mengembalikan `null` (`downloadsDir!` melempar), storage
penuh, atau pengguna membatalkan dialog simpan, **tidak ada pesan apa pun** — pengguna
premium menekan tombol download dan seolah tidak terjadi apa-apa. Ini juga tipe keluhan
yang sulit didiagnosis tanpa crash reporting.

**Saran:** tampilkan `CustomSnackbar` bertipe error dan catat exception ke Crashlytics.

### B-6 · Download PDF tanpa indikator loading 🟠 {#b-6}

`sharePDF()` memanggil `LoadingOverlay.show(context)` di awal, sedangkan `downloadPDF()`
langsung bekerja dan hanya memanggil `LoadingOverlay.hide()`. Untuk tabel 360 baris,
generate PDF berjalan di UI thread selama beberapa saat tanpa umpan balik apa pun.

### B-7 · `setState()` setelah `await` tanpa cek `mounted` 🟠 {#b-7}

Contoh: `BannerAdWidget.listener().onAdLoaded` ([banner_ad_widget.dart:33-39](lib/shared/widgets/banner_ad_widget.dart#L33-L39))
dan `_PremiumPlanScreenState.getPackage()` ([premium_plan_screen.dart:24-27](lib/pages/premiums/premium_plan_screen.dart#L24-L27)).
Kalau pengguna menutup layar sebelum iklan/offering selesai dimuat, akan muncul
`setState() called after dispose()`. Empat file juga sudah mematikan lint
`use_build_context_synchronously` secara global — padahal jalur seperti
`LoadingOverlay.show(context)` → `await` 1 detik → `Navigator.push(context)` benar-benar
bisa dijalankan setelah layar di-pop.

### B-8 · Resource tidak pernah di-dispose 🟠 {#b-8}

Tidak ada satu pun `dispose()` override di seluruh `lib/`:

- `BannerAd` tidak pernah `.dispose()` → memory leak dan request iklan yatim tiap kali
  pengguna keluar-masuk layar.
- `InterstitialAd` tidak di-dispose dan tidak dimuat ulang setelah ditampilkan.
- Semua `TextEditingController` (7 di layar Fix & Floating, 3 di layar utama, dinamis di
  layar Berjenjang) tidak di-dispose.
- `Purchases.addCustomerInfoUpdateListener` didaftarkan di `initState` paywall
  ([premium_plan_screen.dart:35-38](lib/pages/premiums/premium_plan_screen.dart#L35-L38))
  dan **tidak pernah dilepas** → listener menumpuk setiap kali paywall dibuka.

### B-9 · Interstitial tampil sebelum form divalidasi 🟠 {#b-9}

```dart
// lib/pages/home/home_screen.dart:608-614
if (_interstitialAd != null) await _interstitialAd!.show();
if (_formKey.currentState!.validate()) { ... }
```

Iklan muncul walaupun form tidak valid (pengguna melihat iklan tanpa mendapat apa-apa), dan
`show()` selesai begitu iklan tampil — bukan saat ditutup — sehingga navigasi ke tabel
terjadi di belakang iklan. Setelah sekali tampil, `_interstitialAd` tidak pernah diisi ulang
sehingga hanya ada 1 impresi per sesi (pendapatan iklan tertinggal).

**Saran:** validasi dulu → set `fullScreenContentCallback` → navigasi di `onAdDismissedFullScreenContent`
→ muat ulang interstitial di situ juga.

### B-10 · DP nominal boleh melebihi jumlah pinjaman 🟠 {#b-10}

Pada layar Fix & Floating, DP persen sudah di-clamp ke 100 tapi DP nominal hanya di-clamp
ke bawah (`< 0`). Mengetik DP nominal lebih besar dari harga membuat
`_loanTotalController` negatif, dan seluruh tabel angsuran menjadi angka negatif tanpa
peringatan.

### B-11 · Exception `checkPremium()` ditelan 🟠 {#b-11}

```dart
// lib/blocs/purchase_cubit/purchase_cubit.dart:25
} on PlatformException catch (_) {}
```

Saat offline atau Play Services bermasalah, tidak ada state yang di-emit sehingga UI
bertahan di `PurchaseInitial`: ikon premium tidak muncul dan banner tidak dimuat. Sebaiknya
emit state khusus (mis. `PurchaseUnknown`) dan tetap perlakukan sebagai non-premium untuk
gating, sambil menampilkan opsi coba lagi.

### B-12 · Layar utama tanpa `SafeArea` 🟠 {#b-12}

`MyHomePage` merender `AppBar` **di dalam** `Column` (bukan lewat `Scaffold.appBar`) dan
membungkusnya dengan `SizedBox(height: size.height)` tanpa `SafeArea`
([home_screen.dart:255-262](lib/pages/home/home_screen.dart#L255-L262)) — `SafeArea` yang ada
hanya untuk drawer. Karena API 36 memaksa edge-to-edge, judul dan tombol menu berisiko
tertimpa status bar, dan form bawah tertimpa navigation bar. Layar lain
(`AdvancedScreen`, `PrincipalTable`) sudah memakai `SafeArea`, jadi ini tidak konsisten.
**Perlu dicek langsung di perangkat Android 15/16.**

### B-13 · Versi di drawer di-hardcode 🟡 {#b-13}

`ListTile(title: const Text('Versi 1.3.1'))` ([home_screen.dart:242](lib/pages/home/home_screen.dart#L242))
sudah tertinggal satu rilis. Ganti dengan `package_info_plus` supaya otomatis mengikuti
`pubspec.yaml`.

### B-14 · File PDF sementara menumpuk 🟡 {#b-14}

Setiap kali share/download, `PdfUtil` menulis file baru bernama acak ke direktori downloads
dan tidak pernah menghapusnya. Untuk pengguna yang sering bersimulasi, ini menumpuk sampah.
**Saran:** tulis ke `getTemporaryDirectory()` (bukan downloads), pakai nama file deterministik
yang informatif (mis. `Tabel-Angsuran-Anuitas-20260806.pdf`), dan bersihkan file lama.

### B-15 · Delay artifisial 1 detik 🟡 {#b-15}

`await Future.delayed(const Duration(seconds: 1))` ada di 4 tempat (`home_screen.dart:52` &
`:649`, `fix_and_floating_screen.dart:507`, `tiered_screen.dart:486`). Untuk simulasi 15–30
tahun perhitungannya sendiri hanya beberapa milidetik, jadi ini murni menambah 1 detik
tunggu pada setiap aksi utama. Lebih baik hilangkan (atau ganti dengan loading yang hanya
muncul kalau perhitungan benar-benar > 300 ms).

### B-16 · Format angka bukan konvensi Indonesia 🟡 {#b-16}

`NumberFormat.currency(locale: 'EN', symbol: '', decimalDigits: 0)` menghasilkan
`Rp 1,000,000`, sedangkan konvensi Indonesia adalah `Rp1.000.000`. Karena `CurrencyFormat`
mem-parsing balik dengan asumsi koma sebagai pemisah ribuan, perubahan ini harus dilakukan
bersamaan pada formatter input (`ThousandsFormatter`) dan parser — kecil tapi perlu hati-hati.

### B-17 · Drawer "Detail Angsuran" sulit diakses 🟡 {#b-17}

`PrincipalTable` mendefinisikan `drawer:` berisi ringkasan parameter simulasi, tetapi
`AppBar`-nya menyetel `leading:` menjadi tombol back sehingga ikon hamburger hilang. Praktis
drawer hanya bisa dibuka dengan swipe dari tepi kiri — banyak pengguna tidak akan menemukan
fitur ini. Sebaiknya jadikan tombol eksplisit di `actions` (mis. ikon info).

### B-18 · `openEndDrawer()` dipakai untuk menutup drawer 🟡 {#b-18}

Beberapa tempat memanggil `_scaffoldKey.currentState?.openEndDrawer()` untuk *menutup*
drawer kiri. Ini kebetulan bekerja karena implementasi `openEndDrawer()` di framework
menutup drawer utama lebih dulu, tapi niatnya menyesatkan dan bisa berubah. Gunakan
`Navigator.pop(context)` atau `_scaffoldKey.currentState?.closeDrawer()`.

### B-19 · Layar yang tidak pernah ditampilkan 🟡 {#b-19}

`pages/about/disclaimer.dart`, `pages/about/other_app.dart`, dan
`pages/pdf/principal_table_pdf.dart` tidak di-route dari mana pun. Konsekuensinya:
dependency `cached_network_image` dan `flutter_pdfview` ikut terbawa ke bundle padahal
hanya dipakai layar mati tersebut. **Untuk aplikasi finansial, disclaimer justru sebaiknya
ditampilkan** (lihat [C-3](#c-3)) — sisanya hapus atau hidupkan.

---

## 2. Perbaikan teknis & kualitas kode

| ID | Prioritas | Usulan |
| --- | --- | --- |
| T-1 | Tinggi | **Unit test untuk `core/helpers.dart`.** Kunci semua rumus dengan angka acuan (mis. plafon 500 jt, 15 tahun, 10% → angsuran anuitas ±5,37 jt) plus kasus tepi: bunga 0, tenor 1 bulan, `fixYear` = tenor − 1, jumlah baris tabel, dan total pokok = plafon. Ini pengaman paling murah untuk bagian yang paling berisiko. |
| T-2 | Tinggi | **Crashlytics + analytics.** Tanpa ini, bug seperti [B-1](#b-1) tidak terdeteksi. Event yang layak dilacak: metode yang dipilih, pemakaian layar Advanced, tombol download/share ditekan (premium vs non-premium), paywall dibuka → beli. |
| T-3 | Tinggi | **Satu sumber kebenaran status premium.** Hapus `isPremium()` berbasis field, baca dari state Cubit; panggil `checkPremium()` sekali di root, bukan di setiap `BannerAdWidget` (sekarang tiap banner memicu panggilan RevenueCat sendiri). |
| T-4 | Sedang | **Lifecycle bersih.** Tambahkan `dispose()` untuk controller & iklan, cek `mounted` setelah `await`, lepas listener RevenueCat, lalu hapus `// ignore_for_file: use_build_context_synchronously`. |
| T-5 | Sedang | **Pisahkan validasi input** ke satu tempat (mis. `core/validators.dart`) supaya layar utama dan Advanced punya aturan yang sama (bunga > 0, tenor 1–40 tahun, DP ≤ harga). |
| T-6 | Sedang | **Hentikan mutasi `CalculateModel`.** Buat `helpers` menerima model dan mengembalikan hasil tanpa mengubah input (`copyWith` + variabel lokal). Sekarang setiap pemanggil terpaksa membuat dua instance identik hanya untuk menghindari efek samping — sumber bug yang mudah terulang saat menambah skema baru. |
| T-7 | Sedang | **Konstanta terpusat** untuk ad unit id, RevenueCat key, entitlement id, dan URL (`core/config.dart` atau `--dart-define`), menggantikan string yang tersebar di widget. |
| T-8 | Sedang | **Tema terpusat + Material 3 + dark mode.** `Colors.purple` ditulis ulang di puluhan tempat dan `useMaterial3: false`. Dark mode termasuk permintaan yang umum untuk aplikasi kalkulator. |
| T-9 | Rendah | **CI sederhana** (GitHub Actions): `flutter analyze` + `flutter test` pada setiap push. |
| T-10 | Rendah | **Pecah widget raksasa.** `home_screen.dart` 707 baris, `principal_table.dart` 647 baris, dua layar Advanced ±550 baris dengan blok form yang hampir identik — ekstrak `LabeledCurrencyField`, `ResultRing`, dan `SimulationForm` agar bisa dipakai ulang. |
| T-11 | Rendah | Hapus dependency yang hanya dipakai layar mati ([B-19](#b-19)), dan `requestLegacyExternalStorage="true"` yang sudah tidak relevan karena penyimpanan memakai SAF. |

---

## 3. Ide fitur baru

Diurutkan berdasarkan **manfaat bagi pengguna ÷ usaha implementasi**. Semua ide di bawah
bisa memakai mesin perhitungan yang sudah ada.

### F-1 · Simulasi pelunasan dipercepat (extra payment) ⭐ {#f-1}

**Kenapa berharga:** ini pertanyaan paling sering muncul setelah orang melihat tabel
angsuran — *"kalau saya nambah bayar 2 juta per bulan / 50 juta di tahun ke-3, berapa hemat
bunganya dan berapa tahun lebih cepat lunas?"* Belum ada di aplikasi ini, dan kompetitor
web pun jarang menyediakannya dengan baik.

**Bentuk:** input pembayaran ekstra (bulanan tetap / sekali di bulan ke-N), lalu tampilkan
kartu hasil: **hemat bunga Rp X**, **lunas Y bulan lebih cepat**, plus tabel baru.
Implementasinya: kurangi `principalTotalRemain` di iterasi terkait lalu hitung ulang sisa
tenor — semuanya di dalam `helpers.dart`.

**Usaha:** sedang. **Kandidat kuat untuk fitur premium.**

### F-2 · Kalkulator biaya awal KPR ⭐ {#f-2}

**Kenapa berharga:** angsuran bukan satu-satunya kejutan; calon debitur sering kaget dengan
dana yang harus disiapkan di awal. Komponen yang bisa dihitung: DP, **biaya provisi**
(±1%), administrasi, appraisal, **BPHTB** (5% dari NJOP − NPOPTKP), AJB/notaris/balik nama,
**asuransi jiwa & asuransi kebakaran**, serta biaya KPR lainnya.

**Bentuk:** satu layar dengan nilai default yang bisa diubah, output "Total dana yang harus
disiapkan" + rincian. Ini fitur yang sangat lokal (Indonesia) dan sulit ditiru aplikasi
kalkulator generik.

**Usaha:** rendah–sedang (murni aritmetika + form).

### F-3 · Ringkasan total & grafik di layar hasil {#f-3}

Saat ini **total bunga** dan **total pembayaran** hanya muncul di baris terakhir tabel —
padahal itu angka paling menohok ("bunga yang Anda bayar Rp 480 jt untuk pinjaman Rp 500 jt").
Tambahkan kartu ringkasan di layar hasil, dan grafik:

- kurva **sisa pinjaman** per tahun,
- **stacked bar pokok vs bunga** per tahun,
- opsi tabel **mode ringkas per tahun** (30 baris, bukan 360) dengan expand ke bulanan.

**Usaha:** rendah untuk kartu ringkasan, sedang untuk grafik (`fl_chart`).

### F-4 · Bandingkan skenario berdampingan ⭐ {#f-4}

Simpan 2–3 simulasi (mis. Bank A 7,5% fix 3 tahun vs Bank B 6,9% fix 2 tahun) lalu tampilkan
perbandingan: angsuran awal, angsuran setelah floating, total bunga, total pembayaran.
Ini mengubah aplikasi dari kalkulator menjadi **alat pengambilan keputusan** — alasan kuat
untuk membuka paywall.

**Usaha:** sedang (butuh penyimpanan + layar banding).

### F-5 · Simpan & riwayat simulasi {#f-5}

Sekarang semua input hilang begitu aplikasi ditutup. Menyimpan simulasi (dengan nama, mis.
"BTN 15 tahun") memakai `shared_preferences`/`sqflite` adalah quality-of-life yang murah dan
menjadi fondasi untuk [F-4](#f-4). Batasi 3 simulasi untuk pengguna gratis, tanpa batas untuk premium.

**Usaha:** rendah–sedang.

### F-6 · Kalkulator kemampuan & hitung mundur {#f-6}

Dua arah perhitungan yang belum ada:

- **Kemampuan cicilan:** dari penghasilan bulanan + rasio angsuran maksimal (umumnya 30–35%
  dari penghasilan), hitung **plafon maksimal** dan perkiraan harga rumah yang sanggup dibeli.
- **Hitung mundur:** "saya sanggup Rp 5 juta/bulan selama 15 tahun, berapa plafon yang bisa
  saya ambil?" — cukup membalik rumus anuitas.

Ini biasanya menjadi **langkah pertama** pengguna, sebelum tahu harga rumah — pintu masuk
yang bagus di layar utama.

**Usaha:** rendah.

### F-7 · Tanggal mulai kredit & tenor dalam bulan {#f-7}

Tabel sekarang hanya menampilkan "Bulan ke-1". Dengan input tanggal akad, kolom bisa
menampilkan **"Feb 2026"** sehingga pengguna langsung tahu kapan cicilan berakhir dan berapa
angsuran di tahun tertentu. Sekalian dukung tenor dalam bulan (`allowFraction: false` saat
ini memaksa tahun bulat), karena banyak bank memakai kelipatan bulan.

**Usaha:** rendah.

### F-8 · KPR Syariah {#f-8}

Pasar KPR syariah di Indonesia besar dan kalkulatornya jarang ada di aplikasi sejenis:
**murabahah** (margin tetap, mirip flat tapi istilah dan penyajiannya berbeda) dan
**musyarakah mutanaqisah** (bagi hasil menurun). Menambahkan mode ini membuka segmen
pengguna baru dengan usaha implementasi relatif kecil karena rumusnya berdekatan dengan yang
sudah ada.

**Usaha:** sedang (yang sulit justru penamaan & edukasi, bukan matematikanya).

### F-9 · Take over / refinancing {#f-9}

Input sisa pinjaman, sisa tenor, bunga berjalan, dan tawaran bunga baru → hitung selisih
angsuran dan total penghematan setelah dikurangi biaya pindah bank. Relevan untuk pengguna
yang bunga fix-nya baru saja berakhir dan angsurannya melonjak — momen yang justru sering
mendorong orang mencari kalkulator KPR.

**Usaha:** rendah (memakai ulang mesin yang ada).

### F-10 · Skema capped rate {#f-10}

`README.md` sudah menjelaskan tiga skema penentuan bunga termasuk **capped rate**, tetapi
aplikasi baru mengimplementasikan fix & floating dan berjenjang. Menambahkan batas atas
(cap) pada periode floating akan menyelaraskan aplikasi dengan materi edukasi yang sudah ada.

**Usaha:** rendah.

### F-11 · Ekspor & berbagi yang lebih luas {#f-11}

- **Ekspor CSV/Excel** untuk pengguna yang ingin mengolah sendiri (permintaan klasik untuk
  tabel angsuran).
- **Bagikan ringkasan sebagai teks/gambar** ke WhatsApp — jauh lebih sering dipakai daripada
  PDF, dan bisa menjadi kanal pertumbuhan organik kalau menyertakan tautan aplikasi.

**Usaha:** rendah.

---

## 4. Monetisasi & konversi premium

- **Klaim paywall belum akurat.** Paywall menulis "Akses Semua Fitur", padahal satu-satunya
  yang terkunci adalah download & share PDF (layar Advanced gratis). Ini berisiko dianggap
  menyesatkan dan membuat pembeli kecewa. Pilih salah satu: ubah teks menjadi manfaat yang
  nyata, atau tambahkan fitur premium yang benar-benar bernilai ([F-1](#f-1), [F-4](#f-4),
  [F-5](#f-5), [F-11](#f-11)).
- **Rewarded ad sebagai jembatan.** Beri satu kali download PDF setelah menonton rewarded
  ad. Pola ini memberi pendapatan dari pengguna yang tidak akan pernah membayar, sekaligus
  membuat mereka merasakan fitur premium — pendorong konversi yang terbukti.
- **Perbaiki hasil interstitial** ([B-9](#b-9)): memuat ulang iklan setelah ditampilkan bisa
  melipatgandakan impresi per sesi tanpa menambah gangguan.
- **Banner adaptif.** `AdSize.banner` (320×50) sudah usang; anchored adaptive banner mengisi
  lebar layar dan umumnya menghasilkan eCPM lebih baik.
- **Tampilkan harga per bulan setara** dan (kalau tersedia) masa percobaan/intro price dari
  RevenueCat — sekarang paywall hanya menampilkan `priceString` mentah.
- **Tombol "Kembalikan Pembelian" hanya ada di paywall.** Pengguna yang ganti HP dan
  langsung melihat iklan bisa mengira pembeliannya hilang → tambahkan juga di drawer.

---

## 5. Compliance & rilis

### C-1 · Consent iklan (UMP)

`google_mobile_ads` sudah menyediakan User Messaging Platform. Kalau ada pengguna dari
EEA/UK, form consent wajib ditampilkan sebelum memuat iklan. Saat ini iklan langsung dimuat
tanpa consent flow apa pun.

### C-2 · `upgrader` memaksa update tanpa jalan keluar

`showIgnore: false`, `showLater: false`, `barrierDismissible: false` berarti pengguna
**tidak bisa memakai aplikasi sama sekali** ketika `upgrader` mendeteksi versi baru. Kalau
lookup Play Store salah baca (region/locale/rollout bertahap), pengguna terkunci total.
Pertimbangkan `showLater: true` untuk update biasa, dan sediakan mode paksa hanya untuk
versi minimum yang benar-benar kritikal.

### C-3 · Disclaimer belum tampil {#c-3}

Aplikasi memberi angka finansial yang dipakai orang untuk keputusan besar, tetapi
`disclaimer.dart` tidak pernah dirender. Tampilkan disclaimer singkat di layar hasil/tabel
dan di menu — bahwa hasil adalah simulasi, angka final mengikuti kebijakan bank.

### C-4 · Data safety & privasi

Pastikan form Data Safety di Play Console konsisten dengan kenyataan (AdMob mengumpulkan
identifier iklan; RevenueCat menyimpan ID pembelian). Aplikasi tidak menyimpan data pribadi
lain — poin yang layak ditonjolkan di store listing.

---

## 6. Usulan urutan pengerjaan

**Tahap 1 — stabilkan (rilis patch 1.3.3)**
[B-1](#b-1), [B-2](#b-2), [B-3](#b-3) (validasi input + guard rumus) · [B-4](#b-4) ·
[B-5](#b-5)/[B-6](#b-6) · [B-13](#b-13) · [T-1](#) unit test helpers · [T-2](#) Crashlytics.

**Tahap 2 — rapikan (1.4.0)**
[B-7](#b-7)/[B-8](#b-8) lifecycle · [B-12](#b-12) edge-to-edge · [B-15](#b-15) hapus delay ·
[B-16](#b-16) format Rupiah · [T-3](#)–[T-8](#) · [C-1](#c-1)–[C-3](#c-3).

**Tahap 3 — nilai tambah untuk pengguna (1.5.0)**
[F-3](#f-3) ringkasan + grafik · [F-6](#f-6) kalkulator kemampuan · [F-7](#f-7) tanggal mulai
kredit · [F-2](#f-2) biaya awal KPR.

**Tahap 4 — pembeda & monetisasi (2.0.0)**
[F-1](#f-1) pelunasan dipercepat · [F-5](#f-5) riwayat · [F-4](#f-4) bandingkan skenario ·
paywall baru dengan manfaat yang jujur + rewarded ad.

**Kandidat berikutnya:** [F-8](#f-8) KPR syariah, [F-9](#f-9) take over, [F-10](#f-10)
capped rate, [F-11](#f-11) ekspor CSV & share ringkasan.
