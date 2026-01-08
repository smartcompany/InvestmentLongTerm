import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyProvider with ChangeNotifier {
  static final CurrencyProvider shared = CurrencyProvider._();

  CurrencyProvider._() {
    _loadCurrency();
  }

  static const String _currencyKey = 'selected_currency';
  String? _selectedCurrency;

  String? get selectedCurrency => _selectedCurrency;

  /// 선택된 통화 심볼을 반환합니다. 선택된 통화가 없으면 시스템 로케일 또는 제공된 localeCode를 기반으로 기본값을 반환합니다.
  String getCurrencySymbol() {
    if (_selectedCurrency != null) {
      return _selectedCurrency!;
    }

    // localeCode가 제공되지 않으면 시스템 로케일 사용 (context 없이)
    final systemLocaleCode = ui.PlatformDispatcher.instance.locale.languageCode;

    // 기본값: 언어에 따라 자동 설정
    switch (systemLocaleCode) {
      case 'ko':
        return '₩';
      case 'ja':
        return '¥';
      case 'zh':
        return 'CN¥';
      case 'en':
      default:
        return '\$';
    }
  }

  Future<void> setCurrency(String currencySymbol) async {
    _selectedCurrency = currencySymbol;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, currencySymbol);
  }

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedCurrency = prefs.getString(_currencyKey);
    notifyListeners();
  }

  Future<void> resetToDefault(String localeCode) async {
    _selectedCurrency = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currencyKey);
  }
}
