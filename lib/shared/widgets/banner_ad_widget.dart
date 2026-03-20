import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kalkulator_kpr/blocs/purchase_cubit/purchase_cubit.dart';

enum StatusAd { initial, loaded }

enum BannerPlacement {
  flatDescription,
  anuitasDescription,
  effectiveDescription,
  principalTable,
  advancedPage,
}

class BannerAdWidget extends StatefulWidget {
  final BannerPlacement? placement;
  final EdgeInsetsGeometry? margin;
  const BannerAdWidget({super.key, this.placement, this.margin});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? myBanner;
  StatusAd statusAd = StatusAd.initial;
  late PurchaseCubit purchaseCubit;

  BannerAdListener listener() {
    return BannerAdListener(
      onAdLoaded: (Ad ad) {
        if (kDebugMode) print('Ad Loaded');
        setState(() {
          statusAd = StatusAd.loaded;
        });
      },
    );
  }

  Future<void> initBanner() async {
    await purchaseCubit.checkPremium();

    // if (!kDebugMode && !purchaseCubit.isPremium()) {
    if (!purchaseCubit.isPremium()) {
      myBanner = BannerAd(
        adUnitId: getAddUnitId(),
        size: AdSize.banner,
        request: const AdRequest(),
        listener: listener(),
      );
      myBanner!.load();
    }
  }

  @override
  void initState() {
    purchaseCubit = BlocProvider.of<PurchaseCubit>(context);
    initBanner();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return statusAd == StatusAd.loaded
        ? Container(
            margin: widget.margin ??
                const EdgeInsets.only(left: 15, right: 15, bottom: 15),
            alignment: Alignment.center,
            width: myBanner!.size.width.toDouble(),
            height: myBanner!.size.height.toDouble(),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AdWidget(ad: myBanner!)),
          )
        : const SizedBox();
  }

  String getAddUnitId() {
    String debugUnitID = 'ca-app-pub-3940256099942544/6300978111';
    if (kDebugMode) return debugUnitID;

    switch (widget.placement) {
      case BannerPlacement.flatDescription:
        return 'ca-app-pub-2465007971338713/7887856855';
      case BannerPlacement.anuitasDescription:
        return 'ca-app-pub-2465007971338713/1541940350';
      case BannerPlacement.effectiveDescription:
        return 'ca-app-pub-2465007971338713/1849062116';
      case BannerPlacement.principalTable:
        return 'ca-app-pub-2465007971338713/9945891754';
      case BannerPlacement.advancedPage:
        return 'ca-app-pub-2465007971338713/2784671586';
      default:
        return debugUnitID;
    }
  }
}
