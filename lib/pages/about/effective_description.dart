import 'package:flutter/material.dart';
import 'package:kalkulator_kpr/shared/widgets/banner_ad_widget.dart';

enum StatusAd { initial, loaded }

class EffectiveDescription extends StatefulWidget {
  const EffectiveDescription({super.key});

  @override
  State<EffectiveDescription> createState() => _EffectiveDescriptionState();
}

class _EffectiveDescriptionState extends State<EffectiveDescription> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Efektif'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(children: [
          Center(
            child: BannerAdWidget(
              placement: BannerPlacement.effectiveDescription,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 15),
            child: const Text(
                'Bunga efektif merupakan kebalikan dari bunga flat. Sistem perhitungan ini membuat angsuran semakin mengecil setiap bulannya.'),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 15),
            child: const Text(
                'Hal ini disebabkan karena bunga efektif menghitung besaran bunga berdasarkan sisa pokok utang atau jumlah yang belum dibayarkan. Sehingga, pembayaran bunga pun akan terus berkurang dari waktu ke waktu. Umumnya, bunga efektif digunakan pada jenis kredit jangka panjang, seperti investasi atau KPR.'),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 15),
            child: const Text(
                'Adapun cara menghitung bunga pinjaman per tahun dengan sistem efektif ialah sebagai berikut.'),
          ),
          SizedBox(
              width: size.width, child: Image.asset('assets/effective.png')),
          Container(
            margin: const EdgeInsets.only(bottom: 15, top: 15),
            child: const Text(
                'Hasil simulasi pada halaman utama adalah jumlah angsuran pada bulan pertama saja termasuk bunga dan pinjaman pokok.'),
          ),
        ]),
      ),
    );
  }
}
