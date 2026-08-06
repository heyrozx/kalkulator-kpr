import 'package:flutter/material.dart';
import 'package:kalkulator_kpr/shared/widgets/banner_ad_widget.dart';

enum StatusAd { initial, loaded }

class AnuitasDescription extends StatefulWidget {
  const AnuitasDescription({super.key});

  @override
  State<AnuitasDescription> createState() => _AnuitasDescriptionState();
}

class _AnuitasDescriptionState extends State<AnuitasDescription> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anuitas'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(children: [
          Center(
            child: BannerAdWidget(
              placement: BannerPlacement.anuitasDescription,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 15),
            child: const Text(
                'Bunga anuitas merupakan modifikasi dari bunga efektif dimana total cicilan per bulan jumlahnya sama. Namun, cara perhitungan bunganya akan tetap dikalkulasikan dari saldo pokok pinjaman.'),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 15),
            child: const Text(
                'Dalam perhitungan bunga anuitas, besaran cicilan pokok pinjaman akan meningkat, sementara besaran bunga menurun. Tujuannya ialah untuk mempermudah nasabah dalam melunasi angsuran bulanan dan tidak bingung dengan jumlah yang berubah-ubah. Berikut contohnya.'),
          ),
          SizedBox(width: size.width, child: Image.asset('assets/anuitas.png')),
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
