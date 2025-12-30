import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import '../models/my_asset.dart';
import '../services/api_service.dart';
import '../utils/currency_converter.dart';

class MyAssetsProvider with ChangeNotifier {
  final List<MyAsset> _assets = [];
  bool _isLoading = false;
  List<FlSpot>? _portfolioSpots; // 전체 포트폴리오 그래프 데이터
  bool _isLoadingPortfolio = false;
  DateTime? _portfolioStartDate; // 포트폴리오 시작일
  DateTime? _portfolioEndDate; // 포트폴리오 종료일

  List<MyAsset> get assets => List.unmodifiable(_assets);
  bool get isLoading => _isLoading;
  List<FlSpot>? get portfolioSpots => _portfolioSpots;
  bool get isLoadingPortfolio => _isLoadingPortfolio;
  DateTime? get portfolioStartDate => _portfolioStartDate;
  DateTime? get portfolioEndDate => _portfolioEndDate;

  // 총 매수 금액
  double get totalPurchaseAmount {
    return _assets.fold<double>(0, (sum, asset) => sum + asset.initialAmount);
  }

  // 총 현재 가치
  double? get totalCurrentValue {
    final values = _assets
        .where((asset) => asset.currentValue != null)
        .map((asset) => asset.currentValue!)
        .toList();
    if (values.isEmpty) return null;
    return values.fold<double>(0, (sum, value) => sum + value);
  }

  // 총 수익률
  double? get totalReturnRate {
    if (totalPurchaseAmount == 0) return null;
    final currentValue = totalCurrentValue;
    if (currentValue == null) return null;
    // 실제 값으로 계산 (소수점 포함)
    return ((currentValue / totalPurchaseAmount) - 1) * 100;
  }

  static const String _keyAssets = 'my_assets_list';

  Future<void> loadAssets() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final assetsJson = prefs.getString(_keyAssets);

      if (assetsJson != null) {
        final List<dynamic> decoded = jsonDecode(assetsJson);
        _assets.clear();
        _assets.addAll(
          decoded.map((json) => MyAsset.fromJson(json as Map<String, dynamic>)),
        );

        // 각 자산의 현재 가치 업데이트
        for (final asset in _assets) {
          await _updateCurrentValue(asset);
        }
      }

