import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kalkulator_kpr/blocs/purchase_cubit/purchase_cubit.dart';
import 'package:kalkulator_kpr/core/theme.dart';
import 'package:kalkulator_kpr/pages/home/home_screen.dart';
import 'package:upgrader/upgrader.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => PurchaseCubit()..checkPremium(),
        ),
      ],
      child: MaterialApp(
        title: 'Kalkulator KPR',
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        home: UpgradeAlert(
            showIgnore: false,
            showLater: false,
            barrierDismissible: false,
            showReleaseNotes: false,
            upgrader: Upgrader(
              durationUntilAlertAgain: const Duration(hours: 3),
            ),
            child: const MyHomePage(title: 'Kalkulator KPR')),
      ),
    );
  }
}
