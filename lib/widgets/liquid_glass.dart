import 'package:flutter/material.dart';
import 'dart:ui';

/// Liquid Glass 효과를 제공하는 위젯
/// iOS 18+ 스타일의 glass morphism 효과를 구현합니다.
class LiquidGlass extends StatelessWidget {
  final Widget child;
  final double? blur;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final EdgeInsetsGeometry? padding;
  final double? opacity;

  const LiquidGlass({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.backgroundColor,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.padding,
    this.opacity = 0.25,
  });

  @override
  Widget build(BuildContext context) {
    final defaultBackgroundColor = backgroundColor ?? Colors.white;
    final defaultBorderRadius = borderRadius ?? BorderRadius.circular(20);
    final defaultBorder =
        border ??
        Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5);
    final defaultBoxShadow =
        boxShadow ??
        [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ];

    return ClipRRect(
      borderRadius: defaultBorderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur!, sigmaY: blur!),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: defaultBackgroundColor.withOpacity(opacity!),
            borderRadius: defaultBorderRadius,
            border: defaultBorder,
            boxShadow: defaultBoxShadow,
          ),
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
  final Color? selectedColor;
  final double? blur;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  const LiquidGlassButton({
    super.key,
    required this.child,
    this.onTap,
    this.isSelected = false,
    this.selectedColor,
    this.blur = 12.0,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final defaultSelectedColor = selectedColor ?? const Color(0xFFFBBF24);
    final defaultBorderRadius = borderRadius ?? BorderRadius.circular(22);

    if (isSelected) {
      return GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: defaultBorderRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur!, sigmaY: blur!),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    defaultSelectedColor.withValues(alpha: 0.5),
                    defaultSelectedColor.withValues(alpha: 0.4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: defaultBorderRadius,
                border: Border.all(
                  color: defaultSelectedColor.withValues(alpha: 0.7),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: defaultSelectedColor.withValues(alpha: 0.5),
                    blurRadius: 30,
                    offset: Offset(0, 15),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ),
      );
    } else {
      return LiquidGlass(
        blur: blur,
        borderRadius: defaultBorderRadius,
        padding: padding,
        backgroundColor: Colors.white,
        opacity: 0.18,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1.5,
        ),
        child: GestureDetector(onTap: onTap, child: child),
      );
    }
  }
}
