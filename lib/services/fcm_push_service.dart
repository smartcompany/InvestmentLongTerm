import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'anonymous_identity_service.dart';
import 'api_service.dart';
import 'notification_navigation.dart';
import 'push_preferences.dart';

/// FCM 원격 푸시 등록·탭 처리 (LetsMeet PushService와 동일하게 FCM 토큰만 사용).
class FcmPushService {
  FcmPushService._();
  static final FcmPushService shared = FcmPushService._();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    _initialized = true;

    final messaging = FirebaseMessaging.instance;

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[FCM] foreground: ${message.notification?.title}');
    });

    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      _handleMessage(initial);
    }

    messaging.onTokenRefresh.listen((token) async {
      debugPrint('[FCM] token refresh');
      if (await PushPreferences.shared.needsRemotePush()) {
        await _registerToken(token);
      }
    });

    if (await PushPreferences.shared.needsRemotePush()) {
      await registerIfEnabled();
    }
  }

  Future<void> registerIfEnabled() async {
    if (kIsWeb) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[FCM] permission denied');
        return;
      }

      if (Platform.isIOS) {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      final token = await messaging.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('[FCM] no token');
        return;
      }
      await _registerToken(token);
    } catch (e) {
      debugPrint('[FCM] register failed: $e');
    }
  }

  Future<void> syncPreferences({String? locale}) async {
    try {
      final prefs = PushPreferences.shared;
      final master = await prefs.isMasterEnabled();
      final needsRemote = await prefs.needsRemotePush();
      final identity = await AnonymousIdentityService.shared.ensureIdentity();

      String? token;
      if (needsRemote) {
        await registerIfEnabled();
        token = await FirebaseMessaging.instance.getToken();
      }

      await ApiService.registerPushToken(
        anonymousId: identity.anonymousId,
        deviceId: identity.deviceId,
        token: token,
        platform: Platform.isIOS ? 'ios' : 'android',
        locale: locale,
        pushEnabled: master && needsRemote,
        pushPortfolioChange: await prefs.isPortfolioChangeEnabled(),
        pushAiTrend: await prefs.isAiInsightsEnabled(),
        pushAiPortfolio: await prefs.isAiInsightsEnabled(),
      );
    } catch (e) {
      debugPrint('[FCM] syncPreferences failed: $e');
    }
  }

  @Deprecated('Use syncPreferences')
  Future<void> setPushEnabled(bool enabled, {String? locale}) async {
    await PushPreferences.shared.setMasterEnabled(enabled);
    await syncPreferences(locale: locale);
  }

  Future<void> _registerToken(String token) async {
    final prefs = PushPreferences.shared;
    final identity = await AnonymousIdentityService.shared.ensureIdentity();
    await ApiService.registerPushToken(
      anonymousId: identity.anonymousId,
      deviceId: identity.deviceId,
      token: token,
      platform: Platform.isIOS ? 'ios' : 'android',
      pushEnabled: await prefs.needsRemotePush(),
      pushPortfolioChange: await prefs.isPortfolioChangeEnabled(),
      pushAiTrend: await prefs.isAiInsightsEnabled(),
      pushAiPortfolio: await prefs.isAiInsightsEnabled(),
    );
    debugPrint('[FCM] token registered');
  }

  void _handleMessage(RemoteMessage message) {
    final payload = message.data['payload'];
    if (payload is String) {
      NotificationNavigation.handlePayload(payload);
    }
  }
}
