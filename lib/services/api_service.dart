import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/investment_config.dart';
import '../models/calculation_result.dart';
import '../models/asset_option.dart';
import '../models/investment_insight.dart';
import '../models/market_briefing.dart';
import 'package:fl_chart/fl_chart.dart';

class ApiService {
  static const String baseUrl =
      'https://investment-long-term-server.vercel.app';

  static Future<List<AssetOption>> fetchAssets() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/assets'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data
            .map((item) => AssetOption.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load assets: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load assets: $e');
    }
  }

  static Future<CalculationResult> calculate(InvestmentConfig config) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/calculate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'asset': config.asset,
          'yearsAgo': config.yearsAgo,
          'amount': config.amount,
          'type': config.type == InvestmentType.single ? 'single' : 'recurring',
          'frequency': config.frequency == Frequency.monthly
              ? 'monthly'
              : 'weekly',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CalculationResult(
          totalInvested: (data['totalInvested'] as num).toDouble(),
          finalValue: (data['finalValue'] as num).toDouble(),
          cagr: (data['cagr'] as num).toDouble(),
          yieldRate: (data['yieldRate'] as num).toDouble(),
          investedSpots: (data['investedSpots'] as List)
              .map(
                (spot) => FlSpot(
                  (spot['x'] as num).toDouble(),
                  (spot['y'] as num).toDouble(),
                ),
              )
              .toList(),
          valueSpots: (data['valueSpots'] as List)
              .map(
                (spot) => FlSpot(
                  (spot['x'] as num).toDouble(),
                  (spot['y'] as num).toDouble(),
                ),
              )
              .toList(),
        );
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to calculate: $e');
    }
  }

  /// Yahoo Finance 기반 종목 검색 (카탈로그 밖 종목)
  static Future<List<Map<String, dynamic>>> searchAssets(
    String query, {
    String? type,
    String? lang,
  }) async {
    try {
      final params = <String, String>{'q': query};
      if (type != null && type.isNotEmpty) params['type'] = type;
      if (lang != null && lang.isNotEmpty) params['lang'] = lang;

      final uri = Uri.parse(
        '$baseUrl/api/assets/search',
      ).replace(queryParameters: params);

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to search assets: $e');
    }
  }

  // 일봉 가격 데이터 가져오기
  static Future<List<Map<String, dynamic>>> fetchDailyPrices(
    String assetId,
    int days, {
    String? symbol,
    String? type,
  }) async {
    try {
      final body = <String, dynamic>{
        'assetId': assetId,
        'days': days,
      };
      if (symbol != null && symbol.isNotEmpty) {
        body['symbol'] = symbol;
      }
      if (type != null && type.isNotEmpty) {
        body['type'] = type;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/prices'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch daily prices: $e');
    }
  }

  /// 최근 1일 조회는 Yahoo에서 빈 응답이 나는 경우가 있어,
  /// 기간 데이터(기본 1년)의 마지막 종가를 현재가로 사용합니다.
  static Future<double?> fetchLatestPrice(
    String assetId, {
    int days = 365,
    String? symbol,
    String? type,
  }) async {
    final safeDays = days < 5 ? 365 : days;
    final priceData = await fetchDailyPrices(
      assetId,
      safeDays,
      symbol: symbol,
      type: type,
    );
    if (priceData.isEmpty) return null;
    final latest = (priceData.last['price'] as num?)?.toDouble();
    if (latest == null || !latest.isFinite || latest <= 0) return null;
    return latest;
  }

  static Future<InvestmentInsight> fetchInvestmentInsight({
    required String locale,
    required String displayCurrency,
    required List<Map<String, dynamic>> assets,
    double? totalPurchaseAmount,
    double? totalCurrentValue,
    double? totalReturnRatePct,
    String? userRequest,
  }) async {
    final uri = Uri.parse('$baseUrl/api/insights');
    final body = <String, dynamic>{
      'locale': locale,
      'displayCurrency': displayCurrency,
      'assets': assets,
    };
    if (totalPurchaseAmount != null) {
      body['totalPurchaseAmount'] = totalPurchaseAmount;
    }
    if (totalCurrentValue != null) {
      body['totalCurrentValue'] = totalCurrentValue;
    }
    if (totalReturnRatePct != null) {
      body['totalReturnRatePct'] = totalReturnRatePct;
    }
    final trimmedRequest = userRequest?.trim();
    if (trimmedRequest != null && trimmedRequest.isNotEmpty) {
      body['userRequest'] = trimmedRequest;
    }

    debugPrint('[ApiService] POST $uri');
    debugPrint('[ApiService] insight body: ${jsonEncode(body)}');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      debugPrint(
        '[ApiService] insight status=${response.statusCode} '
        'bodyLen=${response.body.length}',
      );
      debugPrint(
        '[ApiService] insight response: ${response.body.length > 1200 ? '${response.body.substring(0, 1200)}…' : response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return InvestmentInsight.fromJson(data);
      }

      String message = 'Server error: ${response.statusCode}';
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        final errorText = err['error'] as String?;
        if (errorText != null && errorText.isNotEmpty) {
          message = errorText;
        }
      } catch (_) {
        if (response.statusCode == 404) {
          message =
              'Insights API not found (404). Deploy /api/insights to the server.';
        }
      }
      throw Exception(message);
    } catch (e) {
      debugPrint('[ApiService] insight exception: $e');
      throw Exception('Failed to fetch investment insight: $e');
    }
  }

  static Future<MarketBriefing> fetchMarketBriefing({
    required String locale,
    required String displayCurrency,
    required List<Map<String, dynamic>> assets,
    String? asOfDate,
    String? userRequest,
  }) async {
    final uri = Uri.parse('$baseUrl/api/market-briefing');
    final body = <String, dynamic>{
      'locale': locale,
      'displayCurrency': displayCurrency,
      'assets': assets,
    };
    if (asOfDate != null && asOfDate.isNotEmpty) {
      body['asOfDate'] = asOfDate;
    }
    final trimmedRequest = userRequest?.trim();
    if (trimmedRequest != null && trimmedRequest.isNotEmpty) {
      body['userRequest'] = trimmedRequest;
    }

    debugPrint('[ApiService] POST $uri');
    debugPrint('[ApiService] market-briefing body: ${jsonEncode(body)}');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      debugPrint(
        '[ApiService] market-briefing status=${response.statusCode} '
        'bodyLen=${response.body.length}',
      );
      debugPrint(
        '[ApiService] market-briefing response: ${response.body.length > 1200 ? '${response.body.substring(0, 1200)}…' : response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return MarketBriefing.fromJson(data);
      }

      String message = 'Server error: ${response.statusCode}';
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        final errorText = err['error'] as String?;
        if (errorText != null && errorText.isNotEmpty) {
          message = errorText;
        }
      } catch (_) {
        if (response.statusCode == 404) {
          message =
              'Market briefing API not found (404). Deploy /api/market-briefing.';
        }
      }
      throw Exception(message);
    } catch (e) {
      debugPrint('[ApiService] market-briefing exception: $e');
      throw Exception('Failed to fetch market briefing: $e');
    }
  }

  static Future<Map<String, double>> fetchExchangeRates() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/exchange-rates'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>;
        return {
          'KRW': (rates['KRW'] as num).toDouble(),
          'JPY': (rates['JPY'] as num).toDouble(),
          'CNY': (rates['CNY'] as num).toDouble(),
        };
      } else {
        throw Exception(
          'Failed to load exchange rates: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to load exchange rates: $e');
    }
  }

  // 익명 ID 생성/조회
  static Future<String> getOrCreateAnonymousId(String deviceId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/anonymous-id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'deviceId': deviceId}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['anonymousId'] as String;
      } else {
        throw Exception('Failed to get anonymous ID: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get anonymous ID: $e');
    }
  }

  /// 서버 holdings 스냅샷 동기화 (전체 교체)
  static Future<void> syncMyAssets({
    required String anonymousId,
    required String deviceId,
    required List<Map<String, dynamic>> assets,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/my-assets'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'anonymousId': anonymousId,
        'deviceId': deviceId,
        'assets': assets,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to sync assets: ${response.statusCode}');
    }
  }

  /// 서버에서 holdings 복구
  static Future<List<Map<String, dynamic>>> getMyAssets({
    required String anonymousId,
    required String deviceId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/my-assets').replace(
      queryParameters: {
        'anonymousId': anonymousId,
        'deviceId': deviceId,
      },
    );
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((item) => item as Map<String, dynamic>).toList();
    }
    throw Exception('Failed to load assets: ${response.statusCode}');
  }

  static Future<void> registerPushToken({
    required String anonymousId,
    required String deviceId,
    String? token,
    String? platform,
    String? locale,
    bool pushEnabled = true,
    bool? pushPortfolioChange,
    bool? pushAiTrend,
    bool? pushAiPortfolio,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/push-token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'anonymousId': anonymousId,
        'deviceId': deviceId,
        if (token != null) 'token': token,
        if (platform != null) 'platform': platform,
        if (locale != null) 'locale': locale,
        'pushEnabled': pushEnabled,
        if (pushPortfolioChange != null)
          'pushPortfolioChange': pushPortfolioChange,
        if (pushAiTrend != null) 'pushAiTrend': pushAiTrend,
        if (pushAiPortfolio != null) 'pushAiPortfolio': pushAiPortfolio,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to register push token: ${response.statusCode}');
    }
  }
}
