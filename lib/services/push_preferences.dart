import 'package:shared_preferences/shared_preferences.dart';

/// 푸시 마스터 + 2종류 수신 설정 (로컬).
/// 1) 자산 가치 변동  2) AI 자산 인사이트 (트렌드·포트폴리오·일일 안내)
class PushPreferences {
  PushPreferences._();
  static final PushPreferences shared = PushPreferences._();

  static const masterKey = 'push_notifications_enabled_v1';
  static const portfolioChangeKey = 'push_pref_portfolio_change_v1';
  static const aiInsightsKey = 'push_pref_ai_insights_v1';

  // legacy keys (마이그레이션용)
  static const _legacyDailyKey = 'push_pref_daily_v1';
  static const _legacyAiTrendKey = 'push_pref_ai_trend_v1';
  static const _legacyAiPortfolioKey = 'push_pref_ai_portfolio_v1';

  Future<bool> isMasterEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(masterKey) ?? true;
  }

  Future<void> setMasterEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(masterKey, enabled);
  }

  Future<bool> isPortfolioChangeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(portfolioChangeKey) ?? true;
  }

  Future<void> setPortfolioChangeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(portfolioChangeKey, enabled);
  }

  Future<bool> isAiInsightsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getBool(aiInsightsKey);
    if (current != null) return current;

    // 이전 세분 설정이 있으면 OR로 이전
    final legacyDaily = prefs.getBool(_legacyDailyKey);
    final legacyTrend = prefs.getBool(_legacyAiTrendKey);
    final legacyPortfolio = prefs.getBool(_legacyAiPortfolioKey);
    if (legacyDaily != null ||
        legacyTrend != null ||
        legacyPortfolio != null) {
      final migrated =
          (legacyDaily ?? true) ||
          (legacyTrend ?? true) ||
          (legacyPortfolio ?? true);
      await prefs.setBool(aiInsightsKey, migrated);
      return migrated;
    }
    return true;
  }

  Future<void> setAiInsightsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(aiInsightsKey, enabled);
  }

  /// 서버 FCM이 필요한 카테고리 중 하나라도 켜져 있는지.
  Future<bool> needsRemotePush() async {
    if (!await isMasterEnabled()) return false;
    return await isPortfolioChangeEnabled() || await isAiInsightsEnabled();
  }
}
