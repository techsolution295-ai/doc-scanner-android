import 'package:flutter/material.dart';

import '../../features/card_scanner/card_scanner_screen.dart';
import '../../features/editor/editor_screen.dart';
import '../../features/files/files_screen.dart';
import '../../features/home/home_constants.dart';
import '../../features/home/home_screen.dart';
import '../../features/image_to_pdf/image_to_pdf_screen.dart';
// import '../../features/onboarding/onboarding_screen.dart';
import '../../features/pdf_preview/pdf_preview_screen.dart';
import '../../features/pdf_tools/pdf_tools_screen.dart';
import '../../features/pdf_viewer/pdf_viewer_screen.dart';
import '../../features/premium/premium_screen.dart';
import '../../features/scanner/scanner_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../shared/models/scan_session.dart';
import 'route_names.dart';

class AppRoutes {
  AppRoutes._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.splash:
        return _fadeRoute(const SplashScreen(), settings);
      // case RouteNames.onboarding:
      //   return _slideRoute(const OnboardingScreen(), settings);
      case RouteNames.home:
        return _homeFromSplashRoute(const HomeScreen(), settings);
      case RouteNames.scanner:
        final args = settings.arguments as ScannerArgs?;
        return _slideRoute(ScannerScreen(args: args), settings);
      case RouteNames.cardScanner:
        return _slideRoute(const CardScannerScreen(), settings);
      case RouteNames.imageToPdf:
        return _slideRoute(const ImageToPdfScreen(), settings);
      case RouteNames.editor:
        final session = settings.arguments as ScanSession;
        return _slideRoute(EditorScreen(session: session), settings);
      case RouteNames.pdfPreview:
        final session = settings.arguments as ScanSession;
        return _slideRoute(PdfPreviewScreen(session: session), settings);
      case RouteNames.files:
        return _slideRoute(const FilesScreen(), settings);
      case RouteNames.pdfTools:
        return _slideRoute(const PdfToolsScreen(), settings);
      case RouteNames.pdfViewer:
        final args = settings.arguments as PdfViewerArgs;
        return _slideRoute(PdfViewerScreen(args: args), settings);
      case RouteNames.premium:
        return _slideRoute(const PremiumScreen(), settings);
      case RouteNames.settings:
        return _slideRoute(const SettingsScreen(), settings);
      default:
        return _fadeRoute(const SplashScreen(), settings);
    }
  }

  /// Splash → Home: fade home in over the home background (no white flash).
  static PageRouteBuilder<dynamic> _homeFromSplashRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return ColoredBox(
          color: HomeConstants.background,
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }

  static PageRouteBuilder<dynamic> _fadeRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  static PageRouteBuilder<dynamic> _slideRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final offset = Tween<Offset>(
          begin: const Offset(0.05, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
        return SlideTransition(
          position: offset,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

/// Arguments for scanner screen navigation.
class ScannerArgs {
  const ScannerArgs({
    this.isBatchMode = false,
    this.isCardMode = false,
    this.existingSession,
  });

  final bool isBatchMode;
  final bool isCardMode;
  final ScanSession? existingSession;
}
