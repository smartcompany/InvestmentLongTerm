import 'package:flutter/material.dart';

/// 은퇴 시뮬 애니메이션·결과 차트에서 공유하는 색상.
/// 전체/인출/현금과 겹치지 않도록 채도·색상 계열을 분리합니다.
class RetireChartStyle {
  /// 전체 자산 — 진한 네이비 (메인 라인)
  static const Color total = Color(0xFF1E3A8A);

  /// 누적 인출 — 주황 점선
  static const Color withdrawal = Color(0xFFEA580C);

  /// 현금 — 슬레이트 그레이
  static const Color cash = Color(0xFF64748B);

  /// 개별 자산 — 서로·전체·인출과 확실히 구분되는 색
  static const List<Color> assetPalette = [
    Color(0xFF0D9488), // teal
    Color(0xFF16A34A), // green
    Color(0xFFDB2777), // pink
    Color(0xFF7C3AED), // violet
    Color(0xFFEAB308), // yellow
    Color(0xFF0891B2), // cyan
    Color(0xFFDC2626), // red
    Color(0xFF65A30D), // lime
  ];

  static Color assetAt(int index) =>
      assetPalette[index % assetPalette.length];

  static Color colorForAssetId(String assetId, {required int paletteIndex}) {
    if (assetId == 'cash') return cash;
    return assetAt(paletteIndex);
  }
}
