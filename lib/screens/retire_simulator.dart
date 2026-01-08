import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../models/asset_option.dart';
import '../providers/retire_simulator_provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/currency_provider.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../widgets/asset_input_card.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/retirement_setup_dialog.dart';
import '../l10n/app_localizations.dart';
import '../services/ad_service.dart';
import 'retire_simulator_result_screen.dart';
import 'settings_screen.dart';

class RetireSimulatorScreen extends StatefulWidget {
  final bool isVisible;

  const RetireSimulatorScreen({super.key, this.isVisible = false});

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
  bool _hasShownSetupDialog = false; // 다이얼로그 표시 여부 추적

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<RetireSimulatorProvider>();
      final currencySymbol = CurrencyProvider.shared.getCurrencySymbol();
      _lastCurrencySymbol = currencySymbol;

      // 저장된 설정 로드
      await provider.loadSettings();

      // 화면이 보일 때만 다이얼로그 표시 (initState에서는 표시하지 않음)
      _updateCurrencyBasedDefaults();
    });
  }

  @override
  void didUpdateWidget(RetireSimulatorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 화면이 보이게 되었을 때만 다이얼로그 표시
    if (widget.isVisible && !oldWidget.isVisible && !_hasShownSetupDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndShowSetupDialog();
      });
    }
  }

  @override
  void dispose() {
    _iconController.dispose();
    _initialAssetController.dispose();
    _monthlyWithdrawalController.dispose();
    super.dispose();
  }

  Future<void> _checkAndShowSetupDialog() async {
    if (_hasShownSetupDialog || !mounted) return;

    final provider = context.read<RetireSimulatorProvider>();
    final currencySymbol = CurrencyProvider.shared.getCurrencySymbol();
    _lastCurrencySymbol = currencySymbol;

    // 저장된 설정이 없으면 단계별 입력 다이얼로그 표시
    final hasSetup = await provider.hasSavedSettings();
    if (!hasSetup && mounted) {
      _hasShownSetupDialog = true;
      final currencyUnit = _getCurrencyUnit(currencySymbol);
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => RetirementSetupDialog(
          currencySymbol: currencySymbol,
          currencyUnit: currencyUnit,
        ),
      );
      // 다이얼로그가 닫힌 후 입력 필드 업데이트
      if (mounted) {
        _updateCurrencyBasedDefaults();
      }
    }
  }

  double _parseCurrency(String text) {
    return double.tryParse(text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0.0;
  }

  void _updateCurrencyBasedDefaults() {
    if (!mounted) return;

    final provider = context.read<RetireSimulatorProvider>();

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
    final localeCode = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: CurrencyProvider.shared,
      builder: (context, _) {
        final currencySymbol = CurrencyProvider.shared.getCurrencySymbol();
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
              // Provider에서 통화 기본값 업데이트
              provider.updateCurrencyDefaults(currencySymbol);
              // 입력 필드 텍스트 업데이트
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
            child: GestureDetector(
              onTap: () {
                // 텍스트 필드 외부 클릭 시 포커스 해제 및 키보드 닫기
                FocusScope.of(context).unfocus();
              },
              behavior: HitTestBehavior.opaque,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20,
                  bottom: MediaQuery.of(context).padding.bottom + 30,
                  left: 24,
                  right: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 24),
                    // 서술형 질문 섹션 (입력 필드 포함)
                    _buildQuestionSection(
                      provider,
                      appProvider,
                      currencyFormat,
                      l10n,
                    ),
                    SizedBox(height: 36),
                    // 입력 영역 (시나리오 선택만)
                    _buildInputSection(provider, currencyFormat, l10n),
                    SizedBox(height: 32),
                    // 자산 포트폴리오
                    _buildPortfolioSection(
                      provider,
                      appProvider,
                      l10n,
                      currencyFormat,
                    ),
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
        );
      },
    );
  }

  Widget _buildQuestionSection(
    RetireSimulatorProvider provider,
    AppStateProvider appProvider,
    NumberFormat currencyFormat,
    AppLocalizations l10n,
  ) {
    final currencyUnit = _getCurrencyUnit(currencyFormat.currencySymbol);

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
        // 서술형 질문 (입력 필드 포함)
        _buildDescriptiveQuestion(
          provider: provider,
          currencyUnit: currencyUnit,
          l10n: l10n,
          appProvider: appProvider,
          isLargeText: false,
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
    // 시나리오 선택과 인플레이션율 입력
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildScenarioSelector(provider, l10n),
        SizedBox(height: 24),
        _buildInflationRateInput(provider, l10n),
      ],
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
      onTap: () {
        // 시나리오 버튼 클릭 시 포커스 해제
        FocusScope.of(context).unfocus();
        onTap();
      },
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

  Widget _buildInflationRateInput(
    RetireSimulatorProvider provider,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.inflationRate,
          style: TextStyle(
            color: AppColors.slate400,
            fontSize: _scenarioLabelFontSize,
          ),
        ),
        SizedBox(height: 8),
        Text(
          l10n.inflationRateDesc,
          style: TextStyle(color: AppColors.slate400, fontSize: 14),
        ),
        SizedBox(height: 12),
        LiquidGlass(
          blur: 10,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Slider(
                  value: provider.inflationRate,
                  min: 0.0,
                  max: 0.10, // 0% ~ 10%
                  divisions: 100,
                  label:
                      '${(provider.inflationRate * 100).toStringAsFixed(1)}%',
                  activeColor: AppColors.gold,
                  inactiveColor: AppColors.slate700,
                  onChanged: (value) {
                    provider.setInflationRate(value);
                  },
                ),
              ),
              SizedBox(width: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: SelectedButtonStyle.solidBoxDecoration(
                      BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(provider.inflationRate * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: AppColors.navyDark,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptiveQuestion({
    required RetireSimulatorProvider provider,
    required String currencyUnit,
    required AppLocalizations l10n,
    required AppStateProvider appProvider,
    bool isLargeText = false,
  }) {
    final localeCode = Localizations.localeOf(context).languageCode;
    final textSize = isLargeText ? 30.0 : 18.0;
    final textWeight = isLargeText ? FontWeight.w800 : FontWeight.w500;
    final textColor = isLargeText ? AppColors.gold : Colors.white;

    // 선택된 자산 목록 가져오기
    final selectedAssetIds = provider.assets.map((a) => a.assetId).toList();
    final availableAssets = appProvider.assets;
    final selectedAssetNames = selectedAssetIds.map((id) {
      try {
        final assetOption = availableAssets.firstWhere((a) => a.id == id);
        return assetOption.displayName();
      } catch (e) {
        return id; // 자산 옵션을 찾을 수 없으면 ID 사용
      }
    }).toList();
    final assetListText = selectedAssetNames.isEmpty
        ? ''
        : selectedAssetNames.join(', ');

    // 한국어, 일본어, 중국어: "내 돈 [금액] 으로 자산 [비트코인, 이더리움] 을 보유하고 매월 [금액]원 [년]년 놀고 먹을 수 있을까?"
    // 영어: "With my money [amount], holding assets [Bitcoin, Ethereum], can I play and eat for [years] years by spending [amount] monthly?"
    if (localeCode == 'en') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 첫 번째 줄: "With my money [amount],"
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text(
                'With my money ',
                style: TextStyle(
                  color: textColor,
                  fontSize: textSize,
                  fontWeight: textWeight,
                ),
              ),
              _buildInlineTextField(
                controller: _initialAssetController,
                currencyUnit: currencyUnit,
                onChanged: (value) {
                  provider.setInitialAsset(_parseCurrency(value));
                },
                isLarge: isLargeText,
              ),
              Text(
                ',',
                style: TextStyle(
                  color: textColor,
                  fontSize: textSize,
                  fontWeight: textWeight,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          // 두 번째 줄: "holding assets [Bitcoin, Ethereum],"
          if (assetListText.isNotEmpty)
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(
                  'holding assets ',
                  style: TextStyle(
                    color: textColor,
                    fontSize: textSize,
                    fontWeight: textWeight,
                  ),
                ),
                Text(
                  assetListText,
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: textSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ',',
                  style: TextStyle(
                    color: textColor,
                    fontSize: textSize,
                    fontWeight: textWeight,
                  ),
                ),
              ],
            ),
          if (assetListText.isNotEmpty) SizedBox(height: 8),
          // 세 번째 줄: "can I play and eat for [years] years by spending [amount]"
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text(
                'can I play and eat for ',
                style: TextStyle(
                  color: textColor,
                  fontSize: textSize,
                  fontWeight: textWeight,
                ),
              ),
              _buildInlineYearPicker(provider, l10n, isLarge: isLargeText),
              Text(
                ' by spending ',
                style: TextStyle(
                  color: textColor,
                  fontSize: textSize,
                  fontWeight: textWeight,
                ),
              ),
              _buildInlineTextField(
                controller: _monthlyWithdrawalController,
                currencyUnit: currencyUnit,
                onChanged: (value) {
                  provider.setMonthlyWithdrawal(_parseCurrency(value));
                },
                isLarge: isLargeText,
              ),
            ],
          ),
          SizedBox(height: 8),
          // 네 번째 줄: "monthly?" + 통화 설정 버튼
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  'monthly?',
                  style: TextStyle(
                    color: textColor,
                    fontSize: textSize,
                    fontWeight: textWeight,
                  ),
                ),
              ),
              SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
                child: Tooltip(
                  message: l10n.currencySettings,
                  child: Icon(
                    Icons.currency_exchange,
                    color: AppColors.gold,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // 한국어, 일본어, 중국어
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 첫 번째 줄: "내 돈 [금액] 으로"
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '내 돈 ', // "내 자산" 대신 "내 돈" 사용
                style: TextStyle(
                  color: textColor,
                  fontSize: textSize,
                  fontWeight: textWeight,
                ),
              ),
              SizedBox(width: 8),
              _buildInlineTextField(
                controller: _initialAssetController,
                currencyUnit: currencyUnit,
                onChanged: (value) {
                  provider.setInitialAsset(_parseCurrency(value));
                },
                isLarge: isLargeText,
              ),
              SizedBox(width: 8),
              Text(
                ' 으로',
                style: TextStyle(
                  color: textColor,
                  fontSize: textSize,
                  fontWeight: textWeight,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          // 두 번째 줄: "자산 [비트코인, 이더리움] 을 보유하고"
          if (assetListText.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '자산 ',
                  style: TextStyle(
                    color: textColor,
                    fontSize: textSize,
                    fontWeight: textWeight,
                  ),
                ),
                Flexible(
                  child: Text(
                    assetListText,
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: textSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  ' 을 보유하고',
                  style: TextStyle(
                    color: textColor,
                    fontSize: textSize,
                    fontWeight: textWeight,
                  ),
                ),
              ],
            ),
          if (assetListText.isNotEmpty) SizedBox(height: 8),
          // 세 번째 줄: "매월" + [월 인출 금액 입력] + "을 쓰면서"
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                l10n.retirementQuestionMonthlyPrefix,
                style: TextStyle(
                  color: textColor,
                  fontSize: textSize,
                  fontWeight: textWeight,
                ),
              ),
              SizedBox(width: 8),
              _buildInlineTextField(
                controller: _monthlyWithdrawalController,
                currencyUnit: currencyUnit,
                onChanged: (value) {
                  provider.setMonthlyWithdrawal(_parseCurrency(value));
                },
                isLarge: isLargeText,
              ),
              SizedBox(width: 8),
              Text(
                l10n.retirementQuestionSuffix,
                style: TextStyle(
                  color: textColor,
                  fontSize: textSize,
                  fontWeight: textWeight,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          // 네 번째 줄: [년 선택] + "동안 놀고 먹을 수 있을까?" + 통화 설정 버튼
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildInlineYearPicker(provider, l10n, isLarge: isLargeText),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  l10n.retirementQuestionEnd,
                  style: TextStyle(
                    color: textColor,
                    fontSize: textSize,
                    fontWeight: textWeight,
                  ),
                ),
              ),
              SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
                child: Tooltip(
                  message: l10n.currencySettings,
                  child: Icon(
                    Icons.currency_exchange,
                    color: AppColors.gold,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildInlineTextField({
    required TextEditingController controller,
    required String currencyUnit,
    required Function(String) onChanged,
    bool isLarge = false,
  }) {
    final fontSize = isLarge ? 30.0 : 18.0;
    final suffixSize = isLarge ? 24.0 : 16.0;
    final textStyle = TextStyle(
      color: AppColors.gold,
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
    );
    final suffixStyle = TextStyle(
      color: AppColors.gold,
      fontSize: suffixSize,
      fontWeight: FontWeight.bold,
    );

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        // 텍스트 너비 계산
        final displayText = value.text.isEmpty ? '0' : value.text;
        final textPainter = TextPainter(
          text: TextSpan(text: displayText, style: textStyle),
          textDirection: Directionality.of(context),
        );
        textPainter.layout();

        // 통화 단위 너비 계산
        final suffixPainter = TextPainter(
          text: TextSpan(text: currencyUnit, style: suffixStyle),
          textDirection: Directionality.of(context),
        );
        suffixPainter.layout();

        // 전체 너비 = 텍스트 너비 + 통화 단위 너비 + 패딩
        final minWidth = 100.0;
        final calculatedWidth =
            textPainter.width +
            suffixPainter.width +
            20; // 패딩 포함 (horizontal: 4 * 2 = 8, 여유 공간 12)
        final fieldWidth = calculatedWidth < minWidth
            ? minWidth
            : calculatedWidth;

        return Container(
          width: fieldWidth,
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              suffixText: currencyUnit,
              suffixStyle: suffixStyle,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 4,
                vertical: isLarge ? 12 : 8,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d,]+')),
              TextInputFormatter.withFunction((oldValue, newValue) {
                if (newValue.text.isEmpty) return newValue;
                final cleanText = newValue.text.replaceAll(
                  RegExp(r'[^\d]'),
                  '',
                );
                final number = int.tryParse(cleanText);
                if (number == null) return oldValue;
                final formatted = NumberFormat('#,###').format(number);
                return TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              }),
            ],
            textAlign: TextAlign.right,
            style: textStyle,
            onChanged: onChanged,
          ),
        );
      },
    );
  }

  Widget _buildInlineYearPicker(
    RetireSimulatorProvider provider,
    AppLocalizations l10n, {
    bool isLarge = false,
  }) {
    final fontSize = isLarge ? 30.0 : 18.0;
    final iconSize = isLarge ? 28.0 : 20.0;
    final padding = isLarge
        ? EdgeInsets.symmetric(horizontal: 12, vertical: 8)
        : EdgeInsets.symmetric(horizontal: 8, vertical: 4);

    return GestureDetector(
      onTap: () {
        _showYearsPicker(context, provider, l10n);
      },
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.gold, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${provider.simulationYears}',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 4),
            Text(
              l10n.year,
              style: TextStyle(
                color: AppColors.gold,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: AppColors.gold, size: iconSize),
          ],
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
        // 키보드 포커스 제거
        FocusScope.of(context).unfocus();
        _showYearsPicker(context, provider, l10n);
      },
      child: LiquidGlass(
        blur: 10,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1.5,
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      isDismissible: true,
      enableDrag: true,
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
                        // 키보드 포커스 제거
                        FocusScope.of(context).unfocus();
                        Navigator.pop(context);
                        // 모달이 닫힌 후에도 포커스가 다시 생기지 않도록
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (context.mounted) {
                            FocusScope.of(context).unfocus();
                          }
                        });
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
    ).then((_) {
      // 모달이 닫힌 후에도 포커스 제거 보장
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    });
  }

  Widget _buildPortfolioSection(
    RetireSimulatorProvider provider,
    AppStateProvider appProvider,
    AppLocalizations l10n,
    NumberFormat currencyFormat,
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
            GestureDetector(
              onTap: () {
                // 포커스 제거를 먼저 수행
                FocusScope.of(context).unfocus();

                final availableAssetsList = availableAssets
                    .where((asset) => !selectedAssetIds.contains(asset.id))
                    .toList();

                if (availableAssetsList.isEmpty) return;

                // 모달이 닫힐 때 포커스 제거를 보장하기 위해
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  isDismissible: true,
                  enableDrag: true,
                  barrierColor: Colors.black.withValues(alpha: 0.5),
                  builder: (context) {
                    // 모달 내부에서 barrier 탭을 감지하여 포커스 제거
                    return WillPopScope(
                      onWillPop: () async {
                        FocusScope.of(context).unfocus();
                        return true;
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                              border: Border(
                                top: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            child: SafeArea(
                              child: Container(
                                constraints: BoxConstraints(
                                  maxHeight:
                                      MediaQuery.of(context).size.height * 0.6,
                                ),
                                child: ListView(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  children: availableAssetsList.map((asset) {
                                    return InkWell(
                                      onTap: () {
                                        // 키보드 포커스 제거
                                        FocusScope.of(context).unfocus();
                                        Navigator.pop(context);
                                        // 자산 추가 후에도 포커스가 다시 생기지 않도록
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                              if (context.mounted) {
                                                FocusScope.of(
                                                  context,
                                                ).unfocus();
                                              }
                                            });
                                        provider.addAsset(asset.id);
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              asset.icon,
                                              style: TextStyle(
                                                fontSize: _assetIconFontSize,
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              asset.displayName(),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: _assetNameFontSize,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ).then((_) {
                  // 모달이 닫힌 후에도 포커스 제거 보장 (드래그로 닫거나 외부 탭으로 닫을 때)
                  // barrier 탭이 뒤로 전파되어 포커스가 생기는 것을 방지하기 위해
                  // 여러 프레임에 걸쳐 포커스를 확인하고 제거
                  if (mounted) {
                    // 즉시 포커스 제거
                    FocusScope.of(context).unfocus();

                    // barrier 탭 이벤트가 완전히 처리될 때까지 여러 번 포커스 제거
                    for (int i = 0; i < 3; i++) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          FocusScope.of(context).unfocus();
                        }
                      });
                    }
                  }
                });
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: SelectedButtonStyle.solidBoxDecoration(
                      BorderRadius.circular(8),
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
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        if (provider.assets.isEmpty)
          LiquidGlass(
            blur: 10,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1.5,
              ),
            ),
            padding: EdgeInsets.all(20),
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
              onRetryLoadCagr: () {
                provider.retryLoadCagr(entry.value.assetId);
              },
              l10n: l10n,
              initialAsset: provider.initialAsset,
              currencyFormat: currencyFormat,
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
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 20,
                    ),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: GestureDetector(
            onTap: allLoaded
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

                    // Show ad
                    await AdService.shared.showFullScreenAd(
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
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 16),
              decoration: SelectedButtonStyle.solidBoxDecoration(
                BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  allLoaded ? l10n.runSimulation : l10n.loadingAnnualReturn,
                  style: AppTextStyles.buttonTextPrimary.copyWith(
                    color: AppColors.navyDark,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
