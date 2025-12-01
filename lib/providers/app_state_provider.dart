import 'package:flutter/material.dart';
import '../models/investment_config.dart';
import '../models/calculation_result.dart';
import '../models/asset_option.dart';
import '../services/api_service.dart';

class AppStateProvider with ChangeNotifier {
  InvestmentConfig _config = InvestmentConfig();
  CalculationResult? _result;
  CalculationResult? _singleResult;
  final Map<Frequency, CalculationResult> _recurringResults = {};
  final List<AssetOption> _assets = [];
  bool _isLoading = false;
  bool _isAssetsLoading = false;
  String? _error;
  String? _assetsError;

  InvestmentConfig get config => _config;
  CalculationResult? get result => _result;
  CalculationResult? get singleResult => _singleResult;
  Map<Frequency, CalculationResult> get recurringResults =>
      Map.unmodifiable(_recurringResults);
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<AssetOption> get assets => List.unmodifiable(_assets);
  bool get isAssetsLoading => _isAssetsLoading;
  String? get assetsError => _assetsError;
  AssetOption? get selectedAsset =>
      _assets.where((asset) => asset.id == _config.asset).firstOrNull;

  void updateConfig({
    String? asset,
    int? yearsAgo,
    double? amount,
    InvestmentType? type,
    Frequency? frequency,
  }) {
    if (asset != null) _config.asset = asset;
    if (yearsAgo != null) _config.yearsAgo = yearsAgo;
    if (amount != null) _config.amount = amount;
    if (type != null) _config.type = type;
    if (frequency != null) {
      _config.frequency = frequency;
      _config.selectedFrequencies
        ..clear()
        ..add(frequency);
    }

    notifyListeners();
  }

  Future<void> loadAssets() async {
    if (_isAssetsLoading || _assets.isNotEmpty) return;
    _isAssetsLoading = true;
    notifyListeners();

    try {
      final fetched = await ApiService.fetchAssets();
      _assets
        ..clear()
        ..addAll(fetched);

      if (_assets.isNotEmpty) {
        final current = _assets.firstWhere(
          (asset) => asset.id == _config.asset,
          orElse: () => _assets.first,
        );
        _config.asset = current.id;
        if (current.defaultYearsAgo != null) {
          _config.yearsAgo = current.defaultYearsAgo!;
        }
      }

      _assetsError = null;
    } catch (e) {
      _assetsError = e.toString();
    } finally {
      _isAssetsLoading = false;
      notifyListeners();
    }
  }

  void selectAsset(AssetOption asset) {
    _config.asset = asset.id;
    if (asset.defaultYearsAgo != null) {
      _config.yearsAgo = asset.defaultYearsAgo!;
    }
    notifyListeners();
  }

  String assetNameForLocale(String localeCode, {String? assetId}) {
    final targetId = assetId ?? _config.asset;
    final asset = _assets.firstWhereOrNull((item) => item.id == targetId);
    return asset?.displayName(localeCode) ?? targetId;
  }

  void toggleFrequencySelection(Frequency frequency) {
    if (_config.selectedFrequencies.contains(frequency)) {
      if (_config.selectedFrequencies.length == 1) {
        return;
      }
      _config.selectedFrequencies.remove(frequency);
    } else {
      _config.selectedFrequencies.add(frequency);
    }
    _config.frequency = _config.selectedFrequencies.first;
    notifyListeners();
  }

  Future<void> calculate() async {
    _isLoading = true;
    _error = null;
    _singleResult = null;
    _recurringResults.clear();
    notifyListeners();

    try {
      if (_config.type == InvestmentType.single) {
        _result = await ApiService.calculate(_config);
        _singleResult = _result;
      } else {
        final singleConfig = InvestmentConfig(
          asset: _config.asset,
          yearsAgo: _config.yearsAgo,
          amount: _config.amount,
          type: InvestmentType.single,
          frequency: Frequency.monthly,
        );

        final selectedFrequencies = _config.selectedFrequencies.isNotEmpty
            ? _config.selectedFrequencies
            : {Frequency.monthly};

        final recurringFutures = selectedFrequencies.map((frequency) async {
          final recurringConfig = InvestmentConfig(
            asset: _config.asset,
            yearsAgo: _config.yearsAgo,
            amount: _config.amount,
            type: InvestmentType.recurring,
            frequency: frequency,
          );
          final result = await ApiService.calculate(recurringConfig);
          return MapEntry(frequency, result);
        }).toList();

        final singleFuture = ApiService.calculate(singleConfig);
        final recurringResults = await Future.wait(recurringFutures);
        _singleResult = await singleFuture;

        for (final entry in recurringResults) {
          _recurringResults[entry.key] = entry.value;
        }

        _result = recurringResults.isNotEmpty
            ? recurringResults.first.value
            : _singleResult;
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
      _result = null;
      _singleResult = null;
      _recurringResults.clear();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    final currentAsset = _config.asset;
    _config = InvestmentConfig(asset: currentAsset);
    final asset = _assets.firstWhereOrNull((item) => item.id == currentAsset);
    if (asset?.defaultYearsAgo != null) {
      _config.yearsAgo = asset!.defaultYearsAgo!;
    }
    _result = null;
    _singleResult = null;
    _recurringResults.clear();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}

extension _IterableHelpers<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }

  E? get firstOrNull {
    if (isEmpty) return null;
    return first;
  }
}
