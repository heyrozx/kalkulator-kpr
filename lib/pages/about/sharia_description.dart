import 'package:flutter/material.dart';
import 'package:kalkulator_kpr/core/theme.dart';

/// Penjelasan singkat akad KPR syariah, sejajar dengan halaman penjelasan
/// Flat/Efektif/Anuitas yang sudah ada.
class ShariaDescription extends StatelessWidget {
  const ShariaDescription({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KPR Syariah'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Paragraph(
              'KPR syariah tidak memungut bunga. Bank memperoleh imbalan lewat '
              'akad jual beli atau kerja sama kepemilikan, sehingga istilah '
              'yang dipakai pun berbeda dengan KPR konvensional.',
            ),
            const _Heading('Murabahah'),
            const _Paragraph(
              'Akad jual beli. Bank membeli rumah yang Anda pilih, lalu '
              'menjualnya kembali kepada Anda dengan margin keuntungan yang '
              'disepakati di awal.',
            ),
            const _Paragraph(
              'Harga jual = harga pokok + margin. Angka itu dikunci sejak akad '
              'dan dicicil rata sampai lunas, jadi angsuran Anda tidak pernah '
              'berubah — tidak ada periode floating seperti KPR konvensional.',
            ),
            const _Paragraph(
              'Karena margin dihitung dari harga pokok yang tidak menyusut, '
              'angkanya menyerupai perhitungan bunga flat. Bedanya, yang Anda '
              'lunasi adalah harga jual yang sudah pasti, bukan pokok yang '
              'terus berbunga.',
            ),
            const _Heading('Musyarakah Mutanaqisah'),
            const _Paragraph(
              'Akad kerja sama kepemilikan yang menurun. Rumah dimiliki '
              'bersama: porsi Anda berasal dari uang muka, sisanya porsi bank.',
            ),
            const _Paragraph(
              'Setiap bulan Anda membayar dua hal sekaligus — membeli sebagian '
              'porsi bank, dan membayar sewa (ujrah) atas porsi yang masih '
              'dimiliki bank. Begitu porsi bank mengecil, sewanya ikut '
              'mengecil, sampai akhirnya rumah sepenuhnya milik Anda.',
            ),
            const _Paragraph(
              'Ada dua pola yang biasa dipakai bank:',
            ),
            const _Bullet(
              'Angsuran menurun — porsi yang Anda beli tetap tiap bulan, '
              'sementara sewa terus mengecil, sehingga total angsuran menurun.',
            ),
            const _Bullet(
              'Angsuran tetap — total angsuran dikunci; porsi yang Anda beli '
              'membesar seiring sewa yang mengecil.',
            ),
            const _Heading('Catatan'),
            const _Paragraph(
              'Hasil kalkulator ini adalah perkiraan berdasarkan angka yang '
              'Anda masukkan. Ketentuan, biaya, dan skema tiap bank syariah '
              'dapat berbeda — pastikan kembali ke bank yang bersangkutan.',
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  const _Paragraph(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(text),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
