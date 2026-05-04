import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../app_theme.dart';
import '../camera/camera_manager.dart';
import '../ml/tflite_detector.dart';
import '../ml/detection.dart';
import '../widgets/bounding_box_painter.dart';
import '../feedback/feedback_manager.dart';

class FaceDetectionScreen extends StatefulWidget {
  const FaceDetectionScreen({super.key});

  @override
  State<FaceDetectionScreen> createState() => _FaceDetectionScreenState();
}

class _FaceDetectionScreenState extends State<FaceDetectionScreen> {
  final CameraManager _cameraManager = CameraManager();
  final TfliteDetector _detector = TfliteDetector();
  final FeedbackManager _feedback = FeedbackManager();
  
  final ValueNotifier<List<Detection>> _detections = ValueNotifier([]);

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _cameraManager.initialize();
      await _detector.loadModel(modelName: 'yolo11s.tflite');
      await _feedback.init();
      if (mounted) {
        setState(() {});
        _cameraManager.startStream(_processFrame);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Initialization Error: $e')),
        );
      }
    }
  }

  Future<void> _processFrame(CameraImage image) async {
    final detections = await _detector.detect(image);
    // Filter for 'person' as a proxy for face in this YOLO model
    final personDetections = detections.where((d) => d.label == 'person').toList();
    _detections.value = personDetections;

    if (personDetections.isNotEmpty) {
      final zone = personDetections.first.zone;
      String dir = zone == DetectionZone.left ? 'left' : (zone == DetectionZone.right ? 'right' : 'center');
      await _feedback.announceObjects(personDetections); 
      await _feedback.speak('Person detected in the $dir');
    }
  }

  @override
  void dispose() {
    _cameraManager.dispose();
    _detector.dispose();
    _feedback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraManager.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            const Text('Jnanetra', style: TextStyle(color: Colors.white, fontSize: 20)),
            Text('Face Detection', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          CameraPreview(_cameraManager.controller!),
          
          ValueListenableBuilder(
            valueListenable: _detections,
            builder: (context, detections, child) {
              return CustomPaint(
                painter: BoundingBoxPainter(
                  detections: detections,
                  imageSize: Size(
                    _cameraManager.controller!.value.previewSize!.height,
                    _cameraManager.controller!.value.previewSize!.width,
                  ),
                ),
                child: Container(),
              );
            },
          ),

          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineVariant, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ValueListenableBuilder(
                    valueListenable: _detections,
                    builder: (context, detections, child) {
                      final count = detections.length;
                      return Text(
                        '$count person${count == 1 ? '' : 's'} detected nearby',
                        style: const TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.explore_rounded, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(
                        _getDirectionText(),
                        style: const TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 22,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '~1.2m away',
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDirectionText() {
    if (_detections.value.isEmpty) return 'No one detected';
    final zone = _detections.value.first.zone;
    switch (zone) {
      case DetectionZone.left: return 'Slightly to your left';
      case DetectionZone.right: return 'Slightly to your right';
      case DetectionZone.center: return 'Right in front of you';
      case DetectionZone.none: return 'Unknown direction';
    }
  }
}
