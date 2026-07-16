import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'dart:io';
import '../models/my_asset.dart';
import '../services/api_service.dart';
import '../services/icloud_service.dart';
import '../utils/currency_converter.dart';

class MyAssetsProvider with ChangeNotifier {
  final List<MyAsset> _assets = [];
  bool _isLoading = false;
  List<FlSpot>? _portfolioSpots; // 전체 포트폴리오 그래프 데이터
  bool _isLoadingPortfolio = false;
  DateTime? _portfolioStartDate; // 포트폴리오 시작일
  DateTime? _portfolioEndDate; // 포트폴리오 종료일
  int _selectedChartYears = 1; // 선택된 차트 기간 (년)

  List<MyAsset> get assets => List.unmodifiable(_assets);
  bool get isLoading => _isLoading;
  List<FlSpot>? get portfolioSpots => _portfolioSpots;
  bool get isLoadingPortfolio => _isLoadingPortfolio;
  DateTime? get portfolioStartDate => _portfolioStartDate;
  DateTime? get portfolioEndDate => _portfolioEndDate;
  int get selectedChartYears => _selectedChartYears;

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

  // 자산 데이터 저장 (로컬)
  Future<void> _saveAssets() async {
    try {
      final assetsJson = jsonEncode(
        _assets.map((asset) => asset.toJson()).toList(),
      );

      if (Platform.isIOS) {
        // iOS: iCloud + SharedPreferences 동시 저장 (로드 시 누락 방지)
        final success = await ICloudService.setValue(_keyAssets, assetsJson);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyAssets, assetsJson);
        if (success) {
          debugPrint(
            '✅ [LocalStorage] iOS iCloud+Prefs 자산 저장 완료: ${_assets.length}개',
          );
        } else {
          debugPrint('⚠️ [LocalStorage] iCloud 실패, SharedPreferences에 저장됨');
        }
      } else {
        // Android: SharedPreferences 사용 (Auto Backup으로 자동 백업됨)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyAssets, assetsJson);
        debugPrint(
          '✅ [LocalStorage] Android에 자산 저장 완료: ${_assets.length}개 (Auto Backup)',
        );
      }
    } catch (e) {
      debugPrint('❌ [LocalStorage] 자산 저장 실패: $e');
    }
  }

  Future<void> loadAssets({
    int? chartYears,
    String? targetCurrency,
    String Function(String assetId)? getAssetOriginalCurrency,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 로컬에서 데이터 로드
      // iOS: iCloud Key-Value Storage 사용 (자동 동기화, iCloud 로그인 시)
      // Android: SharedPreferences + Auto Backup

      // iOS: iCloud Key-Value Storage는 항상 작동하며, iCloud 로그인 시 자동 동기화됨
      if (Platform.isIOS) {
        debugPrint(
          '📱 [LocalStorage] iOS iCloud Key-Value Storage 사용 중 (자동 동기화)',
        );
      }

      String? assetsJson;

      if (Platform.isIOS) {
        // iOS: iCloud Key-Value Storage에서 읽기 (자동 동기화된 데이터)
        debugPrint(
          '📱 [LocalStorage] iOS iCloud Key-Value Storage에서 자산 데이터 로드 시작...',
        );
        assetsJson = await ICloudService.getValue(_keyAssets);

        if (assetsJson == null || assetsJson.isEmpty) {
          // iCloud에 없으면 SharedPreferences에서 읽기 (백업)
          debugPrint(
            '⚠️ [LocalStorage] iCloud에 데이터 없음, SharedPreferences 확인 중...',
          );
          final prefs = await SharedPreferences.getInstance();
          assetsJson = prefs.getString(_keyAssets);
        }
      } else {
        // Android: SharedPreferences에서 읽기 (Auto Backup으로 복원됨)
        debugPrint(
          '📱 [LocalStorage] Android SharedPreferences에서 자산 데이터 로드 시작...',
        );
        final prefs = await SharedPreferences.getInstance();
        assetsJson = prefs.getString(_keyAssets);
      }
      debugPrint(
        '📱 [LocalStorage] 데이터 조회 결과: ${assetsJson != null ? '있음' : '없음'}',
      );

      if (assetsJson != null && assetsJson.isNotEmpty) {
        try {
          final List<dynamic> decoded = jsonDecode(assetsJson);
          _assets.clear();
          _assets.addAll(
            decoded.map(
              (json) => MyAsset.fromJson(json as Map<String, dynamic>),
            ),
          );
          debugPrint('✅ [LocalStorage] 자산 로드 완료: ${_assets.length}개 자산');
        } catch (e) {
          debugPrint('❌ [LocalStorage] JSON 파싱 실패: $e');
        }
      } else {
        debugPrint('ℹ️ [LocalStorage] 저장된 자산 없음');
      }

      // 각 자산의 현재 가치 업데이트
      for (final asset in _assets) {
        await _updateCurrentValue(asset);
      }

      // 통화 정보가 제공된 경우 포트폴리오 차트 자동 로드
      if (targetCurrency != null &&
          getAssetOriginalCurrency != null &&
          chartYears != null) {
        await loadPortfolioChart(
          years: chartYears,
          targetCurrency: targetCurrency,
          getAssetOriginalCurrency: getAssetOriginalCurrency,
        );
      }
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
      // 현금은 시세 API 없이 원금 = 현재 가치
      if (asset.assetId == 'cash') {
        final index = _assets.indexWhere((a) => a.id == asset.id);
        if (index >= 0) {
          _assets[index] = asset.copyWith(currentValue: asset.initialAmount);
          notifyListeners();
        }
        return;
      }

      final currentPrice = await _getCurrentPrice(asset.assetId);
      if (currentPrice == null || currentPrice <= 0) {
        debugPrint('Failed to get current price for ${asset.id}');
        return;
      }

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
  Future<void> loadPortfolioChart({
    int years = 1,
    String? targetCurrency,
    String Function(String assetId)? getAssetOriginalCurrency,
  }) async {
    if (_assets.isEmpty) {
      _portfolioSpots = null;
      notifyListeners();
      return;
    }

    _isLoadingPortfolio = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      // 차트 시작일을 지정된 년수 전으로 설정
      final totalDays = years * 365;
      final earliestDate = now.subtract(Duration(days: totalDays));

      // 각 자산별로 일봉 데이터 가져오기
      final Map<String, Map<DateTime, double>> assetPricesByDate = {};

      for (final asset in _assets) {
        try {
          // 지정된 년수 전부터 현재까지의 가격 데이터 가져오기
          final priceData = await ApiService.fetchDailyPrices(
            asset.assetId,
            totalDays, // 지정된 년수치 데이터
          );

          final assetPrices = <DateTime, double>{};

          // 1년 전부터 현재까지의 가격 데이터 사용
          for (final pricePoint in priceData) {
            final dateStr = pricePoint['date'] as String?;
            final price = (pricePoint['price'] as num).toDouble();

            if (dateStr == null || price.isNaN || !price.isFinite) continue;

            final date = DateTime.parse(dateStr).toLocal();

            // 차트 시작일 이전 데이터는 스킵
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

          // 시작일 가격이 없으면 첫 번째 가격 사용
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
            // 보유 주수 * 가격 = 현재 가치 (원본 통화 기준)
            double assetValue = asset.quantity * price;

            // 통화 변환 (targetCurrency가 제공된 경우)
            if (targetCurrency != null && getAssetOriginalCurrency != null) {
              final originalCurrency = getAssetOriginalCurrency(asset.assetId);
              debugPrint(
                '[PortfolioChart] 자산 ${asset.assetId}: 원본 통화=$originalCurrency, 목표 통화=$targetCurrency, 변환 전 가치=$assetValue',
              );
              if (originalCurrency != targetCurrency) {
                // 동기 변환 사용 (현재 환율 기준)
                final beforeValue = assetValue;
                assetValue = CurrencyConverter.shared.convertSync(
                  assetValue,
                  originalCurrency,
                  targetCurrency,
                );
                debugPrint(
                  '[PortfolioChart] 변환 후: $beforeValue ($originalCurrency) -> $assetValue ($targetCurrency)',
                );
              }
            }

            totalValue += assetValue;
          }
        }

        // x 좌표: 시작일부터의 일수 / 전체 기간
        final daysFromStart = date.difference(earliestDate).inDays;
        final x = totalDays > 0 ? daysFromStart / totalDays : 0.0;

        spots.add(FlSpot(x, totalValue));
      }

      // 마지막 포인트를 실제 총 현재 가치로 명시적으로 설정 (차트와 표시된 현재 가치 일치)
      double? actualTotalCurrentValue = totalCurrentValue;

      // 통화 변환 (targetCurrency가 제공된 경우)
      if (actualTotalCurrentValue != null &&
          targetCurrency != null &&
          getAssetOriginalCurrency != null) {
        // totalCurrentValue는 이미 각 자산의 원본 통화로 계산되어 있으므로
        // 각 자산별로 변환해서 합산해야 함
        actualTotalCurrentValue = 0.0;
        for (final asset in _assets) {
          if (asset.currentValue == null) continue;
          final originalCurrency = getAssetOriginalCurrency(asset.assetId);
          final convertedValue = CurrencyConverter.shared.convertSync(
            asset.currentValue!,
            originalCurrency,
            targetCurrency,
          );
          actualTotalCurrentValue = actualTotalCurrentValue! + convertedValue;
        }
        debugPrint(
          '[PortfolioChart] 마지막 포인트 변환: $totalCurrentValue -> $actualTotalCurrentValue $targetCurrency',
        );
      }

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
    debugPrint('💾 [LocalStorage] 자산 추가 시작: $assetName ($assetId)');

    final newAsset = MyAsset(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      assetId: assetId,
      assetName: assetName,
      initialAmount: initialAmount,
      registeredDate: registeredDate,
      quantity: quantity,
    );

    _assets.add(newAsset);

    // 현재 가격으로 currentValue 업데이트
    await _updateCurrentValue(newAsset);

    // 로컬에 저장
    await _saveAssets();

    notifyListeners();
    debugPrint('✅ [LocalStorage] 자산 추가 완료! 총 ${_assets.length}개 자산');
  }

  /// 은퇴 시뮬 보유 자산을 내 자산으로 가져옵니다.
  /// 동일 assetId가 있으면 수량·평가액을 갱신합니다.
  Future<void> importRetireHoldings(
    List<
      ({String assetId, String assetName, double quantity, double valuation})
    >
    holdings,
  ) async {
    if (holdings.isEmpty) return;

    for (final h in holdings) {
      if (h.quantity <= 0) continue;
      final existingIndex = _assets.indexWhere((a) => a.assetId == h.assetId);
      final amount = h.valuation > 0 ? h.valuation : 0.0;

      if (existingIndex >= 0) {
        final existing = _assets[existingIndex];
        final updated = existing.copyWith(
          assetName: h.assetName,
          quantity: h.quantity,
          initialAmount: amount > 0 ? amount : existing.initialAmount,
          registeredDate: existing.registeredDate,
        );
        _assets[existingIndex] = updated;
        await _updateCurrentValue(updated);
      } else {
        final newAsset = MyAsset(
          id: '${DateTime.now().millisecondsSinceEpoch}_${h.assetId}',
          assetId: h.assetId,
          assetName: h.assetName,
          initialAmount: amount,
          registeredDate: DateTime.now(),
          quantity: h.quantity,
        );
        _assets.add(newAsset);
        await _updateCurrentValue(newAsset);
      }
    }

    await _saveAssets();
    notifyListeners();
    debugPrint(
      '✅ [LocalStorage] 은퇴 보유 자산 import 완료: ${holdings.length}건 → 총 ${_assets.length}개',
    );
  }

  // 선택된 차트 기간 설정
  void setSelectedChartYears(int years) {
    _selectedChartYears = years;
    notifyListeners();
  }

  // 개별 자산의 가격 히스토리 가져오기 (상세 화면용)
  Future<List<FlSpot>> getPriceHistory(
    MyAsset asset, {
    int? years,
    String? targetCurrency,
    String Function(String assetId)? getAssetOriginalCurrency,
  }) async {
    try {
      final now = DateTime.now();
      // 차트 시작일을 지정된 년수 전으로 설정 (기본값은 선택된 기간 사용)
      final chartYears = years ?? _selectedChartYears;
      final totalDays = chartYears * 365;
      final earliestDate = now.subtract(Duration(days: totalDays));

      // 지정된 년수 전부터 현재까지의 가격 데이터 가져오기
      debugPrint(
        '[getPriceHistory] 가격 데이터 요청: assetId=${asset.assetId}, totalDays=$totalDays',
      );
      final priceData = await ApiService.fetchDailyPrices(
        asset.assetId,
        totalDays,
      );
      debugPrint('[getPriceHistory] 가격 데이터 수신: ${priceData.length}개 포인트');

      final assetPrices = <DateTime, double>{};

      // 지정된 년수 전부터 현재까지의 가격 데이터 사용
      for (final pricePoint in priceData) {
        final dateStr = pricePoint['date'] as String?;
        final price = (pricePoint['price'] as num).toDouble();

        if (dateStr == null || price.isNaN || !price.isFinite) continue;

        final date = DateTime.parse(dateStr).toLocal();

        // 차트 시작일 이전 데이터는 스킵
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

      // 시작일 가격이 없으면 첫 번째 가격 사용
      if (!assetPrices.containsKey(earliestDate)) {
        if (assetPrices.isNotEmpty) {
          final sortedDates = assetPrices.keys.toList()..sort();
          assetPrices[earliestDate] = assetPrices[sortedDates.first]!;
        } else {
          assetPrices[earliestDate] = 1.0;
        }
      }

      // 통화 변환을 위한 환율 로드 (targetCurrency가 제공된 경우)
      // CurrencyConverter.shared를 사용하면 자동으로 초기화됨
      // 하지만 convertSync는 동기 함수이므로 환율이 준비될 때까지 대기
      if (targetCurrency != null && getAssetOriginalCurrency != null) {
        final isReady = await CurrencyConverter.shared.waitUntilReady(
          maxWaitSeconds: 10,
        );
        if (!isReady) {
          debugPrint(
            '[getPriceHistory] ⚠️ 환율 캐시가 준비되지 않음. 통화 변환 없이 진행 (원본 통화로 표시됨)',
          );
        } else {
          debugPrint(
            '[getPriceHistory] ✅ 환율 캐시 준비 완료. 통화 변환 진행: ${getAssetOriginalCurrency(asset.assetId)} -> $targetCurrency',
          );
        }
      }

      // 모든 날짜를 수집하고 정렬
      final sortedDates = assetPrices.keys.toList()..sort();

      // 각 날짜별로 가치 계산 (quantity * 가격)
      final spots = <FlSpot>[];
      for (final date in sortedDates) {
        if (date.isBefore(earliestDate) || date.isAfter(now)) continue;

        final price = assetPrices[date]!;
        // 보유 주수 * 가격 = 현재 가치 (원본 통화 기준)
        double value = asset.quantity * price;

        // 통화 변환 (targetCurrency가 제공된 경우)
        if (targetCurrency != null && getAssetOriginalCurrency != null) {
          final originalCurrency = getAssetOriginalCurrency(asset.assetId);
          if (originalCurrency != targetCurrency) {
            // 동기 변환 사용 (현재 환율 기준)
            final convertedValue = CurrencyConverter.shared.convertSync(
              value,
              originalCurrency,
              targetCurrency,
            );
            // convertSync가 원본 값을 반환했다면 (캐시가 없음) 비동기 변환 시도
            if (convertedValue == value && originalCurrency != targetCurrency) {
              debugPrint(
                '[getPriceHistory] ⚠️ convertSync가 원본 값 반환. 비동기 변환 시도: $value $originalCurrency -> $targetCurrency',
              );
              try {
                value = await CurrencyConverter.shared.convert(
                  value,
                  originalCurrency,
                  targetCurrency,
                );
                debugPrint(
                  '[getPriceHistory] ✅ 비동기 변환 성공: $value $targetCurrency',
                );
              } catch (e) {
                debugPrint('[getPriceHistory] ❌ 비동기 변환 실패: $e');
              }
            } else {
              value = convertedValue;
            }
          }
        }

        // x 좌표: 시작일부터의 일수 / 전체 기간
        final daysFromStart = date.difference(earliestDate).inDays;
        final x = totalDays > 0 ? daysFromStart / totalDays : 0.0;

        spots.add(FlSpot(x, value));
      }

      // 시작일과 현재일이 포함되도록 보장
      if (spots.isEmpty || spots.first.x > 0) {
        final startPrice = assetPrices[earliestDate]!;
        double startValue = asset.quantity * startPrice;

        // 통화 변환 (targetCurrency가 제공된 경우)
        if (targetCurrency != null && getAssetOriginalCurrency != null) {
          final originalCurrency = getAssetOriginalCurrency(asset.assetId);
          if (originalCurrency != targetCurrency) {
            final convertedStartValue = CurrencyConverter.shared.convertSync(
              startValue,
              originalCurrency,
              targetCurrency,
            );
            // convertSync가 원본 값을 반환했다면 (캐시가 없음) 비동기 변환 시도
            if (convertedStartValue == startValue) {
              try {
                startValue = await CurrencyConverter.shared.convert(
                  startValue,
                  originalCurrency,
                  targetCurrency,
                );
              } catch (e) {
                debugPrint('[getPriceHistory] 시작값 변환 실패: $e');
              }
            } else {
              startValue = convertedStartValue;
            }
          }
        }

        spots.insert(0, FlSpot(0, startValue));
      }

      // 마지막 포인트를 현재 가치로 명시적으로 설정 (차트와 표시된 현재 가치 일치)
      if (asset.currentValue != null) {
        // 기존 마지막 포인트 제거 (x가 1.0인 경우)
        spots.removeWhere((spot) => spot.x >= 1.0);

        // 현재 가치 통화 변환
        double finalValue = asset.currentValue!;
        if (targetCurrency != null && getAssetOriginalCurrency != null) {
          final originalCurrency = getAssetOriginalCurrency(asset.assetId);
          if (originalCurrency != targetCurrency) {
            final convertedFinalValue = CurrencyConverter.shared.convertSync(
              finalValue,
              originalCurrency,
              targetCurrency,
            );
            // convertSync가 원본 값을 반환했다면 (캐시가 없음) 비동기 변환 시도
            if (convertedFinalValue == finalValue) {
              try {
                finalValue = await CurrencyConverter.shared.convert(
                  finalValue,
                  originalCurrency,
                  targetCurrency,
                );
              } catch (e) {
                debugPrint('[getPriceHistory] 최종값 변환 실패: $e');
              }
            } else {
              finalValue = convertedFinalValue;
            }
          }
        }

        // 현재 가치를 마지막 포인트로 추가
        spots.add(FlSpot(1.0, finalValue));
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
    debugPrint('🗑️ [LocalStorage] 자산 삭제 시작: $id');

    _assets.removeWhere((asset) => asset.id == id);

    // 로컬에 저장
    await _saveAssets();

    notifyListeners();
    debugPrint('✅ [LocalStorage] 자산 삭제 완료! 남은 자산: ${_assets.length}개');
  }
}
