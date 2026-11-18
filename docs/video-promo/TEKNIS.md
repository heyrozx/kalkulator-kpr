# Teknis Pipeline Video

Semua file di `store/video/`.

| File | Fungsi |
| --- | --- |
| `stage.html` | Seluruh animasi sebagai fungsi deterministik `render(t)`. Param URL: `?o=v` / `?o=h`, `&t=12` (lihat 1 frame di browser), `&cues=JSON` (override `S`) |
| `prep.py` | Membuat `assets/home_clean.png` & `assets/daya_clean.png`: area yang dianimasikan (nilai input, donut, angka, switch, kolom penghasilan) dihapus dari screenshot |
| `render.js` | Playwright render frame demi frame → pipe JPEG ke ffmpeg (libx264 CRF 18). Mode: `node render.js v out.mp4 30`, `node render.js v snap <dir> 1.5,6.2`, `node render.js v events` |
| `mix.py` | Menyusun audio dari `out/events_<o>.json`: SFX per event, VO per potongan, musik loop + ducking → `out/audio_<o>.wav` |
| `build.sh` | Jalankan semuanya + mux AAC 192k, loudnorm −14 LUFS → `export/` |
| `assets/` | Screenshot asli (`../source/shots/`), versi bersih, `logo.png` |
| `fonts/` | Roboto Regular/Medium/Bold/Black |
| `sfx/`, `vo/` | Audio ElevenLabs (lihat `AUDIO.md`) |
| `out/` | Hasil antara (di-gitignore) |
| `export/` | MP4 final (di-commit) |

## Prinsip desain kode

- **Deterministik**: tidak ada CSS animation/transition; semua dihitung dari `t`
  sehingga render frame-by-frame stabil dan bisa di-snapshot di waktu mana pun.
- **Event audio dari sumber yang sama**: setiap `tap()`, `typeField()`, `typer()`, `ev()`
  mencatat event ke `EVENTS` → audio selalu sinkron dengan visual.
- **Overlay di koordinat screenshot**: elemen dinamis ditaruh di koordinat piksel
  screenshot asli (font Roboto, ukuran dikalibrasi): nilai input 48px baseline 1848/2022,
  angka total 81px bold baseline 970, legenda 45px bold baseline 1481, switch pil
  x172 y264 738×102. Donut: pusat (539,5, 944,5), r 341, stroke 38.
- **Satu sumber dua orientasi**: `V` (vertikal) vs horizontal hanya beda anchor kamera,
  keyframe `CAM`, dan posisi overlay.

## Render ulang

```bash
cd store/video
python3 prep.py                     # hanya jika screenshot berubah
node render.js v out/video_v.mp4 30 & node render.js h out/video_h.mp4 30 & wait
python3 mix.py v h
# lalu mux (lihat build.sh), atau cukup ./build.sh
```

Render ±3 fps per versi (software rendering). Dua versi paralel ±6 menit untuk 32 dtk.
Selalu cek snapshot dulu sebelum render penuh.

## Mengganti voice-over

1. Simpan file ke `vo/voiceover_siti.mp3` (atau ganti nama di `mix.py`).
2. Ukur jeda kalimat:
   `ffmpeg -i vo/voiceover_siti.mp3 -af silencedetect=n=-25dB:d=0.18 -f null - 2>&1 | grep silence_`
3. Isi `VO` di `stage.html` dengan potongan `src` (potong di tengah jeda).
4. Atur ulang `S` dan offset aksi agar tiap adegan ≈ panjang potongan VO-nya.
   Cek tidak ada VO bertumpuk:
   `node render.js v events` lalu bandingkan `t + (src1 - src0)` dengan `t` berikutnya.
5. Snapshot → render → mix → export.

## Mengganti screenshot aplikasi

Screenshot mentah 1080×2340 di `store/source/shots/` (lihat `store/README.md`). Kalau UI
beranda/daya bayar berubah, koordinat di `prep.py` dan `FIELDS`/donut/switch di
`stage.html` harus diukur ulang (pakai PIL: cari baris/kolom piksel gelap & border abu
`rgb(189,189,189)`).

## Jebakan yang pernah terjadi

- Keyframe kamera berhenti-jalan berturut-turut → terlihat patah. Gabungkan jadi satu
  segmen `inOut`; cek kecepatan dengan `camAt()` per frame.
- `white-space: pre` membuat teks panjang tidak turun baris → pakai `\n` eksplisit
  untuk versi vertikal.
- Musik ElevenLabs 30 dtk punya ekor fade-out (±25,5 dtk) → dipotong di 24 dtk sebelum
  di-loop dengan crossfade 0,25 dtk.
- 3 dari 4 take "tap" ElevenLabs nyaris hening; yang dipakai `tap4.mp3`. Rekaman
  ketikan dipecah jadi ketukan tunggal lewat deteksi onset di `mix.py`.
- `loudnorm` satu tahap menghasilkan ±−14,6 sampai −15 LUFS (cukup untuk sosial media).
- ElevenLabs Free Tier akun ini pernah diblokir untuk TTS ("unusual activity") saat
  dipanggil dari cloud → VO dibuat manual di situs ElevenLabs lalu diunggah.
