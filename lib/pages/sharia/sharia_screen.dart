import 'package:flutter/material.dart';
import 'package:kalkulator_kpr/core/theme.dart';
import 'package:kalkulator_kpr/pages/about/sharia_description.dart';
import 'package:kalkulator_kpr/pages/sharia/mmq_screen.dart';
import 'package:kalkulator_kpr/pages/sharia/murabahah_screen.dart';

/// Layar KPR Syariah (F-8): satu tab per akad.
class ShariaScreen extends StatelessWidget {
  const ShariaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'KPR Syariah',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            Text(
                              'Pembiayaan Tanpa Bunga',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Penjelasan akad',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ShariaDescription()),
                      ),
                      icon: SizedBox(
                        width: 25,
                        height: 25,
                        child: Image.asset('assets/question.png'),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  height: 50,
                  child: AppBar(
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    bottom: const TabBar(
                      indicatorColor: AppColors.primary,
                      tabs: <Widget>[
                        Tab(
                          child: Text(
                            'Murabahah',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                          ),
                        ),
                        Tab(
                          child: Text(
                            'Musyarakah MQ',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Expanded(
                child: TabBarView(
                  children: <Widget>[
                    MurabahahScreen(),
                    MmqScreen(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
