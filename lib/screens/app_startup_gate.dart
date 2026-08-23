import 'package:flutter/material.dart';
import '../services/onboarding_service.dart';
import '../services/push_notification_service.dart';
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
  int? _initialTabIndex;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final completed = await OnboardingService.isCompleted();
    final fromPush = PushNotificationService.shared.launchPayload ==
        PushNotificationService.payloadMyAssets;
    if (!mounted) return;
    setState(() {
      _showOnboarding = !completed;
      _initialTabIndex = fromPush ? 1 : null;
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

    return MainTabScreen(initialIndex: _initialTabIndex);
  }
}
