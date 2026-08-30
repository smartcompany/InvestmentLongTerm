import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/asset.dart';
import '../models/my_asset.dart';
import '../models/retire_holding.dart';
import '../models/investment_config.dart';
import '../services/api_service.dart';
import '../utils/asset_currency.dart';
import '../utils/currency_converter.dart';
import 'app_state_provider.dart';
import 'currency_provider.dart';

class RetireSimulatorProvider with ChangeNotifier {
  static const String _krwBaselineCurrency = '₩';
  static const double _krwCashBaseline = 1000000; // 100만 원
  static const double _krwMonthlyBaseline = 5000000; // 500만 원

  /// 통화별 기본 현금·월 지출 (원화 기준 개념을 각 통화에 맞게 반올림)
  static const Map<String, ({double cash, double monthly})> _baselineByCurrency = {
    '₩': (cash: 1000000, monthly: 5000000),
    '\$': (cash: 800, monthly: 4000),
    '¥': (cash: 100000, monthly: 500000),
    'CN¥': (cash: 5000, monthly: 25000),
  };

  // UX: 현금 + 보유 자산(수량). 시뮬레이션은 평가금액 합 → allocation으로 변환.
  double _cash = _krwCashBaseline;
  double _monthlyWithdrawal = _krwMonthlyBaseline;
  int _simulationYears = 5;
  String _selectedScenario = 'neutral'; // 'positive', 'neutral', 'negative'
  double _inflationRate = 0.03; // 연간 인플레이션율 3% (기본값)
  String? _valuesCurrencySymbol; // _cash·_monthlyWithdrawal 이 표현된 통화
  final List<RetireHolding> _holdings = [];
  final List<Asset> _assets = []; // 시뮬레이션용 (allocation 포트폴리오)
  double _initialAsset = 1000000;
  final Map<String, double> _cagrCache = {}; // assetId -> CAGR 캐시
  final Map<String, bool> _loadingCagr = {}; // assetId -> 로딩 상태
  final Map<String, int> _cagrRetryCount = {}; // assetId -> 재시도 횟수
  /// 내 자산에서 가져온 일회성 세션(탭 상태와 분리)
  bool _portfolioFromMyAssets = false;

  RetireSimulatorProvider() {
    _rebuildSimulationAssets();
  }

  double get cash => _cash;
  double get initialAsset => _initialAsset;
  double get monthlyWithdrawal => _monthlyWithdrawal;
  int get simulationYears => _simulationYears;
  String get selectedScenario => _selectedScenario;
  double get inflationRate => _inflationRate;
  List<RetireHolding> get holdings => List.unmodifiable(_holdings);
  List<Asset> get assets => List.unmodifiable(_assets);
  Map<String, double> get cagrCache => Map.unmodifiable(_cagrCache);

  double get holdingsValue =>
      _holdings.fold(0.0, (sum, h) => sum + h.valuation);

  double get totalNetWorth => _cash + holdingsValue;

  bool get isLoadingAnyPrice => _holdings.any((h) => h.isLoadingPrice);

  bool get isLoadingAnyCagr =>
      _assets.any(
        (a) =>
            a.assetId != 'cash' &&
            a.annualReturn == null &&
            _loadingCagr[a.assetId] == true,
      );

  bool get canRunSimulation =>
      _assets.isNotEmpty &&
      _initialAsset > 0 &&
      allCagrLoaded &&
      !isLoadingAnyPrice;

  Future<void> _applyBaselineDefaults(String currencySymbol) async {
    final baselines = baselineAmountsForCurrency(currencySymbol);
    _cash = baselines.cash;
    _monthlyWithdrawal = baselines.monthly;
    _simulationYears = 5;
    _selectedScenario = 'neutral';
    _inflationRate = 0.03;
    _valuesCurrencySymbol = currencySymbol;
  }

