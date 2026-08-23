import 'dart:async';

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
import '../widgets/asset_icon.dart';
import '../services/api_service.dart';

class AddAssetDialog extends StatefulWidget {
  const AddAssetDialog({super.key});

  @override
  State<AddAssetDialog> createState() => _AddAssetDialogState();
}

class _AddAssetDialogState extends State<AddAssetDialog> {
  String? _selectedAssetId;
  String? _selectedAssetName;
  String? _selectedSymbol;
  String? _selectedAssetType;
  final TextEditingController _principalController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _annualRateController =
      TextEditingController(text: '0');
  final Map<String, bool> _expandedTypes = {};
  int _currentStep = 0; // 0: 자산 선택, 1: 투자 원금 및 보유 갯수
  bool _isLoading = false;

  static const _searchableTypes = {
    'crypto',
    'stock',
    'korean_stock',
    'commodity',
  };

  @override
  void dispose() {
    _principalController.dispose();
    _quantityController.dispose();
    _annualRateController.dispose();
    super.dispose();
  }

  double _parseCurrency(String text) {
    return double.tryParse(text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0.0;
  }

  double _parseQuantity(String text) {
    // 수량은 소수점 포함 가능
    return double.tryParse(text.replaceAll(',', '')) ?? 0.0;
  }

  double _parseAnnualRate(String text) {
    if (text.trim().isEmpty) return 0;
    return double.tryParse(text.replaceAll(',', '')) ?? 0;
  }

  bool get _isCashSelected => _selectedAssetId == 'cash';

  bool get _isCustomSelected =>
      _selectedSymbol != null && _selectedSymbol!.isNotEmpty;

  void _selectAsset(String assetId, {String? name}) {
    setState(() {
      _selectedAssetId = assetId;
      _selectedAssetName = name;
      _selectedSymbol = null;
      _selectedAssetType = null;
      if (assetId == 'cash') {
        if (_annualRateController.text.trim().isEmpty) {
          _annualRateController.text = '0';
        }
      } else if (_quantityController.text == '1') {
        _quantityController.clear();
      }
      if (_currentStep == 0) {
        _currentStep = 1;
      }
    });
  }

  void _selectCustomAsset({
    required String id,
    required String name,
    required String symbol,
    required String type,
  }) {
    setState(() {
      _selectedAssetId = id;
      _selectedAssetName = name;
      _selectedSymbol = symbol;
      _selectedAssetType = type;
      if (_quantityController.text == '1') {
        _quantityController.clear();
      }
      _currentStep = 1;
    });
  }

  bool get _canSubmitStep1 {
    if (_selectedAssetId == null || _isLoading) return false;
    if (_parseCurrency(_principalController.text) <= 0) return false;
    return _isCashSelected || _parseQuantity(_quantityController.text) > 0;
  }

  Future<void> _submit() async {
    if (!_canSubmitStep1) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final appProvider = context.read<AppStateProvider>();
      final myAssetsProvider = context.read<MyAssetsProvider>();

      String assetName;
      if (_isCustomSelected && _selectedAssetName != null) {
        assetName = _selectedAssetName!;
      } else {
        final asset = appProvider.assets.firstWhere(
          (a) => a.id == _selectedAssetId!,
        );
        assetName = asset.displayName();
      }

      final principal = _parseCurrency(_principalController.text);
      final quantity =
          _isCashSelected ? 1.0 : _parseQuantity(_quantityController.text);
      final double annualInterestRate = _isCashSelected
          ? _parseAnnualRate(_annualRateController.text)
          : 0.0;

      if (!_isCashSelected) {
        double? currentPrice;
        try {
          final priceData = await ApiService.fetchDailyPrices(
            _selectedAssetId!,
            1,
            symbol: _selectedSymbol,
            type: _selectedAssetType,
          );
          if (priceData.isNotEmpty) {
            currentPrice = (priceData.last['price'] as num?)?.toDouble();
          }
        } catch (e) {
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
      }

      await myAssetsProvider.addAsset(
        assetId: _selectedAssetId!,
        assetName: assetName,
        initialAmount: principal,
        registeredDate: DateTime.now(),
        quantity: quantity,
        annualInterestRate: annualInterestRate,
        symbol: _selectedSymbol,
        assetType: _selectedAssetType,
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

  Future<void> _openAssetSearch(String type, AppLocalizations l10n) async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AssetSearchSheet(assetType: type, l10n: l10n),
    );

    if (result == null || !mounted) return;

    _selectCustomAsset(
      id: result['id']!,
      name: result['name']!,
      symbol: result['symbol']!,
      type: result['type']!,
    );
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
                ? AppColors.primary
                : AppColors.border,
          ),
          child: Center(
            child: isCompleted
                ? Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : AppColors.textSecondary,
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
                ? AppColors.primary
                : AppColors.textSecondary,
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
            color: AppColors.textSecondary,
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
            color: AppColors.textSecondary,
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
            hintStyle: TextStyle(color: AppColors.textSecondary),
            suffixText: currencyUnit,
            suffixStyle: TextStyle(color: AppColors.primary, fontSize: 20),
            filled: true,
            fillColor: AppColors.bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
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
          style: TextStyle(color: AppColors.textPrimary, fontSize: 20),
          textAlign: TextAlign.right,
        ),
        SizedBox(height: 24),
        Text(
          _isCashSelected ? l10n.annualInterestRate : l10n.quantity,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        if (_isCashSelected)
          TextField(
            controller: _annualRateController,
            enabled: !_isLoading,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(color: AppColors.textSecondary),
              suffixText: '%',
              suffixStyle: TextStyle(color: AppColors.primary, fontSize: 20),
              filled: true,
              fillColor: AppColors.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            style: TextStyle(color: AppColors.textPrimary, fontSize: 20),
            textAlign: TextAlign.right,
          )
        else
          TextField(
            controller: _quantityController,
            enabled: !_isLoading,
            onChanged: (value) {
              setState(() {});
            },
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
            style: TextStyle(color: AppColors.textPrimary, fontSize: 20),
            textAlign: TextAlign.right,
          ),
      ],
    );
  }

