import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class ICloudService {
  static const MethodChannel _channel = MethodChannel(
    'com.smartcompany.longterminvestment/icloud',
  );

  /// iCloud가 활성화되어 있는지 확인 (iOS만)
  static Future<bool> isICloudEnabled() async {
    if (!Platform.isIOS) {
      // Android는 항상 true (Auto Backup 사용)
      return true;
    }

    try {
      final bool result = await _channel.invokeMethod('isICloudEnabled');
      return result;
    } on PlatformException catch (e) {
      debugPrint('iCloud 상태 확인 실패: ${e.message}');
      return false;
    }
  }

  /// iCloud Key-Value Storage에 값 저장 (자동 동기화, 사용자 권한 불필요)
  static Future<bool> setValue(String key, String value) async {
    if (!Platform.isIOS) {
      // Android는 SharedPreferences 사용
      return false;
    }

    try {
      final result =
          await _channel.invokeMethod('setICloudValue', {
                'key': key,
                'value': value,
              })
              as bool?;
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('iCloud 저장 실패: ${e.message}');
      return false;
    }
  }

  /// iCloud Key-Value Storage에서 값 읽기
  static Future<String?> getValue(String key) async {
    if (!Platform.isIOS) {
      // Android는 SharedPreferences 사용
      return null;
    }

    try {
      final String? result = await _channel.invokeMethod('getICloudValue', {
        'key': key,
      });
      return result;
    } on PlatformException catch (e) {
      debugPrint('iCloud 읽기 실패: ${e.message}');
      return null;
    }
  }
}
