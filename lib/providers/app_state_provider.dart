import 'package:flutter/material.dart';
import '../models/investment_config.dart';
import '../models/calculation_result.dart';
import '../services/api_service.dart';

class AppStateProvider with ChangeNotifier {
  InvestmentConfig _config = InvestmentConfig();
  CalculationResult? _result;
  CalculationResult? _comparisonResult;
  bool _isLoading = false;
  String? _error;

  InvestmentConfig get config => _config;
  CalculationResult? get result => _result;
  CalculationResult? get comparisonResult => _comparisonResult;
  bool get isLoading => _isLoading;
  String? get error => _error;

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
    if (frequency != null) _config.frequency = frequency;

    notifyListeners();
  }

  Future<void> calculate() async {
    _isLoading = true;
    _error = null;
    _comparisonResult = null;
    notifyListeners();

    try {
      _result = await ApiService.calculate(_config);

      if (_config.type == InvestmentType.recurring) {
        final singleConfig = InvestmentConfig(
          asset: _config.asset,
          yearsAgo: _config.yearsAgo,
          amount: _config.amount,
          type: InvestmentType.single,
          frequency: Frequency.monthly,
        );
        _comparisonResult = await ApiService.calculate(singleConfig);
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
      _result = null;
      _comparisonResult = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _config = InvestmentConfig();
    _result = null;
    _comparisonResult = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