  Widget _buildEnterManuallyButton(String type, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AssetButton(
        assetName: l10n.enterManually,
        assetId: 'custom_search',
        type: type,
        isSelected: false,
        isDisabled: _isLoading,
        onTap: _isLoading ? () {} : () => _openAssetSearch(type, l10n),
      ),
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
      final canSearch = _searchableTypes.contains(type);

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
                color: AppColors.textSecondary,
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
              onTap: _isLoading ? null : () => _selectAsset(asset.id),
              child: AssetButton(
                assetName: asset.displayName(),
                assetId: asset.id,
                type: asset.type,
                isSelected: _selectedAssetId == asset.id && !_isCustomSelected,
                isDisabled: _isLoading,
                onTap: _isLoading ? () {} : () => _selectAsset(asset.id),
              ),
            ),
          ),
        );
      }

      // 더보기 펼친 뒤(또는 항목이 2개 이하일 때) 직접 입력
      final showManualEntry =
          canSearch && (isExpanded || assets.length <= 2);
      if (showManualEntry) {
        widgets.add(_buildEnterManuallyButton(type, l10n));
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
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.primary,
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
    final l10n = AppLocalizations.of(context)!;
    final localeCode = Localizations.localeOf(context).languageCode;

    return ListenableBuilder(
      listenable: CurrencyProvider.shared,
      builder: (context, _) {
        final currencySymbol = CurrencyProvider.shared.getCurrencySymbol();

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
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
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
                              color: AppColors.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: AppColors.textSecondary,
                            ),
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
                                ? AppColors.primary
                                : AppColors.border,
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
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
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
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
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
                                          : (_canSubmitStep1
                                                ? () async => await _submit()
                                                : null)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
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
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AssetSearchSheet extends StatefulWidget {
  final String assetType;
  final AppLocalizations l10n;

  const _AssetSearchSheet({
    required this.assetType,
    required this.l10n,
  });

  @override
  State<_AssetSearchSheet> createState() => _AssetSearchSheetState();
}

class _AssetSearchSheetState extends State<_AssetSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  bool _isSearching = false;
  String? _error;
  List<Map<String, dynamic>> _results = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _error = null;
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _runSearch(query);
    });
  }

  Future<void> _runSearch(String query) async {
    try {
      final lang = Localizations.localeOf(context).languageCode;
      final results = await ApiService.searchAssets(
        query,
        type: widget.assetType,
        lang: lang,
      );
      if (!mounted) return;
      setState(() {
        _results = results;
        _error = null;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _error = widget.l10n.searchAssetFailed;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.searchAssetTitle,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _onQueryChanged,
                decoration: InputDecoration(
                  hintText: l10n.searchAssetHint,
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                  ),
                  filled: true,
                  fillColor: AppColors.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _buildBody(l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              l10n.searchingAssets,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_controller.text.trim().isEmpty) {
      return Center(
        child: Text(
          l10n.searchAssetHint,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Text(
          l10n.noSearchResults,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _results[index];
        final id = item['id'] as String? ?? '';
        final name = item['name'] as String? ?? '';
        final symbol = item['symbol'] as String? ?? '';
        final type = item['type'] as String? ?? widget.assetType;
        final exchange = item['exchange'] as String?;

        return Material(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.pop(context, {
                'id': id,
                'name': name,
                'symbol': symbol,
                'type': type,
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  AssetIcon(assetId: id, type: type, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          exchange != null && exchange.isNotEmpty
                              ? '$symbol · $exchange'
                              : symbol,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
