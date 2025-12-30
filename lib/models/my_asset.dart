class MyAsset {
  final String id;
  final String assetId; // AssetOption의 id
  final String assetName;
  final double initialAmount; // 투자 원금
  final DateTime registeredDate;
  final double quantity; // 보유 주수 (현재 평가 금액 / 입력 시점의 현재 가격)
  double? currentValue; // 현재 가치 (quantity * 현재 가격으로 계산)

  MyAsset({
    required this.id,
    required this.assetId,
    required this.assetName,
    required this.initialAmount,
    required this.registeredDate,
    required this.quantity,
    this.currentValue,
  });

  MyAsset copyWith({
    String? id,
    String? assetId,
    String? assetName,
    double? initialAmount,
    DateTime? registeredDate,
    double? quantity,
    double? currentValue,
  }) {
    return MyAsset(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      assetName: assetName ?? this.assetName,
      initialAmount: initialAmount ?? this.initialAmount,
      registeredDate: registeredDate ?? this.registeredDate,
      quantity: quantity ?? this.quantity,
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
      'currentValue': currentValue,
    };
  }

  factory MyAsset.fromJson(Map<String, dynamic> json) {
    // 기존 데이터 호환성: quantity가 없으면 currentValue / initialAmount로 역산
    double quantity;
    if (json['quantity'] != null) {
      quantity = (json['quantity'] as num).toDouble();
    } else if (json['currentValue'] != null && json['initialAmount'] != null) {
      // 기존 데이터: quantity를 추정하기 위해 1.0으로 설정 (나중에 업데이트됨)
      quantity = 1.0;
    } else {
      quantity = 1.0;
    }

    return MyAsset(
      id: json['id'] as String,
      assetId: json['assetId'] as String,
      assetName: json['assetName'] as String,
      initialAmount: (json['initialAmount'] as num).toDouble(),
      registeredDate: DateTime.parse(json['registeredDate'] as String),
      quantity: quantity,
      currentValue: json['currentValue'] != null
          ? (json['currentValue'] as num).toDouble()
          : null,
    );
  }
}
