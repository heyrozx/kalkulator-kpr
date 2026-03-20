import 'package:flutter/material.dart';
import 'package:kalkulator_kpr/shared/widgets/banner_ad_widget.dart';

import '../../models/calculate_model.dart';
import 'fix_and_floating_screen.dart';
import 'tiered_screen.dart';

// Feature source:
// https://www.rumah123.com/kpr/simulasi-kpr/

class AdvancedScreen extends StatefulWidget {
  final CalculatorType? type;
  const AdvancedScreen({super.key, this.type});

  @override
  State<AdvancedScreen> createState() => _AdvancedScreenState();
}

typedef MenuEntry = DropdownMenuEntry<String>;

class _AdvancedScreenState extends State<AdvancedScreen> {
  late CalculatorType type;

  @override
  initState() {
    type = widget.type ?? CalculatorType.anuitas;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(
                height: 10,
              ),
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                child: Row(
                  children: [
                    IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back)),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Advanced',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            Text(
                              'Perhitungan Lengkap',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        _showMyDialog();
                      },
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        color: Colors.purple.withValues(alpha: 0.1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 12),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                type == CalculatorType.anuitas
                                    ? 'Anuitas'
                                    : type == CalculatorType.effective
                                        ? 'Efektif'
                                        : 'Flat',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_drop_down)
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Center(
                child: BannerAdWidget(
                  margin: EdgeInsets.only(left: 15, right: 15, bottom: 4),
                  placement: BannerPlacement.advancedPage,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  // color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: SizedBox(
                  height: 50,
                  child: AppBar(
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    bottom: TabBar(
                      indicatorColor: Colors.purple,
                      tabs: <Widget>[
                        Tab(
                          child: Text(
                            'Fix & Floating',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                          ),
                        ),
                        Tab(
                          child: Text(
                            'Berjenjang',
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
              Expanded(
                child: TabBarView(
                  children: <Widget>[
                    FixAndFloatingScreen(
                      type: type,
                    ),
                    TieredScreen(
                      type: type,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pilih Perhitungan'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                ListTile(
                  onTap: () {
                    setState(() {
                      type = CalculatorType.anuitas;
                    });
                    Navigator.pop(context);
                  },
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Anuitas',
                    style: type == CalculatorType.anuitas
                        ? TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple)
                        : TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  trailing: Icon(Icons.chevron_right),
                ),
                ListTile(
                  onTap: () {
                    setState(() {
                      type = CalculatorType.effective;
                    });
                    Navigator.pop(context);
                  },
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Efektif',
                    style: type == CalculatorType.effective
                        ? TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple)
                        : TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  trailing: Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
