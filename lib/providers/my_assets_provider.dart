import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import '../models/my_asset.dart';
import '../services/api_service.dart';
import '../models/investment_config.dart';

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

  Future<void> _updateCurrentValue(MyAsset asset) async {
    try {
      final daysSinceRegistration = DateTime.now()
          .difference(asset.registeredDate)
          .inDays;

      if (daysSinceRegistration <= 0) {
        final index = _assets.indexWhere((a) => a.id == asset.id);
        if (index >= 0) {
          _assets[index] = asset.copyWith(currentValue: asset.initialAmount);
          notifyListeners();
        }
        return;
      }

      // 등록일부터 현재까지의 기간 계산 (년 단위)
      final yearsSinceRegistration = daysSinceRegistration / 365.0;
      final yearsAgo = yearsSinceRegistration.ceil().clamp(1, 10);

      // API에서 가격 데이터 가져오기
      final config = InvestmentConfig(
        asset: asset.assetId,
        yearsAgo: yearsAgo,
        amount: asset.initialAmount,
        type: InvestmentType.single,
        frequency: Frequency.monthly,
      );

      final result = await ApiService.calculate(config);

      // 등록일부터의 실제 기간에 맞게 현재 가치 계산
      double calculatedValue;
      if (yearsSinceRegistration > 0 && yearsAgo > 0) {
        final ratio = yearsSinceRegistration / yearsAgo;
        calculatedValue =
            asset.initialAmount +
            (result.finalValue - asset.initialAmount) * ratio;
      } else {
        calculatedValue = asset.initialAmount;
      }

      final index = _assets.indexWhere((a) => a.id == asset.id);
      if (index >= 0) {
        _assets[index] = asset.copyWith(currentValue: calculatedValue);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to update current value for ${asset.id}: $e');
      final index = _assets.indexWhere((a) => a.id == asset.id);
      if (index >= 0) {
        _assets[index] = asset.copyWith(currentValue: asset.initialAmount);
        notifyListeners();
      }
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
      // 가장 오래된 등록일 찾기
      final earliestDate = _assets
          .map((a) => a.registeredDate)
          .reduce((a, b) => a.isBefore(b) ? a : b);

      final now = DateTime.now();
      final totalDays = now.difference(earliestDate).inDays;

      if (totalDays <= 0) {
        // 아직 하루도 지나지 않음
        final totalValue = _assets.fold<double>(
          0,
          (sum, asset) => sum + asset.initialAmount,
        );
        _portfolioSpots = [FlSpot(0, totalValue)];
        _isLoadingPortfolio = false;
        notifyListeners();
        return;
      }

      // 각 자산별로 일봉 데이터 가져오기
      final Map<String, Map<DateTime, double>> assetPricesByDate = {};

      for (final asset in _assets) {
        final daysSinceRegistration = now
            .difference(asset.registeredDate)
            .inDays;
        if (daysSinceRegistration <= 0) continue;

        // 등록일부터 현재까지의 일수 + 여유분
        final daysToFetch = daysSinceRegistration + 30;

        try {
          // 일봉 데이터 직접 가져오기
          final priceData = await ApiService.fetchDailyPrices(
            asset.assetId,
            daysToFetch.clamp(1, 3650), // 최대 10년
          );

          final assetPrices = <DateTime, double>{};

          // 등록일의 초기 가격 (1.0 기준)
          double? initialPrice;

          // 등록일 이후의 가격 데이터만 사용
          for (final pricePoint in priceData) {
            final dateStr = pricePoint['date'] as String?;
            final price = (pricePoint['price'] as num).toDouble();

            if (dateStr == null || price.isNaN || !price.isFinite) continue;

            final date = DateTime.parse(dateStr).toLocal();

            // 등록일 이전 데이터는 스킵
            if (date.isBefore(asset.registeredDate)) {
              // 등록일에 가장 가까운 이전 가격을 초기 가격으로 사용
              if (initialPrice == null ||
                  date.isAfter(
                    asset.registeredDate.subtract(const Duration(days: 7)),
                  )) {
                initialPrice = price;
              }
              continue;
            }

            // 등록일 이후의 데이터만 저장
            if (date.isAfter(asset.registeredDate) ||
                date.isAtSameMomentAs(asset.registeredDate)) {
              assetPrices[date] = price;
            }
          }

          // 등록일의 가격 설정 (초기 가격이 있으면 사용, 없으면 첫 번째 가격 또는 1.0)
          if (initialPrice != null) {
            assetPrices[asset.registeredDate] = initialPrice;
          } else if (assetPrices.isNotEmpty) {
            // 등록일 이후 첫 번째 가격 사용
            final sortedDates = assetPrices.keys.toList()..sort();
            assetPrices[asset.registeredDate] = assetPrices[sortedDates.first]!;
          } else {
            assetPrices[asset.registeredDate] = 1.0;
          }

          // 현재 가치 추가 (가장 최근 가격 데이터가 있으면 사용)
          if (asset.currentValue != null && assetPrices.isNotEmpty) {
            final sortedDates = assetPrices.keys.toList()..sort();
            if (sortedDates.isNotEmpty) {
              final latestDate = sortedDates.last;
              final latestPrice = assetPrices[latestDate]!;
              // 현재 가치를 기준으로 최신 가격 업데이트
              final currentPrice = asset.currentValue! / asset.initialAmount;
              // 최신 가격과 현재 가치의 비율로 조정
              if (latestPrice > 0) {
                final priceRatio = currentPrice / latestPrice;
                // 모든 가격에 비율 적용
                final adjustedPrices = <DateTime, double>{};
                for (final entry in assetPrices.entries) {
                  adjustedPrices[entry.key] = entry.value * priceRatio;
                }
                assetPrices.clear();
                assetPrices.addAll(adjustedPrices);
              }
            }
          }

          assetPricesByDate[asset.id] = assetPrices;
        } catch (e) {
          debugPrint('Failed to load price data for ${asset.id}: $e');
          // 실패한 자산은 초기 가격만 사용
          assetPricesByDate[asset.id] = {asset.registeredDate: 1.0, now: 1.0};
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
      for (int i = 0; i < sortedDates.length; i++) {
        final date = sortedDates[i];
        if (date.isAfter(now)) continue;

        double totalValue = 0.0;

        for (final asset in _assets) {
          if (date.isBefore(asset.registeredDate)) {
            // 아직 등록되지 않은 자산은 제외
            continue;
          }

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
            // 초기 투자 금액 * 가격 비율 = 현재 가치
            totalValue += asset.initialAmount * price;
          }
        }

        // x 좌표: 등록일부터의 일수 / 전체 기간
        final daysFromStart = date.difference(earliestDate).inDays;
        final x = totalDays > 0 ? daysFromStart / totalDays : 0.0;

        spots.add(FlSpot(x, totalValue));
      }

      _portfolioSpots = spots.isNotEmpty ? spots : null;
    } catch (e) {
      debugPrint('Failed to load portfolio chart: $e');
      _portfolioSpots = null;
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
  }) async {
    final newAsset = MyAsset(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      assetId: assetId,
      assetName: assetName,
      initialAmount: initialAmount,
      registeredDate: registeredDate,
    );

    _assets.add(newAsset);
    await _saveAssets();
    await _updateCurrentValue(newAsset);
    await _loadPortfolioChart(); // 포트폴리오 그래프 업데이트
    notifyListeners();
  }

  // 개별 자산의 가격 히스토리 가져오기 (상세 화면용)
  Future<List<FlSpot>> getPriceHistory(MyAsset asset) async {
    try {
      final daysSinceRegistration = DateTime.now()
          .difference(asset.registeredDate)
          .inDays;

      if (daysSinceRegistration <= 0) {
        return [FlSpot(0, asset.initialAmount)];
      }

      final yearsSinceRegistration = daysSinceRegistration / 365.0;
      final yearsAgo = yearsSinceRegistration.ceil().clamp(1, 10);

      final config = InvestmentConfig(
        asset: asset.assetId,
        yearsAgo: yearsAgo,
        amount: asset.initialAmount,
        type: InvestmentType.single,
        frequency: Frequency.monthly,
      );

      final result = await ApiService.calculate(config);

      // valueSpots를 등록일부터의 실제 기간에 맞게 변환
      final spots = <FlSpot>[];
      final totalDays = daysSinceRegistration;

      for (int i = 0; i < result.valueSpots.length; i++) {
        final spot = result.valueSpots[i];
        // spot.x는 년 단위이므로 일 단위로 변환
        final daysFromStart = (spot.x * 365).round();
        if (daysFromStart <= totalDays) {
          // 실제 등록일부터의 일수로 변환
          final dayRatio = daysFromStart / totalDays;
          spots.add(FlSpot(dayRatio, spot.y));
        }
      }

      // 현재 가치를 마지막에 추가
      if (asset.currentValue != null) {
        spots.add(FlSpot(1.0, asset.currentValue!));
      }

      return spots.isNotEmpty ? spots : [FlSpot(0, asset.initialAmount)];
    } catch (e) {
      debugPrint('Failed to load price history for ${asset.id}: $e');
      return [FlSpot(0, asset.initialAmount)];
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
