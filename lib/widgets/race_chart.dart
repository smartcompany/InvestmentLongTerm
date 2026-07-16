import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'asset_icon.dart';

/// Dark race canvas에서 글자/아이콘이 묻히지 않도록 밝기를 보정합니다.
Color readableOnDark(Color color) {
  if (color.computeLuminance() >= 0.42) return color;
  final hsl = HSLColor.fromColor(color);
  return hsl
      .withLightness(math.max(hsl.lightness, 0.72))
      .withSaturation(hsl.saturation.clamp(0.5, 0.95))
      .toColor();
}


class RacePoint {
  final double x;
  final double y;

  const RacePoint(this.x, this.y);
}

class RaceChartData {
  final String assetId;
  final String name;
  final String icon;
  final Color color;
  final List<RacePoint> spots;
  final double currentGrowthRate;
  final int rank; // 0-based rank

  RaceChartData({
    required this.assetId,
    required this.name,
    required this.icon,
    required this.color,
    required this.spots,
    required this.currentGrowthRate,
    required this.rank,
  });
}

/// 카메라가 세로 원근 트랙에서 시작해, 점점 사이드뷰(가로=시간, 세로=수익률)로 회전.
class RaceChart extends StatelessWidget {
  final List<RaceChartData> series;
  final double maxX;
  final double minX;
  final double maxY;
  final double minY;
  final double raceStartX;
  final double raceEndX;
  final bool isRaceComplete;

  const RaceChart({
    super.key,
    required this.series,
    required this.maxX,
    this.minX = 0.0,
    required this.maxY,
    required this.minY,
    required this.raceStartX,
    required this.raceEndX,
    this.isRaceComplete = false,
  });

  static double cameraBlend({
    required double leadX,
    required double raceStartX,
    required double raceEndX,
    required bool isRaceComplete,
  }) {
    if (isRaceComplete) return 1.0;
    final start = raceStartX;
    final end = raceEndX > start ? raceEndX : leadX;
    final span = math.max(end - start, 1.0);
    final progress = ((leadX - start) / span).clamp(0.0, 1.0);
    // 초반 18%는 세로뷰 유지 → 이후 사이드뷰로 회전 → 55%쯤 완전 전환
    if (progress <= 0.18) return 0.0;
    if (progress >= 0.55) return 1.0;
    final t = (progress - 0.18) / (0.55 - 0.18);
    return Curves.easeInOutCubic.transform(t.clamp(0.0, 1.0));
  }

  /// 결승선 직전 줌인(0→1) → 피니시에서 줌아웃(1→0).
  /// 완료 시 0 (전체 뷰).
  static double finalePunch({
    required double leadX,
    required double raceStartX,
    required double raceEndX,
    required bool isRaceComplete,
  }) {
    if (isRaceComplete) return 0.0;
    final start = raceStartX;
    final end = raceEndX > start ? raceEndX : leadX;
    final span = math.max(end - start, 1.0);
    final progress = ((leadX - start) / span).clamp(0.0, 1.0);
    // 78%부터 줌인 → 89% 피크 → 100%까지 풀아웃
    if (progress < 0.78) return 0.0;
    if (progress < 0.89) {
      final t = (progress - 0.78) / 0.11;
      return Curves.easeInOutCubic.transform(t.clamp(0.0, 1.0));
    }
    final t = (progress - 0.89) / 0.11;
    return 1.0 - Curves.easeInOutCubic.transform(t.clamp(0.0, 1.0));
  }

