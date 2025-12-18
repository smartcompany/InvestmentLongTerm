import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/asset.dart';
import '../models/investment_config.dart';
import '../services/api_service.dart';

class RetireSimulatorProvider with ChangeNotifier {
  double _initialAsset = 1000000000; // 10억 원
  double _monthlyWithdrawal = 5000000; // 500만 원
  int _simulationYears = 5;
  String _selectedScenario = 'neutral'; // 'positive', 'neutral', 'negative'
  double _inflationRate = 0.03; // 연간 인플레이션율 3% (기본값)
  String? _lastCurrencySymbol; // 마지막 통화 기호 (통화 변경 감지용)
  final List<Asset> _assets = [];
  final Map<String, double> _cagrCache = {}; // assetId -> CAGR 캐시
  final Map<String, bool> _loadingCagr = {}; // assetId -> 로딩 상태
  final Map<String, int> _cagrRetryCount = {}; // assetId -> 재시도 횟수

  double get initialAsset => _initialAsset;
  double get monthlyWithdrawal => _monthlyWithdrawal;
  int get simulationYears => _simulationYears;
  String get selectedScenario => _selectedScenario;
  double get inflationRate => _inflationRate;
  List<Asset> get assets => List.unmodifiable(_assets);
  Map<String, double> get cagrCache => Map.unmodifiable(_cagrCache);

  void setInitialAsset(double value) {
    _initialAsset = value;
    notifyListeners();
  }

  void setMonthlyWithdrawal(double value) {
    _monthlyWithdrawal = value;
    notifyListeners();
  }

  void setSimulationYears(int value) {
    _simulationYears = value;
    notifyListeners();
  }

  void setSelectedScenario(String scenario) {
    if (scenario == 'positive' ||
        scenario == 'neutral' ||
        scenario == 'negative') {
      _selectedScenario = scenario;
      notifyListeners();
    }
  }

  void setInflationRate(double value) {
    _inflationRate = value.clamp(0.0, 1.0); // 0% ~ 100% 범위로 제한
    notifyListeners();
  }

  // 통화 변경 시 기본값 재설정
  void updateCurrencyDefaults(String currencySymbol) {
    // 통화가 변경되지 않았으면 무시
    if (_lastCurrencySymbol == currencySymbol) {
      return;
    }

    // 원화 기본값 정의
    const krwInitialAsset = 1000000000.0; // 10억 원
    const krwMonthlyWithdrawal = 5000000.0; // 500만 원

    // 통화별 기본값 정의
    final defaultValues = {
      '\$': {'initial': 1000000.0, 'monthly': 5000.0}, // 달러
      '¥': {'initial': 150000000.0, 'monthly': 750000.0}, // 엔
      'CN¥': {'initial': 7000000.0, 'monthly': 35000.0}, // 위안
      '₩': {'initial': krwInitialAsset, 'monthly': krwMonthlyWithdrawal}, // 원화
    };

    // 현재 값이 이전 통화의 기본값인지 확인
    bool isDefaultValue = false;
    if (_lastCurrencySymbol != null &&
        defaultValues.containsKey(_lastCurrencySymbol)) {
      final prevDefaults = defaultValues[_lastCurrencySymbol]!;
      isDefaultValue =
          (_initialAsset == prevDefaults['initial'] &&
          _monthlyWithdrawal == prevDefaults['monthly']);
    } else {
      // 첫 실행이거나 이전 통화가 없으면 원화 기본값인지 확인
      isDefaultValue =
          (_initialAsset == krwInitialAsset &&
          _monthlyWithdrawal == krwMonthlyWithdrawal);
    }

    // 기본값인 경우에만 새 통화의 기본값으로 변경
    if (isDefaultValue && defaultValues.containsKey(currencySymbol)) {
      final newDefaults = defaultValues[currencySymbol]!;
      _initialAsset = newDefaults['initial']!;
      _monthlyWithdrawal = newDefaults['monthly']!;
      _lastCurrencySymbol = currencySymbol;
      notifyListeners();
    } else {
      // 기본값이 아니면 통화만 업데이트 (값은 유지)
      _lastCurrencySymbol = currencySymbol;
    }
  }

