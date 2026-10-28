# Aset Listing Google Play

Semua file di folder ini siap diunggah ke **Play Console → Kehadiran di toko →
Listing toko utama**. Semua PNG 24-bit tanpa alpha (syarat Play Console).

| File | Ukuran | Dipakai untuk |
| --- | --- | --- |
| `icon_512.png` | 512 × 512 | Ikon aplikasi |
| `feature_graphic_1024x500.png` | 1024 × 500 | Grafis fitur |
| `screenshots/phone_01.png` … `phone_08.png` | 1080 × 1920 (9:16) | Screenshot ponsel, unggah sesuai urutan |

## Urutan screenshot

1. **Intro** — logo, tagline, dua mockup (beranda + tabel angsuran) bertumpuk
2. **Tiga Metode Bunga** — beranda (anuitas / efektif / flat)
3. **Grafik Angsuran** — tab Grafik di halaman Tabel Angsuran
4. **Tabel Angsuran** — tab Tabel
5. **Cek Daya Bayar** — tab Daya Bayar
6. **Fix & Floating** — kalkulator Advanced
7. **KPR Syariah** — murabahah
8. **Simpan Riwayat** — riwayat simulasi

Data contoh: pinjaman Rp 500 jt, 15 tahun, bunga 7,5% (anuitas).

## Membuat ulang

Screenshot aplikasi mentah ada di `source/shots/` (1080 × 2340, diambil dari
widget test dengan status bar 30dp & gesture bar 16dp kosong). Mockup disusun di
HTML/CSS (`source/gen.py`) lalu dirender Chromium lewat Playwright
(`source/render.js`).

```bash
cd store/source
mkdir -p fonts out
cp <flutter-sdk>/bin/cache/artifacts/material_fonts/Roboto-{Regular,Medium,Bold,Black}.ttf fonts/
cp ../../assets/ic_launcher.png logo.png
python3 gen.py            # menulis slide_XX.html & feature_graphic.html
node render.js "$PWD/out" # butuh package playwright + chromium
```

Hasil di `out/` masih berupa PNG dari Chromium; konversi ke RGB (tanpa alpha)
sebelum diunggah. File HTML, `fonts/`, `logo.png`, dan `out/` tidak perlu
di-commit.
