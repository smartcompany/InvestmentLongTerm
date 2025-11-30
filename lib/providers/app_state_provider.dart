import 'package:flutter/material.dart';
import '../models/investment_config.dart';
import '../models/calculation_result.dart';
import '../utils/calculator.dart';

class AppStateProvider with ChangeNotifier {
  InvestmentConfig _config = InvestmentConfig();
  CalculationResult? _result;

  InvestmentConfig get config => _config;
  CalculationResult? get result => _result;

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

  void calculate() {
    _result = InvestmentCalculator.calculate(_config);
    notifyListeners();
  }

  void reset() {
    _config = InvestmentConfig();
    _result = null;
    notifyListeners();
  }
}
