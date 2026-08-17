import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../app/constants/app_assets.dart';
import '../../app/routes/route_names.dart';
import '../../shared/providers/document_provider.dart';
import 'splash_constants.dart';
import 'widgets/splash_animated_background.dart';
import 'widgets/splash_brand_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _masterController;
  late final Animation<double> _scanAnimation;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0B1F4A),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _masterController = AnimationController(
      vsync: this,
      duration: SplashConstants.splashDuration,
    );

    _scanAnimation = CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.0, 0.85, curve: Curves.easeInOut),
    );
    _pulseAnimation = CurvedAnimation(
      parent: _masterController,
      curve: Curves.easeInOut,
    );
    _progressAnimation = CurvedAnimation(
      parent: _masterController,
      curve: Curves.easeOutCubic,
    );

    _masterController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _navigateNext();
    });
  }

  Future<void> _navigateNext() async {
    // Run splash timing and warm up home data in parallel.
    final docsFuture = context.read<DocumentProvider>().ensureLoaded();
    await Future.wait<void>([
      Future<void>.delayed(SplashConstants.splashDuration),
      docsFuture,
    ]);
    if (!mounted) return;

    // Warm home banner so the first home frame is not blank.
    try {
      await precacheImage(const AssetImage(AppAssets.homeBanner), context);
    } catch (_) {
      // Ignore asset warm-up failures; home still opens.
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

    Navigator.of(context).pushReplacementNamed(RouteNames.home);
  }

  @override
  void dispose() {
    _masterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _masterController,
      builder: (context, _) {
        final pulse = (math.sin(_pulseAnimation.value * math.pi * 4) + 1) / 2;

        return Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              SplashAnimatedBackground(scanProgress: _scanAnimation.value),
              const SplashFloatingParticles(),
              SafeArea(
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    SplashBrandLogo(pulse: pulse),
                    const Spacer(flex: 2),
                    SplashProgressBar(progress: _progressAnimation.value)
                        .animate()
                        .fadeIn(delay: 800.ms),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
