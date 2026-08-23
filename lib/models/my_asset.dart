import 'dart:math' as math;

class MyAsset {
  final String id;
  final String assetId; // AssetOption의 id (커스텀: custom_*)
  final String assetName;
  final double initialAmount; // 투자 원금
  final DateTime registeredDate;
  final double quantity; // 보유 주수 (현재 평가 금액 / 입력 시점의 현재 가격)
  /// 현금 전용 연 이자율 (%). 예: 3.5 → 3.5%
  final double annualInterestRate;
  /// Yahoo Finance 심볼 (커스텀 종목용)
  final String? symbol;
  /// 자산 타입 (커스텀 종목용: crypto|stock|korean_stock|commodity|…)
  final String? assetType;
  double? currentValue; // 현재 가치 (quantity * 현재 가격으로 계산)

  MyAsset({
    required this.id,
    required this.assetId,
    required this.assetName,
    required this.initialAmount,
    required this.registeredDate,
    required this.quantity,
    this.annualInterestRate = 0,
    this.symbol,
    this.assetType,
    this.currentValue,
  });

  bool get isCustom =>
      assetId.startsWith('custom_') ||
      (symbol != null && symbol!.isNotEmpty);

  /// 현금 잔액 — 등록일부터 [at]까지 연복리 적용
  static double calculateCashValue({
    required double initialAmount,
    required double annualInterestRate,
    required DateTime registeredDate,
    required DateTime at,
  }) {
    if (at.isBefore(registeredDate)) return initialAmount;
    if (annualInterestRate == 0) return initialAmount;

    final days = at.difference(registeredDate).inDays;
    if (days <= 0) return initialAmount;

    final years = days / 365.0;
    return initialAmount *
        math.pow(1 + annualInterestRate / 100, years).toDouble();
  }

  double cashValueAt(DateTime at) {
    return calculateCashValue(
      initialAmount: initialAmount,
      annualInterestRate: annualInterestRate,
      registeredDate: registeredDate,
      at: at,
    );
  }

  MyAsset copyWith({
    String? id,
    String? assetId,
    String? assetName,
    double? initialAmount,
    DateTime? registeredDate,
    double? quantity,
    double? annualInterestRate,
    String? symbol,
    String? assetType,
    double? currentValue,
  }) {
    return MyAsset(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      assetName: assetName ?? this.assetName,
      initialAmount: initialAmount ?? this.initialAmount,
      registeredDate: registeredDate ?? this.registeredDate,
      quantity: quantity ?? this.quantity,
      annualInterestRate: annualInterestRate ?? this.annualInterestRate,
      symbol: symbol ?? this.symbol,
      assetType: assetType ?? this.assetType,
      currentValue: currentValue ?? this.currentValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assetId': assetId,
      'assetName': assetName,
      'initialAmount': initialAmount,
      'registeredDate': registeredDate.toIso8601String(),
      'quantity': quantity,
      'annualInterestRate': annualInterestRate,
      if (symbol != null) 'symbol': symbol,
      if (assetType != null) 'assetType': assetType,
      'currentValue': currentValue,
    };
  }

  factory MyAsset.fromJson(Map<String, dynamic> json) {
    double quantity;
    if (json['quantity'] != null) {
      quantity = (json['quantity'] as num).toDouble();
    } else if (json['currentValue'] != null && json['initialAmount'] != null) {
      quantity = 1.0;
    } else {
      quantity = 1.0;
    }

    final assetId = json['assetId'] as String;
    final annualInterestRate = json['annualInterestRate'] != null
        ? (json['annualInterestRate'] as num).toDouble()
        : 0.0;

    return MyAsset(
      id: json['id'] as String,
      assetId: assetId,
      assetName: json['assetName'] as String,
      initialAmount: (json['initialAmount'] as num).toDouble(),
      registeredDate: DateTime.parse(json['registeredDate'] as String),
      quantity: quantity,
      annualInterestRate: assetId == 'cash' ? annualInterestRate : 0,
      symbol: json['symbol'] as String?,
      assetType: json['assetType'] as String?,
      currentValue: json['currentValue'] != null
          ? (json['currentValue'] as num).toDouble()
          : null,
    );
  }
}
