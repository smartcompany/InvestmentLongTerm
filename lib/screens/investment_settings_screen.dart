import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/investment_config.dart';
import '../providers/app_state_provider.dart';
import '../utils/colors.dart';
import 'result_screen.dart';

class InvestmentSettingsScreen extends StatefulWidget {
  const InvestmentSettingsScreen({super.key});

  @override
  State<InvestmentSettingsScreen> createState() =>
      _InvestmentSettingsScreenState();
}

class _InvestmentSettingsScreenState extends State<InvestmentSettingsScreen> {
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final config = context.read<AppStateProvider>().config;
    _amountController.text = config.amount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _calculateAndNavigate() async {
    final provider = context.read<AppStateProvider>();
    double? amount = double.tryParse(_amountController.text);
    if (amount != null) {
      provider.updateConfig(amount: amount);
      await provider.calculate();

      if (!mounted) return;

      if (provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('계산 실패: ${provider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => ResultScreen()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final config = provider.config;

    return Scaffold(
      backgroundColor: AppColors.navyDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              config.asset == 'bitcoin' ? "비트코인 투자 설정" : "테슬라 투자 설정",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 40),

            // Years Slider
            Text(
              "투자 시작 시점: ${config.yearsAgo}년 전",
              style: TextStyle(color: AppColors.slate300, fontSize: 16),
            ),
            SizedBox(height: 10),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppColors.gold,
                inactiveTrackColor: AppColors.slate700,
                thumbColor: AppColors.gold,
                overlayColor: AppColors.gold.withValues(alpha: 0.2),
                trackHeight: 4,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10),
              ),
              child: Slider(
                value: config.yearsAgo.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                onChanged: (value) {
                  provider.updateConfig(yearsAgo: value.toInt());
                },
              ),
            ),

            SizedBox(height: 30),

            // Amount Input
            Text(
              "투자 금액",
              style: TextStyle(color: AppColors.slate300, fontSize: 16),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                prefixText: "\$ ",
                prefixStyle: TextStyle(
                  color: AppColors.gold,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.slate700),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.gold),
                ),
              ),
            ),

            SizedBox(height: 30),

            // Investment Type
            Text(
              "투자 방식",
              style: TextStyle(color: AppColors.slate300, fontSize: 16),
            ),
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<InvestmentType>(
                segments: [
                  ButtonSegment(
                    value: InvestmentType.single,
                    label: Text("단일 투자"),
                  ),
                  ButtonSegment(
                    value: InvestmentType.recurring,
                    label: Text("정기 투자"),
                  ),
                ],
                selected: {config.type},
                onSelectionChanged: (Set<InvestmentType> newSelection) {
                  provider.updateConfig(type: newSelection.first);
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>((
                    states,
                  ) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.gold;
                    }
                    return AppColors.navyMedium;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith<Color>((
                    states,
                  ) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.navyDark;
                    }
                    return Colors.white;
                  }),
                ),
              ),
            ),

            // Frequency (Animated)
            AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: config.type == InvestmentType.recurring
                  ? Padding(
                      key: ValueKey("frequency-options"),
                      padding: EdgeInsets.only(top: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "투자 주기 (중복 선택 가능)",
                            style:
                                TextStyle(color: AppColors.slate300, fontSize: 16),
                          ),
                          SizedBox(height: 12),
                          Wrap(
                            spacing: 16,
                            runSpacing: 12,
                            children: [
                              _buildFrequencyOption(
                                Frequency.monthly,
                                "매월",
                                provider,
                              ),
                              _buildFrequencyOption(
                                Frequency.weekly,
                                "매주",
                                provider,
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            "둘 다 선택하면 단일 투자와 함께 그래프로 비교해볼 수 있어요.",
                            style: TextStyle(
                              color: AppColors.slate400,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SizedBox.shrink(key: ValueKey("frequency-empty")),
            ),

            SizedBox(height: 40),

            // Summary Preview
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.navyMedium,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.slate700),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.gold),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getSummaryText(config),
                      style: TextStyle(color: AppColors.slate300),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 40),

            // Calculate Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _calculateAndNavigate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navyDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "결과 보기",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyOption(
    Frequency value,
    String label,
    AppStateProvider provider,
  ) {
    final isSelected = provider.config.selectedFrequencies.contains(value);

    return GestureDetector(
      onTap: () => provider.toggleFrequencySelection(value),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.slate700,
          ),
          color: isSelected
              ? AppColors.gold.withValues(alpha: 0.08)
              : AppColors.navyMedium,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected ? AppColors.gold : AppColors.slate400,
                  width: 2,
                ),
                color: isSelected ? AppColors.gold : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 14,
                      color: AppColors.navyDark,
                    )
                  : null,
            ),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSummaryText(InvestmentConfig config) {
    String asset = config.asset == 'bitcoin' ? '비트코인' : '테슬라';
    String amount = _amountController.text.isEmpty ? '0' : _amountController.text;
    String period = "${config.yearsAgo}년 전부터";

    if (config.type == InvestmentType.single) {
      return "$period $asset에 \$$amount를 한 번 투자했다면...";
    } else {
      final hasMonthly = config.selectedFrequencies.contains(Frequency.monthly);
      final hasWeekly = config.selectedFrequencies.contains(Frequency.weekly);

      String freqLabel;
      if (hasMonthly && hasWeekly) {
        freqLabel = "매월과 매주";
      } else if (hasMonthly) {
        freqLabel = "매월";
      } else {
        freqLabel = "매주";
      }

      return "$period $asset에 $freqLabel 각각 동일한 총 투자금 \$$amount을 투자하면 어떻게 될까요?";
    }
  }
}