  /// 은퇴 시뮬레이션 탭 진입 시: 모든 입력을 기본값으로 초기화합니다 (저장/복원 없음).
  Future<void> prepareSession(String currencySymbol) async {
    if (_portfolioFromMyAssets) return;

    _portfolioFromMyAssets = false;
    _holdings.clear();
    _assets.clear();
    await _applyBaselineDefaults(currencySymbol);
    _rebuildSimulationAssets();
    notifyListeners();
  }

  /// 내 자산 → 은퇴 시뮬 일회성 화면을 닫을 때 탭용 상태로 되돌립니다.
  Future<void> endMyAssetsSession(String currencySymbol) async {
    _portfolioFromMyAssets = false;
    await prepareSession(currencySymbol);
  }

  Future<double> _convertAmount(
    double amount,
    String fromCurrency,
    String toCurrency,
  ) async {
    if (fromCurrency == toCurrency) return amount;
    await CurrencyConverter.shared.waitUntilReady();
    final converted = await CurrencyConverter.shared.convert(
      amount,
      fromCurrency,
      toCurrency,
    );
    return _roundForCurrency(converted, toCurrency);
  }

  double _roundForCurrency(double value, String currencySymbol) {
    if (currencySymbol == '₩' || currencySymbol == '¥') {
      return value.roundToDouble();
    }
    if (currencySymbol == 'CN¥') {
      return (value * 10).round() / 10;
    }
    return (value * 100).round() / 100;
  }

  ({double cash, double monthly}) baselineAmountsForCurrency(
    String currencySymbol,
  ) {
    return _baselineByCurrency[currencySymbol] ??
        _baselineByCurrency[_krwBaselineCurrency]!;
  }

  bool _isAtBaselineForCurrency(String currencySymbol) {
    final baseline = baselineAmountsForCurrency(currencySymbol);
    return _cash == baseline.cash && _monthlyWithdrawal == baseline.monthly;
  }

  /// 표시 통화가 바뀌면 현금·월 인출·보유 단가를 변환합니다.
  /// 기본값 상태면 환율 변환 대신 해당 통화의 기본값을 사용합니다.
  Future<void> applyCurrencyChange(String newCurrencySymbol) async {
    final fromCurrency = _valuesCurrencySymbol ?? _krwBaselineCurrency;
    if (fromCurrency == newCurrencySymbol &&
        _valuesCurrencySymbol == newCurrencySymbol) {
      return;
    }

    if (fromCurrency != newCurrencySymbol) {
      if (_isAtBaselineForCurrency(fromCurrency)) {
        final baselines = baselineAmountsForCurrency(newCurrencySymbol);
        _cash = baselines.cash;
        _monthlyWithdrawal = baselines.monthly;
      } else {
        _cash = await _convertAmount(_cash, fromCurrency, newCurrencySymbol);
        _monthlyWithdrawal = await _convertAmount(
          _monthlyWithdrawal,
          fromCurrency,
          newCurrencySymbol,
        );
      }

      for (var i = 0; i < _holdings.length; i++) {
        final holding = _holdings[i];
        final price = holding.currentPrice;
        if (price == null) continue;
        _holdings[i] = holding.copyWith(
          currentPrice: await _convertAmount(
            price,
            fromCurrency,
            newCurrencySymbol,
          ),
        );
      }
    }

    _valuesCurrencySymbol = newCurrencySymbol;
    _rebuildSimulationAssets();
    notifyListeners();
  }

  @Deprecated('Use applyCurrencyChange')
  Future<void> updateCurrencyDefaults(String currencySymbol) =>
      applyCurrencyChange(currencySymbol);

  void setCash(double value) {
    _cash = value.clamp(0, double.infinity);
    _rebuildSimulationAssets();
    notifyListeners();
  }

  /// 하위 호환: 기존 코드용
  void setInitialAsset(double value) {
    setCash(value);
  }

  void setMonthlyWithdrawal(double value) {
    _monthlyWithdrawal = value.clamp(0, double.infinity);
    notifyListeners();
  }

