import 'package:flutter/material.dart';
import 'colors.dart';

/// 앱 전체에서 사용되는 텍스트 스타일 상수 정의
class AppTextStyles {
  static const TextStyle appBarTitle = TextStyle(
    color: AppColors.textPrimary,
    fontWeight: FontWeight.bold,
    fontSize: 20,
  );

  static const TextStyle homeMainQuestion = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.35,
  );

  static const TextStyle homeSubDescription = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 15,
    height: 1.5,
  );

  static const TextStyle settingsAssetTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 22,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle settingsSectionLabel = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle settingsAmountInput = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 22,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle settingsAmountPrefix = TextStyle(
    color: AppColors.primary,
    fontSize: 22,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle resultCardTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle resultCardValueBig = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 28,
    fontWeight: FontWeight.w900,
  );

  static const TextStyle resultCardYield = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 28,
  );

  static const TextStyle resultCardGain = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 18,
  );

  static const TextStyle resultStatLabel = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 14,
  );

  static const TextStyle resultStatValue = TextStyle(
    color: AppColors.textPrimary,
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );

  static const TextStyle badgeText = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 12,
  );

  static const TextStyle chartSectionTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle chartLegend = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 14,
  );

  static const TextStyle chartTooltip = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 14,
  );

  static const TextStyle buttonTextPrimary = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle assetButtonText = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const TextStyle shareButtonLabel = TextStyle(
    color: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle insightMessage = TextStyle(
    color: AppColors.primary,
    fontSize: 17,
    fontWeight: FontWeight.bold,
    height: 1.5,
  );

  static const TextStyle cardTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 17,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle cardSubtitle = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 13,
    height: 1.4,
  );
}
