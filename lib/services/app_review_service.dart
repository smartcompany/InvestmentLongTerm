import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 리뷰 요청을 관리하는 서비스
///
/// - 최소 3회 이상 시뮬레이션(결과 화면) 완료 후
/// - 마지막 리뷰 요청 후 30일 이상 경과
/// - 디버그에서도 쿨다운은 유지 (매번 뜨지 않도록)
class AppReviewService {
  static const String _keyLastReviewRequestDate = 'last_review_request_date';
  static const String _keyReviewDismissed = 'review_dismissed';
  static const String _keySimulationCompleteCount = 'simulation_complete_count';

  static const int _minSimulationCount = 3;
  static const int _daysBetweenRequests = 30;

  /// 시뮬레이션/결과 화면 진입 시 호출.
  /// 조건을 만족하면 시스템 인앱 리뷰를 요청합니다.
  static Future<void> requestReviewIfAppropriate() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final reviewDismissed = prefs.getBool(_keyReviewDismissed) ?? false;
      if (reviewDismissed) {
        debugPrint('[AppReview] skipped: dismissed');
        return;
      }

      final currentCount = prefs.getInt(_keySimulationCompleteCount) ?? 0;
      final nextCount = currentCount + 1;
      await prefs.setInt(_keySimulationCompleteCount, nextCount);

      if (nextCount < _minSimulationCount) {
        debugPrint(
          '[AppReview] skipped: count $nextCount < $_minSimulationCount',
        );
        return;
      }

      final lastRequestDateStr = prefs.getString(_keyLastReviewRequestDate);
      if (lastRequestDateStr != null) {
        final lastRequestDate = DateTime.parse(lastRequestDateStr);
        final daysSinceLastRequest =
            DateTime.now().difference(lastRequestDate).inDays;
        if (daysSinceLastRequest < _daysBetweenRequests) {
          debugPrint(
            '[AppReview] skipped: $daysSinceLastRequest days since last '
            '(need $_daysBetweenRequests)',
          );
          return;
        }
      }

      final review = InAppReview.instance;
      if (!await review.isAvailable()) {
        debugPrint('[AppReview] skipped: not available');
        return;
      }

      // 요청 직전에 저장 — 시스템 UI가 안 떠도 연타로 반복 호출되는 것 방지
      await prefs.setString(
        _keyLastReviewRequestDate,
        DateTime.now().toIso8601String(),
      );

      debugPrint('[AppReview] requesting review (count=$nextCount)');
      await review.requestReview();
    } catch (e) {
      debugPrint('[AppReview] failed: $e');
    }
  }

  /// 커스텀 UI에서 사용자가 거절했을 때 호출.
  /// (시스템 팝업의 "지금 안 함"은 콜백이 없어 감지 불가)
  static Future<void> markReviewDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReviewDismissed, true);
  }

  static Future<void> resetReviewState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyReviewDismissed);
    await prefs.remove(_keyLastReviewRequestDate);
    await prefs.remove(_keySimulationCompleteCount);
  }

  static Future<void> openStoreListing() async {
    try {
      final review = InAppReview.instance;
      await review.openStoreListing();
    } catch (e) {
      debugPrint('[AppReview] openStoreListing failed: $e');
    }
  }

  /// 테스트용: 조건 무시하고 강제 요청
  static Future<void> requestReviewForTesting() async {
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        debugPrint('[AppReview] not available on this device/simulator');
      }
    } catch (e) {
      debugPrint('[AppReview] failed: $e');
    }
  }
}