  /// 내 자산 화면의 평가액을 그대로 가져와 은퇴 시뮬에 반영합니다.
  /// 가격을 다시 조회하지 않고, 내 자산과 동일한 통화 변환을 사용합니다.
  Future<void> importFromMyAssets(
    List<MyAsset> myAssets, {
    required AppStateProvider appProvider,
  }) async {
    _holdings.clear();
    _assets.clear();
    _cash = 0;
    _portfolioFromMyAssets = true;

    final targetCurrency = CurrencyProvider.shared.getCurrencySymbol();
    await CurrencyConverter.shared.waitUntilReady();

    final mergedHoldings = <String, RetireHolding>{};
    final mergedValuations = <String, double>{};

    for (final asset in myAssets) {
      final assetId = asset.assetId;
      final quantity = asset.quantity;
      final symbol = asset.symbol;
      final assetName = asset.assetName;

      // 카탈로그 타입으로 보완 (samsung 등 assetType이 비어 있는 경우)
      String? assetType = asset.assetType;
      if (assetType == null || assetType.isEmpty) {
        try {
          assetType = appProvider.assets.firstWhere((a) => a.id == assetId).type;
        } catch (_) {}
      }

      final rawValue = asset.currentValue ?? asset.initialAmount;
      final fromCurrency = AssetCurrency.originalCurrency(
        assetId,
        appProvider,
        assetType: assetType,
      );
      final displayValue = fromCurrency == targetCurrency
          ? rawValue
          : await CurrencyConverter.shared.convert(
              rawValue,
              fromCurrency,
              targetCurrency,
            );

      if (assetId == 'cash') {
        _cash += displayValue;
        continue;
      }

      final mergeKey = '${assetId}::${symbol ?? ''}::${assetType ?? ''}';
      mergedValuations[mergeKey] =
          (mergedValuations[mergeKey] ?? 0) + displayValue;

      final existing = mergedHoldings[mergeKey];
      if (existing != null) {
        mergedHoldings[mergeKey] = existing.copyWith(
          quantity: existing.quantity + quantity,
        );
      } else {
        mergedHoldings[mergeKey] = RetireHolding(
          assetId: assetId,
          assetName: assetName,
          assetType: assetType,
          symbol: symbol,
          quantity: quantity,
          isLoadingPrice: false,
        );
      }
    }

    for (final entry in mergedHoldings.entries) {
      final holding = entry.value;
      final totalValue = mergedValuations[entry.key] ?? 0;
      final unitPrice =
          holding.quantity > 0 && totalValue > 0
              ? totalValue / holding.quantity
              : null;
      _holdings.add(
        holding.copyWith(
          currentPrice: unitPrice,
          isLoadingPrice: false,
        ),
      );
    }

    _valuesCurrencySymbol = targetCurrency;
    _rebuildSimulationAssets();
    notifyListeners();
  }

  Future<void> addHolding(
    String assetId, {
    double quantity = 1,
    String? assetType,
  }) async {
    if (assetId == 'cash') return;
    if (_holdings.any((h) => h.assetId == assetId)) return;

    _holdings.add(
      RetireHolding(
        assetId: assetId,
        assetType: assetType,
        quantity: quantity,
        isLoadingPrice: true,
      ),
    );
    _rebuildSimulationAssets();
    notifyListeners();
    await _loadPriceForHolding(assetId, type: assetType);
  }

  int _holdingIndex(
    String assetId, {
    String? symbol,
    String? type,
  }) {
    return _holdings.indexWhere((h) {
      if (h.assetId != assetId) return false;
      if (symbol != null && h.symbol != symbol) return false;
      if (type != null && h.assetType != type) return false;
      return true;
    });
  }

  void updateHoldingQuantity(String assetId, double quantity) {
    final index = _holdings.indexWhere((h) => h.assetId == assetId);
    if (index < 0) return;
    _holdings[index] = _holdings[index].copyWith(
      quantity: quantity.clamp(0, double.infinity),
    );
    _rebuildSimulationAssets();
    notifyListeners();
  }

