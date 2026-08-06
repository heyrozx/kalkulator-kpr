## 1.3.3 (13)

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

## 1.3.2 (12)

* Update target Android SDK ke API 36 (Android 16) sesuai persyaratan Google Play
* Rilis pertama yang memakai Google Play Billing Library 8 (persyaratan Google Play)
* Batasi permission WRITE_EXTERNAL_STORAGE hanya untuk Android 9 (API 28) ke bawah
* Tambah dokumentasi proyek (CLAUDE.md)
* Tambah dokumentasi teknis (TECHNICAL.md): arsitektur, daftar fitur, paket utama, dan alur premium
* Tambah dokumen analisis (ANALISIS-IMPROVEMENT.md): temuan potensi bug, usulan perbaikan teknis, dan ide fitur baru

## 1.3.1 (11)

* Update ad unit id and banner widget
* Update privacy policy link
