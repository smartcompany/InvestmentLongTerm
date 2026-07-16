import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/asset.dart';
import '../models/asset_option.dart';
import '../utils/colors.dart';
import '../l10n/app_localizations.dart';
import 'asset_icon.dart';
import 'liquid_glass.dart';

class AssetInputCard extends StatelessWidget {
  final Asset asset;
  final AssetOption? assetOption; // AssetOption 정보
  final int index;
  final Function(double) onAllocationChanged; // 슬라이더 변경 시 호출
  final VoidCallback onDelete;
  final bool isLoadingCagr;
  final VoidCallback? onRetryLoadCagr; // CAGR 재시도 콜백

  // 폰트 크기 상수
  static const double _assetIconSize = 24.0;
  static const double _assetNameFontSize = 20.0;
  static const double _cagrLoadingFontSize = 20.0; // "연수익률 계산 중..." 텍스트
  static const double _cagrValueFontSize = 20.0; // "과거 연평균 수익률 (CAGR): XX%" 텍스트
  static const double _cagrErrorFontSize = 20.0; // "연수익률을 불러올 수 없습니다" 텍스트
  static const double _allocationLabelFontSize = 20.0; // "비중" 라벨 텍스트
  static const double _allocationValueFontSize =
      18.0; // 비중 퍼센트 값 텍스트 (예: "60.0%")

  final AppLocalizations? l10n;
  final double? initialAsset;
  final NumberFormat? currencyFormat;

  const AssetInputCard({
    super.key,
    required this.asset,
    this.assetOption,
    required this.index,
    required this.onAllocationChanged,
    required this.onDelete,
    this.isLoadingCagr = false,
    this.onRetryLoadCagr,
    this.l10n,
    this.initialAsset,
    this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final localeCode = Localizations.localeOf(context).languageCode;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: LiquidGlass(
        blur: 10,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        padding: EdgeInsets.all(16),
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
                        AssetIcon(
                          assetId: assetOption!.id,
                          type: assetOption!.type,
                          size: _assetIconSize,
                        ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          assetOption?.displayName() ?? asset.assetId,
                          style: TextStyle(
                            color: AppColors.textPrimary,
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
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    l10n?.calculatingAnnualReturn ?? '연수익률 계산 중...',
                    style: TextStyle(
                      color: AppColors.textSecondary,
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
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 18),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '연수익률을 불러올 수 없습니다',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: _cagrErrorFontSize,
                        ),
                      ),
                    ),
                    if (onRetryLoadCagr != null) ...[
                      SizedBox(width: 8),
                      GestureDetector(
                        onTap: onRetryLoadCagr,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.refresh, color: Colors.red, size: 16),
                              SizedBox(width: 4),
                              Text(
                                '재시도',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            SizedBox(height: 16),
            // 비중 슬라이더
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.allocation ?? '비중',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: _allocationLabelFontSize,
                      ),
                    ),
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        children: [
                          Text(
                            '${(asset.allocation * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: _allocationValueFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (initialAsset != null && currencyFormat != null)
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: screenWidth * 0.4,
                              ),
                              child: Text(
                                '(${currencyFormat!.format((initialAsset! * asset.allocation).toInt())})',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: _allocationValueFontSize - 2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.visible,
                                softWrap: true,
                              ),
                            ),
                        ],
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
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.border,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
