import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

/// 환율 변환 유틸리티 (서버 API 사용)
class CurrencyConverter {
  // 싱글톤 인스턴스
  static final CurrencyConverter shared = CurrencyConverter._();

  CurrencyConverter._();

  static const String _cacheKey = 'exchange_rates';
  static const String _cacheDateKey = 'exchange_rates_date';

  Map<String, double>? _ratesCache;
  DateTime? _cacheDate;
  bool _isInitializing = false;
  bool _isInitialized = false;

  /// 날짜만 비교 (시간 무시)
  bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// 환율 가져오기 (캐시 확인 후 서버 API 호출)
  /// 동일 날짜면 저장된 환율을 재사용합니다.
  Future<Map<String, double>> _getExchangeRates() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 메모리 캐시 확인 (같은 날이면 사용)
    if (_ratesCache != null && _cacheDate != null) {
      final cachedDate = DateTime(
        _cacheDate!.year,
        _cacheDate!.month,
        _cacheDate!.day,
      );
      if (_isSameDate(cachedDate, today)) {
        return _ratesCache!;
      }
    }

    try {
      // SharedPreferences에서 캐시 확인
      final prefs = await SharedPreferences.getInstance();
      final cachedRatesJson = prefs.getString(_cacheKey);
      final cachedDateStr = prefs.getString(_cacheDateKey);

      if (cachedRatesJson != null && cachedDateStr != null) {
        final cachedDate = DateTime.parse(cachedDateStr);
        final cachedDateOnly = DateTime(
          cachedDate.year,
          cachedDate.month,
          cachedDate.day,
        );

        // 같은 날이면 캐시된 환율 사용
        if (_isSameDate(cachedDateOnly, today)) {
          _ratesCache = Map<String, double>.from(
            jsonDecode(cachedRatesJson) as Map<String, dynamic>,
          );
          _cacheDate = cachedDate;
          return _ratesCache!;
        }
      }

      // 서버 API 호출 (오늘 날짜 환율이 없을 때만)
      _ratesCache = await ApiService.fetchExchangeRates();
      _cacheDate = DateTime.now();

      // 디버깅: 서버에서 받은 환율 로그
      debugPrint(
        '[CurrencyConverter] 서버에서 환율 가져옴: KRW=${_ratesCache!['KRW']}, JPY=${_ratesCache!['JPY']}, CNY=${_ratesCache!['CNY']}',
      );

      // 캐시에 저장
      await prefs.setString(_cacheKey, jsonEncode(_ratesCache));
      await prefs.setString(_cacheDateKey, _cacheDate!.toIso8601String());

      return _ratesCache!;
    } catch (e) {
      debugPrint('Failed to fetch exchange rates: $e');
      rethrow; // 에러를 다시 던짐
    }
  }

  /// 환율 초기화 (앱 시작 시 호출 권장, 또는 첫 사용 시 자동 호출)
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (_isInitializing) {
      // 이미 초기화 중이면 완료될 때까지 대기
      while (_isInitializing) {
        await Future.delayed(Duration(milliseconds: 100));
      }
      return;
    }

    _isInitializing = true;
    try {
      await _getExchangeRates();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize currency converter: $e');
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// 초기화 확인 및 필요시 초기화
  Future<void> _ensureInitialized() async {
    if (!_isInitialized && !_isInitializing) {
      await initialize();
    } else if (_isInitializing) {
      // 초기화 중이면 완료될 때까지 대기
      while (_isInitializing) {
        await Future.delayed(Duration(milliseconds: 100));
      }
    }
  }

  /// 환율 변환 (from에서 to로)
  Future<double> convert(
    double amount,
    String fromCurrency,
    String toCurrency,
  ) async {
    await _ensureInitialized();
    if (fromCurrency == toCurrency) return amount;

    final rates = await _getExchangeRates();

    // USD로 먼저 변환
    double usdAmount = _toUsd(amount, fromCurrency, rates);

    // USD에서 목표 통화로 변환
    return _fromUsd(usdAmount, toCurrency, rates);
  }

  /// USD로 변환
  double _toUsd(double amount, String currency, Map<String, double> rates) {
    switch (currency) {
      case '\$':
      case 'USD':
        return amount;
      case '₩':
      case 'KRW':
        return amount / rates['KRW']!;
      case '¥':
      case 'JPY':
        return amount / rates['JPY']!;
      case 'CN¥':
      case 'CNY':
        return amount / rates['CNY']!;
      default:
        return amount;
    }
  }

  /// USD에서 변환
  double _fromUsd(
    double usdAmount,
    String currency,
    Map<String, double> rates,
  ) {
    switch (currency) {
      case '\$':
      case 'USD':
        return usdAmount;
      case '₩':
      case 'KRW':
        return usdAmount * rates['KRW']!;
      case '¥':
      case 'JPY':
        return usdAmount * rates['JPY']!;
      case 'CN¥':
      case 'CNY':
        return usdAmount * rates['CNY']!;
      default:
        return usdAmount;
    }
  }
}
