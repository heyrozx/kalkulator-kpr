# Audio

## Voice-over

- File: `store/video/vo/voiceover_siti.mp3` (28,9 dtk), dibuat pemilik project di
  ElevenLabs. Voice: **"Siti – Clean Chill Expressive Casual"**, model **Eleven v4**.
- Alternatif yang pernah dipilih (gagal karena Free Tier diblokir): "Finn – Expressive &
  Ads Indonesian" (`zmTMXWr9TzPTCLvo0Uqr`).

Naskah (tag `[curious]`/`[excited]` untuk model v3/v4; hapus untuk model lain; baris
kosong = jeda, dipakai sebagai titik potong):

```
[curious] Mau beli rumah, tapi bingung berapa cicilannya?

[excited] Kenalin, Kalkulator KPR!

Cukup masukkan jumlah pinjaman, jangka waktu, dan suku bunga.

Angsuran per bulan langsung muncul. Bisa pilih anuitas, efektif, atau flat.

Cek tabel angsuran lengkap tiap bulan, grafik sisa pinjaman, sampai daya bayar, apakah cicilanmu masih aman.

Ada juga simulasi fix and floating, bunga berjenjang, dan KPR Syariah.

[excited] Kalkulator KPR. Download gratis sekarang di Google Play!
```

## SFX & musik (ElevenLabs Sound Effects v3, flow "Kalkulator KPR – Video Promo")

| File | Prompt | Dipakai untuk |
| --- | --- | --- |
| `tap4.mp3` | Single soft smartphone screen tap click… | tap di layar HP (`tap1–3` nyaris hening, tidak dipakai) |
| `keys_phone.mp3` | Smartphone virtual keyboard typing… | ketikan nilai input (dipecah 15 ketukan) |
| `keys_mech.mp3` | Mechanical keyboard typing… | ketikan teks overlay/caption (39 ketukan) |
| `whoosh.mp3` | Fast clean airy whoosh transition… | transisi logo, push layar, fitur lanjutan, outro; versi pelan = `swoosh` |
| `pop.mp3` | Cute bubbly UI pop sound… | logo/chip muncul |
| `ding1–3.mp3` | Bright positive success notification chime… | hasil cicilan & rasio daya bayar |
| `music.mp3` | Upbeat modern corporate background music loop… 112 bpm | musik latar (dipotong 24 dtk, di-loop) |

## Level mixing (`mix.py`)

- `VOL = {tap .6, key .42, type .36, whoosh .45, swoosh .3, pop .5, ding .42}` × gain event.
- Event `count`: 18 tik cepat dari `keys_phone` saat angka menghitung naik.
- VO ×0,9 dengan fade 20 ms tiap potongan.
- Musik ×0,17, fade-in 0,8 dtk, fade-out 2,5 dtk di akhir, **ducking −60%** saat VO
  bicara (envelope dihaluskan 0,25 dtk).
- Export: AAC 192k 48 kHz, `loudnorm=I=-14:TP=-1.5:LRA=11`.
