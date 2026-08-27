import 'package:flutter/material.dart';

/// 알림 탭 → 내 자산 탭 / AI 액션 진입용.
class NotificationNavigation {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// MainTabScreen이 구독. 1 = 내 자산.
  static final ValueNotifier<int?> pendingTabIndex = ValueNotifier<int?>(null);

  /// MyAssetsScreen이 구독. market_briefing | portfolio_insight
  static final ValueNotifier<String?> pendingAiAction =
      ValueNotifier<String?>(null);

  static const aiActionMarketBriefing = 'market_briefing';
  static const aiActionPortfolioInsight = 'portfolio_insight';

  static void openMyAssets() {
    pendingTabIndex.value = null;
    pendingTabIndex.value = 1;
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  static void openMyAssetsAi(String action) {
    pendingAiAction.value = null;
    pendingAiAction.value = action;
    openMyAssets();
  }

  static void handlePayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    switch (payload) {
      case 'ai_market_briefing':
        openMyAssetsAi(aiActionMarketBriefing);
      case 'ai_portfolio_insight':
        openMyAssetsAi(aiActionPortfolioInsight);
      case 'my_assets':
        openMyAssets();
      default:
        break;
    }
  }
}
