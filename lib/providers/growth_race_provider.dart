import 'package:flutter/material.dart';
import '../models/asset_option.dart';
import '../services/api_service.dart';

class GrowthRaceProvider with ChangeNotifier {
  final Set<String> _selectedAssetIds = {};
  final Map<String, AssetOption> _customAssets = {};
  int _selectedYears = 5;
  bool _isLoading = false;
  bool _isRacing = false;
  Map<String, List<Map<String, dynamic>>> _priceData =
      {}; // assetId -> price data
  Map<String, double> _currentGrowthRates =
      {}; // assetId -> current growth rate
  List<String> _rankedAssetIds = []; // 순위별 assetId 목록
  DateTime? _raceStartDate;
  DateTime? _currentDate;

  Set<String> get selectedAssetIds => Set.unmodifiable(_selectedAssetIds);
  Map<String, AssetOption> get customAssets => Map.unmodifiable(_customAssets);
  int get selectedYears => _selectedYears;
  bool get isLoading => _isLoading;
  bool get isRacing => _isRacing;
  Map<String, List<Map<String, dynamic>>> get priceData =>
      Map.unmodifiable(_priceData);
  Map<String, double> get currentGrowthRates =>
      Map.unmodifiable(_currentGrowthRates);
  List<String> get rankedAssetIds => List.unmodifiable(_rankedAssetIds);
  DateTime? get raceStartDate => _raceStartDate;
  DateTime? get currentDate => _currentDate;

  /// 카탈로그 + 직접 입력 자산에서 id로 조회
  AssetOption? resolveAsset(String assetId, List<AssetOption> catalog) {
    for (final asset in catalog) {
      if (asset.id == assetId) return asset;
    }
    return _customAssets[assetId];
  }

  List<AssetOption> customAssetsOfType(String type) {
    return _customAssets.values.where((a) => a.type == type).toList();
  }

  void toggleAsset(String assetId) {
    if (_selectedAssetIds.contains(assetId)) {
      _selectedAssetIds.remove(assetId);
    } else {
      _selectedAssetIds.add(assetId);
    }
    notifyListeners();
  }

  /// 검색으로 고른 종목을 비교 목록에 넣고 선택합니다.
  void selectCustomAsset({
    required String id,
    required String name,
    required String symbol,
    required String type,
  }) {
    final option = AssetOption(
      id: id,
      type: type,
      symbol: symbol.isNotEmpty ? symbol : id,
      icon: '📈',
      names: {
        'en': name,
        'ko': name,
        'ja': name,
        'zh': name,
      },
    );
    _customAssets[id] = option;
    _selectedAssetIds.add(id);
    notifyListeners();
  }

  void setSelectedYears(int years) {
    _selectedYears = years;
    notifyListeners();
  }

  /// 온보딩/데모용 — 선택 자산·기간을 한 번에 설정합니다.
  void prepareDemoRace({
    required Iterable<String> assetIds,
    required int years,
  }) {
    _selectedAssetIds
      ..clear()
      ..addAll(assetIds);
    _selectedYears = years;
    _isLoading = false;
    _isRacing = false;
    _priceData.clear();
    _currentGrowthRates.clear();
    _rankedAssetIds = assetIds.toList();
    _raceStartDate = null;
    _currentDate = null;
    notifyListeners();
  }

  Future<void> loadPriceData() async {
    if (_selectedAssetIds.isEmpty) return;

    _isLoading = true;
    _priceData.clear();
    notifyListeners();

    try {
      final days = _selectedYears * 365;
      final futures = _selectedAssetIds.map((assetId) async {
        try {
          final custom = _customAssets[assetId];
          final data = await ApiService.fetchDailyPrices(
            assetId,
            days,
            symbol: custom?.symbol,
            type: custom?.type,
          );
          // 날짜 기준으로 정렬 (오래된 것부터)
          final sortedData = List<Map<String, dynamic>>.from(data)
            ..sort((a, b) {
              final dateA = a['date'] as String?;
              final dateB = b['date'] as String?;
              if (dateA == null || dateB == null) return 0;
              return dateA.compareTo(dateB);
            });
          return MapEntry(assetId, sortedData);
        } catch (e) {
          debugPrint('Failed to load price data for $assetId: $e');
          return MapEntry(assetId, <Map<String, dynamic>>[]);
        }
      });

      final results = await Future.wait(futures);
      for (final entry in results) {
        _priceData[entry.key] = entry.value;
      }
    } catch (e) {
      debugPrint('Error loading price data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void startRace() {
    if (_selectedAssetIds.isEmpty || _priceData.isEmpty) return;

    _isRacing = true;
    _currentDate = null;
    _currentGrowthRates.clear();
    _rankedAssetIds = _selectedAssetIds.toList();
    _raceStartDate = DateTime.now();

    // 모든 자산의 첫 번째 날짜를 찾아서 가장 오래된 날짜로 설정
    DateTime? earliestDate;
    for (final assetId in _selectedAssetIds) {
      final data = _priceData[assetId];
      if (data != null && data.isNotEmpty) {
        try {
          final firstDateStr = data[0]['date'] as String?;
          if (firstDateStr != null) {
            final date = DateTime.parse(firstDateStr);
            if (earliestDate == null || date.isBefore(earliestDate)) {
              earliestDate = date;
            }
          }
        } catch (e) {
          // 날짜 파싱 실패 시 무시
        }
      }
    }

    if (earliestDate != null) {
      _currentDate = earliestDate;
    }

    notifyListeners();
  }

  void stopRace() {
    _isRacing = false;
    _currentDate = null;
    notifyListeners();
  }

  void updateRaceDate(DateTime date) {
    if (!_isRacing) return;
    _currentDate = date;

    // 각 자산의 현재 성장률 계산
    _currentGrowthRates.clear();

    for (final assetId in _selectedAssetIds) {
      final data = _priceData[assetId];
      if (data != null && data.isNotEmpty) {
        final firstPrice = (data[0]['price'] as num).toDouble();

        // 해당 날짜에 데이터가 있으면 사용, 없으면 가장 가까운 과거 데이터 사용
        // 데이터가 날짜순으로 정렬되어 있으므로 역순으로 확인
        double currentPrice = firstPrice;
        for (int i = data.length - 1; i >= 0; i--) {
          try {
            final dateStr = data[i]['date'] as String?;
            if (dateStr != null) {
              final dataDate = DateTime.parse(dateStr);
              if (!dataDate.isAfter(date)) {
                currentPrice = (data[i]['price'] as num).toDouble();
                break;
              }
            }
          } catch (e) {
            // 날짜 파싱 실패 시 무시
          }
        }

        if (firstPrice > 0) {
          final growthRate = ((currentPrice - firstPrice) / firstPrice) * 100;
          _currentGrowthRates[assetId] = growthRate;
        }
      }
    }

    // 성장률에 따라 순위 재정렬 (내림차순)
    _rankedAssetIds = _selectedAssetIds.toList();
    _rankedAssetIds.sort((a, b) {
      final rateA = _currentGrowthRates[a] ?? 0;
      final rateB = _currentGrowthRates[b] ?? 0;
      return rateB.compareTo(rateA);
    });

    notifyListeners();
  }

  void reset() {
    _selectedAssetIds.clear();
    _customAssets.clear();
    _selectedYears = 5;
    _isLoading = false;
    _isRacing = false;
    _priceData.clear();
    _currentGrowthRates.clear();
    _rankedAssetIds.clear();
    _raceStartDate = null;
    _currentDate = null;
    notifyListeners();
  }
}
