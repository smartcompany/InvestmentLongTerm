import 'package:flutter/material.dart';
import '../utils/colors.dart';

/// 선택된 버튼/카드의 공통 스타일 (라이트·블루)
class SelectedButtonStyle {
  static const Color backgroundColor = AppColors.primarySoft;
  static const double opacity = 1.0;
  static Color get borderColor => AppColors.primary;
  static const double borderWidth = 2.0;

  static List<Color> get gradientColors => [
    AppColors.primary,
    AppColors.primaryLight,
  ];

  static LinearGradient get gradient => LinearGradient(
    colors: gradientColors,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get solidGradient => gradient;

  static Border get border =>
      Border.all(color: borderColor, width: borderWidth);

  static List<BoxShadow> get boxShadow => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.18),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static BoxDecoration solidBoxDecoration([BorderRadius? borderRadius]) {
    return BoxDecoration(
      color: AppColors.primary,
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      border: Border.all(color: AppColors.primary, width: borderWidth),
      boxShadow: boxShadow,
    );
  }

  static BoxDecoration softSelectedDecoration([BorderRadius? borderRadius]) {
    return BoxDecoration(
      color: AppColors.primarySoft,
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      border: Border.all(color: AppColors.primary, width: borderWidth),
    );
  }
}

/// 라이트 카드 컨테이너 (구 LiquidGlass 대체)
class LiquidGlass extends StatelessWidget {
  final Widget child;
  final double? blur;
  final BoxDecoration decoration;
  final EdgeInsetsGeometry? padding;

  const LiquidGlass({
    super.key,
    required this.child,
    this.blur,
    required this.decoration,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius =
        decoration.borderRadius as BorderRadius? ?? BorderRadius.circular(20);

    return Container(
      padding: padding,
      decoration: decoration.copyWith(
        color: decoration.color ?? AppColors.surface,
        borderRadius: borderRadius,
        boxShadow: decoration.boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
      ),
      child: child,
    );
  }
}

/// 선택 가능 카드 버튼
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
    this.blur,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(20);

    final decoration = isSelected
        ? SelectedButtonStyle.softSelectedDecoration(radius)
        : BoxDecoration(
            color: AppColors.surface,
            borderRadius: radius,
            border: Border.all(color: AppColors.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: LiquidGlass(
        decoration: decoration,
        padding: padding,
        child: child,
      ),
    );
  }
}