  void removeHolding(String assetId) {
    _holdings.removeWhere((h) => h.assetId == assetId);
    _rebuildSimulationAssets();
    notifyListeners();
  }

  Future<void> _loadPriceForHolding(
    String assetId, {
    String? symbol,
    String? type,
  }) async {
    final index = _holdingIndex(assetId, symbol: symbol, type: type);
    if (index < 0) return;

    _holdings[index] = _holdings[index].copyWith(isLoadingPrice: true);
    notifyListeners();

    try {
      double? price = await ApiService.fetchLatestPrice(
        assetId,
        days: _simulationYears * 365,
        symbol: symbol,
        type: type,
      );

      if (price != null && price.isFinite && price > 0) {
        final idxForFx = _holdingIndex(assetId, symbol: symbol, type: type);
        if (idxForFx >= 0) {
          final holding = _holdings[idxForFx];
          final targetCurrency = CurrencyProvider.shared.getCurrencySymbol();
          await CurrencyConverter.shared.waitUntilReady();
          price = await CurrencyConverter.shared.convert(
            price,
            holding.sourceCurrency,
            targetCurrency,
          );
        }
      }

      final idx = _holdingIndex(assetId, symbol: symbol, type: type);
      if (idx >= 0) {
        _holdings[idx] = _holdings[idx].copyWith(
          currentPrice:
              (price != null && price.isFinite && price > 0) ? price : null,
          isLoadingPrice: false,
        );
      }
    } catch (e) {
      debugPrint('Failed to load holding price for $assetId: $e');
      final idx = _holdingIndex(assetId, symbol: symbol, type: type);
      if (idx >= 0) {
        _holdings[idx] = _holdings[idx].copyWith(isLoadingPrice: false);
      }
    } finally {
      final idx = _holdingIndex(assetId, symbol: symbol, type: type);
      if (idx >= 0 && _holdings[idx].isLoadingPrice) {
        _holdings[idx] = _holdings[idx].copyWith(isLoadingPrice: false);
      }
    }

    _rebuildSimulationAssets();
    notifyListeners();
  }

