import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants/app_constants.dart';
import 'routes/app_routes.dart';
import 'routes/route_names.dart';
import 'theme/app_theme.dart';
import '../shared/providers/document_provider.dart';
import '../shared/providers/settings_provider.dart';
import '../shared/services/ad_service.dart';
import '../shared/services/app_open_ad_service.dart';
import '../shared/services/document_service.dart';
import '../shared/services/pro_purchase_service.dart';

class SmartDocScannerApp extends StatelessWidget {
  const SmartDocScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(accent: settings.accent),
          themeMode: ThemeMode.light,
          initialRoute: RouteNames.splash,
          onGenerateRoute: AppRoutes.onGenerateRoute,
        );
      },
    );
  }
}

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  final imagePickerImplementation = ImagePickerPlatform.instance;
  if (imagePickerImplementation is ImagePickerAndroid) {
    imagePickerImplementation.useAndroidPhotoPicker = true;
  }
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final prefs = await SharedPreferences.getInstance();
  final documentService = DocumentService(prefs);
  final settings = SettingsProvider(prefs);
  final purchases = ProPurchaseService(settings);

  AdService.instance.bind(isPro: () => settings.isPremium);
  try {
    await MobileAds.instance.initialize();
    AdService.instance.initialize();
    unawaited(AppOpenAdManager.instance.loadAd());
  } catch (error) {
    if (kDebugMode) debugPrint('Ads init failed: $error');
  }
  await purchases.start();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ChangeNotifierProvider<ProPurchaseService>.value(value: purchases),
        ChangeNotifierProvider(
          create: (_) => DocumentProvider(documentService),
        ),
      ],
      child: const SmartDocScannerApp(),
    ),
  );
}
