import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();
  static final AdService shared = AdService._();

  static const String _baseUrl = 'https://investment-long-term-server.vercel.app';
  String get _settingsEndpoint => '$_baseUrl/api/settings';

  String? _adsType;
  String? _interstitialAdId;

  String? get interstitialAdId => _interstitialAdId;

  Future<bool> loadSettings() async {
    try {
      final uri = Uri.parse(_settingsEndpoint);
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return false;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      _adsType = () {
        if (io.Platform.isIOS) {
          return data['ios_ad'] as String?;
        } else if (io.Platform.isAndroid) {
          return data['android_ad'] as String?;
        }
        return null;
      }();

      _interstitialAdId = () {
        if (io.Platform.isIOS) {
          return data['ref']?['ios']?[_adsType] as String?;
        } else if (io.Platform.isAndroid) {
          return data['ref']?['android']?[_adsType] as String?;
        }
        return null;
      }();

      return _interstitialAdId != null && _interstitialAdId!.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> showInterstitialAd({
    required VoidCallback onAdDismissed,
    VoidCallback? onAdFailedToShow,
  }) async {
    if (_interstitialAdId == null || _interstitialAdId!.isEmpty) {
      // If no ad ID, just proceed
      onAdDismissed();
      return;
    }

    await InterstitialAd.load(
      adUnitId: _interstitialAdId!,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              onAdDismissed();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              onAdFailedToShow?.call();
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (error) {
          // If ad fails to load, proceed anyway
          onAdFailedToShow?.call();
        },
      ),
    );
  }
}

