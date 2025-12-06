import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/asset_option.dart';
import '../providers/retire_simulator_provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/currency_provider.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../widgets/asset_input_card.dart';
import '../widgets/tab_navigation.dart';
import '../l10n/app_localizations.dart';
import '../services/ad_service.dart';
import 'retire_simulator_result_screen.dart';
import 'settings_screen.dart';

class RetireSimulatorScreen extends StatefulWidget {
  const RetireSimulatorScreen({super.key});

  @override
  State<RetireSimulatorScreen> createState() => _RetireSimulatorScreenState();
}

class _RetireSimulatorScreenState extends State<RetireSimulatorScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _initialAssetController = TextEditingController();
  final TextEditingController _monthlyWithdrawalController =
      TextEditingController();
  late AnimationController _iconController;
  String? _lastCurrencySymbol;

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
    _iconController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currencyProvider = context.read<CurrencyProvider>();
      final localeCode = Localizations.localeOf(context).languageCode;
      final currencySymbol = currencyProvider.getCurrencySymbol(localeCode);
      _lastCurrencySymbol = currencySymbol;
      _updateCurrencyBasedDefaults();
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    _initialAssetController.dispose();
    _monthlyWithdrawalController.dispose();
    super.dispose();
  }

  double _parseCurrency(String text) {
    return double.tryParse(text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0.0;
  }

  void _updateCurrencyBasedDefaults() {
    if (!mounted) return;

    final provider = context.read<RetireSimulatorProvider>();
    final currencyProvider = context.read<CurrencyProvider>();
    final localeCode = Localizations.localeOf(context).languageCode;
    final currencySymbol = currencyProvider.getCurrencySymbol(localeCode);

    // 통화에 따라 기본값 조정 (원화 기준값이면 변환)
    double initialAsset = provider.initialAsset;
    double monthlyWithdrawal = provider.monthlyWithdrawal;

    // 원화 기본값인 경우 통화에 맞게 변환
    if (initialAsset == 1000000000 && monthlyWithdrawal == 5000000) {
      switch (currencySymbol) {
        case '\$':
          // 달러: 10억 원 → 100만 달러, 500만 원 → 5천 달러
          initialAsset = 1000000; // $1,000,000
          monthlyWithdrawal = 5000; // $5,000
          provider.setInitialAsset(initialAsset);
          provider.setMonthlyWithdrawal(monthlyWithdrawal);
          break;
        case '¥':
          // 엔: 10억 원 → 1억 5천만 엔 (약 1,000원 = 150엔 가정), 500만 원 → 75만 엔
          initialAsset = 150000000; // ¥150,000,000
          monthlyWithdrawal = 750000; // ¥750,000
          provider.setInitialAsset(initialAsset);
          provider.setMonthlyWithdrawal(monthlyWithdrawal);
          break;
        case 'CN¥':
          // 위안: 10억 원 → 700만 위안 (약 1,000원 = 7위안 가정), 500만 원 → 3.5만 위안
          initialAsset = 7000000; // CN¥7,000,000
          monthlyWithdrawal = 35000; // CN¥35,000
          provider.setInitialAsset(initialAsset);
          provider.setMonthlyWithdrawal(monthlyWithdrawal);
          break;
        case '₩':
        default:
          // 원화는 그대로
          break;
      }
    }

    // 통화가 변경되면 항상 입력 필드 텍스트를 현재 값으로 업데이트
    _initialAssetController.text = NumberFormat(
      '#,###',
    ).format(provider.initialAsset);
    _monthlyWithdrawalController.text = NumberFormat(
      '#,###',
    ).format(provider.monthlyWithdrawal);
  }

  Widget _buildAnimatedIcon(IconData icon, double delay) {
    return AnimatedBuilder(
      animation: _iconController,
      builder: (context, child) {
        double value = _iconController.value + delay;
        if (value > 1.0) value -= 1.0;
        double yOffset = -10 * (value < 0.5 ? value * 2 : (1 - value) * 2);

        return Transform.translate(
          offset: Offset(0, yOffset),
          child: Icon(icon, size: 40, color: AppColors.gold),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RetireSimulatorProvider>();
    final appProvider = context.watch<AppStateProvider>();
    final currencyProvider = context.watch<CurrencyProvider>();
    final localeCode = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;
    final currencySymbol = currencyProvider.getCurrencySymbol(localeCode);
    final currencyFormat = NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: 0,
      locale: localeCode,
    );

    // 통화가 변경되면 기본값 업데이트 및 입력 필드 새로고침
    if (_lastCurrencySymbol != currencySymbol) {
      _lastCurrencySymbol = currencySymbol;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateCurrencyBasedDefaults();
        }
      });
    }

    // 자산 목록 로드
    if (appProvider.assets.isEmpty && !appProvider.isAssetsLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appProvider.loadAssets();
      });
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.navyDark, AppColors.navyMedium],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: GestureDetector(
            onTap: () {
              // 텍스트 필드 외부 클릭 시 포커스 해제 및 키보드 닫기
              FocusScope.of(context).unfocus();
            },
            behavior: HitTestBehavior.opaque,
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 탭 버튼 (투자 시뮬레이션 / 은퇴 자산 시뮬레이션)
                  TabNavigation(isHomeScreen: false),
                  SizedBox(height: 24),
                  // 홈 화면 스타일 질문 섹션
                  _buildQuestionSection(l10n),
                  SizedBox(height: 36),
                  // 입력 영역
                  _buildInputSection(provider, currencyFormat, l10n),
                  SizedBox(height: 32),
                  // 자산 포트폴리오
                  _buildPortfolioSection(provider, appProvider, l10n),
                  SizedBox(height: 32),
                  // 시뮬레이션 실행 버튼
                  if (provider.assets.isNotEmpty &&
                      provider.totalAllocation > 0)
                    _buildRunButton(provider, l10n),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAnimatedIcon(Icons.trending_up, 0.0),
            SizedBox(width: 16),
            _buildAnimatedIcon(Icons.calendar_today, 0.3),
            SizedBox(width: 16),
            _buildAnimatedIcon(Icons.bar_chart, 0.6),
          ],
        ),
        SizedBox(height: 32),
        Text(
          l10n.retirementQuestionPart1,
          textAlign: TextAlign.center,
          style: AppTextStyles.homeMainQuestion.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          l10n.retirementQuestionPart2,
          textAlign: TextAlign.center,
          style: AppTextStyles.homeMainQuestion.copyWith(
            color: AppColors.gold,
            fontSize: 30,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 16),
        Text(
          l10n.retirementDescription,
          textAlign: TextAlign.center,
          style: AppTextStyles.homeSubDescription,
        ),
      ],
    );
  }

  String _getCurrencyUnit(String currencySymbol) {
    final l10n = AppLocalizations.of(context)!;
    switch (currencySymbol) {
      case '₩':
        return l10n.won;
      case '\$':
        return l10n.dollar;
      case '¥':
        return l10n.yen;
      case 'CN¥':
        return l10n.yuan;
      default:
        return currencySymbol;
    }
  }

  Widget _buildInputSection(
    RetireSimulatorProvider provider,
    NumberFormat currencyFormat,
    AppLocalizations l10n,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                l10n.simulationSettings,
                style: AppTextStyles.chartSectionTitle.copyWith(
                  fontSize: _sectionTitleFontSize,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.currency_exchange,
                  color: AppColors.gold,
                  size: 24,
                ),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                tooltip: l10n.currencySettings,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildNumberField(
            controller: _initialAssetController,
            label: l10n.initialAssetAmount,
            suffix: _getCurrencyUnit(currencyFormat.currencySymbol),
            onChanged: (value) {
              provider.setInitialAsset(_parseCurrency(value));
            },
          ),
          SizedBox(height: 16),
          _buildNumberField(
            controller: _monthlyWithdrawalController,
            label: l10n.monthlyWithdrawalAmount,
            suffix: _getCurrencyUnit(currencyFormat.currencySymbol),
            onChanged: (value) {
              provider.setMonthlyWithdrawal(_parseCurrency(value));
            },
          ),
          SizedBox(height: 16),
          // 시뮬레이션 기간 선택 (스크롤 피커)
          _buildSimulationYearsPicker(provider, l10n),
          SizedBox(height: 16),
          // 시나리오 선택
          _buildScenarioSelector(provider, l10n),
        ],
      ),
    );
  }

  Widget _buildScenarioSelector(
    RetireSimulatorProvider provider,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.scenarioSelection,
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
                l10n.scenarioPositive,
                'positive',
                provider.selectedScenario == 'positive',
                AppColors.success,
                () => provider.setSelectedScenario('positive'),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildScenarioButton(
                l10n.scenarioNeutral,
                'neutral',
                provider.selectedScenario == 'neutral',
                AppColors.gold,
                () => provider.setSelectedScenario('neutral'),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildScenarioButton(
                l10n.scenarioNegative,
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

  Widget _buildSimulationYearsPicker(
    RetireSimulatorProvider provider,
    AppLocalizations l10n,
  ) {
    return GestureDetector(
      onTap: () {
        _showYearsPicker(context, provider, l10n);
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
            Flexible(
              child: Text(
                l10n.duration,
                style: TextStyle(
                  color: AppColors.slate400,
                  fontSize: _textFieldLabelFontSize,
                ),
                overflow: TextOverflow.ellipsis,
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
                  l10n.year,
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
    AppLocalizations l10n,
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
                      l10n.selectSimulationDuration,
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
                        l10n.confirm,
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
                        '${l10n.yearLabel(year)}',
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
    AppLocalizations l10n,
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
              l10n.assetPortfolio,
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
                      l10n.addAsset,
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
                l10n.pleaseAddAssets,
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
              l10n: l10n,
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
                  '${l10n.totalAllocation}: ${(provider.totalAllocation * 100).toStringAsFixed(1)}%',
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

  Widget _buildRunButton(
    RetireSimulatorProvider provider,
    AppLocalizations l10n,
  ) {
    final allLoaded = provider.allCagrLoaded;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: allLoaded
            ? () async {
                // Show loading dialog
                if (!mounted) return;
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  barrierColor: Colors.black.withValues(alpha: 0.7),
                  builder: (context) => WillPopScope(
                    onWillPop: () async => false,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.gold,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                );

                // Load ad settings
                await AdService.shared.loadSettings();

                if (!mounted) return;

                // Show ad
                await AdService.shared.showInterstitialAd(
                  onAdDismissed: () {
                    if (!mounted) return;
                    Navigator.of(context).pop(); // Close loading dialog
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            const RetireSimulatorResultScreen(),
                      ),
                    );
                  },
                  onAdFailedToShow: () {
                    // If ad fails, close loading dialog and proceed
                    if (!mounted) return;
                    Navigator.of(context).pop(); // Close loading dialog
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            const RetireSimulatorResultScreen(),
                      ),
                    );
                  },
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
          allLoaded ? l10n.runSimulation : l10n.loadingAnnualReturn,
          style: AppTextStyles.buttonTextPrimary,
        ),
      ),
    );
  }
}
