import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../models/asset_option.dart';
import '../utils/colors.dart';
import '../l10n/app_localizations.dart';

class AssetInputCard extends StatelessWidget {
  final Asset asset;
  final AssetOption? assetOption; // AssetOption 정보
  final int index;
  final Function(double) onAllocationChanged; // 슬라이더 변경 시 호출
  final VoidCallback onDelete;
  final bool isLoadingCagr;

  // 폰트 크기 상수
  static const double _assetIconFontSize = 24.0; // 자산 아이콘 크기 (비트코인, 테슬라 등 이모지)
  static const double _assetNameFontSize = 20.0; // 자산 이름 텍스트 (비트코인, 테슬라 등)
  static const double _cagrLoadingFontSize = 20.0; // "연수익률 계산 중..." 텍스트
  static const double _cagrValueFontSize = 20.0; // "과거 연평균 수익률 (CAGR): XX%" 텍스트
  static const double _cagrErrorFontSize = 20.0; // "연수익률을 불러올 수 없습니다" 텍스트
  static const double _allocationLabelFontSize = 20.0; // "비중" 라벨 텍스트
  static const double _allocationValueFontSize =
      18.0; // 비중 퍼센트 값 텍스트 (예: "60.0%")

  final AppLocalizations? l10n;

  const AssetInputCard({
    super.key,
    required this.asset,
    this.assetOption,
    required this.index,
    required this.onAllocationChanged,
    required this.onDelete,
    this.isLoadingCagr = false,
    this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final localeCode = Localizations.localeOf(context).languageCode;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navyMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (assetOption != null)
                      Text(
                        assetOption!.icon,
                        style: TextStyle(fontSize: _assetIconFontSize),
                      ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        assetOption?.displayName(localeCode) ?? asset.assetId,
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: _assetNameFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onDelete,
                tooltip: l10n?.delete ?? '삭제',
              ),
            ],
          ),
          SizedBox(height: 12),
          // CAGR 표시
          if (isLoadingCagr)
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.gold,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  l10n?.calculatingAnnualReturn ?? '연수익률 계산 중...',
                  style: TextStyle(
                    color: AppColors.slate400,
                    fontSize: _cagrLoadingFontSize,
                  ),
                ),
              ],
            )
          else if (asset.annualReturn != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${l10n?.pastAnnualReturn ?? '과거 연평균 수익률 (CAGR)'}: ${(asset.annualReturn! * 100).toStringAsFixed(2)}%',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: _cagrValueFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '연수익률을 불러올 수 없습니다',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: _cagrErrorFontSize,
                ),
              ),
            ),
          SizedBox(height: 16),
          // 비중 슬라이더
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n?.allocation ?? '비중',
                    style: TextStyle(
                      color: AppColors.slate400,
                      fontSize: _allocationLabelFontSize,
                    ),
                  ),
                  Text(
                    '${(asset.allocation * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: _allocationValueFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Slider(
                value: asset.allocation,
                min: 0.0,
                max: 1.0,
                divisions: 100,
                onChanged: onAllocationChanged,
                activeColor: AppColors.gold,
                inactiveColor: AppColors.slate700,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
