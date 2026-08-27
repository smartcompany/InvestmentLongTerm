import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 기기 고유 ID — Keychain / Keystore에 보관 (앱 삭제 후에도 유지, 공장 초기화 시 리셋).
class DeviceId {
  static const String _keyDeviceId = 'device_id';
  static String? _cachedDeviceId;

  static const FlutterSecureStorage _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
      synchronizable: false,
    ),
  );

  static Future<String> getId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    try {
      final fromSecure = await _secure.read(key: _keyDeviceId);
      if (fromSecure != null && fromSecure.isNotEmpty) {
        _cachedDeviceId = fromSecure;
        debugPrint('📱 [DeviceId] Keychain/Keystore ID: $fromSecure');
        return fromSecure;
      }

      // SharedPreferences → secure 마이그레이션
      final prefs = await SharedPreferences.getInstance();
      final legacy = prefs.getString(_keyDeviceId);
      if (legacy != null && legacy.isNotEmpty) {
        await _secure.write(key: _keyDeviceId, value: legacy);
        await prefs.remove(_keyDeviceId);
        _cachedDeviceId = legacy;
        debugPrint('📱 [DeviceId] migrated prefs → secure: $legacy');
        return legacy;
      }

      final deviceId = _generateUuidV4();
      await _secure.write(key: _keyDeviceId, value: deviceId);
      _cachedDeviceId = deviceId;
      debugPrint('✅ [DeviceId] created: $deviceId');
      return deviceId;
    } catch (e) {
      debugPrint('❌ [DeviceId] failed: $e');
      final fallback = 'fallback_${DateTime.now().millisecondsSinceEpoch}';
      _cachedDeviceId = fallback;
      return fallback;
    }
  }

  static String _generateUuidV4() {
    final r = Random.secure();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    final h = bytes.map(hex).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-'
        '${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  static void clearCache() {
    _cachedDeviceId = null;
  }
}
