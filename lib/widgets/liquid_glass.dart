import 'package:flutter/material.dart';
import 'dart:ui';
import '../utils/colors.dart';

/// 선택된 버튼/카드의 공통 스타일 설정
class SelectedButtonStyle {
  /// 선택된 버튼의 배경색
  static const Color backgroundColor = AppColors.goldLight;

  /// 선택된 버튼의 투명도
  static const double opacity = 0.6;

  /// 선택된 버튼의 테두리 색상
  static Color get borderColor => AppColors.gold.withValues(alpha: 0.7);

  /// 선택된 버튼의 테두리 두께
  static const double borderWidth = 2.0;

  /// 선택된 버튼의 그라디언트 색상
  static List<Color> get gradientColors => [
    AppColors.gold.withValues(alpha: 0.6),
    AppColors.goldLight.withValues(alpha: 0.5),
  ];

  /// 선택된 버튼의 그라디언트 (LiquidGlass용)
  static LinearGradient get gradient => LinearGradient(
    colors: gradientColors,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// 선택된 버튼의 그라디언트 (Container용 - 더 불투명)
  static LinearGradient get solidGradient => LinearGradient(
    colors: [
      AppColors.gold.withOpacity(0.9),
      AppColors.goldLight.withOpacity(0.85),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// 선택된 버튼의 테두리
  static Border get border =>
      Border.all(color: borderColor, width: borderWidth);

  /// 선택된 버튼의 그림자
  static List<BoxShadow> get boxShadow => [
    BoxShadow(
      color: AppColors.gold.withValues(alpha: 0.4),
      blurRadius: 20,
      offset: Offset(0, 10),
    ),
  ];

  /// 선택된 버튼의 BoxDecoration (더 불투명한 그라디언트 사용)
  static BoxDecoration solidBoxDecoration([BorderRadius? borderRadius]) {
    final gradient = LinearGradient(
      colors: [
        AppColors.gold.withOpacity(0.9),
        AppColors.goldLight.withOpacity(0.85),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return BoxDecoration(
      gradient: gradient,
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      border: border,
      boxShadow: boxShadow,
    );
  }
}

/// Liquid Glass 효과를 제공하는 위젯
/// iOS 18+ 스타일의 glass morphism 효과를 구현합니다.
class LiquidGlass extends StatelessWidget {
  final Widget child;
  final double? blur;
  final BoxDecoration decoration;
  final EdgeInsetsGeometry? padding;

  const LiquidGlass({
    super.key,
    required this.child,
    this.blur = 10.0,
    required this.decoration,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius =
        decoration.borderRadius as BorderRadius? ?? BorderRadius.circular(20);

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur!, sigmaY: blur!),
        child: Container(
          padding: padding,
          decoration: decoration,
          child: child,
        ),
      ),
    );
  }
}

/// 선택된 상태의 Liquid Glass 버튼 스타일
class LiquidGlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isSelected;
  final double? blur;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  const LiquidGlassButton({
    super.key,
    required this.child,
    this.onTap,
    this.isSelected = false,
    this.blur = 30.0,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final defaultBorderRadius = borderRadius ?? BorderRadius.circular(22);

    // isSelected에 따라 공통 스타일 또는 기본 스타일 사용
    final borderColor = isSelected
        ? SelectedButtonStyle.borderColor
        : Colors.white.withValues(alpha: 0.25);

    final borderWidth = isSelected ? SelectedButtonStyle.borderWidth : 1.5;

    final decoration = isSelected
        ? SelectedButtonStyle.solidBoxDecoration(defaultBorderRadius)
        : BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
          borderRadius: defaultBorderRadius,
            border: Border.all(color: borderColor, width: borderWidth),
      );

      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: LiquidGlass(
          blur: blur,
        decoration: decoration,
          padding: padding,
          child: child,
        ),
      );
  }
}
