import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/asset_option.dart';
import '../providers/retire_simulator_provider.dart';
import '../providers/app_state_provider.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../widgets/asset_input_card.dart';
import 'retire_simulator_result_screen.dart';

class RetireSimulatorScreen extends StatefulWidget {
  const RetireSimulatorScreen({super.key});

  @override
  State<RetireSimulatorScreen> createState() => _RetireSimulatorScreenState();
}

class _RetireSimulatorScreenState extends State<RetireSimulatorScreen> {
  final TextEditingController _initialAssetController = TextEditingController();
  final TextEditingController _monthlyWithdrawalController =
      TextEditingController();

  // 폰트 크기 상수
  static const double _sectionTitleFontSize =
      20.0; // 섹션 제목 ("시뮬레이션 설정", "자산 포트폴리오")
  static const double _scenarioLabelFontSize = 20.0; // "시나리오 선택" 라벨 텍스트
  static const double _scenarioButtonFontSize =
      16.0; // 시나리오 버튼 텍스트 (긍정적/중립적/부정적)
  static const double _textFieldLabelFontSize =
      25.0; // 입력 필드 라벨 텍스트 ("초기 자산 금액", "월 인출 금액", "시뮬레이션 기간")
  static const double _textFieldInputFontSize =
      20.0; // 입력 필드에 표시되는 숫자 텍스트 (예: "1,000,000,000", "5,000,000")
  static const double _textFieldSuffixFontSize =
      20.0; // 입력 필드 접미사 텍스트 ("원", "년")
  static const double _assetIconFontSize = 24.0; // 자산 아이콘 크기 (비트코인, 테슬라 등 이모지)
  static const double _assetNameFontSize = 20.0; // 자산 이름 텍스트 (비트코인, 테슬라 등)
  static const double _addAssetIconSize = 20.0; // "자산 추가" 버튼의 + 아이콘 크기
  static const double _addAssetButtonFontSize = 20.0; // "자산 추가" 버튼 텍스트
  static const double _totalAllocationFontSize = 20.0; // "총 비중: XX%" 텍스트
  static const double _emptyStateFontSize = 20.0; // "자산을 추가해주세요" 빈 상태 메시지

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RetireSimulatorProvider>();
      _initialAssetController.text = NumberFormat(
        '#,###',
      ).format(provider.initialAsset);
      _monthlyWithdrawalController.text = NumberFormat(
        '#,###',
      ).format(provider.monthlyWithdrawal);
    });
  }

  @override
  void dispose() {
    _initialAssetController.dispose();
    _monthlyWithdrawalController.dispose();
    super.dispose();
  }

  double _parseCurrency(String text) {
    return double.tryParse(text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RetireSimulatorProvider>();
    final appProvider = context.watch<AppStateProvider>();
    final localeCode = Localizations.localeOf(context).languageCode;
    final currencyFormat = NumberFormat.currency(
      symbol: '₩',
      decimalDigits: 0,
      locale: localeCode,
    );

    // 자산 목록 로드
    if (appProvider.assets.isEmpty && !appProvider.isAssetsLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appProvider.loadAssets();
      });
    }

    return Scaffold(
      backgroundColor: AppColors.navyDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('은퇴 자산 시뮬레이션', style: AppTextStyles.appBarTitle),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 입력 영역
            _buildInputSection(provider, currencyFormat),
            SizedBox(height: 32),
            // 자산 포트폴리오
            _buildPortfolioSection(provider, appProvider),
            SizedBox(height: 32),
            // 시뮬레이션 실행 버튼
            if (provider.assets.isNotEmpty && provider.totalAllocation > 0)
              _buildRunButton(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection(
    RetireSimulatorProvider provider,
    NumberFormat currencyFormat,
  ) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.navyMedium,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '시뮬레이션 설정',
            style: AppTextStyles.chartSectionTitle.copyWith(
              fontSize: _sectionTitleFontSize,
            ),
          ),
          SizedBox(height: 20),
          _buildNumberField(
            controller: _initialAssetController,
            label: '초기 자산 금액',
            suffix: '원',
            onChanged: (value) {
              provider.setInitialAsset(_parseCurrency(value));
            },
          ),
          SizedBox(height: 16),
          _buildNumberField(
            controller: _monthlyWithdrawalController,
            label: '월 인출 금액',
            suffix: '원',
            onChanged: (value) {
              provider.setMonthlyWithdrawal(_parseCurrency(value));
            },
          ),
          SizedBox(height: 16),
          // 시뮬레이션 기간 선택 (스크롤 피커)
          _buildSimulationYearsPicker(provider),
          SizedBox(height: 16),
          // 시나리오 선택
          _buildScenarioSelector(provider),
        ],
      ),
    );
  }

  Widget _buildScenarioSelector(RetireSimulatorProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '시나리오 선택',
          style: TextStyle(
            color: AppColors.slate400,
            fontSize: _scenarioLabelFontSize,
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildScenarioButton(
                '긍정적 (+20%)',
                'positive',
                provider.selectedScenario == 'positive',
                AppColors.success,
                () => provider.setSelectedScenario('positive'),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildScenarioButton(
                '중립적 (0%)',
                'neutral',
                provider.selectedScenario == 'neutral',
                AppColors.gold,
                () => provider.setSelectedScenario('neutral'),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildScenarioButton(
                '부정적 (-20%)',
                'negative',
                provider.selectedScenario == 'negative',
                Colors.red,
                () => provider.setSelectedScenario('negative'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScenarioButton(
    String label,
    String value,
    bool isSelected,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : AppColors.navyDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : AppColors.slate700,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? color : AppColors.slate300,
            fontSize: _scenarioButtonFontSize,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    String? suffix,
    bool isInteger = false,
    required Function(String) onChanged,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        labelStyle: TextStyle(
          color: AppColors.slate400,
          fontSize: _textFieldLabelFontSize,
        ),
        suffixStyle: TextStyle(
          color: AppColors.slate300,
          fontSize: _textFieldSuffixFontSize,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.slate700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.slate700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.gold, width: 2),
        ),
      ),
      keyboardType: isInteger
          ? TextInputType.number
          : TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d,]+')),
        TextInputFormatter.withFunction((oldValue, newValue) {
          if (newValue.text.isEmpty) return newValue;
          final cleanText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
          final number = isInteger
              ? int.tryParse(cleanText)
              : double.tryParse(cleanText);
          if (number == null) return oldValue;
          final formatted = isInteger
              ? NumberFormat('#,###').format(number)
              : NumberFormat('#,###').format(number.toInt());
          return TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
        }),
      ],
      style: TextStyle(color: Colors.white, fontSize: _textFieldInputFontSize),
      onChanged: onChanged,
    );
  }

  Widget _buildSimulationYearsPicker(RetireSimulatorProvider provider) {
    return GestureDetector(
      onTap: () {
        _showYearsPicker(context, provider);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.slate700),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '시뮬레이션 기간',
              style: TextStyle(
                color: AppColors.slate400,
                fontSize: _textFieldLabelFontSize,
              ),
            ),
            Row(
              children: [
                Text(
                  '${provider.simulationYears}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _textFieldInputFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  '년',
                  style: TextStyle(
                    color: AppColors.slate300,
                    fontSize: _textFieldSuffixFontSize,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_drop_down, color: AppColors.slate400),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showYearsPicker(
    BuildContext context,
    RetireSimulatorProvider provider,
  ) {
    int selectedYear = provider.simulationYears;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.navyMedium,
      builder: (BuildContext context) {
        return Container(
          height: 250,
          child: Column(
            children: [
              // 헤더
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.navyDark,
                  border: Border(bottom: BorderSide(color: AppColors.slate700)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '시뮬레이션 기간 선택',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        provider.setSimulationYears(selectedYear);
                      },
                      child: Text(
                        '확인',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 피커
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                    initialItem: selectedYear - 1, // 1년부터 시작
                  ),
                  itemExtent: 50,
                  onSelectedItemChanged: (int index) {
                    selectedYear = index + 1; // 1년부터 시작
                  },
                  children: List.generate(50, (index) {
                    final year = index + 1;
                    return Center(
                      child: Text(
                        '$year년',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPortfolioSection(
    RetireSimulatorProvider provider,
    AppStateProvider appProvider,
  ) {
    final localeCode = Localizations.localeOf(context).languageCode;
    final availableAssets = appProvider.assets;
    final selectedAssetIds = provider.assets.map((a) => a.assetId).toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '자산 포트폴리오',
              style: AppTextStyles.chartSectionTitle.copyWith(
                fontSize: _sectionTitleFontSize,
              ),
            ),
            PopupMenuButton<AssetOption>(
              color: AppColors.navyMedium,
              onSelected: (assetOption) {
                provider.addAsset(assetOption.id);
              },
              itemBuilder: (context) {
                return availableAssets
                    .where((asset) => !selectedAssetIds.contains(asset.id))
                    .map((asset) {
                      return PopupMenuItem<AssetOption>(
                        value: asset,
                        child: Row(
                          children: [
                            Text(
                              asset.icon,
                              style: TextStyle(fontSize: _assetIconFontSize),
                            ),
                            SizedBox(width: 12),
                            Text(
                              asset.displayName(localeCode),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: _assetNameFontSize,
                              ),
                            ),
                          ],
                        ),
                      );
                    })
                    .toList();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add,
                      size: _addAssetIconSize,
                      color: AppColors.navyDark,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '자산 추가',
                      style: TextStyle(
                        color: AppColors.navyDark,
                        fontSize: _addAssetButtonFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        if (provider.assets.isEmpty)
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.navyMedium,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.slate700),
            ),
            child: Center(
              child: Text(
                '자산을 추가해주세요',
                style: TextStyle(
                  color: AppColors.slate400,
                  fontSize: _emptyStateFontSize,
                ),
              ),
            ),
          )
        else
          ...provider.assets.asMap().entries.map((entry) {
            AssetOption? assetOption;
            try {
              assetOption = availableAssets.firstWhere(
                (a) => a.id == entry.value.assetId,
              );
            } catch (e) {
              assetOption = null;
            }
            return AssetInputCard(
              asset: entry.value,
              assetOption: assetOption,
              index: entry.key,
              isLoadingCagr: provider.isLoadingCagr(entry.value.assetId),
              onAllocationChanged: (newAllocation) {
                provider.updateAssetAllocation(entry.key, newAllocation);
              },
              onDelete: () {
                provider.removeAsset(entry.key);
              },
            );
          }),
        if (provider.assets.isNotEmpty) ...[
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 20),
                SizedBox(width: 8),
                Text(
                  '총 비중: ${(provider.totalAllocation * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: _totalAllocationFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRunButton(RetireSimulatorProvider provider) {
    final allLoaded = provider.allCagrLoaded;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: allLoaded
            ? () {
                // 결과 화면으로 이동
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const RetireSimulatorResultScreen(),
                  ),
                );
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.navyDark,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          allLoaded ? '시뮬레이션 실행' : '연수익률 로딩 중...',
          style: AppTextStyles.buttonTextPrimary,
        ),
      ),
    );
  }
}
