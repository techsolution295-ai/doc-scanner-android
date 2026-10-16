class AppConstants {
  AppConstants._();

  static const String appName = 'Doc Scanner';
  static const String appVersion = '1.0.0';

  static const String privacyPolicyUrl =
      'https://sites.google.com/view/app-bounties/home';
  static const String termsUrl = 'https://sites.google.com/view/appbounties/home';
  static const String supportEmail = 'appbounties@gmail.com';
  static const String moreAppsUrl = 'https://play.google.com/store/apps';

  static const String prefsOnboardingDone = 'onboarding_done';
  static const String prefsThemeMode = 'theme_mode';
  static const String prefsLanguage = 'app_language';
  static const String prefsAppLock = 'app_lock_enabled';
  static const String prefsPremium = 'is_premium';
  static const String prefsDocuments = 'saved_documents';

  static const String documentsFolder = 'smart_doc_scanner';
  static const String pdfExtension = '.pdf';
  static const String imageExtension = '.jpg';

  // TODO: Integrate Google ML Kit or OpenCV for real-time edge detection.
  static const bool useNativeEdgeDetection = false;

  // TODO: Integrate Google ML Kit Text Recognition for OCR feature.
  static const bool ocrEnabled = false;

  // TODO: Integrate Firebase Storage or Google Drive API for cloud backup.
  static const bool cloudBackupEnabled = false;

  static const bool paymentsEnabled = true;
  static const bool adsEnabled = true;

  static const String weeklyProductId = 'weekly_premium';
  static const String monthlyProductId = 'app_premium';
  static const String yearlyProductId = 'yearly_premium';
}
