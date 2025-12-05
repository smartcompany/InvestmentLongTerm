import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyProvider with ChangeNotifier {
  static const String _currencyKey = 'selected_currency';
  String? _selectedCurrency;

  CurrencyProvider() {
    _loadCurrency();
  }

  String? get selectedCurrency => _selectedCurrency;

  String getCurrencySymbol(String localeCode) {
    if (_selectedCurrency != null) {
      return _selectedCurrency!;
    }
    // 기본값: 언어에 따라 자동 설정
    switch (localeCode) {
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
