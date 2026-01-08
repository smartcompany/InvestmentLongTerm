import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class DeviceId {
  static const String _keyDeviceId = 'device_id';
  static String? _cachedDeviceId;

  // iOS: iCloud Key-Value Storage 사용
  // Android: SharedPreferences 사용 (Auto Backup 활성화됨)

  /// 기기 고유 ID를 가져옵니다.
  /// iOS: iCloud Key-Value Storage에 저장
  /// Android: SharedPreferences에 저장 (Auto Backup으로 자동 백업)
  static Future<String> getId() async {
    if (_cachedDeviceId != null) {
      return _cachedDeviceId!;
    }

    try {
      String? savedDeviceId;

      // iOS와 Android 모두 SharedPreferences 사용
      // iOS: UserDefaults (iCloud 백업 포함 가능)
      // Android: SharedPreferences (Auto Backup으로 자동 백업됨)
      final prefs = await SharedPreferences.getInstance();
      savedDeviceId = prefs.getString(_keyDeviceId);
      if (savedDeviceId != null && savedDeviceId.isNotEmpty) {
        _cachedDeviceId = savedDeviceId;
        debugPrint('📱 [DeviceId] 저장된 기기 ID 사용: $savedDeviceId');
        return savedDeviceId;
      }

      // 새로운 기기 ID 생성
      final deviceInfo = DeviceInfoPlugin();
      String deviceId;

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        // Android ID 사용 (앱 삭제 후에도 동일, 공장 초기화 시에만 변경)
        deviceId = androidInfo.id;
        debugPrint('📱 [DeviceId] Android ID 사용: $deviceId');
        debugPrint('   - 앱 삭제 후에도 동일한 ID 유지됨 ✅');
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        // identifierForVendor 사용
        deviceId =
            iosInfo.identifierForVendor ??
            'ios_${DateTime.now().millisecondsSinceEpoch}';
        debugPrint('📱 [DeviceId] iOS identifierForVendor 생성: $deviceId');
      } else {
        // 기타 플랫폼
        deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
        debugPrint('📱 [DeviceId] 임시 기기 ID 생성: $deviceId');
      }

      // iOS와 Android 모두 SharedPreferences에 저장
      // iOS: UserDefaults (iCloud 백업 포함 가능)
      // Android: SharedPreferences (Auto Backup으로 자동 백업됨)
      await prefs.setString(_keyDeviceId, deviceId);
      debugPrint('✅ [DeviceId] 기기 ID 저장 완료: $deviceId');

      _cachedDeviceId = deviceId;
      return deviceId;
    } catch (e) {
      debugPrint('❌ [DeviceId] 기기 ID 가져오기 실패: $e');
      // 실패 시 임시 ID 생성
      final fallbackId = 'fallback_${DateTime.now().millisecondsSinceEpoch}';
      _cachedDeviceId = fallbackId;
      return fallbackId;
    }
  }

  /// 기기 ID 캐시 초기화 (테스트용)
  static void clearCache() {
    _cachedDeviceId = null;
  }
}
