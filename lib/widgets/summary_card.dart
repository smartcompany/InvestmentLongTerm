import 'package:flutter/material.dart';
import '../utils/colors.dart';

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final bool isHighlight;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isHighlight
            ? LinearGradient(
                colors: [AppColors.gold, AppColors.goldLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isHighlight ? null : AppColors.navyMedium,
        borderRadius: BorderRadius.circular(20),
        border: isHighlight ? null : Border.all(color: AppColors.slate700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isHighlight
                  ? AppColors.navyDark.withValues(alpha: 0.7)
                  : AppColors.slate400,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: isHighlight ? AppColors.navyDark : Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                color: isHighlight ? AppColors.success : AppColors.success,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
