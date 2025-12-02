import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ChartImageUtils {
  /// Converts a widget to an image
  static Future<Uint8List?> widgetToImage(GlobalKey key) async {
    try {
      final RenderRepaintBoundary? boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        return null;
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      image.dispose();

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error converting widget to image: $e');
      return null;
    }
  }

  /// Creates a shareable chart widget wrapped in RepaintBoundary
  static Widget wrapChartWithRepaintBoundary({
    required GlobalKey key,
    required Widget chart,
  }) {
    return RepaintBoundary(
      key: key,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: EdgeInsets.all(20),
        child: chart,
      ),
    );
  }
}