      // 포트폴리오 그래프 데이터 로드
      await _loadPortfolioChart();
    } catch (e) {
      debugPrint('Failed to load assets: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 현재 가격 가져오기
  Future<double?> _getCurrentPrice(String assetId) async {
    try {
      // 최근 1일 데이터를 가져와서 최신 가격 추출
      final priceData = await ApiService.fetchDailyPrices(assetId, 1);
      if (priceData.isNotEmpty) {
        final latestPrice = (priceData.last['price'] as num?)?.toDouble();
        if (latestPrice != null && latestPrice.isFinite) {
          return latestPrice;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Failed to get current price for $assetId: $e');
      return null;
    }
  }

  Future<void> _updateCurrentValue(MyAsset asset) async {
    try {
      // 현재 가격 가져오기
      final currentPrice = await _getCurrentPrice(asset.assetId);
      if (currentPrice == null || currentPrice <= 0) {
        debugPrint('Failed to get current price for ${asset.id}');
        return;
      }

      // quantity * 현재 가격으로 현재 가치 계산
      final calculatedValue = asset.quantity * currentPrice;

      final index = _assets.indexWhere((a) => a.id == asset.id);
      if (index >= 0) {
        _assets[index] = asset.copyWith(currentValue: calculatedValue);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to update current value for ${asset.id}: $e');
    }
  }

  // 전체 포트폴리오 그래프 데이터 로드
  Future<void> _loadPortfolioChart() async {
    if (_assets.isEmpty) {
      _portfolioSpots = null;
      notifyListeners();
      return;
    }

    _isLoadingPortfolio = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      // 차트 시작일을 1년 전으로 설정
      final earliestDate = now.subtract(const Duration(days: 365));
      final totalDays = 365; // 1년

      // 각 자산별로 일봉 데이터 가져오기 (1년치)

      // 각 자산별로 일봉 데이터 가져오기 (1년치)
      final Map<String, Map<DateTime, double>> assetPricesByDate = {};

      for (final asset in _assets) {
        try {
          // 1년 전부터 현재까지의 가격 데이터 가져오기
          final priceData = await ApiService.fetchDailyPrices(
            asset.assetId,
            365, // 1년치 데이터
          );

          final assetPrices = <DateTime, double>{};

          // 1년 전부터 현재까지의 가격 데이터 사용
          for (final pricePoint in priceData) {
            final dateStr = pricePoint['date'] as String?;
            final price = (pricePoint['price'] as num).toDouble();

            if (dateStr == null || price.isNaN || !price.isFinite) continue;

            final date = DateTime.parse(dateStr).toLocal();

            // 차트 시작일(1년 전) 이전 데이터는 스킵
            if (date.isBefore(earliestDate)) continue;

            // 차트 범위 내의 데이터만 저장
            if (date.isBefore(now) || date.isAtSameMomentAs(now)) {
              assetPrices[date] = price;
            }
          }

          // quantity가 있으면 가격 데이터를 그대로 사용 (quantity * price로 계산)
          // 가격 데이터가 없으면 현재 가치를 사용
          if (assetPrices.isEmpty) {
            // 가격 데이터가 없으면 현재 가격을 가져와서 사용
            final currentPrice = await _getCurrentPrice(asset.assetId);
            if (currentPrice != null && currentPrice > 0) {
              assetPrices[now] = currentPrice;
              assetPrices[earliestDate] = currentPrice;
            } else {
              // 가격을 가져올 수 없으면 현재 가치 기준으로 역산
              if (asset.currentValue != null && asset.quantity > 0) {
                final estimatedPrice = asset.currentValue! / asset.quantity;
                assetPrices[now] = estimatedPrice;
                assetPrices[earliestDate] = estimatedPrice;
              } else {
                assetPrices[now] = 1.0;
                assetPrices[earliestDate] = 1.0;
              }
            }
          }

          // 1년 전 가격이 없으면 첫 번째 가격 사용
          if (!assetPrices.containsKey(earliestDate)) {
            if (assetPrices.isNotEmpty) {
              final sortedDates = assetPrices.keys.toList()..sort();
              assetPrices[earliestDate] = assetPrices[sortedDates.first]!;
            } else {
              assetPrices[earliestDate] = 1.0;
            }
          }

          assetPricesByDate[asset.id] = assetPrices;
        } catch (e) {
          debugPrint('Failed to load price data for ${asset.id}: $e');
          // 실패한 자산은 현재 가격을 가져와서 사용
          final currentPrice = await _getCurrentPrice(asset.assetId);
          if (currentPrice != null && currentPrice > 0) {
            assetPricesByDate[asset.id] = {
              earliestDate: currentPrice,
              now: currentPrice,
            };
          } else {
            // 가격을 가져올 수 없으면 현재 가치 기준으로 역산
            final estimatedPrice =
                asset.currentValue != null && asset.quantity > 0
                ? asset.currentValue! / asset.quantity
                : 1.0;
            assetPricesByDate[asset.id] = {
              earliestDate: estimatedPrice,
              now: estimatedPrice,
            };
          }
        }
      }

      // 모든 날짜를 수집하고 정렬
      final allDates = <DateTime>{};
      for (final prices in assetPricesByDate.values) {
        allDates.addAll(prices.keys);
      }
      final sortedDates = allDates.toList()..sort();

      // 각 날짜별로 전체 포트폴리오 가치 계산
      final spots = <FlSpot>[];

      // 차트 시작일부터 현재까지의 모든 날짜에 대해 계산
      // 날짜 목록에 없어도 시작일과 현재일은 포함
      final datesToCalculate = <DateTime>{...sortedDates};
      datesToCalculate.add(earliestDate);
      final allDatesToCalculate = datesToCalculate.toList()
        ..sort()
        ..removeWhere((date) => date.isAfter(now)); // 현재 이후 날짜 제거

      for (final date in allDatesToCalculate) {
        if (date.isBefore(earliestDate) || date.isAfter(now)) continue;

        double totalValue = 0.0;

        for (final asset in _assets) {
          final assetPrices = assetPricesByDate[asset.id];
          if (assetPrices == null) continue;

          // 해당 날짜의 가격 찾기 (가장 가까운 이전 가격 사용)
          double? price;
          final availableDates = assetPrices.keys.toList()..sort();
          for (final availableDate in availableDates.reversed) {
            if (availableDate.isBefore(date) ||
                availableDate.isAtSameMomentAs(date)) {
              price = assetPrices[availableDate];
              break;
            }
          }

          if (price != null) {
            // 보유 주수 * 가격 = 현재 가치
            totalValue += asset.quantity * price;
          }
        }

        // x 좌표: 시작일부터의 일수 / 전체 기간
        final daysFromStart = date.difference(earliestDate).inDays;
        final x = totalDays > 0 ? daysFromStart / totalDays : 0.0;

        spots.add(FlSpot(x, totalValue));
      }

      // 마지막 포인트를 실제 총 현재 가치로 명시적으로 설정 (차트와 표시된 현재 가치 일치)
      final actualTotalCurrentValue = totalCurrentValue;
      if (actualTotalCurrentValue != null) {
        // 기존 마지막 포인트 제거 (x가 1.0인 경우)
        spots.removeWhere((spot) => spot.x >= 1.0);
        // 실제 총 현재 가치를 마지막 포인트로 추가
        spots.add(FlSpot(1.0, actualTotalCurrentValue));
      } else if (spots.isEmpty || spots.last.x < 1.0) {
        // currentValue가 없으면 마지막 계산된 값 사용
        final lastValue = spots.isNotEmpty ? spots.last.y : 0.0;
        spots.add(FlSpot(1.0, lastValue));
      }

      _portfolioSpots = spots.isNotEmpty ? spots : null;
      _portfolioStartDate = earliestDate;
      _portfolioEndDate = now;
    } catch (e) {
      debugPrint('Failed to load portfolio chart: $e');
      _portfolioSpots = null;
      _portfolioStartDate = null;
      _portfolioEndDate = null;
    } finally {
      _isLoadingPortfolio = false;
      notifyListeners();
    }
  }

  Future<void> addAsset({
    required String assetId,
    required String assetName,
    required double initialAmount,
    required DateTime registeredDate,
    required double quantity,
  }) async {
    final newAsset = MyAsset(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      assetId: assetId,
      assetName: assetName,
      initialAmount: initialAmount,
      registeredDate: registeredDate,
      quantity: quantity,
    );

    _assets.add(newAsset);
    await _saveAssets();
    // 현재 가격으로 currentValue 업데이트
    await _updateCurrentValue(newAsset);
    await _loadPortfolioChart(); // 포트폴리오 그래프 업데이트
    notifyListeners();
  }

  // 개별 자산의 가격 히스토리 가져오기 (상세 화면용)
  Future<List<FlSpot>> getPriceHistory(MyAsset asset) async {
    try {
      final now = DateTime.now();
      // 차트 시작일을 1년 전으로 설정
      final earliestDate = now.subtract(const Duration(days: 365));
      final totalDays = 365; // 1년

      // 1년 전부터 현재까지의 가격 데이터 가져오기
      final priceData = await ApiService.fetchDailyPrices(asset.assetId, 365);

      final assetPrices = <DateTime, double>{};

      // 1년 전부터 현재까지의 가격 데이터 사용
      for (final pricePoint in priceData) {
        final dateStr = pricePoint['date'] as String?;
        final price = (pricePoint['price'] as num).toDouble();

        if (dateStr == null || price.isNaN || !price.isFinite) continue;

        final date = DateTime.parse(dateStr).toLocal();

        // 차트 시작일(1년 전) 이전 데이터는 스킵
        if (date.isBefore(earliestDate)) continue;

        // 차트 범위 내의 데이터만 저장
        if (date.isBefore(now) || date.isAtSameMomentAs(now)) {
          assetPrices[date] = price;
        }
      }

      // 가격 데이터가 없으면 현재 가격 사용
      if (assetPrices.isEmpty) {
        final currentPrice = await _getCurrentPrice(asset.assetId);
        if (currentPrice != null && currentPrice > 0) {
          assetPrices[now] = currentPrice;
          assetPrices[earliestDate] = currentPrice;
        } else {
          // 가격을 가져올 수 없으면 현재 가치 기준으로 역산
          if (asset.currentValue != null && asset.quantity > 0) {
            final estimatedPrice = asset.currentValue! / asset.quantity;
            assetPrices[now] = estimatedPrice;
            assetPrices[earliestDate] = estimatedPrice;
          } else {
            return [FlSpot(0, asset.currentValue ?? asset.initialAmount)];
          }
        }
      }

      // 1년 전 가격이 없으면 첫 번째 가격 사용
      if (!assetPrices.containsKey(earliestDate)) {
        if (assetPrices.isNotEmpty) {
          final sortedDates = assetPrices.keys.toList()..sort();
          assetPrices[earliestDate] = assetPrices[sortedDates.first]!;
        } else {
          assetPrices[earliestDate] = 1.0;
        }
      }

      // 모든 날짜를 수집하고 정렬
      final sortedDates = assetPrices.keys.toList()..sort();

      // 각 날짜별로 가치 계산 (quantity * 가격)
      final spots = <FlSpot>[];
      for (final date in sortedDates) {
        if (date.isBefore(earliestDate) || date.isAfter(now)) continue;

        final price = assetPrices[date]!;
        final value = asset.quantity * price;

        // x 좌표: 시작일부터의 일수 / 전체 기간
        final daysFromStart = date.difference(earliestDate).inDays;
        final x = totalDays > 0 ? daysFromStart / totalDays : 0.0;

        spots.add(FlSpot(x, value));
      }

      // 시작일과 현재일이 포함되도록 보장
      if (spots.isEmpty || spots.first.x > 0) {
        final startPrice = assetPrices[earliestDate]!;
        spots.insert(0, FlSpot(0, asset.quantity * startPrice));
      }

      // 마지막 포인트를 현재 가치로 명시적으로 설정 (차트와 표시된 현재 가치 일치)
      if (asset.currentValue != null) {
        // 기존 마지막 포인트 제거 (x가 1.0인 경우)
        spots.removeWhere((spot) => spot.x >= 1.0);
        // 현재 가치를 마지막 포인트로 추가
        spots.add(FlSpot(1.0, asset.currentValue!));
      } else if (spots.isEmpty || spots.last.x < 1.0) {
        final endPrice = assetPrices[now] ?? assetPrices.values.last;
        spots.add(FlSpot(1.0, asset.quantity * endPrice));
      }

      return spots.isNotEmpty
          ? spots
          : [FlSpot(0, asset.currentValue ?? asset.initialAmount)];
    } catch (e) {
      debugPrint('Failed to load price history for ${asset.id}: $e');
      return [FlSpot(0, asset.currentValue ?? asset.initialAmount)];
    }
  }

  Future<void> removeAsset(String id) async {
    _assets.removeWhere((asset) => asset.id == id);
    await _saveAssets();
    await _loadPortfolioChart(); // 포트폴리오 그래프 업데이트
    notifyListeners();
  }

  Future<void> _saveAssets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final assetsJson = jsonEncode(
        _assets.map((asset) => asset.toJson()).toList(),
      );
      await prefs.setString(_keyAssets, assetsJson);
    } catch (e) {
      debugPrint('Failed to save assets: $e');
    }
  }
}
