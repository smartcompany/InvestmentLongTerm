import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../utils/colors.dart';
import 'ad_service.dart';
import 'api_service.dart';

/// Gates growth-race "compare assets" with an ad confirm every N starts.
///
/// Interval `growth_race_ad_every` comes from `GET /api/settings`.
abstract final class GrowthRaceAdGate {
  static const _countKey = 'growth_race_compare_count';
  static const _settingsFallbackEvery = 5;

  static int? _every;
  static var _settingsLoaded = false;

  static int get every {
    final value = _every;
    if (value == null || value < 1) return _settingsFallbackEvery;
    return value;
  }

  static Future<void> ensureSettingsLoaded() async {
    if (_settingsLoaded) return;

    try {
      await AdService.shared.loadSettings();
      final uri = Uri.parse('${ApiService.baseUrl}/api/settings');
      final response =
          await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          final raw = data['growth_race_ad_every'];
          if (raw is int && raw > 0) {
            _every = raw;
          } else if (raw is num && raw.toInt() > 0) {
            _every = raw.toInt();
          }
        }
      }
      debugPrint('[GrowthRaceAdGate] growth_race_ad_every=$every');
    } catch (error, stackTrace) {
      debugPrint('[GrowthRaceAdGate] settings load error: $error');
      debugPrint('$stackTrace');
      _every = _settingsFallbackEvery;
    } finally {
      _settingsLoaded = true;
    }
  }

  /// Returns true if the user may start the race.
  ///
  /// Free for attempts that are not multiples of [every]. On every Nth
  /// compare, shows the watch-ad confirm dialog then an interstitial.
  static Future<bool> confirmBeforeCompare(BuildContext context) async {
    await ensureSettingsLoaded();
    if (!context.mounted) return false;

    final prefs = await SharedPreferences.getInstance();
    final previous = prefs.getInt(_countKey) ?? 0;
    final next = previous + 1;
    final threshold = every;
    final needsAd = next % threshold == 0;

    if (!needsAd) {
      await prefs.setInt(_countKey, next);
      debugPrint(
        '[GrowthRaceAdGate] free compare $next/$threshold',
      );
      return true;
    }

    if (!context.mounted) return false;
    final l10n = AppLocalizations.of(context)!;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          title: Text(
            l10n.watchAdChoiceTitle,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Text(
            l10n.watchAdChoiceMessage,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                l10n.cancel,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                l10n.watchAdChoiceWatch,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (proceed != true) {
      debugPrint('[GrowthRaceAdGate] user cancelled ad gate');
      return false;
    }
    if (!context.mounted) return false;

    final adShown = Completer<void>();
    var finished = false;
    void finish() {
      if (finished) return;
      finished = true;
      if (!adShown.isCompleted) adShown.complete();
    }

    try {
      await AdService.shared.showFullScreenAd(
        onAdDismissed: finish,
        onAdFailedToShow: finish,
      );
      await adShown.future.timeout(const Duration(seconds: 90));
    } catch (error) {
      debugPrint('[GrowthRaceAdGate] showAd error/timeout: $error');
      finish();
    }

    await prefs.setInt(_countKey, next);
    debugPrint(
      '[GrowthRaceAdGate] ad gate passed; count=$next/$threshold',
    );
    return true;
  }
}