  void addAsset(String assetId) {
    // 중복 체크
    if (_assets.any((a) => a.assetId == assetId)) {
      return;
    }

    // 새 자산 추가 시 비중 재분배
    Asset newAsset;
    if (_assets.isEmpty) {
      // 첫 자산은 100%
      // 현금 자산은 즉시 annualReturn 설정
      newAsset = Asset(
        assetId: assetId,
        allocation: 1.0,
        annualReturn: assetId == 'cash' ? 0.021 : null, // 현금은 2.1%
      );
      _assets.add(newAsset);
    } else {
      // 기존 자산들의 비중을 균등하게 재분배
      final newCount = _assets.length + 1;
      final equalAllocation = 1.0 / newCount;

      // 기존 자산들 비중 재설정
      for (int i = 0; i < _assets.length; i++) {
        _assets[i] = _assets[i].copyWith(allocation: equalAllocation);
      }

      // 새 자산 추가 (현금 자산은 즉시 annualReturn 설정)
      newAsset = Asset(
        assetId: assetId,
        allocation: equalAllocation,
        annualReturn: assetId == 'cash' ? 0.021 : null, // 현금은 2.1%
      );
      _assets.add(newAsset);
    }

    // 현금 자산이 아닌 경우에만 API 호출
    if (assetId != 'cash') {
      _loadCagrForAsset(assetId);
    } else {
      // 현금 자산은 캐시에 저장하고 로딩 상태 설정
      _cagrCache[assetId] = 0.021;
      _loadingCagr[assetId] = false;
    }
    notifyListeners();
  }

  void updateAsset(int index, Asset asset) {
    if (index >= 0 && index < _assets.length) {
      _assets[index] = asset;
      notifyListeners();
    }
  }

  // 자산 비중 조절 (슬라이더용)
  void updateAssetAllocation(int index, double newAllocation) {
    if (index < 0 || index >= _assets.length) return;

    // 새 비중이 0보다 작거나 1보다 크면 조정
    newAllocation = newAllocation.clamp(0.0, 1.0);

    // 현재 총 비중
    final currentTotal = totalAllocation;
    final currentAllocation = _assets[index].allocation;

    // 변경할 자산의 비중 업데이트
    _assets[index] = _assets[index].copyWith(allocation: newAllocation);

    // 나머지 자산들의 비중 재분배
    if (_assets.length > 1) {
      final otherAssetsTotal = currentTotal - currentAllocation;
      final remainingAllocation = 1.0 - newAllocation;

      if (otherAssetsTotal > 0 && remainingAllocation >= 0) {
        // 나머지 자산들의 비율을 유지하면서 재분배
        for (int i = 0; i < _assets.length; i++) {
          if (i != index) {
            final ratio = _assets[i].allocation / otherAssetsTotal;
            final newAlloc = remainingAllocation * ratio;
            _assets[i] = _assets[i].copyWith(allocation: newAlloc);
          }
        }
      } else {
        // 나머지 자산들을 균등하게 분배
        final equalAllocation = remainingAllocation / (_assets.length - 1);
        for (int i = 0; i < _assets.length; i++) {
          if (i != index) {
            _assets[i] = _assets[i].copyWith(allocation: equalAllocation);
          }
        }
      }
    }

    notifyListeners();
  }

  void removeAsset(int index) {
    if (index < 0 || index >= _assets.length) return;

    if (_assets.length == 1) {
      // 마지막 자산이면 그냥 삭제
      _assets.removeAt(index);
    } else {
      // 삭제할 자산의 비중을 나머지 자산들에게 재분배
      final removedAllocation = _assets[index].allocation;
      _assets.removeAt(index);

      if (_assets.isNotEmpty) {
        final remainingTotal = totalAllocation;
        if (remainingTotal > 0) {
          // 기존 비율 유지하면서 재분배
          for (int i = 0; i < _assets.length; i++) {
            final ratio = _assets[i].allocation / remainingTotal;
            _assets[i] = _assets[i].copyWith(
              allocation: _assets[i].allocation + (removedAllocation * ratio),
            );
          }
        } else {
          // 균등 분배
          final equalAllocation = 1.0 / _assets.length;
          for (int i = 0; i < _assets.length; i++) {
            _assets[i] = _assets[i].copyWith(allocation: equalAllocation);
          }
        }
      }
    }

    notifyListeners();
  }

