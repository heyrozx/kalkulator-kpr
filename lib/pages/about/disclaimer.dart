import 'package:flutter/material.dart';
import 'package:kalkulator_kpr/core/config.dart';
import 'package:kalkulator_kpr/core/theme.dart';

class Disclaimer extends StatelessWidget {
  const Disclaimer({super.key});

  static const List<String> _points = [
    'Seluruh angka pada aplikasi ini adalah hasil simulasi dan bukan penawaran '
        'kredit. Besaran angsuran yang berlaku ditentukan oleh bank atau lembaga '
        'pembiayaan tempat Anda mengajukan KPR.',
    'Perhitungan hanya memakai jumlah pinjaman, jangka waktu, dan suku bunga '
        'yang Anda masukkan. Biaya lain di luar itu — provisi, administrasi, '
        'appraisal, notaris, BPHTB, asuransi jiwa, dan asuransi kebakaran — '
        'belum diperhitungkan.',
    'Pada skema fix & floating maupun bunga berjenjang, bunga setelah masa fix '
        'berakhir mengikuti kebijakan bank dan dapat berubah sewaktu-waktu. '
        'Angka pada tabel angsuran memakai asumsi bunga yang Anda isi.',
    'Hasil pembulatan pada tabel dan PDF dapat berbeda tipis dengan tagihan '
        'resmi bank karena perbedaan metode pembulatan dan hari bunga.',
    'Aplikasi ini tidak menyimpan data simulasi Anda di server mana pun.',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disclaimer'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const Text(
              'Simulasi, bukan penawaran resmi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            for (final point in _points)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6, right: 10),
                      child:
                          Icon(Icons.circle, size: 7, color: AppColors.primary),
                    ),
                    Expanded(
                        child:
                            Text(point, style: const TextStyle(height: 1.5))),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Untuk keterangan pemakaian data, lihat kebijakan privasi di '
              '${AppConfig.privacyPolicyUrl}.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
