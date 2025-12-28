import 'dart:math' as math;

class Asset {
  final String assetId; // AssetOption의 id
  final double allocation; // 비중 (0.0 ~ 1.0)
  double? annualReturn; // 연 평균 수익률 (CAGR, API에서 가져옴, null이면 로딩 중)

  Asset({
    required this.assetId,
    required this.allocation,
    this.annualReturn,
  });

  String get name => assetId; // 임시, 나중에 AssetOption에서 가져올 예정

  // 월 복리 수익률 계산: (1 + r)^(1/12) - 1
  double get monthlyReturn {
    if (annualReturn == null) return 0.0;
    // -1보다 작으면 pow 계산 에러 방지를 위해 -0.99로 제한
    final safeReturn = annualReturn!.clamp(-0.99, double.infinity);
    return math.pow(1 + safeReturn, 1 / 12).toDouble() - 1;
  }

  // 시나리오별 수익률 조정
  double getMonthlyReturnForScenario(String scenario) {
    if (annualReturn == null) return 0.0;
    double adjustedReturn = annualReturn!;
    switch (scenario) {
      case 'positive':
        adjustedReturn = annualReturn! * 1.2; // +20%
        break;
      case 'neutral':
        adjustedReturn = annualReturn!; // 그대로
        break;
      case 'negative':
        adjustedReturn = annualReturn! * 0.8; // -20%
        break;
    }
    // -1보다 작으면 pow 계산 에러 방지를 위해 -0.99로 제한
    final safeReturn = adjustedReturn.clamp(-0.99, double.infinity);
    // 월 복리 수익률: (1 + r)^(1/12) - 1
    return math.pow(1 + safeReturn, 1 / 12).toDouble() - 1;
  }

  Asset copyWith({
    String? assetId,
    double? allocation,
    double? annualReturn,
  }) {
    return Asset(
      assetId: assetId ?? this.assetId,
      allocation: allocation ?? this.allocation,
      annualReturn: annualReturn ?? this.annualReturn,
    );
  }
}
