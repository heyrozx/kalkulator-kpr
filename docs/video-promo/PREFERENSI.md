# Preferensi Gaya (dari revisi pemilik project)

Aturan di bawah lahir dari feedback langsung. Ikuti tanpa perlu ditanyakan lagi.

## Wajib

- **Dua versi sekaligus**: vertikal 1080×1920 dan horizontal 1920×1080, maksimal
  1 menit. Saat ini ±32 detik.
- **Mockup HP realistis** dengan screenshot asli aplikasi (`store/source/shots/`),
  bukan UI gambaran ulang yang berbeda dari aplikasi.
- **Kamera zoom in/out**, jangan menampilkan seluruh layar terus-menerus sehingga
  terlihat kecil. Zoom sampai elemen terpotong (crop) **boleh**, asalkan teks yang
  sedang diketik/dibahas tetap terbaca utuh.
- **Efek ketik** (typing) pada judul, caption, dan nilai input. Nilai input diketik
  angka demi angka dengan format ribuan otomatis (5 → 5.000 → … → 500.000.000).
- **SFX**: tap/klik, ketikan keyboard HP (input), ketikan keyboard mekanik (teks
  overlay), whoosh (transisi), pop (elemen muncul), ding (hasil keluar).
- **Durasi mengikuti voice-over.** Jangan ada jeda kosong panjang di narasi; adegan
  dipercepat/dipadatkan supaya narasi nyambung (jeda antar-kalimat ±0,1–0,4 detik).
- **Latar cukup gradien** ungu (`#D154E8 → #9C27B0 → #6A1B9A`). Tanpa blob, lingkaran,
  pola titik, atau dekorasi lain — dinilai "terlalu ramai".
- **Komponen floating besar** (kartu "Angsuran per bulan", chip caption) — versi
  kecil dinilai kurang terbaca.
- **Bagian akhir rata tengah vertikal**: logo + judul + subtitle (+ HP utuh di versi
  vertikal) sebagai satu grup di tengah frame.

## Jangan

- ❌ Ikon generik (mis. ikon rumah Material) — terlihat kaku. Kalau butuh visual,
  pakai ilustrasi; tapi untuk pembuka saat ini **tanpa ikon/ilustrasi sama sekali**.
- ❌ Dua kalimat hook ditumpuk dalam satu layar dengan ukuran berbeda. Hook = adegan
  teks bergantian: "Mau beli rumah?" → keluar → "Tapi bingung cicilannya?" masuk,
  **font & ukuran sama**, posisi sama di tengah.
- ❌ Caret/indikator ketik yang tetap berkedip setelah teks selesai diketik (khususnya
  di chip caption). Caret hanya terlihat selama mengetik.
- ❌ Badge/tombol "Download gratis di Google Play" atau logo Google Play di layar
  penutup. Ajakan download **cukup lewat suara**.
- ❌ Efek ketik pada subtitle penutup ("Hitung cicilan rumah dalam hitungan detik") —
  cukup fade-in.
- ❌ Gerakan kamera berhenti-jalan beruntun (terlihat patah-patah). Gerakan masuk/pindah
  harus satu kurva mulus; cek kecepatan per frame (≤ ~100 px/frame di 30 fps).

## Nada & bahasa

- Bahasa Indonesia santai ("Kenalin", "cicilanmu"), ajakan jelas di akhir.
- Teks layar singkat; caption bernomor 1–7 dalam chip putih teks ungu.
- Warna aksen: ungu aplikasi `#9C27B0`, highlight kuning `#FFC83D` di kata kunci
  (`cicilannya`, `KPR`).
