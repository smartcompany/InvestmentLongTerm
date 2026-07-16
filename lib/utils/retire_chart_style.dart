import 'package:flutter/material.dart';

/// 은퇴 시뮬 애니메이션·결과 차트에서 공유하는 색상.
class RetireChartStyle {
  static const List<Color> assetPalette = [
    Color(0xFF5B8FF7),
    Color(0xFF4ADE80),
    Color(0xFFC084FC),
    Color(0xFFF472B6),
    Color(0xFF22D3EE),
    Color(0xFF2DD4BF),
    Color(0xFFFBBF24),
  ];

  static const Color total = Color(0xFF3B82F6);
  static const Color withdrawal = Color(0xFFFB923C);

  static Color assetAt(int index) =>
      assetPalette[index % assetPalette.length];
}
