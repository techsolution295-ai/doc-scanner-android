class AppConstants {
  AppConstants._();

  static const String appName = 'Doc Scanner';
  static const String appVersion = '1.0.0';

  static const String privacyPolicyUrl = 'https://example.com/privacy-policy';
  static const String termsUrl = 'https://example.com/terms-and-conditions';
  static const String supportEmail = 'support@smartdocscanner.com';
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

  // TODO: Integrate in_app_purchase for premium subscriptions.
  static const bool paymentsEnabled = false;

  // TODO: Integrate google_mobile_ads for ad monetization.
  static const bool adsEnabled = false;
}
