import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 리뷰 요청을 관리하는 서비스
///
/// 사용자가 앱을 여러 번 사용한 후 적절한 타이밍에 리뷰를 요청합니다.
/// - 최소 3회 이상 시뮬레이션 완료 후
/// - 마지막 리뷰 요청 후 7일 이상 경과
/// - 사용자가 리뷰를 거부하지 않은 경우
class AppReviewService {
  static const String _keyLastReviewRequestDate = 'last_review_request_date';
  static const String _keyReviewDismissed = 'review_dismissed';
  static const String _keySimulationCompleteCount = 'simulation_complete_count';

  // 리뷰 요청 조건
  static const int _minSimulationCount = 3; // 최소 시뮬레이션 완료 횟수
  static const int _daysBetweenRequests = 7; // 리뷰 요청 간 최소 일수

  // 개발/테스트 모드 (kDebugMode일 때 조건 완화)
  static bool get _isTestMode => kDebugMode;

  /// 시뮬레이션 완료 시 호출
  /// 조건을 만족하면 리뷰를 요청합니다.
  static Future<void> requestReviewIfAppropriate() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 리뷰를 거부한 경우 더 이상 요청하지 않음
      final reviewDismissed = prefs.getBool(_keyReviewDismissed) ?? false;
      if (reviewDismissed) {
        return;
      }

      // 시뮬레이션 완료 횟수 증가
      final currentCount = prefs.getInt(_keySimulationCompleteCount) ?? 0;
      await prefs.setInt(_keySimulationCompleteCount, currentCount + 1);

      // 테스트 모드가 아닐 때만 조건 확인
      if (!_isTestMode) {
        // 최소 횟수 미만이면 요청하지 않음
        if (currentCount + 1 < _minSimulationCount) {
          return;
        }

        // 마지막 요청 날짜 확인
        final lastRequestDateStr = prefs.getString(_keyLastReviewRequestDate);
        if (lastRequestDateStr != null) {
          final lastRequestDate = DateTime.parse(lastRequestDateStr);
          final daysSinceLastRequest = DateTime.now()
              .difference(lastRequestDate)
              .inDays;

          // 최소 일수 경과하지 않았으면 요청하지 않음
          if (daysSinceLastRequest < _daysBetweenRequests) {
            return;
          }
        }
      }

      // 리뷰 요청 가능 여부 확인
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        // 리뷰 요청 날짜 저장
        await prefs.setString(
          _keyLastReviewRequestDate,
          DateTime.now().toIso8601String(),
        );

        // 리뷰 요청
        await review.requestReview();
      }
    } catch (e) {
      // 리뷰 요청 실패는 무시 (앱 동작에 영향 없음)
      print('App review request failed: $e');
    }
  }

  /// 리뷰를 거부한 경우 호출 (사용자가 "나중에" 등을 선택한 경우)
  static Future<void> markReviewDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReviewDismissed, true);
  }

  /// 리뷰 거부 상태 초기화 (테스트용)
  static Future<void> resetReviewState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyReviewDismissed);
    await prefs.remove(_keyLastReviewRequestDate);
    await prefs.remove(_keySimulationCompleteCount);
  }

  /// 앱스토어로 직접 이동하여 리뷰 작성
  static Future<void> openStoreListing() async {
    try {
      final review = InAppReview.instance;
      await review.openStoreListing();
    } catch (e) {
      print('Failed to open store listing: $e');
    }
  }

  /// 테스트용: 강제로 리뷰 요청 (조건 무시)
  static Future<void> requestReviewForTesting() async {
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        print('In-app review is not available (시뮬레이터/에뮬레이터에서는 동작하지 않습니다)');
      }
    } catch (e) {
      print('App review request failed: $e');
    }
  }
}
