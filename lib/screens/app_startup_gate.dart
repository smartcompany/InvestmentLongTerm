import 'package:flutter/material.dart';
import '../services/onboarding_service.dart';
import '../utils/colors.dart';
import 'main_tab_screen.dart';
import 'onboarding_screen.dart';

/// 첫 실행 시 온보딩, 이후 메인 탭으로 진입합니다.
class AppStartupGate extends StatefulWidget {
  const AppStartupGate({super.key});

  @override
  State<AppStartupGate> createState() => _AppStartupGateState();
}

class _AppStartupGateState extends State<AppStartupGate> {
  bool _loading = true;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final completed = await OnboardingService.isCompleted();
    if (!mounted) return;
    setState(() {
      _showOnboarding = !completed;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_showOnboarding) {
      return const OnboardingScreen();
    }

    return const MainTabScreen();
  }
}
