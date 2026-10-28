## 1.5.1 (17)

* Pilihan metode bunga di beranda (Anuitas / Efektif / Flat) kini berupa switch
  berbentuk pil dengan penanda ungu yang bergeser, menggantikan tab bergaris.
  Ukurannya ringkas di tengah, tidak lagi selebar layar
* Beranda kini memakai latar ungu lembut; tombol Hitung dan Tabel Angsuran
  tampil datar tanpa bayangan
* Ikon tanda tanya di pojok kanan atas beranda dipindah ke menu samping sebagai
  **Bantuan**, berisi daftar penjelasan bunga anuitas, efektif, flat, KPR
  Syariah, dan disklaimer
* Judul "Kalkulator KPR" di beranda dibuat lebih kecil
* Logo aplikasi tampil di bagian atas menu samping
* Ikon premium di pojok kanan atas beranda kini berupa ikon lencana: garis ungu
  untuk user gratis (membuka halaman upgrade), emas terisi untuk user premium
  (membuka Pengaturan untuk melihat status langganan)
* Bayangan panel form di bagian bawah beranda dibuat lebih halus dan menyatu
  dengan latar
* Ikon premium di beranda kini berada di atas tab bergradasi (ungu untuk user
  gratis, emas untuk user premium) yang membulat di sisi kiri dan menempel ke
  tepi kanan layar
* Halaman Tabel Angsuran: ringkasan pinjaman di bagian atas kini menyatu dengan
  AppBar (latar ungu lembut, tanpa kartu), tombol premium memakai tab bergradasi
  yang sama dengan beranda
* Tombol Download dan Bagikan PDF diberi titik emas untuk user gratis sebagai
  penanda fitur premium
* Tab baru **Kemampuan Bayar** di halaman Tabel Angsuran: isi penghasilan bersih
  dan cicilan lain untuk melihat rasio cicilan (Aman ≤30%, Waspada ≤40%, Berat
  >40%), sisa penghasilan, dan penghasilan minimal yang disarankan. Dihitung
  dari angsuran tertinggi selama tenor
* Halaman Tabel Angsuran: judul pindah dari AppBar ke atas ringkasan, bagian
  atas kini rata tanpa sudut membulat, dan ringkasan ikut tergulung ke atas
  saat halaman digulir sehingga tab Grafik/Tabel/Kemampuan Bayar menempel di
  bawah AppBar. Header kolom tabel juga tetap menempel saat tabel digulir
* Kartu di halaman Tabel Angsuran dibuat lebih membulat
* Perbaikan: judul kolom "Bulan ke" di tabel angsuran tidak lagi terpotong
* Perbaikan: aplikasi bisa crash saat dibuka di build rilis dengan pesan
  "Failed to create an instance of androidx.work.impl.WorkDatabase"
  (WorkManager bawaan AdMob terpangkas oleh R8)

## 1.5.0 (16) - RELEASED

KPR Syariah (F-8 di `ANALISIS-IMPROVEMENT.md`).

* Menu **KPR Syariah** baru di menu samping, berisi dua akad:
* **Murabahah** — bank membeli rumah lalu menjualnya kembali dengan margin yang
  disepakati di awal. Harga jual dan angsuran terkunci sejak akad, jadi angsuran
  tidak pernah berubah sampai lunas
* **Musyarakah Mutanaqisah** — kepemilikan bersama: tiap bulan Anda membeli
  sebagian porsi bank sekaligus membayar sewa atas porsi yang masih milik bank,
  sehingga sewanya ikut mengecil. Tersedia pola angsuran menurun dan angsuran tetap
* Harga jual, total margin/sewa, dan angsuran per bulan langsung tampil di form
  begitu isiannya lengkap
* Seluruh hasil memakai istilah akad, bukan "bunga": tabel angsuran, grafik, dan
  PDF menampilkan **Margin** / **Sewa (Ujrah)**, **Sisa Harga Jual** / **Sisa Porsi
  Bank**, dan **Porsi Dibeli**
* Simulasi syariah bisa disimpan ke Riwayat Simulasi seperti kalkulator lain
* Halaman penjelasan akad murabahah & musyarakah mutanaqisah, dibuka lewat ikon
  tanda tanya di layar KPR Syariah
* Perbaikan: error saat menutup dialog nama pada tombol simpan simulasi di tabel
  angsuran dan saat mengubah nama di Riwayat Simulasi

**Halaman premium**

* Halaman langganan premium diganti dengan paywall resmi RevenueCat: tampilan,
  daftar paket, harga, dan tombol "kembalikan pembelian" kini mengikuti
  konfigurasi paywall di dashboard, sehingga penawaran bisa diubah tanpa harus
  merilis versi baru aplikasi
* Status premium langsung disegarkan setiap kali paywall ditutup, jadi iklan dan
  fitur premium menyesuaikan tanpa perlu menutup aplikasi

**Tampilan beranda & menu**

* Judul beranda kini **Kalkulator KPR**, dan pilihan **Anuitas / Efektif / Flat**
  pindah dari menu samping ke tab di bawah judul — cukup satu ketukan untuk
  membandingkan ketiga metode tanpa membuka menu
* Nilai yang sudah diisi tetap dipertahankan saat berpindah tab dan hasilnya
  langsung dihitung ulang dengan metode yang dipilih
* Menu samping dirapikan: **Advanced**, **KPR Syariah**, dan **Riwayat Simulasi**
  kini berbentuk daftar menu berikon dengan keterangan singkat
* Tab yang belum dipilih kini juga bergaris (abu-abu), jadi ketiganya terlihat
  sebagai pilihan
