import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_state_provider.dart';
import '../providers/growth_race_provider.dart';
import '../services/onboarding_service.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../widgets/app_ui.dart';
import '../widgets/asset_icon.dart';
import 'main_tab_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _isStarting = false;

  String _assetLabel(String assetId, AppStateProvider appProvider) {
    try {
      return appProvider.assets
          .firstWhere((a) => a.id == assetId)
          .displayName();
    } catch (_) {
      switch (assetId) {
        case 'bitcoin':
          return 'Bitcoin';
        case 'nvidia':
          return 'NVIDIA';
        case 'sk_hynix':
          return 'SK Hynix';
        case 'gold':
          return 'Gold';
        default:
          return assetId;
      }
    }
  }

  Future<void> _startDemoRace() async {
    if (_isStarting) return;
    setState(() => _isStarting = true);

    try {
      final appProvider = context.read<AppStateProvider>();
      if (appProvider.assets.isEmpty && !appProvider.isAssetsLoading) {
        await appProvider.loadAssets();
      }

      final raceProvider = context.read<GrowthRaceProvider>();
      raceProvider.prepareDemoRace(
        assetIds: OnboardingService.demoAssetIds,
        years: OnboardingService.demoYears,
      );
      await raceProvider.loadPriceData();
      if (raceProvider.priceData.values.every((data) => data.isEmpty)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.failedToLoadAssetList)),
          );
        }
        return;
      }

      await OnboardingService.markCompleted();
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const MainTabScreen(openOnboardingRace: true),
        ),
      );
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  Future<void> _skipOnboarding() async {
    if (_isStarting) return;
    await OnboardingService.markCompleted();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainTabScreen()),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appProvider = context.read<AppStateProvider>();
      if (appProvider.assets.isEmpty && !appProvider.isAssetsLoading) {
        appProvider.loadAssets();
      }
    });
  }

  Widget _buildRacePreview(AppStateProvider appProvider, AppLocalizations l10n) {
    const avatarSize = 52.0;
    const overlap = 18.0;
    final assetIds = OnboardingService.demoAssetIds;
    final rowWidth = avatarSize + (assetIds.length - 1) * (avatarSize - overlap);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.navyDark,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${OnboardingService.demoYears} YEAR RACE',
              style: const TextStyle(
                color: AppColors.slate300,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: rowWidth,
            height: avatarSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (int i = 0; i < assetIds.length; i++)
                  Positioned(
                    left: i * (avatarSize - overlap),
                    child: Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.navyMedium,
                        border: Border.all(
                          color: AppColors.navyDark,
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: AssetIcon(
                          assetId: assetIds[i],
                          size: 26,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            assetIds.map((id) => _assetLabel(id, appProvider)).join(' · '),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.slate300,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 72,
            width: double.infinity,
            child: CustomPaint(
              painter: _OnboardingTrackPainter(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingRaceMatchup,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.slate400,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appProvider = context.watch<AppStateProvider>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: _isStarting ? null : _skipOnboarding,
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  tooltip: l10n.close,
                ),
              ),
              Text(
                l10n.onboardingRaceTitle,
                style: AppTextStyles.homeMainQuestion.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.onboardingRaceSubtitle,
                style: AppTextStyles.homeSubDescription.copyWith(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Center(
                  child: _buildRacePreview(appProvider, l10n),
                ),
              ),
              const SizedBox(height: 24),
              AppPrimaryButton(
                label: l10n.onboardingRaceStart,
                loading: _isStarting,
                onPressed: _isStarting ? null : _startDemoRace,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingTrackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final horizonY = h * 0.18;

    final lanePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var i = 0; i <= 4; i++) {
      final t = i / 4;
      final y = horizonY + (h - horizonY) * t;
      canvas.drawLine(Offset(0, y), Offset(w, y), lanePaint);
    }

    final leftEdge = Path()
      ..moveTo(w * 0.22, h)
      ..lineTo(w * 0.38, horizonY);
    final rightEdge = Path()
      ..moveTo(w * 0.78, h)
      ..lineTo(w * 0.62, horizonY);

    final edgePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(leftEdge, edgePaint);
    canvas.drawPath(rightEdge, edgePaint);

    final dashPaint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const dashCount = 6;
    for (var i = 0; i < dashCount; i++) {
      final t = (i + 0.5) / dashCount;
      final y = horizonY + (h - horizonY) * t * 0.92;
      final halfWidth = (w * 0.2) * (1 - t * 0.75);
      final centerX = w / 2;
      canvas.drawLine(
        Offset(centerX - halfWidth, y),
        Offset(centerX + halfWidth, y),
        dashPaint,
      );
    }

    const dotColors = [
      Color(0xFF5B8FF7),
      Color(0xFF4ADE80),
      Color(0xFF38BDF8),
      Color(0xFFC084FC),
    ];
    for (var i = 0; i < dotColors.length; i++) {
      final t = 0.35 + i * 0.12;
      final y = horizonY + (h - horizonY) * t;
      final x = w * (0.5 + math.sin(i * 1.7) * 0.08);
      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()..color = dotColors[i],
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
