import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'detection.dart';
import '../utils/image_utils.dart';

class TfliteDetector {
  Interpreter? _interpreter;
  bool _isProcessing = false;
  bool _isLoaded = false;

  static const Map<int, String> _targetClasses = {
    0: 'person', 15: 'cat', 16: 'dog', 24: 'backpack', 26: 'handbag',
    28: 'suitcase', 39: 'bottle', 40: 'wine glass', 41: 'cup', 42: 'fork',
    43: 'knife', 44: 'spoon', 45: 'bowl', 56: 'chair', 57: 'couch',
    58: 'potted plant', 59: 'bed', 60: 'dining table', 61: 'toilet',
    62: 'tv', 63: 'laptop', 64: 'mouse', 65: 'remote', 66: 'keyboard',
    67: 'cell phone', 68: 'microwave', 69: 'oven', 70: 'toaster',
    71: 'sink', 72: 'refrigerator', 73: 'book', 74: 'clock', 75: 'vase',
    76: 'scissors', 77: 'teddy bear', 78: 'hair drier', 79: 'toothbrush',
  };

  static const double _confThreshold = 0.35;
  static const double _iouThreshold = 0.45;
  static const int _inputSize = 416;

  bool get isLoaded => _isLoaded;

  Future<void> loadModel({String modelName = 'yolo11s.tflite'}) async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/$modelName',
      );
      _isLoaded = true;
    } catch (e) {
      debugPrint('TFLite Model load failed: $e');
      _isLoaded = false;
      rethrow;
    }
  }

  Future<List<Detection>> detect(CameraImage image) async {
    if (_interpreter == null || _isProcessing) return [];
    _isProcessing = true;

    try {
      final rgb = ImageUtils.convertYUV420toRGB(image);
      final lb = ImageUtils.letterboxResize(rgb, _inputSize);

      // Pre-process tensor: [1, 416, 416, 3] BHWC Float32
      final input = lb.tensor.reshape([1, _inputSize, _inputSize, 3]);
      
      // Output shape for YOLOv11 TFLite is typically [1, 84, num_boxes]
      final outputDetail = _interpreter!.getOutputTensors().first;
      final outputShape = outputDetail.shape;

      final output = List.generate(
        outputShape[0],
        (_) => List.generate(
          outputShape[1],
          (_) => List.filled(outputShape[2], 0.0),
        ),
      );

      _interpreter!.run(input, output);

      final List<Detection> detections = _parseOutput(output[0], image.width, image.height, lb);
      return _globalNms(detections);
    } catch (e) {
      debugPrint('Detection Error: $e');
      return [];
    } finally {
      _isProcessing = false;
    }
  }

  List<Detection> _parseOutput(List<List<double>> rawData, int imgWidth, int imgHeight, LetterboxResult lb) {
    final List<Detection> detections = [];
    final int numElements = rawData.length; // e.g. 84
    final int numBoxes = rawData[0].length; // e.g. 3549

    for (int i = 0; i < numBoxes; i++) {
      double bestScore = 0;
      int bestClass = -1;

      for (final entry in _targetClasses.entries) {
        final classIdx = entry.key;
        if (classIdx + 4 >= numElements) continue;

        final score = rawData[classIdx + 4][i];
        if (score > bestScore) {
          bestScore = score;
          bestClass = classIdx;
        }
      }

      if (bestScore < _confThreshold || bestClass == -1) continue;

      final cx = rawData[0][i];
      final cy = rawData[1][i];
      final w  = rawData[2][i];
      final h  = rawData[3][i];

      final x1 = cx - w / 2;
      final y1 = cy - h / 2;
      final x2 = cx + w / 2;
      final y2 = cy + h / 2;

      final rawBox = Rect.fromLTRB(x1, y1, x2, y2);
      final scaledBox = ImageUtils.rescaleBox(rawBox, lb.scale, lb.padX, lb.padY);
      final clampedBox = Rect.fromLTRB(
        scaledBox.left.clamp(0, imgWidth.toDouble()),
        scaledBox.top.clamp(0, imgHeight.toDouble()),
        scaledBox.right.clamp(0, imgWidth.toDouble()),
        scaledBox.bottom.clamp(0, imgHeight.toDouble()),
      );

      final centerX = (clampedBox.left + clampedBox.right) / 2;
      final normalizedX = centerX / imgWidth;
      final zone = normalizedX < 0.30
          ? DetectionZone.left
          : normalizedX > 0.70
              ? DetectionZone.right
              : DetectionZone.center;

      detections.add(Detection(
        label: _targetClasses[bestClass]!,
        confidence: bestScore,
        boundingBox: clampedBox,
        zone: zone,
      ));
    }
    return detections;
  }

  List<Detection> _globalNms(List<Detection> detections) {
    if (detections.isEmpty) return [];
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));

    final kept = <Detection>[];
    final suppressed = List.filled(detections.length, false);

    for (int i = 0; i < detections.length; i++) {
      if (suppressed[i]) continue;
      kept.add(detections[i]);
      for (int j = i + 1; j < detections.length; j++) {
        if (!suppressed[j] && _iouDetection(detections[i], detections[j]) > _iouThreshold) {
          suppressed[j] = true;
        }
      }
    }
    return kept;
  }

  double _iouDetection(Detection a, Detection b) {
    final intersection = a.boundingBox.intersect(b.boundingBox);
    if (intersection.width <= 0 || intersection.height <= 0) return 0;
    final intersectionArea = intersection.width * intersection.height;
    final unionArea = (a.boundingBox.width * a.boundingBox.height) +
                     (b.boundingBox.width * b.boundingBox.height) -
                     intersectionArea;
    return intersectionArea / unionArea;
  }

  void dispose() {
    _interpreter?.close();
    _isLoaded = false;
  }
}
