import 'package:flutter/material.dart';
import '../utils/colors.dart';

/// 온보딩 직후 내 자산 탭을 가리키는 코치마크.
class MyAssetsTabHintOverlay extends StatefulWidget {
  final GlobalKey targetKey;
  final String message;
  final String dismissLabel;
  final VoidCallback onDismiss;
  final VoidCallback? onTargetTap;

  const MyAssetsTabHintOverlay({
    super.key,
    required this.targetKey,
    required this.message,
    required this.dismissLabel,
    required this.onDismiss,
    this.onTargetTap,
  });

  @override
  State<MyAssetsTabHintOverlay> createState() => _MyAssetsTabHintOverlayState();
}

class _MyAssetsTabHintOverlayState extends State<MyAssetsTabHintOverlay> {
  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateTargetRect());
  }

  void _updateTargetRect() {
    final context = widget.targetKey.currentContext;
    final box = context?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final topLeft = box.localToGlobal(Offset.zero);
    if (!mounted) return;
    setState(() {
      _targetRect = topLeft & box.size;
    });
  }

  @override
  Widget build(BuildContext context) {
    final target = _targetRect;
    final screenSize = MediaQuery.sizeOf(context);

    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onDismiss,
            child: Container(color: Colors.black.withValues(alpha: 0.42)),
          ),
          if (target != null) ...[
            Positioned(
              left: target.left - 6,
              top: target.top - 6,
              width: target.width + 12,
              height: target.height + 12,
              child: GestureDetector(
                onTap: () {
                  if (widget.onTargetTap != null) {
                    widget.onTargetTap!();
                  } else {
                    widget.onDismiss();
                  }
                },
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _buildHintBubble(context, target, screenSize),
          ],
        ],
      ),
    );
  }

  Widget _buildHintBubble(BuildContext context, Rect target, Size screenSize) {
    const horizontalMargin = 16.0;
    const bubbleWidth = 280.0;
    const arrowWidth = 16.0;

    final bubbleLeft = (target.center.dx - bubbleWidth / 2).clamp(
      horizontalMargin,
      screenSize.width - horizontalMargin - bubbleWidth,
    );
    final bubbleBottom = screenSize.height - target.top + 12;
    final arrowAlignX =
        ((target.center.dx - bubbleLeft - bubbleWidth / 2) / (bubbleWidth / 2))
            .clamp(-1.0, 1.0);

    return Positioned(
      left: bubbleLeft,
      bottom: bubbleBottom,
      width: bubbleWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.message,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: widget.onDismiss,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      widget.dismissLabel,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment(arrowAlignX, 0),
            child: CustomPaint(
              size: const Size(arrowWidth, 8),
              painter: _DownArrowPainter(color: AppColors.surface),
            ),
          ),
        ],
      ),
    );
  }
}

class _DownArrowPainter extends CustomPainter {
  final Color color;

  _DownArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.08), 4, false);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
