import 'package:flutter/material.dart';
import '../services/api_service.dart';

class GrowthRaceProvider with ChangeNotifier {
  final Set<String> _selectedAssetIds = {};
  int _selectedYears = 5;
  bool _isLoading = false;
  bool _isRacing = false;
  Map<String, List<Map<String, dynamic>>> _priceData =
      {}; // assetId -> price data
  Map<String, double> _currentGrowthRates =
      {}; // assetId -> current growth rate
  List<String> _rankedAssetIds = []; // 순위별 assetId 목록
  DateTime? _raceStartDate;
  double _progress = 0.0; // 0.0 ~ 1.0 진행도

  Set<String> get selectedAssetIds => Set.unmodifiable(_selectedAssetIds);
  int get selectedYears => _selectedYears;
  bool get isLoading => _isLoading;
  bool get isRacing => _isRacing;
  Map<String, List<Map<String, dynamic>>> get priceData =>
      Map.unmodifiable(_priceData);
  Map<String, double> get currentGrowthRates =>
      Map.unmodifiable(_currentGrowthRates);
  List<String> get rankedAssetIds => List.unmodifiable(_rankedAssetIds);
  DateTime? get raceStartDate => _raceStartDate;
  double get progress => _progress;

  void toggleAsset(String assetId) {
    if (_selectedAssetIds.contains(assetId)) {
      _selectedAssetIds.remove(assetId);
    } else {
      _selectedAssetIds.add(assetId);
    }
    notifyListeners();
  }

  void setSelectedYears(int years) {
    _selectedYears = years;
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
          final data = await ApiService.fetchDailyPrices(assetId, days);
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
    _progress = 0.0;
    _currentGrowthRates.clear();
    _rankedAssetIds = _selectedAssetIds.toList();
    _raceStartDate = DateTime.now();

    // 모든 자산의 첫 번째 가격을 기준으로 정렬 (초기 순위)
    if (_priceData.isNotEmpty) {
      final firstPrices = <String, double>{};
      for (final assetId in _selectedAssetIds) {
        final data = _priceData[assetId];
        if (data != null && data.isNotEmpty) {
          firstPrices[assetId] = (data[0]['price'] as num).toDouble();
        }
      }
      // 초기 순위는 첫 가격 기준 (내림차순, 높은 가격이 위)
      _rankedAssetIds.sort(
        (a, b) => (firstPrices[a] ?? 0).compareTo(firstPrices[b] ?? 0),
      );
    }

    notifyListeners();
  }

  void stopRace() {
    _isRacing = false;
    _progress = 0.0;
    notifyListeners();
  }

  void updateRaceProgress(double progress) {
    if (!_isRacing) return;
    _progress = progress.clamp(0.0, 1.0);

    // 각 자산의 현재 성장률 계산
    _currentGrowthRates.clear();
    final firstPrices = <String, double>{};
    final currentPrices = <String, double>{};

    for (final assetId in _selectedAssetIds) {
      final data = _priceData[assetId];
      if (data != null && data.isNotEmpty) {
        final firstPrice = (data[0]['price'] as num).toDouble();
        // 진행도에 비례한 인덱스 계산
        final currentIndex = ((progress * (data.length - 1))).round().clamp(
          0,
          data.length - 1,
        );
        final currentPrice = (data[currentIndex]['price'] as num).toDouble();

        firstPrices[assetId] = firstPrice;
        currentPrices[assetId] = currentPrice;

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
    _selectedYears = 5;
    _isLoading = false;
    _isRacing = false;
    _priceData.clear();
    _currentGrowthRates.clear();
    _rankedAssetIds.clear();
    _raceStartDate = null;
    _progress = 0.0;
    notifyListeners();
  }
}
