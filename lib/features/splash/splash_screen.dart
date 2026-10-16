import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';

import '../../app/constants/app_assets.dart';
import '../../app/constants/app_constants.dart';
import '../../app/routes/route_names.dart';
import '../../shared/providers/document_provider.dart';
import '../../shared/providers/settings_provider.dart';
import '../../shared/services/app_open_ad_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Color _background = Color(0xFFF7FAFF);

  static const Duration _maxSplashBudget = Duration(seconds: 8);
  static const Duration _minBeforeAd = Duration(seconds: 3);
  static const Duration _minWhenNoAd = Duration(seconds: 5);
  static const Duration _postAdSplash = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: _background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _navigateNext();
    });
  }

  Duration _remainingBudget(Stopwatch stopwatch) {
    final remaining = _maxSplashBudget - stopwatch.elapsed;
    return remaining > Duration.zero ? remaining : Duration.zero;
  }

  Future<void> _navigateNext() async {
    final stopwatch = Stopwatch()..start();
    final docsFuture = context.read<DocumentProvider>().ensureLoaded();

    await Future<void>.delayed(_minBeforeAd);
    if (!mounted) return;

    final remainingForAd = _remainingBudget(stopwatch);
    final adShown = remainingForAd > Duration.zero
        ? await AppOpenAdManager.instance.showAdIfAvailable(
            loadTimeout: remainingForAd,
          )
        : false;
    if (!mounted) return;

    if (adShown) {
      final budget = _remainingBudget(stopwatch);
      final postAdWait = _postAdSplash < budget ? _postAdSplash : budget;
      if (postAdWait > Duration.zero) {
        await Future<void>.delayed(postAdWait);
      }
    } else {
      final noAdTarget = _minWhenNoAd - stopwatch.elapsed;
      if (noAdTarget > Duration.zero) {
        final budget = _remainingBudget(stopwatch);
        final waitForNoAd = noAdTarget < budget ? noAdTarget : budget;
        if (waitForNoAd > Duration.zero) {
          await Future<void>.delayed(waitForNoAd);
        }
      }
    }
    if (!mounted) return;

    await docsFuture;
    if (!mounted) return;

    try {
      await precacheImage(const AssetImage(AppAssets.homeBanner), context);
    } catch (_) {
      // Home still opens if the banner cannot be warmed up.
    }
    if (!mounted) return;

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    final isPremium = context.read<SettingsProvider>().isPremium;
    Navigator.of(context).pushReplacementNamed(
      isPremium ? RouteNames.home : RouteNames.premium,
      arguments: isPremium ? null : true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: SizedBox.expand(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Spacer(),
              _SplashMark(),
              SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: Text(
                  AppConstants.appName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                    height: 1.1,
                  ),
                ),
              ),
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: Text(
                  'Scan documents into clean PDFs',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ),
              Spacer(),
              Center(child: _SplashLoader()),
              SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashMark extends StatelessWidget {
  const _SplashMark();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B66FF).withValues(alpha: 0.22),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Image.asset(
            AppAssets.appIcon,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class _SplashLoader extends StatelessWidget {
  const _SplashLoader();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LoadingAnimationWidget.staggeredDotsWave(
        color: const Color(0xFF3B66FF),
        size: 40,
      ),
    );
  }
}