  // 특정 자산의 CAGR을 API에서 가져오기 (5년 기준, 보수적 조정 적용)
  Future<void> _loadCagrForAsset(String assetId, {bool isRetry = false}) async {
    // 재시도가 아닌 경우에만 중복 체크
    if (!isRetry &&
        (_cagrCache.containsKey(assetId) || _loadingCagr[assetId] == true)) {
      return; // 이미 로드되었거나 로딩 중
    }

    // 현금 자산은 금리 2.1%로 고정
    if (assetId == 'cash') {
      _loadingCagr[assetId] = false; // 로딩 상태 명시적으로 false로 설정
      _cagrCache[assetId] = 0.021; // 2.1%
      final assetIndex = _assets.indexWhere((a) => a.assetId == assetId);
      if (assetIndex >= 0) {
        _assets[assetIndex] = _assets[assetIndex].copyWith(
          annualReturn: 0.021, // 2.1%
        );
      }
      notifyListeners();
      return;
    }

    _loadingCagr[assetId] = true;
    notifyListeners();

    // CAGR 계산용 임시 금액 (CAGR은 비율이므로 금액과 무관)
    const cagrCalculationAmount = 1000000.0;

    try {
      // 5년 CAGR 가져오기
      final config5y = InvestmentConfig(
        asset: assetId,
        yearsAgo: 5,
        amount: cagrCalculationAmount,
        type: InvestmentType.single,
        frequency: Frequency.monthly,
      );
      final result5y = await ApiService.calculate(config5y);
      final cagr5y = result5y.cagr / 100.0;

      // 3년 CAGR도 가져와서 비교 (최근 트렌드 반영)
      double? cagr3y;
      try {
        final config3y = InvestmentConfig(
          asset: assetId,
          yearsAgo: 3,
          amount: cagrCalculationAmount,
          type: InvestmentType.single,
          frequency: Frequency.monthly,
        );
        final result3y = await ApiService.calculate(config3y);
        cagr3y = result3y.cagr / 100.0;
      } catch (e) {
        // 3년 데이터가 없으면 무시
        debugPrint('3년 CAGR 로드 실패 (무시): $e');
      }

      // 현실적인 CAGR 계산: 가중 평균 또는 보수적 조정
      double adjustedCagr;
      if (cagr3y != null) {
        // 최근 3년과 5년의 가중 평균 (최근 데이터에 더 높은 가중치)
        // 3년: 60%, 5년: 40% 가중치
        adjustedCagr = (cagr3y * 0.6) + (cagr5y * 0.4);

        // 만약 3년 CAGR이 5년보다 훨씬 높으면 (비정상적 상승), 보수적으로 조정
        if (cagr3y > cagr5y * 1.5) {
          // 최근 상승이 너무 크면 5년 CAGR에 더 가깝게 조정
          adjustedCagr = (cagr3y * 0.3) + (cagr5y * 0.7);
        }
      } else {
        // 3년 데이터가 없으면 5년 CAGR의 85% 적용 (보수적)
        adjustedCagr = cagr5y * 0.85;
      }

      // 최종적으로 5년 CAGR의 80%~100% 범위로 제한 (과도한 추정 방지)
      final minCagr = cagr5y * 0.8;
      final maxCagr = cagr5y;
      adjustedCagr = adjustedCagr.clamp(minCagr, maxCagr);

      debugPrint(
        'CAGR 계산 ($assetId): 5년=${(cagr5y * 100).toStringAsFixed(2)}%, '
        '3년=${cagr3y != null ? (cagr3y * 100).toStringAsFixed(2) : "N/A"}%, '
        '조정=${(adjustedCagr * 100).toStringAsFixed(2)}%',
      );

      _cagrCache[assetId] = adjustedCagr;

      // 해당 자산의 annualReturn 업데이트
      final assetIndex = _assets.indexWhere((a) => a.assetId == assetId);
      if (assetIndex >= 0) {
        _assets[assetIndex] = _assets[assetIndex].copyWith(
          annualReturn: adjustedCagr,
        );
      }
    } catch (e) {
      debugPrint('Failed to load CAGR for $assetId: $e');
      // 실패 시 재시도 (최대 2번)
      if (!_cagrRetryCount.containsKey(assetId)) {
        _cagrRetryCount[assetId] = 0;
      }

      if (_cagrRetryCount[assetId]! < 2) {
        _cagrRetryCount[assetId] = _cagrRetryCount[assetId]! + 1;
        debugPrint('CAGR 로드 재시도 ($assetId): ${_cagrRetryCount[assetId]}번째');

        // 2초 후 재시도
        await Future.delayed(Duration(seconds: 2));
        // 재시도 전에 로딩 상태를 false로 설정하여 재시도 가능하도록 함
        _loadingCagr[assetId] = false;
        _loadCagrForAsset(assetId, isRetry: true);
        return;
      } else {
        // 최대 재시도 횟수 초과 시 null 유지
        debugPrint('CAGR 로드 최종 실패 ($assetId): 재시도 횟수 초과');
        _cagrRetryCount[assetId] = 0; // 재시도 카운트 리셋
      }
    } finally {
      _loadingCagr[assetId] = false;
      notifyListeners();
    }
  }

