class MyAsset {
  final String id;
  final String assetId; // AssetOption의 id
  final String assetName;
  final double initialAmount;
  final DateTime registeredDate;
  double? currentValue; // 현재 가치 (일봉 데이터로 계산)

  MyAsset({
    required this.id,
    required this.assetId,
    required this.assetName,
    required this.initialAmount,
    required this.registeredDate,
    this.currentValue,
  });

  MyAsset copyWith({
    String? id,
    String? assetId,
    String? assetName,
    double? initialAmount,
    DateTime? registeredDate,
    double? currentValue,
  }) {
    return MyAsset(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      assetName: assetName ?? this.assetName,
      initialAmount: initialAmount ?? this.initialAmount,
      registeredDate: registeredDate ?? this.registeredDate,
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
      'currentValue': currentValue,
    };
  }

  factory MyAsset.fromJson(Map<String, dynamic> json) {
    return MyAsset(
      id: json['id'] as String,
      assetId: json['assetId'] as String,
      assetName: json['assetName'] as String,
      initialAmount: (json['initialAmount'] as num).toDouble(),
      registeredDate: DateTime.parse(json['registeredDate'] as String),
      currentValue: json['currentValue'] != null
          ? (json['currentValue'] as num).toDouble()
          : null,
    );
  }
}
