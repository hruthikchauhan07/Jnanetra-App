import 'package:flutter/material.dart';

enum DetectionZone { left, center, right, none }

enum NavigationCommand { stop, moveLeft, moveRight, moveForward, clear }

class Detection {
  final String label;
  final double confidence;
  final Rect boundingBox;
  final DetectionZone zone;

  const Detection({
    required this.label,
    required this.confidence,
    required this.boundingBox,
    required this.zone,
  });

  // Color coding by class
  Color get boxColor {
    switch (label.toLowerCase()) {
      case 'person': return const Color(0xFFBA1A1A); // error red
      case 'chair':
      case 'couch':
      case 'bed':
      case 'dining table': return const Color(0xFF9E3D00); // tertiary amber
      case 'face': return const Color(0xFF7C3AED); // violet
      default: return const Color(0xFF0058BC); // primary blue
    }
  }
}
