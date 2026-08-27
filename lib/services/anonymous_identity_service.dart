import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import '../utils/device_id.dart';

/// deviceId → anonymousId 발급/캐시.
class AnonymousIdentityService {
  AnonymousIdentityService._();
  static final AnonymousIdentityService shared = AnonymousIdentityService._();

  static const _prefsAnonymousIdKey = 'assetfit_anonymous_id_v1';

  String? _cachedAnonymousId;
  String? _cachedDeviceId;

  String? get anonymousId => _cachedAnonymousId;
  String? get deviceId => _cachedDeviceId;

  Future<({String anonymousId, String deviceId})> ensureIdentity() async {
    final deviceId = await DeviceId.getId();
    _cachedDeviceId = deviceId;

    if (_cachedAnonymousId != null && _cachedAnonymousId!.isNotEmpty) {
      return (anonymousId: _cachedAnonymousId!, deviceId: deviceId);
    }

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_prefsAnonymousIdKey);
    if (cached != null && cached.isNotEmpty) {
      _cachedAnonymousId = cached;
      // 서버와 재확인 (deviceId 매핑 보장)
      try {
        final confirmed = await ApiService.getOrCreateAnonymousId(deviceId);
        if (confirmed != cached) {
          await prefs.setString(_prefsAnonymousIdKey, confirmed);
          _cachedAnonymousId = confirmed;
        }
      } catch (e) {
        debugPrint('[AnonymousId] offline, using cache: $e');
      }
      return (anonymousId: _cachedAnonymousId!, deviceId: deviceId);
    }

    final anonymousId = await ApiService.getOrCreateAnonymousId(deviceId);
    await prefs.setString(_prefsAnonymousIdKey, anonymousId);
    _cachedAnonymousId = anonymousId;
    debugPrint('[AnonymousId] issued: $anonymousId');
    return (anonymousId: anonymousId, deviceId: deviceId);
  }
}
