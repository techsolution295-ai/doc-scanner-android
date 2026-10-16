import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../services/ad_service.dart';

/// Anchored banner. Hidden for Pro members.
enum BannerAdPlacement { top, bottom }

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({
    super.key,
    this.placement = BannerAdPlacement.bottom,
  });

  final BannerAdPlacement placement;

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  static const double _height = 56;
  static const _retryInterval = Duration(seconds: 30);

  BannerAd? _bannerAd;
  bool _isLoading = false;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadBanner();
      _retryTimer = Timer.periodic(_retryInterval, (_) {
        if (!mounted || _bannerAd != null) return;
        _loadBanner();
      });
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadBanner() {
    if (_isLoading || _bannerAd != null) return;
    final isPro = context.read<SettingsProvider>().isPremium;
    if (isPro) return;
    _isLoading = true;
    final ad = BannerAd(
      adUnitId: AdService.instance.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (loaded) {
          if (!mounted) {
            loaded.dispose();
            return;
          }
          setState(() {
            _bannerAd = loaded as BannerAd;
            _isLoading = false;
          });
        },
        onAdFailedToLoad: (failed, error) {
          failed.dispose();
          if (!mounted) return;
          setState(() {
            _bannerAd = null;
            _isLoading = false;
          });
        },
      ),
    );
    ad.load();
  }

  @override
  Widget build(BuildContext context) {
    final isPro = context.watch<SettingsProvider>().isPremium;
    if (isPro) return const SizedBox.shrink();

    final onTop = widget.placement == BannerAdPlacement.top;
    final bottom = onTop ? 0.0 : MediaQuery.paddingOf(context).bottom;
    return Material(
      color: Colors.white,
      elevation: onTop ? 0 : 8,
      shadowColor: Colors.black26,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Container(
          height: _height,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: onTop
                  ? BorderSide.none
                  : const BorderSide(color: Color(0xFFE5E7EB)),
              bottom: onTop
                  ? const BorderSide(color: Color(0xFFE5E7EB))
                  : BorderSide.none,
            ),
          ),
          alignment: Alignment.center,
          child: _bannerAd == null
              ? const _BannerPlaceholder()
              : SizedBox(
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
        ),
      ),
    );
  }
}

/// Pins the banner directly under the app bar and lets the screen fill the rest.
class TopBannerBody extends StatelessWidget {
  const TopBannerBody({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BannerAdWidget(placement: BannerAdPlacement.top),
        Expanded(child: child),
      ],
    );
  }
}

class _BannerPlaceholder extends StatelessWidget {
  const _BannerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
}
