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

  void _calculateAndNavigate() {
    final provider = context.read<AppStateProvider>();
    double? amount = double.tryParse(_amountController.text);
    if (amount != null) {
      provider.updateConfig(amount: amount);
      provider.calculate();
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => ResultScreen()));
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
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              height: config.type == InvestmentType.recurring ? 100 : 0,
              child: SingleChildScrollView(
                physics: NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    Text(
                      "투자 주기",
                      style: TextStyle(color: AppColors.slate300, fontSize: 16),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        _buildRadio(Frequency.monthly, "매월", config, provider),
                        SizedBox(width: 20),
                        _buildRadio(Frequency.weekly, "매주", config, provider),
                      ],
                    ),
                  ],
                ),
              ),
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

  Widget _buildRadio(
    Frequency value,
    String label,
    InvestmentConfig config,
    AppStateProvider provider,
  ) {
    bool isSelected = config.frequency == value;
    return GestureDetector(
      onTap: () => provider.updateConfig(frequency: value),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.gold : AppColors.slate400,
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.gold,
                      ),
                    ),
                  )
                : null,
          ),
          SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.slate400,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _getSummaryText(InvestmentConfig config) {
    String asset = config.asset == 'bitcoin' ? '비트코인' : '테슬라';
    String amount = _amountController.text;
    String period = "${config.yearsAgo}년 전부터";

    if (config.type == InvestmentType.single) {
      return "$period $asset에 \$$amount를 한 번 투자했다면...";
    } else {
      String freq = config.frequency == Frequency.monthly ? "매월" : "매주";
      int totalPeriods = config.frequency == Frequency.monthly
          ? config.yearsAgo * 12
          : config.yearsAgo * 52;
      double totalAmount = double.tryParse(amount) ?? 0;
      double perPeriodAmount = totalAmount / totalPeriods;
      String periodUnit = config.frequency == Frequency.monthly ? "개월" : "주";

      return "$period $asset에 $freq \$${perPeriodAmount.toStringAsFixed(2)}씩 투자 (총 $totalPeriods$periodUnit)";
    }
  }
}
