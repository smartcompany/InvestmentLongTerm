import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_state_provider.dart';
import '../providers/my_assets_provider.dart';
import '../providers/currency_provider.dart';
import '../models/asset_option.dart';
import '../utils/colors.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/asset_button.dart';
import '../services/api_service.dart';

class AddAssetDialog extends StatefulWidget {
  const AddAssetDialog({super.key});

  @override
  State<AddAssetDialog> createState() => _AddAssetDialogState();
}

class _AddAssetDialogState extends State<AddAssetDialog> {
  String? _selectedAssetId;
  final TextEditingController _principalController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final Map<String, bool> _expandedTypes = {};
  int _currentStep = 0; // 0: 자산 선택, 1: 투자 원금 및 보유 갯수
  bool _isLoading = false;

  @override
  void dispose() {
    _principalController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  double _parseCurrency(String text) {
    return double.tryParse(text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0.0;
  }

  double _parseQuantity(String text) {
    // 수량은 소수점 포함 가능
    return double.tryParse(text.replaceAll(',', '')) ?? 0.0;
  }

  Future<void> _submit() async {
    if (_selectedAssetId == null ||
        _parseCurrency(_principalController.text) == 0 ||
        _parseQuantity(_quantityController.text) == 0 ||
        _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final appProvider = context.read<AppStateProvider>();
      final myAssetsProvider = context.read<MyAssetsProvider>();
      final localeCode = Localizations.localeOf(context).languageCode;

      final asset = appProvider.assets.firstWhere(
        (a) => a.id == _selectedAssetId!,
      );
      final assetName = asset.displayName(localeCode);
      final principal = _parseCurrency(_principalController.text);
      final quantity = _parseQuantity(_quantityController.text);

      // 현재 가격 가져오기
      double? currentPrice;
      try {
        final priceData = await ApiService.fetchDailyPrices(
          _selectedAssetId!,
          1,
        );
        if (priceData.isNotEmpty) {
          currentPrice = (priceData.last['price'] as num?)?.toDouble();
        }
      } catch (e) {
        // 가격을 가져올 수 없으면 에러 표시
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('현재 가격을 가져올 수 없습니다. 다시 시도해주세요.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (currentPrice == null || currentPrice <= 0) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('유효한 현재 가격을 가져올 수 없습니다.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // 현재 평가 금액 계산: 수량 * 현재 가격
      // (이 값은 addAsset 내부에서 _updateCurrentValue에서 다시 계산되므로 여기서는 참고용)
      await myAssetsProvider.addAsset(
        assetId: _selectedAssetId!,
        assetName: assetName,
        initialAmount: principal,
        registeredDate: DateTime.now(), // 현재 시점을 기준으로 설정
        quantity: quantity,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('자산 추가 중 오류가 발생했습니다. 다시 시도해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive || isCompleted
                ? AppColors.gold
                : AppColors.slate700,
          ),
          child: Center(
            child: isCompleted
                ? Icon(Icons.check, color: AppColors.navyDark, size: 20)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? AppColors.navyDark : AppColors.slate400,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive || isCompleted
                ? AppColors.gold
                : AppColors.slate400,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAssetSelectionStep(
    AppStateProvider provider,
    String localeCode,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '자산 선택',
          style: TextStyle(
            color: AppColors.slate300,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        _buildAssetSelection(provider, localeCode, l10n),
      ],
    );
  }

  Widget _buildAmountAndDateStep(String currencyUnit, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.initialAmount,
          style: TextStyle(
            color: AppColors.slate300,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        TextField(
          controller: _principalController,
          enabled: !_isLoading,
          onChanged: (value) {
            setState(() {});
          },
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: TextStyle(color: AppColors.slate400),
            suffixText: currencyUnit,
            suffixStyle: TextStyle(color: AppColors.gold, fontSize: 20),
            filled: true,
            fillColor: AppColors.slate800.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.gold, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.gold, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.gold, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d,]+')),
            TextInputFormatter.withFunction((oldValue, newValue) {
              if (newValue.text.isEmpty) return newValue;
              final cleanText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
              final number = int.tryParse(cleanText);
              if (number == null) return oldValue;
              final formatted = NumberFormat('#,###').format(number);
              return TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(offset: formatted.length),
              );
            }),
          ],
          style: TextStyle(color: Colors.white, fontSize: 20),
          textAlign: TextAlign.right,
        ),
        SizedBox(height: 24),
        Text(
          l10n.quantity,
          style: TextStyle(
            color: AppColors.slate300,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        TextField(
          controller: _quantityController,
          enabled: !_isLoading,
          onChanged: (value) {
            setState(() {});
          },
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: TextStyle(color: AppColors.slate400),
            filled: true,
            fillColor: AppColors.slate800.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.gold, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.gold, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.gold, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
            TextInputFormatter.withFunction((oldValue, newValue) {
              if (newValue.text.isEmpty) return newValue;
              // 소수점은 하나만 허용
              final text = newValue.text;
              final dotCount = text.split('.').length - 1;
              if (dotCount > 1) return oldValue;

              // 쉼표 제거 후 파싱
              final cleanText = text.replaceAll(',', '');
              final number = double.tryParse(cleanText);
              if (number == null && cleanText != '.') return oldValue;

              // 포맷팅 (소수점이 있으면 포맷팅하지 않음)
              if (text.contains('.')) {
                return newValue;
              } else {
                final intValue = int.tryParse(cleanText);
                if (intValue != null) {
                  final formatted = NumberFormat('#,###').format(intValue);
                  return TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(
                      offset: formatted.length,
                    ),
                  );
                }
              }
              return newValue;
            }),
          ],
          style: TextStyle(color: Colors.white, fontSize: 20),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }

  Widget _buildAssetSelection(
    AppStateProvider provider,
    String localeCode,
    AppLocalizations l10n,
  ) {
    final widgets = <Widget>[];

    // 자산을 타입별로 그룹화
    final Map<String, List<AssetOption>> assetsByType = {};
    for (final asset in provider.assets) {
      assetsByType.putIfAbsent(asset.type, () => []).add(asset);
    }

    // 타입별로 정렬된 순서대로 처리
    final sortedTypes = assetsByType.keys.toList()
      ..sort((a, b) {
        final order = {
          'crypto': 0,
          'stock': 1,
          'korean_stock': 2,
          'commodity': 3,
          'cash': 4,
        };
        return (order[a] ?? 99).compareTo(order[b] ?? 99);
      });

    for (final type in sortedTypes) {
      final assets = assetsByType[type]!;
      final isExpanded = _expandedTypes[type] ?? false;

      // 타입 제목 추가
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              type == 'crypto'
                  ? l10n.crypto
                  : type == 'cash'
                  ? l10n.cash
                  : type == 'commodity'
                  ? l10n.commodity
                  : type == 'korean_stock'
                  ? l10n.koreanStock
                  : type == 'real_estate'
                  ? l10n.realEstate
                  : l10n.stock,
              style: TextStyle(
                color: AppColors.slate300,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );

      // 처음 2개만 항상 표시
      final visibleCount = isExpanded
          ? assets.length
          : (assets.length > 2 ? 2 : assets.length);

      for (int i = 0; i < visibleCount; i++) {
        final asset = assets[i];
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: _isLoading
                  ? null
                  : () {
                      setState(() {
                        _selectedAssetId = asset.id;
                        // 자산 선택 시 자동으로 다음 단계로 이동
                        if (_currentStep == 0) {
                          _currentStep = 1;
                        }
                      });
                    },
              child: AssetButton(
                assetName: asset.displayName(localeCode),
                icon: asset.icon,
                isSelected: _selectedAssetId == asset.id,
                isDisabled: _isLoading,
                onTap: _isLoading
                    ? () {}
                    : () {
                        setState(() {
                          _selectedAssetId = asset.id;
                          // 자산 선택 시 자동으로 다음 단계로 이동
                          if (_currentStep == 0) {
                            _currentStep = 1;
                          }
                        });
                      },
              ),
            ),
          ),
        );
      }

      // 나머지가 있으면 펼치기/접기 버튼 추가
      if (assets.length > 2) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Center(
              child: TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _expandedTypes[type] = !isExpanded;
                        });
                      },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isExpanded ? l10n.showLess : l10n.showMore,
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.gold,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppStateProvider>();
    final localeCode = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;
    final currencyProvider = context.watch<CurrencyProvider>();
    final currencySymbol = currencyProvider.getCurrencySymbol(localeCode);

    String _getCurrencyUnit(String symbol) {
      switch (symbol) {
        case '₩':
          return l10n.won;
        case '\$':
          return l10n.dollar;
        case '¥':
          return l10n.yen;
        case 'CN¥':
          return l10n.yuan;
        default:
          return symbol;
      }
    }

    final currencyUnit = _getCurrencyUnit(currencySymbol);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Stack(
        children: [
          LiquidGlass(
            decoration: BoxDecoration(
              color: AppColors.navyDark.withOpacity(0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.gold.withOpacity(0.3)),
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
                minHeight: MediaQuery.of(context).size.height * 0.6,
                maxWidth: double.infinity,
              ),
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 헤더 (타이틀 + X 버튼)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.addAsset,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: AppColors.slate400),
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  // 단계 표시
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStepIndicator(0, '자산 선택'),
                      Container(
                        width: 40,
                        height: 2,
                        color: _currentStep >= 1
                            ? AppColors.gold
                            : AppColors.slate700,
                      ),
                      _buildStepIndicator(1, '정보 입력'),
                    ],
                  ),
                  SizedBox(height: 24),
                  // 단계별 콘텐츠
                  Expanded(
                    child: SingleChildScrollView(
                      child: _currentStep == 0
                          ? _buildAssetSelectionStep(
                              appProvider,
                              localeCode,
                              l10n,
                            )
                          : _buildAmountAndDateStep(currencyUnit, l10n),
                    ),
                  ),
                  SizedBox(height: 24),
                  // 하단 버튼
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentStep == 1)
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _currentStep = 0;
                                  });
                                },
                          child: Text(
                            '이전',
                            style: TextStyle(color: AppColors.slate400),
                          ),
                        )
                      else
                        SizedBox.shrink(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.pop(context),
                            child: Text(
                              l10n.cancel,
                              style: TextStyle(color: AppColors.slate400),
                            ),
                          ),
                          SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : (_currentStep == 0
                                      ? (_selectedAssetId != null
                                            ? () {
                                                setState(() {
                                                  _currentStep = 1;
                                                });
                                              }
                                            : null)
                                      : (_selectedAssetId != null &&
                                                _parseCurrency(
                                                      _principalController.text,
                                                    ) >
                                                    0 &&
                                                _parseQuantity(
                                                      _quantityController.text,
                                                    ) >
                                                    0
                                            ? () async => await _submit()
                                            : null)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              foregroundColor: AppColors.navyDark,
                              padding: EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _currentStep == 0 ? '다음' : l10n.confirm,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // 로딩 오버레이
          if (_isLoading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
