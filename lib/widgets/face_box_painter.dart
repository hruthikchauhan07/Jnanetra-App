import 'package:flutter/material.dart';
import '../ml/detection.dart';
import '../app_theme.dart';

class FaceBoxPainter extends CustomPainter {
  final List<Detection> detections;
  final Size imageSize;

  const FaceBoxPainter({required this.detections, required this.imageSize});

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;

    for (final det in detections) {
      final rect = Rect.fromLTRB(
        det.boundingBox.left * scaleX,
        det.boundingBox.top * scaleY,
        det.boundingBox.right * scaleX,
        det.boundingBox.bottom * scaleY,
      );

      // Face specific styling: Violet with glow
      final boxPaint = Paint()
        ..color = AppColors.face
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;

      final shadowPaint = Paint()
        ..color = AppColors.face.withOpacity(0.3)
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawRect(rect, shadowPaint);
      canvas.drawRect(rect, boxPaint);

      // Label background
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'Face Detected',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            backgroundColor: AppColors.face,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(canvas, Offset(rect.left, rect.top - 18));
    }
  }

  @override
  bool shouldRepaint(FaceBoxPainter old) => old.detections != detections;
}
