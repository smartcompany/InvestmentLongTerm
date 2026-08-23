import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// 로컬 알림: 하루 1회 리마인더 + 자산 가치 변동 알림.
/// 탭 시 payload `my_assets`로 내 자산 탭 진입.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService shared = PushNotificationService._();

  static const _prefsEnabledKey = 'push_notifications_enabled_v1';
  static const _prefsLastTotalKey = 'push_last_portfolio_total_v1';
  static const _prefsLastChangeNotifyDayKey = 'push_last_change_notify_day_v1';
  static const _dailyNotificationId = 1001;
  static const _changeNotificationId = 1002;
  static const payloadMyAssets = 'my_assets';

  /// 일일 리마인더 시각 (로컬)
  static const dailyHour = 9;
  static const dailyMinute = 0;

  /// 이 비율 이상 변하면 변동 알림 (예: 0.01 = 1%)
  static const changeThresholdPct = 0.01;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  void Function(String payload)? onNotificationTap;

  /// 앱 시작 시 cold-start 탭 payload
  String? launchPayload;

  Future<void> initialize({
    void Function(String payload)? onTap,
  }) async {
    if (_initialized) return;
    onNotificationTap = onTap;

    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.local);
    } catch (_) {
      // fallback: leave default
    }

    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          onNotificationTap?.call(payload);
        }
      },
    );

    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      launchPayload = launch?.notificationResponse?.payload;
    }

    _initialized = true;
    debugPrint('[Push] initialized launchPayload=$launchPayload');

    final enabled = await isEnabled();
    if (enabled) {
      await scheduleDailyReminder();
    }
  }

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsEnabledKey) ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsEnabledKey, enabled);
    if (enabled) {
      final granted = await requestPermission();
      if (granted) {
        await scheduleDailyReminder();
      }
    } else {
      await _plugin.cancel(id: _dailyNotificationId);
      await _plugin.cancel(id: _changeNotificationId);
    }
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? true;
    }

    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  Future<void> scheduleDailyReminder({
    String title = '내 자산 트렌드',
    String body = '오늘 내 보유 자산 흐름을 확인해 보세요',
  }) async {
    if (!await isEnabled()) return;

    final granted = await requestPermission();
    if (!granted) {
      debugPrint('[Push] permission denied — skip daily schedule');
      return;
    }

    final when = _nextInstanceOfTime(dailyHour, dailyMinute);
    debugPrint('[Push] schedule daily at $when');

    await _plugin.zonedSchedule(
      id: _dailyNotificationId,
      title: title,
      body: body,
      scheduledDate: when,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_holdings',
          'Daily holdings',
          channelDescription: 'Once-a-day reminder to check your holdings',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payloadMyAssets,
    );
  }

  /// 포트폴리오 총 가치가 의미 있게 변했고, 오늘 아직 변동 알림을 안 보냈으면 알림.
  Future<void> maybeNotifyPortfolioChange({
    required double? currentTotal,
    String Function(double changePct)? titleBuilder,
    String Function(double changePct)? bodyBuilder,
  }) async {
    if (currentTotal == null || !currentTotal.isFinite) return;
    if (!await isEnabled()) return;

    final prefs = await SharedPreferences.getInstance();
    final today = _dayKey(DateTime.now());
    final lastDay = prefs.getString(_prefsLastChangeNotifyDayKey);
    final lastTotal = prefs.getDouble(_prefsLastTotalKey);

    // 첫 스냅샷은 저장만
    if (lastTotal == null || lastTotal <= 0) {
      await prefs.setDouble(_prefsLastTotalKey, currentTotal);
      debugPrint('[Push] stored initial portfolio total=$currentTotal');
      return;
    }

    final changePct = (currentTotal - lastTotal) / lastTotal;
    await prefs.setDouble(_prefsLastTotalKey, currentTotal);

    if (changePct.abs() < changeThresholdPct) {
      debugPrint(
        '[Push] change ${(changePct * 100).toStringAsFixed(2)}% < threshold — skip',
      );
      return;
    }

    if (lastDay == today) {
      debugPrint('[Push] already notified change today — skip');
      return;
    }

    final granted = await requestPermission();
    if (!granted) return;

    final pctText = (changePct * 100).toStringAsFixed(1);
    final sign = changePct >= 0 ? '+' : '';
    final title = titleBuilder?.call(changePct) ?? '보유 자산 가치 변동';
    final body = bodyBuilder?.call(changePct) ??
        '총 평가액이 $sign$pctText% 변했어요. 내 자산에서 확인해 보세요.';

    await _plugin.show(
      id: _changeNotificationId,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'portfolio_changes',
          'Portfolio changes',
          channelDescription: 'Alerts when your holdings value moves',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payloadMyAssets,
    );

    await prefs.setString(_prefsLastChangeNotifyDayKey, today);
    debugPrint('[Push] sent change notification $sign$pctText%');
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
