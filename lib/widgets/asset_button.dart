import 'package:flutter/material.dart';
import '../utils/colors.dart';

class AssetButton extends StatelessWidget {
  final String assetName;
  final String icon; // Emoji or asset path
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const AssetButton({
    super.key,
    required this.assetName,
    required this.icon,
    required this.onTap,
    this.isSelected = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? (color ?? AppColors.gold) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? (color ?? AppColors.gold) : AppColors.slate700,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: TextStyle(fontSize: 24)),
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
