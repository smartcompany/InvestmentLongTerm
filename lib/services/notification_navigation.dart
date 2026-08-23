import 'package:flutter/material.dart';

/// 알림 탭 → 내 자산 탭 진입용.
class NotificationNavigation {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// MainTabScreen이 구독. 1 = 내 자산.
  static final ValueNotifier<int?> pendingTabIndex = ValueNotifier<int?>(null);

  static void openMyAssets() {
    pendingTabIndex.value = null;
    pendingTabIndex.value = 1;
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }
}