* Kolom isian dan tombol dibuat lebih ringkas — seragam di beranda, Advanced,
  dan KPR Syariah — dan panel form beranda kini menempel rapat ke tepi bawah layar
* Menu **Pengaturan** baru menampung Bebas Iklan, Pulihkan Pembelian, Beri Rating,
  Hubungi Kami, Disclaimer, Privacy Policy, dan versi aplikasi
* **Pulihkan Pembelian** kini bisa diakses langsung dari Pengaturan, tidak harus
  lewat halaman paywall
* Menu **Hubungi Kami** baru, membuka halaman kontak Nexadream
* Menu **Reset** dihapus
* Perbaikan: iklan interstitial yang gagal dimuat karena id-nya bentrok kini
  dicoba ulang otomatis, dan kegagalannya tidak lagi muncul sebagai error yang
  tidak tertangani

## 1.4.0 (14) - RELEASED

Dua fitur baru dari `ANALISIS-IMPROVEMENT.md`: ringkasan & grafik hasil (F-3) dan
riwayat simulasi (F-5).

**Ringkasan & grafik di layar hasil**

* Layar Tabel Angsuran kini punya dua tab: **Grafik** dan **Tabel**
* Kartu ringkasan menampilkan total pembayaran, total angsuran pokok, total bunga
  (berikut porsinya terhadap total), serta angsuran bulan pertama dan terakhir —
  angka-angka yang sebelumnya hanya bisa dibaca dari baris terakhir tabel
* Grafik **sisa pinjaman** memperlihatkan posisi utang di akhir tiap tahun
* Grafik **pokok vs bunga** memperlihatkan pergeseran komposisi angsuran tiap tahun
* Grafik tersedia untuk semua pengguna, tanpa premium

**Simpan & riwayat simulasi**

* Tombol simpan di layar Tabel Angsuran menyimpan simulasi beserta namanya
* Menu **Riwayat Simulasi** di menu samping menampilkan simulasi tersimpan, lengkap
  dengan angsuran awal, total bunga, dan total pembayaran; ketuk untuk membuka
  kembali tabel dan grafiknya
* Berlaku untuk semua kalkulator, termasuk Fix & Floating dan Bunga Berjenjang
* Riwayat bisa diubah namanya dan dihapus
* Daftar riwayat dimuat bertahap saat digulir, jadi tetap ringan walau simulasi
  tersimpan sudah banyak
* Pengguna gratis dapat menyimpan 3 simulasi; premium tanpa batas

## 1.3.3 (13) - RELEASED

Perbaikan menyeluruh hasil telaah kode (lihat `ANALISIS-IMPROVEMENT.md` bagian 1 & 2).

**Perbaikan bug**

* Perbaiki aplikasi berhenti saat bunga diisi `0` pada metode anuitas — perhitungan tidak
  lagi menghasilkan nilai tidak wajar dan tabel angsuran tetap bisa dibuka
* Bunga dan jangka waktu kini divalidasi (bunga harus lebih dari 0, jangka waktu 1–40 tahun)
  sehingga tidak ada lagi hasil kosong atau aplikasi membeku karena tenor kelewat besar
* Status premium kini selalu mengikuti kondisi langganan terbaru dalam satu sesi
* Kegagalan download/share tabel angsuran sekarang memberi pesan, tidak lagi diam saja
* Download PDF menampilkan indikator proses seperti share
* Iklan interstitial hanya muncul setelah form valid, dan dimuat ulang setelah ditutup
* DP tidak bisa lagi melebihi jumlah pinjaman pada kalkulator Advanced
* Tampilan layar utama tidak lagi berisiko tertimpa status bar (Android 15/16)
* Angka ditampilkan memakai format Indonesia (`Rp1.000.000`, bukan `Rp1,000,000`)
* Nomor versi di menu samping kini otomatis mengikuti versi aplikasi
* Hilangkan jeda 1 detik yang dibuat-buat di setiap perhitungan — hasil tampil seketika
* File PDF sementara memakai nama yang jelas dan dibersihkan otomatis

**Perbaikan lain**

* Tambah halaman Disclaimer di menu samping
* PDF tabel angsuran dibuat di proses terpisah supaya aplikasi tetap responsif
* Rapikan struktur kode: konfigurasi, validasi, tema, dan pelaporan error terpusat
* Tambah unit test untuk seluruh rumus perhitungan dan workflow CI (analyze + test)
* Hapus layar dan dependency yang sudah tidak dipakai
* Perbaiki build Android yang gagal mengunduh dependency Kotlin (paksa IPv4 dan
  samakan versi `kotlin-stdlib` dengan Kotlin plugin project)
* Matikan Jetifier yang sudah tidak diperlukan dan naikkan heap Gradle, supaya build
  tidak lagi gagal karena `Java heap space`

## 1.3.2 (12) - RELEASED

* Update target Android SDK ke API 36 (Android 16) sesuai persyaratan Google Play
* Rilis pertama yang memakai Google Play Billing Library 8 (persyaratan Google Play)
* Batasi permission WRITE_EXTERNAL_STORAGE hanya untuk Android 9 (API 28) ke bawah
* Tambah dokumentasi proyek (CLAUDE.md)
* Tambah dokumentasi teknis (TECHNICAL.md): arsitektur, daftar fitur, paket utama, dan alur premium
* Tambah dokumen analisis (ANALISIS-IMPROVEMENT.md): temuan potensi bug, usulan perbaikan teknis, dan ide fitur baru

## 1.3.1 (11) - RELEASED

* Update ad unit id and banner widget
* Update privacy policy link
