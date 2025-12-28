import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/retire_simulator_provider.dart';
import '../utils/colors.dart';
import '../widgets/liquid_glass.dart';
import '../l10n/app_localizations.dart';

class RetirementSetupDialog extends StatefulWidget {
  final String currencySymbol;
  final String currencyUnit;

  const RetirementSetupDialog({
    super.key,
    required this.currencySymbol,
    required this.currencyUnit,
  });

  @override
  State<RetirementSetupDialog> createState() => _RetirementSetupDialogState();
}

class _RetirementSetupDialogState extends State<RetirementSetupDialog>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  int _currentStep = 0;

  final TextEditingController _initialAssetController = TextEditingController();
  final TextEditingController _monthlyWithdrawalController =
      TextEditingController();
  int _selectedYears = 5;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _initialAssetController.dispose();
    _monthlyWithdrawalController.dispose();
    super.dispose();
  }

  double _parseCurrency(String text) {
    return double.tryParse(text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0.0;
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _animationController.forward().then((_) {
        _pageController.nextPage(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _animationController.reset();
        setState(() {
          _currentStep++;
        });
      });
    } else {
      _complete();
    }
  }

  void _complete() async {
    final provider = context.read<RetireSimulatorProvider>();
    final initialAsset = _parseCurrency(_initialAssetController.text);
    final monthlyWithdrawal = _parseCurrency(_monthlyWithdrawalController.text);

    if (initialAsset > 0 && monthlyWithdrawal > 0 && _selectedYears > 0) {
      provider.setInitialAsset(initialAsset);
      provider.setMonthlyWithdrawal(monthlyWithdrawal);
      provider.setSimulationYears(_selectedYears);
      await provider.saveSettings();

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Widget _buildStepIndicator(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepDot(0, l10n),
        SizedBox(width: 8),
        Container(
          width: 40,
          height: 2,
          color: _currentStep > 0 ? AppColors.gold : AppColors.slate700,
        ),
        SizedBox(width: 8),
        _buildStepDot(1, l10n),
        SizedBox(width: 8),
        Container(
          width: 40,
          height: 2,
          color: _currentStep > 1 ? AppColors.gold : AppColors.slate700,
        ),
        SizedBox(width: 8),
        _buildStepDot(2, l10n),
      ],
    );
  }

  Widget _buildStepDot(int step, AppLocalizations l10n) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive || isCompleted ? AppColors.gold : AppColors.slate700,
      ),
      child: Center(
        child: isCompleted
            ? Icon(Icons.check, color: AppColors.navyDark, size: 20)
            : Text(
                '${step + 1}',
                style: TextStyle(
                  color: isActive ? AppColors.navyDark : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildStep1(AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.retirementQuestionPart1,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 24),
        TextField(
          controller: _initialAssetController,
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: TextStyle(color: AppColors.slate400),
            suffixText: widget.currencyUnit,
            suffixStyle: TextStyle(color: AppColors.gold, fontSize: 20),
            filled: true,
            fillColor: AppColors.slate800.withValues(alpha: 0.5),
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
      ],
    );
  }

  Widget _buildStep2(AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '매월 인출 금액',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 24),
        TextField(
          controller: _monthlyWithdrawalController,
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: TextStyle(color: AppColors.slate400),
            suffixText: widget.currencyUnit,
            suffixStyle: TextStyle(color: AppColors.gold, fontSize: 20),
            filled: true,
            fillColor: AppColors.slate800.withValues(alpha: 0.5),
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
      ],
    );
  }

  Widget _buildStep3(AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '시뮬레이션 기간',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [5, 10, 15, 20, 25, 30].map((years) {
            final isSelected = _selectedYears == years;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedYears = years;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: isSelected
                    ? SelectedButtonStyle.solidBoxDecoration(
                        BorderRadius.circular(12),
                      )
                    : BoxDecoration(
                        color: AppColors.slate800.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.slate700, width: 1),
                      ),
                child: Text(
                  '$years${l10n.year}',
                  style: TextStyle(
                    color: isSelected ? AppColors.navyDark : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.8;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight, maxWidth: 400),
        child: LiquidGlass(
          decoration: BoxDecoration(
            color: AppColors.navyDark.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStepIndicator(l10n),
                SizedBox(height: 32),
                Flexible(
                  child: PageView(
                    controller: _pageController,
                    physics: NeverScrollableScrollPhysics(),
                    children: [
                      _buildStep1(l10n),
                      _buildStep2(l10n),
                      SingleChildScrollView(child: _buildStep3(l10n)),
                    ],
                  ),
                ),
                SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentStep > 0)
                      TextButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                          setState(() {
                            _currentStep--;
                          });
                        },
                        child: Text(
                          '이전',
                          style: TextStyle(color: AppColors.slate400),
                        ),
                      )
                    else
                      SizedBox(),
                    ElevatedButton(
                      onPressed: () {
                        if (_currentStep == 0 &&
                            _parseCurrency(_initialAssetController.text) == 0) {
                          return;
                        }
                        if (_currentStep == 1 &&
                            _parseCurrency(_monthlyWithdrawalController.text) ==
                                0) {
                          return;
                        }
                        _nextStep();
                      },
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
                        _currentStep < 2 ? '다음' : '완료',
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
          ),
        ),
      ),
    );
  }
}
