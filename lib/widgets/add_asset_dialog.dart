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

class AddAssetDialog extends StatefulWidget {
  const AddAssetDialog({super.key});

  @override
  State<AddAssetDialog> createState() => _AddAssetDialogState();
}

class _AddAssetDialogState extends State<AddAssetDialog> {
  String? _selectedAssetId;
  final TextEditingController _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final Map<String, bool> _expandedTypes = {};
  int _currentStep = 0; // 0: 자산 선택, 1: 초기 금액 및 등록일

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.gold,
              onPrimary: AppColors.navyDark,
              surface: AppColors.navyMedium,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  double _parseCurrency(String text) {
    return double.tryParse(text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0.0;
  }

  void _submit() {
    if (_selectedAssetId == null ||
        _parseCurrency(_amountController.text) == 0) {
      return;
    }

    final appProvider = context.read<AppStateProvider>();
    final myAssetsProvider = context.read<MyAssetsProvider>();
    final localeCode = Localizations.localeOf(context).languageCode;

    final asset = appProvider.assets.firstWhere(
      (a) => a.id == _selectedAssetId!,
    );
    final assetName = asset.displayName(localeCode);
    final amount = _parseCurrency(_amountController.text);

    myAssetsProvider.addAsset(
      assetId: _selectedAssetId!,
      assetName: assetName,
      initialAmount: amount,
      registeredDate: _selectedDate,
    );

    Navigator.of(context).pop();
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
          controller: _amountController,
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
          l10n.registeredDate,
          style: TextStyle(
            color: AppColors.slate300,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.slate800.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gold, width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('yyyy-MM-dd').format(_selectedDate),
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                Icon(Icons.calendar_today, color: AppColors.gold),
              ],
            ),
          ),
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
              onTap: () {
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
                onTap: () {
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
                onPressed: () {
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
      child: LiquidGlass(
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
                    onPressed: () => Navigator.pop(context),
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
                      ? _buildAssetSelectionStep(appProvider, localeCode, l10n)
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
                      onPressed: () {
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
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          l10n.cancel,
                          style: TextStyle(color: AppColors.slate400),
                        ),
                      ),
                      SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _currentStep == 0
                            ? (_selectedAssetId != null
                                  ? () {
                                      setState(() {
                                        _currentStep = 1;
                                      });
                                    }
                                  : null)
                            : (_selectedAssetId != null &&
                                      _parseCurrency(_amountController.text) > 0
                                  ? _submit
                                  : null),
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
    );
  }
}
