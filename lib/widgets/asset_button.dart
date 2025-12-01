import 'package:flutter/material.dart';
import '../utils/colors.dart';

class AssetButton extends StatelessWidget {
  final String assetName;
  final String icon; // Emoji or asset path
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;
  final double iconBoxSize;
  final bool isDisabled;

  const AssetButton({
    super.key,
    required this.assetName,
    required this.icon,
    required this.onTap,
    this.isSelected = false,
    this.color,
    this.iconBoxSize = 40,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [(color ?? AppColors.gold), AppColors.goldLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? (color ?? AppColors.gold) : AppColors.slate700,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (color ?? AppColors.gold).withValues(alpha: 0.35),
                    blurRadius: 25,
                    offset: Offset(0, 12),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: iconBoxSize,
              child: Center(child: Text(icon, style: TextStyle(fontSize: 24))),
            ),
            SizedBox(width: 12),
            Text(
              assetName,
              style: TextStyle(
                color: isSelected ? AppColors.navyDark : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
