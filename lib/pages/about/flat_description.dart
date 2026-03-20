import 'package:flutter/material.dart';
import 'package:kalkulator_kpr/shared/widgets/banner_ad_widget.dart';

enum StatusAd { initial, loaded }

class FlatDescription extends StatefulWidget {
  const FlatDescription({super.key});

  @override
  State<FlatDescription> createState() => _FlatDescriptionState();
}

class _FlatDescriptionState extends State<FlatDescription> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flat'),
        centerTitle: true,
        elevation: 0,
        foregroundColor: Colors.black,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(children: [
          Center(
            child: BannerAdWidget(
              placement: BannerPlacement.flatDescription,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 15),
            child: const Text(
                'Bunga flat adalah sistem perhitungan suku bunga dengan mengacu pada besaran pokok awal pinjaman. Umumnya, jenis perhitungan ini digunakan pada kredit konsumtif, seperti KTA, mobil, handphone, dan lain sebagainya.'),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 15),
            child: const Text(
                'Bunga flat juga termasuk cara menghitung bunga pinjaman di bank paling mudah dibandingkan lainnya. Sebab, besaran nilai bunga dan pokok dalam cicilan bulanan akan tetap sama dan tidak berubah.'),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 15),
            child: const Text(
                'Adapun cara menghitung bunga pinjaman per bulan menggunakan sistem flat ialah sebagai berikut.'),
          ),
          SizedBox(width: size.width, child: Image.asset('assets/flat.png')),
          const SizedBox(
            height: 15,
          ),
        ]),
      ),
    );
  }
}
