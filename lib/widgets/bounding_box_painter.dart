import 'package:flutter/material.dart';
import '../ml/detection.dart';

class BoundingBoxPainter extends CustomPainter {
  final List<Detection> detections;
  final Size imageSize;

  const BoundingBoxPainter({required this.detections, required this.imageSize});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw zone divider lines (dashed) at 30% and 70%
    final dashPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    _drawDashedLine(canvas, Offset(size.width * 0.30, 0), Offset(size.width * 0.30, size.height), dashPaint);
    _drawDashedLine(canvas, Offset(size.width * 0.70, 0), Offset(size.width * 0.70, size.height), dashPaint);

    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;

    for (final det in detections) {
      final rect = Rect.fromLTRB(
        det.boundingBox.left * scaleX,
        det.boundingBox.top * scaleY,
        det.boundingBox.right * scaleX,
        det.boundingBox.bottom * scaleY,
      );

      final boxPaint = Paint()
        ..color = det.boxColor
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;

      canvas.drawRect(rect, boxPaint);

      // Label background
      final label = '${det.label} ${(det.confidence * 100).toStringAsFixed(0)}%';
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            backgroundColor: det.boxColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(canvas, Offset(rect.left, rect.top - 20));
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashLength = 8.0;
    const gapLength = 6.0;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final dist = (end - start).distance;
    double drawn = 0;
    while (drawn < dist) {
      final t1 = drawn / dist;
      final t2 = ((drawn + dashLength) / dist).clamp(0.0, 1.0);
      canvas.drawLine(
        Offset(start.dx + dx * t1, start.dy + dy * t1),
        Offset(start.dx + dx * t2, start.dy + dy * t2),
        paint,
      );
      drawn += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(BoundingBoxPainter old) => old.detections != detections;
}