  bool isLoadingCagr(String assetId) {
    return _loadingCagr[assetId] == true;
  }

  // 비중 합계 확인
  double get totalAllocation {
    return _assets.fold(0.0, (sum, asset) => sum + asset.allocation);
  }

  // 모든 자산의 CAGR이 로드되었는지 확인
  bool get allCagrLoaded {
    return _assets.every((asset) => asset.annualReturn != null);
  }

  // 시뮬레이션 실행 (선택한 시나리오만)
  Map<String, dynamic> runSimulation() {
    if (_assets.isEmpty || !allCagrLoaded) {
      return {'total': <double>[], 'assets': <String, List<double>>{}};
    }

    // 비중 정규화
    final totalAlloc = totalAllocation;
    if (totalAlloc <= 0) {
      return {'total': <double>[], 'assets': <String, List<double>>{}};
    }

    final normalizedAssets = _assets.map((asset) {
      return asset.copyWith(allocation: asset.allocation / totalAlloc);
    }).toList();

    final months = _simulationYears * 12;
    final totalPath = <double>[];
    final assetPaths = <String, List<double>>{};

    // 각 자산별 경로 초기화
    for (final asset in normalizedAssets) {
      assetPaths[asset.assetId] = <double>[];
    }

    // 초기 자산을 각 자산별로 배분
    final assetValues = normalizedAssets.map((asset) {
      return _initialAsset * asset.allocation;
    }).toList();

    // 초기값 기록
    double initialTotal = 0.0;
    for (int i = 0; i < normalizedAssets.length; i++) {
      initialTotal += assetValues[i];
      assetPaths[normalizedAssets[i].assetId]!.add(assetValues[i]);
    }
    totalPath.add(initialTotal);

    // 선택한 시나리오만 계산
    final scenario = _selectedScenario;

    // 디버그: 초기 설정 로그
    debugPrint('=== 시뮬레이션 시작 ===');
    debugPrint(
      '초기 자산: ${_initialAsset.toStringAsFixed(0)}원 (${(_initialAsset / 100000000).toStringAsFixed(2)}억)',
    );
    debugPrint(
      '월 인출액: ${_monthlyWithdrawal.toStringAsFixed(0)}원 (${(_monthlyWithdrawal / 1000000).toStringAsFixed(0)}만원)',
    );
    debugPrint('시뮬레이션 기간: $_simulationYears년 ($months개월)');
    debugPrint('선택한 시나리오: $scenario');
    for (int i = 0; i < normalizedAssets.length; i++) {
      final asset = normalizedAssets[i];
      final annualRet = asset.annualReturn ?? 0.0;
      final monthlyRet = asset.getMonthlyReturnForScenario(scenario);
      debugPrint(
        '자산 ${asset.assetId}: 연수익률 ${(annualRet * 100).toStringAsFixed(2)}%, 월수익률 ${(monthlyRet * 100).toStringAsFixed(4)}%, 비중 ${(asset.allocation * 100).toStringAsFixed(1)}%',
      );
    }

    // 인플레이션 적용을 위한 현재 월 인출액 (매년 갱신)
    double currentMonthlyWithdrawal = _monthlyWithdrawal;
    int currentYear = 0;

    for (int month = 0; month < months; month++) {
      double totalValue = 0.0;

      // 매년 시작 시 인플레이션 적용 (1월 = month % 12 == 0)
      if (month % 12 == 0 && month > 0) {
        currentYear = month ~/ 12;
        // 연간 인플레이션율 적용: 월 인출액 = 월 인출액 × (1 + 인플레이션율)^년수
        currentMonthlyWithdrawal =
            _monthlyWithdrawal * pow(1 + _inflationRate, currentYear);
        debugPrint(
          '${currentYear}년차: 월 인출액 ${(currentMonthlyWithdrawal / 1000000).toStringAsFixed(2)}만원 (인플레이션 ${(_inflationRate * 100).toStringAsFixed(1)}% 적용)',
        );
      }

      // 1단계: 각 자산에 월 복리 수익률 적용 (먼저 수익률 적용)
      // 계산: 자산가치 = 자산가치 × (1 + 월수익률)
      for (int i = 0; i < normalizedAssets.length; i++) {
        final asset = normalizedAssets[i];
        if (asset.annualReturn == null) continue;
        final monthlyReturn = asset.getMonthlyReturnForScenario(scenario);
        // 월 복리 수익률 적용
        assetValues[i] *= (1 + monthlyReturn);
        totalValue += assetValues[i];
      }

      // 2단계: 월 인출액 차감 (수익률 적용 후 인출액 차감)
      // 계산: 자산가치 = 자산가치 - 월인출액 (인플레이션 적용된 금액)
      if (totalValue > 0 && totalValue >= currentMonthlyWithdrawal) {
        // 각 자산의 현재 비중에 따라 월 인출액 분배
        for (int i = 0; i < normalizedAssets.length; i++) {
          final assetRatio = assetValues[i] / totalValue;
          final withdrawalAmount = currentMonthlyWithdrawal * assetRatio;
          // 각 자산에서 비중에 맞게 인출액 차감
          assetValues[i] = (assetValues[i] - withdrawalAmount).clamp(
            0.0,
            double.infinity,
          );
        }
        totalValue -= currentMonthlyWithdrawal;
      } else if (totalValue < currentMonthlyWithdrawal) {
        // 자산이 부족하면 0으로
        totalValue = 0.0;
        for (int i = 0; i < assetValues.length; i++) {
          assetValues[i] = 0.0;
        }
      }

      // 각 자산별 가치 기록
      for (int i = 0; i < normalizedAssets.length; i++) {
        assetPaths[normalizedAssets[i].assetId]!.add(assetValues[i]);
      }
      totalPath.add(totalValue);

      // 디버그: 매년 말 로그
      if ((month + 1) % 12 == 0) {
        final year = (month + 1) ~/ 12;
        // 인플레이션 적용된 총 인출액 계산
        double totalWithdrawn = 0.0;
        for (int y = 0; y < year; y++) {
          final yearWithdrawal =
              _monthlyWithdrawal * pow(1 + _inflationRate, y) * 12;
          totalWithdrawn += yearWithdrawal;
        }
        final netReturn = totalValue + totalWithdrawn - initialTotal;
        debugPrint(
          '${year}년 후: 자산 ${(totalValue / 100000000).toStringAsFixed(2)}억, 인출 누적 ${(totalWithdrawn / 100000000).toStringAsFixed(2)}억, 순수익 ${(netReturn / 100000000).toStringAsFixed(2)}억',
        );
      }
    }

    // 디버그: 최종 결과
    final finalAsset = totalPath.last;
    // 인플레이션 적용된 총 인출액 계산
    double totalWithdrawn = 0.0;
    for (int year = 0; year < _simulationYears; year++) {
      final yearWithdrawal =
          _monthlyWithdrawal * pow(1 + _inflationRate, year) * 12;
      totalWithdrawn += yearWithdrawal;
    }
    debugPrint('=== 시뮬레이션 완료 ===');
    debugPrint('최종 자산: ${(finalAsset / 100000000).toStringAsFixed(2)}억');
    debugPrint(
      '총 인출액 (인플레이션 적용): ${(totalWithdrawn / 100000000).toStringAsFixed(2)}억',
    );

    return {'total': totalPath, 'assets': assetPaths};
  }

  // 결과 요약 계산
  Map<String, dynamic> getSimulationSummary() {
    final simulationResults = runSimulation();
    final totalPath = simulationResults['total'] as List<double>? ?? [];

    if (totalPath.isEmpty) {
      return {
        'finalAsset': 0.0,
        'totalWithdrawn': 0.0,
        'totalReturn': 0.0,
        'cumulativeReturn': 0.0,
      };
    }

    final finalAsset = totalPath.last;
    // 인플레이션 적용된 총 인출액 계산
    double totalWithdrawn = 0.0;
    for (int year = 0; year < _simulationYears; year++) {
      final yearWithdrawal =
          _monthlyWithdrawal * pow(1 + _inflationRate, year) * 12;
      totalWithdrawn += yearWithdrawal;
    }
    // 총 수익 = 최종 자산 + 총 인출액 - 초기 자산
    // 누적 수익률 = 총 수익 / 초기 자산
    final totalReturn = finalAsset + totalWithdrawn - _initialAsset;
    final cumulativeReturn = totalReturn / _initialAsset;

    return {
      'finalAsset': finalAsset,
      'totalWithdrawn': totalWithdrawn,
      'totalReturn': totalReturn,
      'cumulativeReturn': cumulativeReturn,
    };
  }
}
