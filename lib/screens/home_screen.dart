import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../utils/colors.dart';
import '../widgets/asset_button.dart';
import 'investment_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToSettings(BuildContext context, String asset) {
    context.read<AppStateProvider>().updateConfig(asset: asset);
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            InvestmentSettingsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0, 0.1),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedIcon(IconData icon, double delay) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Better sine wave
        double value = _controller.value + delay;
        if (value > 1.0) value -= 1.0;
        // Use sine for smooth oscillation
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAnimatedIcon(Icons.trending_up, 0.0),
                    SizedBox(width: 20),
                    _buildAnimatedIcon(Icons.calendar_today, 0.3),
                    SizedBox(width: 20),
                    _buildAnimatedIcon(Icons.bar_chart, 0.6),
                  ],
                ),
                SizedBox(height: 60),
                Text(
                  "만약 5년 전에\n비트코인을 샀다면\n지금 얼마일까?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "시간을 믿는 투자,\n그 결과를 직접 확인해보세요.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.slate400,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 60),
                AssetButton(
                  assetName: "비트코인 보기",
                  icon: "🪙",
                  isSelected: true,
                  onTap: () => _navigateToSettings(context, 'bitcoin'),
                ),
                SizedBox(height: 16),
                AssetButton(
                  assetName: "테슬라 보기",
                  icon: "⚡",
                  isSelected: false,
                  onTap: () => _navigateToSettings(context, 'tesla'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
