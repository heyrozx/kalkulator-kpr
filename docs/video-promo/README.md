# Konsep Video Promo Kalkulator KPR

Folder ini menyimpan **semua keputusan** tentang video promo aplikasi, supaya permintaan
video berikutnya (revisi, versi baru, atau video fitur lain) bisa langsung dikerjakan
tanpa menjelaskan ulang dari awal.

| File | Isi |
| --- | --- |
| [`PREFERENSI.md`](PREFERENSI.md) | **Baca pertama.** Aturan gaya & hal yang *jangan* dilakukan, dirangkum dari semua revisi pemilik project |
| [`STORYBOARD.md`](STORYBOARD.md) | Urutan adegan, waktu, caption, aksi di layar, dan pemetaan voice-over per adegan |
| [`TEKNIS.md`](TEKNIS.md) | Cara kerja pipeline (HTML → Playwright → ffmpeg), cara render ulang, cara mengganti VO, jebakan teknis |
| [`AUDIO.md`](AUDIO.md) | Voice-over (naskah + voice), daftar SFX & musik ElevenLabs, level mixing |
| [`YOUTUBE.md`](YOUTUBE.md) | Judul, deskripsi, tag untuk YouTube & Shorts |
| [`RIWAYAT.md`](RIWAYAT.md) | Kronologi revisi beserta alasannya |

Kode & aset video ada di [`store/video/`](../../store/video/), hasil akhir di
`store/video/export/`.

## Ringkasan singkat

- **Produk:** video promo ±32 detik, dua versi dari satu sumber:
  vertikal 1080×1920 (Shorts/Reels/TikTok) & horizontal 1920×1080 (YouTube).
- **Gaya:** latar gradien ungu polos, mockup HP realistis berisi screenshot asli
  aplikasi, kamera zoom-in/zoom-out (boleh terpotong/crop), efek ketik pada teks dan
  input, SFX klik/ketik/whoosh/pop/ding, voice-over perempuan santai (Siti).
- **Alur cerita:** hook pertanyaan → logo → isi data → hasil cicilan → pilih metode →
  tabel → grafik → daya bayar → fitur lanjutan → penutup logo + ajakan download (suara).
- **Data contoh di layar:** pinjaman Rp 500.000.000, tenor 15 tahun, bunga 7,5%
  anuitas → angsuran Rp 4.635.062/bulan (efektif/flat bulan pertama Rp 5.902.778).
  Penghasilan contoh Rp 18.000.000 → rasio cicilan 28,5% (Aman).

## Cara cepat render ulang

```bash
cd store/video
./build.sh          # prep → render v & h → mix audio → export/*.mp4
```

Butuh `node` + `playwright` (Chromium), `ffmpeg`, `python3` + `numpy` + `pillow`.
Render dua versi ±6 menit di container 4 core.

## Saat menerima permintaan baru

1. Baca `PREFERENSI.md` — jangan mengulang hal yang sudah ditolak.
2. Kalau ada VO baru: ukur jeda (lihat `TEKNIS.md` → "Mengganti voice-over"), lalu
   susun ulang waktu adegan mengikuti VO, **bukan** sebaliknya.
3. Cek perubahan lewat snapshot frame (`node render.js v snap <dir> t1,t2,...`)
   sebelum render penuh.
4. Setelah render: kirim kedua MP4, commit `store/video/export/`, perbarui
   `RIWAYAT.md` + `CHANGELOG.md`.
