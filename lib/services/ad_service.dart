import 'package:flutter/material.dart';
import 'package:share_lib/share_lib.dart' as share_lib;

/// AdService wrapper for backward compatibility
///
/// 실제 구현은 share_lib의 AdService를 사용합니다.
class AdService {
  AdService._() {
    // baseUrl 초기화
    share_lib.AdService.shared.setBaseUrl(
      'https://investment-long-term-server.vercel.app',
    );
  }
  static final AdService shared = AdService._();

  String? get rewardedAdId => share_lib.AdService.shared.rewardedAdId;
  String? get initialAdId => share_lib.AdService.shared.initialAdId;
  String? get downloadUrl => share_lib.AdService.shared.downloadUrl;

  Future<bool> loadSettings() async {
    // baseUrl이 설정되지 않았으면 설정
    share_lib.AdService.shared.setBaseUrl(
      'https://investment-long-term-server.vercel.app',
    );
    return await share_lib.AdService.shared.loadSettings();
  }

  Future<void> showInterstitialAd({
    required VoidCallback onAdDismissed,
    VoidCallback? onAdFailedToShow,
  }) async {
    return await share_lib.AdService.shared.showInterstitialAd(
      onAdDismissed: onAdDismissed,
      onAdFailedToShow: onAdFailedToShow,
    );
  }
}
