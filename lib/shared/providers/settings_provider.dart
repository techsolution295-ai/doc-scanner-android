import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_constants.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._prefs) {
    _accent = _parseAccent(_prefs.getString(AppConstants.prefsThemeMode));
    _onboardingDone = _prefs.getBool(AppConstants.prefsOnboardingDone) ?? false;
  }

  final SharedPreferences _prefs;

  AppAccent _accent = AppAccent.royal;
  bool _onboardingDone = false;

  AppAccent get accent => _accent;
  bool get onboardingDone => _onboardingDone;

  Future<void> setAccent(AppAccent accent) async {
    _accent = accent;
    await _prefs.setString(AppConstants.prefsThemeMode, accent.name);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _onboardingDone = true;
    await _prefs.setBool(AppConstants.prefsOnboardingDone, true);
    notifyListeners();
  }

  AppAccent _parseAccent(String? raw) {
    return AppAccent.values.firstWhere(
      (a) => a.name == raw,
      orElse: () => AppAccent.royal,
    );
  }
}
