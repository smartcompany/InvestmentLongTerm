import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'asset_icon.dart';
import 'race_chart.dart';

/// 경주 종료 시 1위 자산 배너
class RaceWinnerBanner extends StatelessWidget {
  final String assetId;
  final String assetName;
  final double growthRate;
  final Color accentColor;

  const RaceWinnerBanner({
    super.key,
    required this.assetId,
    required this.assetName,
    required this.growthRate,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.85, end: 1.0),
      duration: const Duration(milliseconds: 550),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFFF8E1),
              AppColors.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.55)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 34),
            const SizedBox(width: 12),
            AssetIcon(assetId: assetId, size: 36, color: accentColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assetName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatGrowthRatePercent(growthRate),
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 화면 위 불꽃놀이 오버레이
class FireworksOverlay extends StatefulWidget {
  final bool active;

  const FireworksOverlay({super.key, required this.active});

  @override
  State<FireworksOverlay> createState() => _FireworksOverlayState();
}

class _FireworksOverlayState extends State<FireworksOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_FireworkBurst> _bursts;
  final _random = math.Random(42);

  static const _colors = [
    Color(0xFFFFD700),
    Color(0xFF5B8FF7),
    Color(0xFF4ADE80),
    Color(0xFFF472B6),
    Color(0xFFFB923C),
    Color(0xFF38BDF8),
    Color(0xFFC084FC),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _bursts = _generateBursts();
    if (widget.active) _controller.forward();
  }

  @override
  void didUpdateWidget(FireworksOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _bursts = _generateBursts();
      _controller.forward(from: 0);
    }
  }

  List<_FireworkBurst> _generateBursts() {
    return List.generate(7, (i) {
      final particleCount = 18 + _random.nextInt(10);
      return _FireworkBurst(
        anchor: Offset(
          0.12 + _random.nextDouble() * 0.76,
          0.08 + _random.nextDouble() * 0.42,
        ),
        delay: i * 0.08,
        color: _colors[i % _colors.length],
        particles: List.generate(particleCount, (j) {
          final angle = (j / particleCount) * math.pi * 2 + _random.nextDouble() * 0.3;
          return _FireworkParticle(
            angle: angle,
            speed: 0.18 + _random.nextDouble() * 0.22,
            size: 2.0 + _random.nextDouble() * 2.5,
          );
        }),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return const SizedBox.shrink();

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.value >= 1.0) return const SizedBox.shrink();
          return CustomPaint(
            painter: _FireworksPainter(
              progress: _controller.value,
              bursts: _bursts,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _FireworkBurst {
  final Offset anchor;
  final double delay;
  final Color color;
  final List<_FireworkParticle> particles;

  const _FireworkBurst({
    required this.anchor,
    required this.delay,
    required this.color,
    required this.particles,
  });
}

class _FireworkParticle {
  final double angle;
  final double speed;
  final double size;

  const _FireworkParticle({
    required this.angle,
    required this.speed,
    required this.size,
  });
}

class _FireworksPainter extends CustomPainter {
  final double progress;
  final List<_FireworkBurst> bursts;

  _FireworksPainter({required this.progress, required this.bursts});

  @override
  void paint(Canvas canvas, Size size) {
    for (final burst in bursts) {
      final local = ((progress - burst.delay) / (1.0 - burst.delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;

      final center = Offset(
        burst.anchor.dx * size.width,
        burst.anchor.dy * size.height,
      );
      final fade = (1.0 - Curves.easeIn.transform(local)).clamp(0.0, 1.0);
      final travel = Curves.easeOutCubic.transform(local);

      for (final p in burst.particles) {
        final dist = p.speed * size.shortestSide * travel;
        final pos = center + Offset(
          math.cos(p.angle) * dist,
          math.sin(p.angle) * dist + travel * travel * 28,
        );
        final paint = Paint()
          ..color = burst.color.withValues(alpha: fade * 0.95)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.size * 0.6);
        canvas.drawCircle(pos, p.size * (0.6 + fade * 0.4), paint);
      }

      // 중심 섬광
      canvas.drawCircle(
        center,
        6 * fade * (1.0 - travel * 0.5),
        Paint()..color = Colors.white.withValues(alpha: fade * 0.7),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FireworksPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
