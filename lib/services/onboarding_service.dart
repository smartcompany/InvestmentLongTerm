import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const _completedKey = 'onboarding_race_completed_v1';
  static const _myAssetsHintShownKey = 'onboarding_my_assets_hint_shown_v1';

  static const demoAssetIds = ['bitcoin', 'nvidia', 'sk_hynix', 'gold'];
  static const demoYears = 5;

  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completedKey) ?? false;
  }

  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);
  }

  static Future<bool> shouldShowMyAssetsHint() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_myAssetsHintShownKey) ?? false);
  }

  static Future<void> markMyAssetsHintShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_myAssetsHintShownKey, true);
  }
}