  void _rebuildSimulationAssets() {
    final parts = <({String id, double value})>[];
    if (_cash > 0) {
      parts.add((id: 'cash', value: _cash));
    }
    for (final h in _holdings) {
      final v = h.valuation;
      if (v > 0) {
        parts.add((id: h.assetId, value: v));
      }
    }

    final total = parts.fold<double>(0, (s, p) => s + p.value);
    _initialAsset = total;

    // 기존 CAGR 유지하면서 allocation만 갱신
    final previousReturns = <String, double?>{
      for (final a in _assets) a.assetId: a.annualReturn,
    };

    _assets
      ..clear()
      ..addAll(
        parts.map((p) {
          final cached = _cagrCache[p.id] ?? previousReturns[p.id];
          return Asset(
            assetId: p.id,
            allocation: total > 0 ? p.value / total : 0,
            annualReturn: p.id == 'cash' ? 0.021 : cached,
          );
        }),
      );

    for (final asset in _assets) {
      if (asset.assetId != 'cash' && asset.annualReturn == null) {
        Future.microtask(() {
          _loadCagrForAsset(asset.assetId).catchError((error) {
            debugPrint('CAGR 로드 실패 (${asset.assetId}): $error');
            _loadingCagr[asset.assetId] = false;
            notifyListeners();
          });
        });
      } else if (asset.assetId == 'cash') {
        _cagrCache['cash'] = 0.021;
        _loadingCagr['cash'] = false;
      }
    }
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
    // 0.1% 단위로 스냅 (표시 소수 첫째 자리와 동일)
    final clamped = value.clamp(0.0, 0.1);
    _inflationRate = (clamped * 1000).round() / 1000;
    notifyListeners();
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

    // UI 업데이트 (자산 추가 반영)
    notifyListeners();

    // 현금 자산이 아닌 경우에만 API 호출
    if (assetId != 'cash') {
      // 다음 프레임에서 CAGR 로드 시작 (UI 업데이트 후 실행되도록)
      // 이렇게 하면 자산이 UI에 먼저 표시되고, 그 다음에 로딩 상태가 표시됨
      Future.microtask(() {
        _loadCagrForAsset(assetId).catchError((error) {
          debugPrint('CAGR 로드 실패 ($assetId): $error');
          // 에러 발생 시 로딩 상태 해제
          _loadingCagr[assetId] = false;
          notifyListeners();
        });
      });
    } else {
      // 현금 자산은 캐시에 저장하고 로딩 상태 설정
      _cagrCache[assetId] = 0.021;
      _loadingCagr[assetId] = false;
      notifyListeners();
    }
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
    // 캐시에 이미 있으면 스킵, 로딩 중이면 재시도가 아닌 경우에만 스킵
    if (!isRetry) {
      if (_cagrCache.containsKey(assetId)) {
        // 캐시에 있으면 자산의 annualReturn도 업데이트
        final cachedCagr = _cagrCache[assetId]!;
        final assetIndex = _assets.indexWhere((a) => a.assetId == assetId);
        if (assetIndex >= 0 && _assets[assetIndex].annualReturn == null) {
          _assets[assetIndex] = _assets[assetIndex].copyWith(
            annualReturn: cachedCagr,
          );
          notifyListeners();
        }
        return; // 이미 로드됨
      }
      // 로딩 중이면 스킵 (재시도가 아닌 경우에만)
      if (_loadingCagr[assetId] == true) {
        return; // 이미 로딩 중
      }
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
      // 음수 CAGR의 경우 clamp 순서 주의 (음수에서는 절댓값이 작을수록 더 큰 값)
      if (cagr5y >= 0) {
        // 양수: min < max
        final minCagr = cagr5y * 0.8;
        final maxCagr = cagr5y;
        adjustedCagr = adjustedCagr.clamp(minCagr, maxCagr);
      } else {
        // 음수: 절댓값이 작을수록 더 큰 값이므로 max < min
        // 예: -0.04 (80%) > -0.05 (100%)
        final maxCagr = cagr5y * 0.8; // 더 작은 손실 (더 큰 값)
        final minCagr = cagr5y; // 더 큰 손실 (더 작은 값)
        adjustedCagr = adjustedCagr.clamp(minCagr, maxCagr);
      }

      // CAGR이 -1보다 작으면 (100% 이상 손실) -0.99로 제한 (pow 계산 안전성)
      adjustedCagr = adjustedCagr.clamp(-0.99, double.infinity);

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
      debugPrint('Error details: ${e.toString()}');

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
        await _loadCagrForAsset(assetId, isRetry: true);
        return;
      } else {
        // 최대 재시도 횟수 초과 시 0% 수익률로 폴백 (시뮬레이션 진행 가능)
        const fallbackCagr = 0.0;
        debugPrint(
          'CAGR 로드 최종 실패 ($assetId): 재시도 횟수 초과. 0%로 폴백. 에러: $e',
        );
        _cagrCache[assetId] = fallbackCagr;
        final assetIndex = _assets.indexWhere((a) => a.assetId == assetId);
        if (assetIndex >= 0) {
          _assets[assetIndex] = _assets[assetIndex].copyWith(
            annualReturn: fallbackCagr,
          );
        }
        _cagrRetryCount[assetId] = 0;
        _loadingCagr[assetId] = false;
      }
    } finally {
      _loadingCagr[assetId] = false;
      notifyListeners();
    }
  }

  bool isLoadingCagr(String assetId) {
    return _loadingCagr[assetId] == true;
  }

  // CAGR 수동 재시도 메서드
  Future<void> retryLoadCagr(String assetId) async {
    // 캐시와 재시도 카운트 초기화
    _cagrCache.remove(assetId);
    _cagrRetryCount[assetId] = 0;
    _loadingCagr[assetId] = false;

    // 재시도
    await _loadCagrForAsset(assetId);
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
      return {
        'total': <double>[],
        'assets': <String, List<double>>{},
        'withdrawals': <double>[],
        'totalWithdrawn': 0.0,
      };
    }

    // 비중 정규화
    final totalAlloc = totalAllocation;
    if (totalAlloc <= 0) {
      return {
        'total': <double>[],
        'assets': <String, List<double>>{},
        'withdrawals': <double>[],
        'totalWithdrawn': 0.0,
      };
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
    double totalWithdrawnAccumulated = 0.0;
    final withdrawalPath = <double>[0.0];

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
      double actualWithdrawal = 0.0;
      if (totalValue > 0) {
        actualWithdrawal = totalValue >= currentMonthlyWithdrawal
            ? currentMonthlyWithdrawal
            : totalValue;
        for (int i = 0; i < normalizedAssets.length; i++) {
          final assetRatio = assetValues[i] / totalValue;
          final withdrawalAmount = actualWithdrawal * assetRatio;
          assetValues[i] = (assetValues[i] - withdrawalAmount).clamp(
            0.0,
            double.infinity,
          );
        }
        totalValue -= actualWithdrawal;
        totalWithdrawnAccumulated += actualWithdrawal;
      }
      withdrawalPath.add(actualWithdrawal);

      // 각 자산별 가치 기록
      for (int i = 0; i < normalizedAssets.length; i++) {
        assetPaths[normalizedAssets[i].assetId]!.add(assetValues[i]);
      }
      totalPath.add(totalValue);

      // 디버그: 매년 말 로그
      if ((month + 1) % 12 == 0) {
        final year = (month + 1) ~/ 12;
        final netReturn = totalValue + totalWithdrawnAccumulated - initialTotal;
        debugPrint(
          '${year}년 후: 자산 ${(totalValue / 100000000).toStringAsFixed(2)}억, 인출 누적 ${(totalWithdrawnAccumulated / 100000000).toStringAsFixed(2)}억, 순수익 ${(netReturn / 100000000).toStringAsFixed(2)}억',
        );
      }
    }

    // 디버그: 최종 결과
    final finalAsset = totalPath.last;
    debugPrint('=== 시뮬레이션 완료 ===');
    debugPrint('최종 자산: ${(finalAsset / 100000000).toStringAsFixed(2)}억');
    debugPrint(
      '총 인출액 (실제): ${(totalWithdrawnAccumulated / 100000000).toStringAsFixed(2)}억',
    );

    return {
      'total': totalPath,
      'assets': assetPaths,
      'withdrawals': withdrawalPath,
      'totalWithdrawn': totalWithdrawnAccumulated,
    };
  }

  // 결과 요약 계산
  Map<String, dynamic> getSimulationSummary([
    Map<String, dynamic>? simulationResults,
  ]) {
    final simulationResultsResolved =
        simulationResults ?? runSimulation();
    final totalPath =
        simulationResultsResolved['total'] as List<double>? ?? [];

    if (totalPath.isEmpty) {
      return {
        'finalAsset': 0.0,
        'totalWithdrawn': 0.0,
        'totalReturn': 0.0,
        'cumulativeReturn': 0.0,
      };
    }

    final finalAsset = totalPath.last;
    final totalWithdrawn =
        simulationResultsResolved['totalWithdrawn'] as double? ?? 0.0;
    // 총 수익 = 최종 자산 + 총 인출액 - 초기 자산
    // 누적 수익률 = 총 수익 / 초기 자산
    final totalReturn = finalAsset + totalWithdrawn - _initialAsset;
    final cumulativeReturn =
        _initialAsset > 0 ? totalReturn / _initialAsset : 0.0;

    return {
      'finalAsset': finalAsset,
      'totalWithdrawn': totalWithdrawn,
      'totalReturn': totalReturn,
      'cumulativeReturn': cumulativeReturn,
    };
  }
}