  /// 피니시 풀아웃(전체 레이스 공개) 양.
  static double finalePullOut({
    required double leadX,
    required double raceStartX,
    required double raceEndX,
    required bool isRaceComplete,
  }) {
    if (isRaceComplete) return 1.0;
    final start = raceStartX;
    final end = raceEndX > start ? raceEndX : leadX;
    final span = math.max(end - start, 1.0);
    final progress = ((leadX - start) / span).clamp(0.0, 1.0);
    if (progress < 0.89) return 0.0;
    final t = (progress - 0.89) / 0.11;
    return Curves.easeInOutCubic.transform(t.clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...series]..sort((a, b) => a.rank.compareTo(b.rank));
    final blend = cameraBlend(
      leadX: maxX,
      raceStartX: raceStartX,
      raceEndX: raceEndX,
      isRaceComplete: isRaceComplete,
    );
    final punch = finalePunch(
      leadX: maxX,
      raceStartX: raceStartX,
      raceEndX: raceEndX,
      isRaceComplete: isRaceComplete,
    );

    // 카메라 각도도 blend에 따라 회전
    final rotateX = ui.lerpDouble(-0.14, -0.035, blend)!;
    final rotateY = ui.lerpDouble(0.025, -0.03, blend)!;
    final persp = ui.lerpDouble(0.0015, 0.0007, blend)!;
    // 결승 직전: 선두(오른쪽) 쪽 중심으로 줌인
    final scale = 1.0 + punch * 0.28;

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, persp)
              ..rotateX(rotateX)
              ..rotateY(rotateY),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment(0.55 + punch * 0.25, -0.05),
              child: CustomPaint(
                painter: _RaceTrackPainter(
                  series: sorted,
                  leadX: maxX,
                  dataMinX: minX,
                  valueMin: minY,
                  valueMax: maxY,
                  raceStartX: raceStartX,
                  raceEndX: raceEndX,
                  isRaceComplete: isRaceComplete,
                  cameraBlend: blend,
                  finalePunch: punch,
                  finalePullOut: finalePullOut(
                    leadX: maxX,
                    raceStartX: raceStartX,
                    raceEndX: raceEndX,
                    isRaceComplete: isRaceComplete,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          width: 220,
          child: Padding(
            padding: const EdgeInsets.only(top: 8, left: 12, right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: sorted.map((data) {
                final isLeader = data.rank == 0;
                final accent = readableOnDark(data.color);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      if (isLeader)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.emoji_events,
                            size: 14,
                            color: Color(0xFFFFD700),
                          ),
                        ),
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.55),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      AssetIcon(
                        assetId: data.assetId,
                        size: 18,
                        color: accent,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          data.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                            shadows: [
                              Shadow(blurRadius: 6, color: Colors.black),
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 2,
                                color: Colors.black87,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${data.currentGrowthRate >= 0 ? '+' : ''}${data.currentGrowthRate.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          shadows: const [
                            Shadow(blurRadius: 6, color: Colors.black),
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 2,
                              color: Colors.black87,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _RaceTrackPainter extends CustomPainter {
  final List<RaceChartData> series;
  final double leadX;
  final double dataMinX;
  final double valueMin;
  final double valueMax;
  final double raceStartX;
  final double raceEndX;
  final bool isRaceComplete;
  final double cameraBlend; // 0 = 세로 트랙, 1 = 사이드뷰
  final double finalePunch; // 0 = 정상, 1 = 최대 줌인
  final double finalePullOut; // 0 = 팔로우, 1 = 전체 공개

  _RaceTrackPainter({
    required this.series,
    required this.leadX,
    required this.dataMinX,
    required this.valueMin,
    required this.valueMax,
    required this.raceStartX,
    required this.raceEndX,
    required this.isRaceComplete,
    required this.cameraBlend,
    this.finalePunch = 0.0,
    this.finalePullOut = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final raceStart = raceStartX.isFinite ? raceStartX : dataMinX;
    final raceEnd =
        raceEndX.isFinite && raceEndX > raceStart ? raceEndX : leadX;
    final totalSpan = math.max(raceEnd - raceStart, 1.0);
    final lead = leadX.isFinite ? leadX : raceStart;
    final blend = cameraBlend.clamp(0.0, 1.0);
    final punch = finalePunch.clamp(0.0, 1.0);
    final pullOut = finalePullOut.clamp(0.0, 1.0);

    // 카메라 시간 윈도우 — 줌인 시 타이트하게, 이후 전체 공개
    var lookBehind = totalSpan * ui.lerpDouble(0.22, 0.32, blend)!;
    var lookAhead = totalSpan * ui.lerpDouble(0.10, 0.0, blend)!;
    lookBehind *= ui.lerpDouble(1.0, 0.28, punch)!;
    lookAhead = math.max(
      lookAhead * ui.lerpDouble(1.0, 0.15, punch)!,
      totalSpan * 0.01,
    );
    if (pullOut > 0 || isRaceComplete) {
      final t = isRaceComplete ? 1.0 : pullOut;
      lookBehind = lookBehind + (lead - raceStart - lookBehind) * t;
      lookAhead = lookAhead + (raceEnd - lead - lookAhead) * t;
    }
    final camNear = math.max(raceStart, lead - lookBehind);
    final camFar = math.min(raceEnd, lead + math.max(lookAhead, 1));
    final camSpan = math.max(camFar - camNear, 1.0);

    // 보이는 Y 범위
    double localMin = double.infinity;
    double localMax = double.negativeInfinity;
    var hasLocal = false;
    for (final s in series) {
      for (final p in s.spots) {
        if (p.x < camNear || p.x > camFar) continue;
        if (!p.y.isFinite) continue;
        hasLocal = true;
        if (p.y < localMin) localMin = p.y;
        if (p.y > localMax) localMax = p.y;
      }
    }
    if (!hasLocal) {
      localMin = valueMin;
      localMax = valueMax;
    }
    var ySpan = math.max(localMax - localMin, 1.0);
    // 줌인 때는 Y도 더 타이트하게
    final yPad = ySpan * ui.lerpDouble(0.22, 0.08, punch)!;
    localMin = math.max(0, localMin - yPad);
    localMax = localMax + yPad;
    ySpan = math.max(localMax - localMin, 1.0);

    final laneIds = series.map((s) => s.assetId).toList()..sort();
    final laneCount = math.max(laneIds.length, 1);
    double laneFor(String assetId) {
      if (laneCount == 1) return 0;
      final idx = laneIds.indexOf(assetId);
      return (idx / (laneCount - 1)) * 2 - 1;
    }

    // --- 뷰 A: 세로 원근 (시간=깊이) ---
    Offset projectDepth(double time, double value, double lane) {
      final depth = ((time - camNear) / camSpan).clamp(0.0, 1.15);
      final vanishingY = size.height * 0.10;
      final nearY = size.height * 0.92;
      final baseY = nearY + (vanishingY - nearY) * depth;
      final nearHalfW = size.width * 0.46;
      final farHalfW = size.width * 0.06;
      final halfW = nearHalfW + (farHalfW - nearHalfW) * depth;
      final valueNorm = ((value - localMin) / ySpan).clamp(0.0, 1.5);
      final lift = valueNorm * size.height * (0.26 * (1.0 - depth * 0.7));
      return Offset(size.width * 0.5 + lane * halfW, baseY - lift);
    }

    // --- 뷰 B: 사이드뷰 (가로=시간, 세로=수익률) ---
    Offset projectSide(double time, double value) {
      final chartLeft = size.width * 0.06;
      final chartRight = size.width * 0.96;
      final chartTop = size.height * 0.10;
      final chartBottom = size.height * 0.86;
      final chartW = chartRight - chartLeft;
      final chartH = chartBottom - chartTop;
      final tx = ((time - camNear) / camSpan).clamp(0.0, 1.0);
      final ty = ((value - localMin) / ySpan).clamp(0.0, 1.2);
      final depthFromLead = 1.0 - tx;
      final foreshorten = 1.0 - depthFromLead * 0.08;
      return Offset(
        chartLeft + tx * chartW,
        chartBottom - ty * chartH * foreshorten,
      );
    }

    Offset project(double time, double value, double lane) {
      final a = projectDepth(time, value, lane);
      final b = projectSide(time, value);
      return Offset.lerp(a, b, blend)!;
    }

    // 배경
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(size.width * 0.5, 0),
          Offset(size.width * 0.5, size.height),
          const [Color(0xFF071018), Color(0xFF0B1524)],
        ),
    );

    // 트랙 면 (두 뷰의 바닥을 blend)
    final depthTrack = Path()
      ..moveTo(projectDepth(camNear, localMin, -1.05).dx,
          projectDepth(camNear, localMin, -1.05).dy)
      ..lineTo(projectDepth(camNear, localMin, 1.05).dx,
          projectDepth(camNear, localMin, 1.05).dy)
      ..lineTo(projectDepth(camFar, localMin, 1.05).dx,
          projectDepth(camFar, localMin, 1.05).dy)
      ..lineTo(projectDepth(camFar, localMin, -1.05).dx,
          projectDepth(camFar, localMin, -1.05).dy)
      ..close();

    final sideBottom = size.height * 0.86;
    final sideTop = sideBottom - size.height * 0.08;
    final sideTrack = Path()
      ..moveTo(size.width * 0.06, sideBottom)
      ..lineTo(size.width * 0.96, sideBottom)
      ..lineTo(size.width * 0.96, sideTop)
      ..lineTo(size.width * 0.06, sideTop + size.height * 0.035)
      ..close();

    canvas.drawPath(
      depthTrack,
      Paint()
        ..color = const Color(0xFF1A2740).withValues(alpha: 0.85 * (1 - blend))
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      sideTrack,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, sideBottom),
          Offset(0, sideTop),
          [
            const Color(0xFF1A2740).withValues(alpha: 0.9 * blend),
            const Color(0xFF0A101A).withValues(alpha: 0.35 * blend),
          ],
        ),
    );

    // 레일 / 가이드
    final railAlpha = ui.lerpDouble(0.20, 0.12, blend)!;
    canvas.drawLine(
      project(camNear, localMin, -1.0),
      project(camFar, localMin, -1.0),
      Paint()
        ..color = Colors.white.withValues(alpha: railAlpha)
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      project(camNear, localMin, 1.0),
      project(camFar, localMin, 1.0),
      Paint()
        ..color = Colors.white.withValues(alpha: railAlpha)
        ..strokeWidth = 2,
    );

    for (var i = 0; i <= 6; i++) {
      final t = camNear + camSpan * (i / 6);
      canvas.drawLine(
        project(t, localMin, -1.0),
        project(t, localMin, 1.0),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.05)
          ..strokeWidth = 1,
      );
    }

    // 수익률 가로선은 사이드뷰로 갈수록 진하게 (올라감 인지)
    for (var i = 0; i <= 4; i++) {
      final v = localMin + ySpan * (i / 4);
      canvas.drawLine(
        project(camNear, v, -1.0),
        project(camFar, v, 1.0),
        Paint()
          ..color = Colors.white.withValues(
            alpha: (i == 0 ? 0.14 : 0.05) * (0.35 + blend * 0.65),
          )
          ..strokeWidth = 1,
      );
    }

    _drawDashedLine(
      canvas,
      project(camNear, localMin, 0),
      project(camFar, localMin, 0),
      Paint()
        ..color = AppColors.gold.withValues(alpha: 0.4)
        ..strokeWidth = 1.5,
      dash: 10,
      gap: 8,
    );

    // 시리즈
    final drawOrder = [...series]..sort((a, b) => b.rank.compareTo(a.rank));
    for (final data in drawOrder) {
      final lane = laneFor(data.assetId);
      final pts = <Offset>[];
      final depths = <double>[];
      for (final spot in data.spots) {
        if (spot.x < camNear - camSpan * 0.02) continue;
        if (spot.x > camFar + camSpan * 0.02) continue;
        pts.add(project(spot.x, spot.y, lane));
        depths.add(((spot.x - camNear) / camSpan).clamp(0.0, 1.0));
      }
      if (pts.length < 2) continue;

      final isLeader = data.rank == 0;
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final p in pts.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }

      // 깊이 모드에서는 세그먼트 thickness, 사이드에서는 일정 두께에 가깝게
      if (blend < 0.85) {
        for (var i = 1; i < pts.length; i++) {
          final d = (depths[i - 1] + depths[i]) * 0.5;
          final nearFactor = 1.0 - d;
          final width = ui.lerpDouble(
            (isLeader ? 5.2 : 3.0) * (0.35 + nearFactor * 0.9),
            isLeader ? 4.5 : 2.6,
            blend,
          )!;
          canvas.drawLine(
            pts[i - 1],
            pts[i],
            Paint()
              ..color = data.color
              ..strokeWidth = width
              ..strokeCap = StrokeCap.round
              ..style = PaintingStyle.stroke,
          );
        }
      } else {
        if (isLeader) {
          canvas.drawPath(
            path,
            Paint()
              ..color = data.color.withValues(alpha: 0.22)
              ..strokeWidth = 12
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
          );
        }
        canvas.drawPath(
          path,
          Paint()
            ..color = data.color
            ..strokeWidth = isLeader ? 4.5 : 2.6
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }

      final head = pts.last;
      canvas.drawCircle(
        head,
        isLeader ? 7 : 5,
        Paint()
          ..color = data.color.withValues(alpha: 0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawCircle(head, isLeader ? 5.5 : 4, Paint()..color = data.color);
      canvas.drawCircle(
        head,
        isLeader ? 5.5 : 4,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: 0.9),
      );

      final label = AssetIcon.letterFor(data.assetId);
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: isLeader ? 14 : 12,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            shadows: const [
              Shadow(blurRadius: 4, color: Colors.black87),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(head.dx - tp.width / 2, head.dy - tp.height - 8));
    }

    // 지평선 포그 (세로뷰에서 더 강함)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.2),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, size.height * 0.2),
          [
            Color(0xFF05080C).withValues(alpha: 0.7 * (1 - blend * 0.5)),
            const Color(0xFF05080C).withValues(alpha: 0.0),
          ],
        ),
    );

    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.8, size.width, size.height * 0.2),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, size.height * 0.8),
          Offset(0, size.height),
          [
            Colors.transparent,
            AppColors.navyDark.withValues(alpha: 0.5),
          ],
        ),
    );
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset a,
    Offset b,
    Paint paint, {
    required double dash,
    required double gap,
  }) {
    final total = (b - a).distance;
    if (total <= 0) return;
    final dir = (b - a) / total;
    var drawn = 0.0;
    while (drawn < total) {
      final start = a + dir * drawn;
      final end = a + dir * math.min(drawn + dash, total);
      canvas.drawLine(start, end, paint);
      drawn += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _RaceTrackPainter oldDelegate) {
    return oldDelegate.leadX != leadX ||
        oldDelegate.cameraBlend != cameraBlend ||
        oldDelegate.finalePunch != finalePunch ||
        oldDelegate.finalePullOut != finalePullOut ||
        oldDelegate.isRaceComplete != isRaceComplete ||
        oldDelegate.series != series ||
        oldDelegate.valueMin != valueMin ||
        oldDelegate.valueMax != valueMax;
  }
}
