# Video Promo Kalkulator KPR

Dua versi, ±32 detik, 30 fps: `export/kalkulator-kpr-promo-vertical-1080x1920.mp4`
(Reels/TikTok/Shorts) dan `export/kalkulator-kpr-promo-horizontal-1920x1080.mp4`
(YouTube/Play Store promo).

## Cara kerja

- `stage.html` — seluruh animasi sebagai fungsi waktu `render(t)` (deterministik).
  Mockup HP memakai screenshot asli dari `../source/shots/`; bagian yang dianimasikan
  (nilai input, donut, angka hasil, switch metode, kolom penghasilan) dihapus oleh
  `prep.py` lalu digambar ulang di posisi aslinya. Kamera (zoom/pan) = keyframe `CAM`.
  Buka `stage.html?o=v&t=12` (atau `o=h`) di browser untuk melihat satu frame.
- `render.js` — Playwright merender frame demi frame ke ffmpeg, sekaligus menulis
  `out/events_<o>.json` (waktu tap, ketikan, whoosh, pop, ding).
- `mix.py` — menyusun SFX sesuai event + musik latar → `out/audio_<o>.wav`.
- `build.sh` — jalankan semuanya dan gabungkan ke `export/` (loudness -14 LUFS).

Durasi adegan bisa diatur lewat `cues.json` (opsional), misal
`{"result": 16.0, "end": 52}` — kunci: hook, logo, input, result, sw, tabel, grafik,
daya, more, outro, end.

## Audio

Semua SFX dan musik di `sfx/` dibuat dengan ElevenLabs Sound Effects v3 (tap, ketikan
HP, ketikan keyboard mekanik, whoosh, pop, ding, musik latar 30 dtk yang di-loop).

Voice-over: `vo/voiceover_siti.mp3` (ElevenLabs, voice "Siti – Clean Chill Expressive
Casual", eleven_v4). File dipotong per kalimat di titik jeda lalu ditempatkan per
adegan — jadwalnya di konstanta `VO` pada `stage.html` (`src` = potongan detik di file,
`t` = waktu tampil). Musik otomatis di-duck saat narasi. Kalau voice-over diganti, ukur
ulang jedanya (`ffmpeg -i vo.mp3 -af silencedetect=n=-25dB:d=0.18 -f null -`) dan
sesuaikan `VO`.

Naskah:

> Mau beli rumah, tapi bingung berapa cicilannya? / Kenalin, Kalkulator KPR! /
> Cukup masukkan jumlah pinjaman, jangka waktu, dan suku bunga. / Angsuran per bulan
> langsung muncul. Bisa pilih anuitas, efektif, atau flat. / Cek tabel angsuran
> lengkap tiap bulan, grafik sisa pinjaman, sampai daya bayar, apakah cicilanmu masih
> aman. / Ada juga simulasi fix and floating, bunga berjenjang, dan KPR Syariah. /
> Kalkulator KPR. Download gratis sekarang di Google Play!
