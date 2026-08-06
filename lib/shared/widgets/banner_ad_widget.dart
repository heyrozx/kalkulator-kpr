import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kalkulator_kpr/blocs/purchase_cubit/purchase_cubit.dart';
import 'package:kalkulator_kpr/core/config.dart';
import 'package:kalkulator_kpr/core/error_reporter.dart';

export 'package:kalkulator_kpr/core/config.dart' show BannerPlacement;

class BannerAdWidget extends StatefulWidget {
  final BannerPlacement? placement;
  final EdgeInsetsGeometry? margin;
  const BannerAdWidget({super.key, this.placement, this.margin});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _banner;
  bool _isLoaded = false;

  /// Iklan hanya dimuat setelah status premium diketahui dan pengguna bukan
  /// premium. Status dibaca dari `PurchaseCubit` — sebelumnya setiap banner
  /// memicu panggilan `checkPremium()` ke RevenueCat sendiri-sendiri.
  void _syncWithPurchaseState(PurchaseState state) {
    final isPremium = state is PurchaseData && state.isPremium;

    if (isPremium) {
      _disposeBanner();
      if (mounted && _isLoaded) setState(() => _isLoaded = false);
      return;
    }

    if (state is PurchaseInitial || _banner != null) return;

    final banner = BannerAd(
      adUnitId: AdConfig.banner(widget.placement),
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          // Tanpa cek `mounted`, keluar dari layar sebelum iklan selesai dimuat
          // memicu "setState() called after dispose()".
          if (!mounted) return;
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (_banner == ad) _banner = null;
          ErrorReporter.report(error, null, hint: 'BannerAd.load');
        },
      ),
    );

    _banner = banner;
    banner.load();
  }

  void _disposeBanner() {
    _banner?.dispose();
    _banner = null;
  }

  @override
  void initState() {
    super.initState();
    _syncWithPurchaseState(context.read<PurchaseCubit>().state);
  }

  @override
  void dispose() {
    _disposeBanner();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PurchaseCubit, PurchaseState>(
      listener: (context, state) => _syncWithPurchaseState(state),
      child: !_isLoaded || _banner == null
          ? const SizedBox()
          : Container(
              margin: widget.margin ??
                  const EdgeInsets.only(left: 15, right: 15, bottom: 15),
              alignment: Alignment.center,
              width: _banner!.size.width.toDouble(),
              height: _banner!.size.height.toDouble(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AdWidget(ad: _banner!),
              ),
            ),
    );
  }
}
