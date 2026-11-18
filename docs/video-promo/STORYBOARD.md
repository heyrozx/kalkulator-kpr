# Storyboard (versi final, 31,8 detik @ 30 fps)

Waktu adegan didefinisikan di objek `S` pada `store/video/stage.html`:

```js
hook: 0.0, logo: 3.4, input: 5.9, result: 9.65, sw: 11.8, tabel: 14.8,
grafik: 17.1, daya: 18.7, more: 22.0, outro: 26.85, end: 31.8
```

Semua aksi di dalam adegan memakai offset relatif terhadap awal adegan (`S.x + detik`).

| # | Adegan (`S`) | Mulai | Visual & aksi | Caption | Voice-over |
| --- | --- | --- | --- | --- | --- |
| 1 | `hook` | 0,0 | Latar gradien. "Mau beli rumah?" diketik di tengah → keluar ke atas di 1,42 dtk → "Tapi bingung **cicilannya**?" diketik (vertikal: 2 baris) | – | "Mau beli rumah, tapi bingung berapa cicilannya?" |
| 2 | `logo` | 3,4 | Ikon aplikasi pop-in, "Kalkulator **KPR**" diketik, sub "Simulasi cicilan rumah — cepat, akurat, gratis" fade | – | "Kenalin, Kalkulator KPR!" |
| 3 | `input` | 5,9 | HP naik mulus dari bawah sambil logo memudar → zoom ke form. Tap & ketik: pinjaman 500.000.000 → tenor 15 → bunga 7.5 (kamera pindah per kolom, kolom aktif bergaris ungu + caret) | ① Isi data pinjaman | "Cukup masukkan jumlah pinjaman, jangka waktu, dan suku bunga." |
| 4 | `result` | 9,65 | Zoom ke donut: track abu-abu terisi, arc ungu tumbuh, angka hitung naik ke Rp 4.635.062 + legenda; ding; kartu floating "Angsuran per bulan" | ② Cicilan langsung muncul | "Angsuran per bulan langsung muncul." |
| 5 | `sw` | 11,8 | Zoom ke switch: tap Efektif (+1,25) → Flat (+2,05) → Anuitas (+2,7); pil ungu bergeser, angka berubah (5.902.778 ↔ 4.635.062) | ③ Anuitas · Efektif · Flat | "Bisa pilih anuitas, efektif, atau flat." |
| 6 | `tabel` | 14,8 | Tap tombol "Tabel Angsuran" → layar push ke tab Tabel → kamera menyusuri baris | ④ Tabel angsuran lengkap | "Cek tabel angsuran lengkap tiap bulan," |
| 7 | `grafik` | 17,1 | Tap tab Grafik → crossfade → zoom "Total Pembayaran Rp 834.311.124" lalu turun ke grafik | ⑤ Grafik sisa pinjaman | "grafik sisa pinjaman," |
| 8 | `daya` | 18,7 | Tap tab Daya Bayar → tap kolom penghasilan, ketik 18.000.000 → rasio 28,5% Aman ter-reveal (wipe) + ding | ⑥ Cek daya bayar | "sampai daya bayar, apakah cicilanmu masih aman." |
| 9 | `more` | 22,0 | HP utama memudar, kamera ke 3 HP miring: Advanced (Fix & Floating), KPR Syariah, Riwayat Simulasi + chip label (vertikal: pan satu per satu; horizontal: ketiganya terlihat) | ⑦ Fitur lanjutan | "Ada juga simulasi fix and floating, bunga berjenjang, dan KPR Syariah." |
| 10 | `outro` | 26,85 | Kembali ke beranda berisi hasil. Logo + "Kalkulator **KPR**" (diketik) + subtitle "Hitung cicilan rumah dalam hitungan detik" (fade, tanpa ketik). Rata tengah vertikal; vertikal: HP utuh di bawah teks; horizontal: teks kiri, HP kanan | – | "Kalkulator KPR. Download gratis sekarang di Google Play!" |

## Pemetaan voice-over (`VO` di `stage.html`)

`src` = potongan detik di `store/video/vo/voiceover_siti.mp3` (dipotong di titik jeda),
`t` = waktu tampil di video.

| Potongan `src` | Ditempatkan di | Kalimat |
| --- | --- | --- |
| 0,00–3,15 | `S.hook + .2` | Mau beli rumah, tapi bingung berapa cicilannya? |
| 3,30–5,65 | `S.logo + .05` | Kenalin, Kalkulator KPR! |
| 5,75–9,30 | `S.input + .15` | Cukup masukkan jumlah pinjaman, jangka waktu, dan suku bunga. |
| 9,30–11,27 | `S.result + .1` | Angsuran per bulan langsung muncul. |
| 11,27–14,07 | `S.sw + .05` | Bisa pilih anuitas, efektif, atau flat. |
| 14,07–16,04 | `S.tabel + .15` | Cek tabel angsuran lengkap tiap bulan, |
| 16,04–17,39 | `S.grafik + .1` | grafik sisa pinjaman, |
| 17,39–20,38 | `S.daya + .1` | sampai daya bayar, apakah cicilanmu masih aman. |
| 20,38–24,94 | `S.more + .15` | Ada juga simulasi fix and floating, bunga berjenjang, dan KPR Syariah. |
| 24,94–28,92 | `S.outro + .2` | Kalkulator KPR. Download gratis sekarang di Google Play! |

Aturan: panjang tiap adegan ≈ panjang potongan VO-nya + jeda kecil; aksi visual kunci
(tap metode, reveal hasil) disinkronkan dengan kata yang diucapkan.

## Posisi kamera & layout

- Kamera = keyframe `CAM` (`K(t, x, y, s)`): titik dunia (x, y) diletakkan di anchor
  (`AX, AY` = 540,1060 vertikal; 1330,540 horizontal), `s` = skala. Koordinat dunia =
  piksel screenshot (layar HP 1080×2340 di origin).
- Zoom tipikal: vertikal 1,04–1,8; horizontal 0,85–1,3. Penutup vertikal skala 0,5 agar
  HP utuh dan grup teks+HP rata tengah.
- Horizontal: caption chip di kiri (x=80), HP di kanan; vertikal: caption di atas (y=150).
