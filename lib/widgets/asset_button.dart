import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'asset_icon.dart';
import 'liquid_glass.dart';

class AssetButton extends StatelessWidget {
  final String assetName;
  final String assetId;
  final String? type;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;
  final double iconBoxSize;
  final bool isDisabled;

  const AssetButton({
    super.key,
    required this.assetName,
    required this.assetId,
    this.type,
    required this.onTap,
    this.isSelected = false,
    this.color,
    this.iconBoxSize = 40,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: iconBoxSize,
          child: Center(
            child: AssetIcon(
              assetId: assetId,
              type: type,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            assetName,
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isSelected) ...[
          const SizedBox(width: 8),
          const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
        ],
      ],
    );

    return Opacity(
      opacity: isDisabled ? 0.45 : 1,
      child: LiquidGlassButton(
        isSelected: isSelected,
        borderRadius: BorderRadius.circular(18),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        onTap: isDisabled ? null : onTap,
        child: content,
      ),
    );
  }
}
