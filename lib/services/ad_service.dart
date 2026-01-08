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

  bool _settingsLoaded = false;
  bool _isLoadingSettings = false;

  String? get rewardedAdId => share_lib.AdService.shared.rewardedAdId;
  String? get initialAdId => share_lib.AdService.shared.initialAdId;
  String? get downloadUrl => share_lib.AdService.shared.downloadUrl;

  Future<bool> loadSettings() async {
    // 이미 로드했거나 로딩 중이면 재호출하지 않음
    if (_settingsLoaded || _isLoadingSettings) {
      return _settingsLoaded;
    }

    _isLoadingSettings = true;
    try {
    // baseUrl이 설정되지 않았으면 설정
    share_lib.AdService.shared.setBaseUrl(
      'https://investment-long-term-server.vercel.app',
    );
      final result = await share_lib.AdService.shared.loadSettings();
      _settingsLoaded = result;
      return result;
    } finally {
      _isLoadingSettings = false;
    }
  }

  Future<void> showFullScreenAd({
    required VoidCallback onAdDismissed,
    VoidCallback? onAdFailedToShow,
  }) async {
    return await share_lib.AdService.shared.showAd(
      onAdDismissed: onAdDismissed,
      onAdFailedToShow: onAdFailedToShow,
    );
  }
}
