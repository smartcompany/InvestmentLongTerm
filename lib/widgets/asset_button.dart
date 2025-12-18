import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'liquid_glass.dart';

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
    if (isDisabled) {
      return LiquidGlassButton(
        isSelected: false,
        borderRadius: BorderRadius.circular(22),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        onTap: null,
        child: Opacity(
          opacity: 0.5,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: iconBoxSize,
                child: Center(
                  child: Text(icon, style: TextStyle(fontSize: 24)),
                ),
              ),
              SizedBox(width: 12),
              Text(
                assetName,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LiquidGlassButton(
      isSelected: isSelected,
      borderRadius: BorderRadius.circular(22),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      onTap: onTap,
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
    );
  }
}
