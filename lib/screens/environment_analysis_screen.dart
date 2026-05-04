import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../app_theme.dart';
import '../camera/camera_manager.dart';
import '../ml/tflite_detector.dart';
import '../ml/detection.dart';
import '../feedback/feedback_manager.dart';

class EnvironmentAnalysisScreen extends StatefulWidget {
  const EnvironmentAnalysisScreen({super.key});

  @override
  State<EnvironmentAnalysisScreen> createState() => _EnvironmentAnalysisScreenState();
}

class _EnvironmentAnalysisScreenState extends State<EnvironmentAnalysisScreen> with SingleTickerProviderStateMixin {
  final CameraManager _cameraManager = CameraManager();
  final TfliteDetector _detector = TfliteDetector();
  final FeedbackManager _feedback = FeedbackManager();
  
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;
  
  final ValueNotifier<List<Detection>> _detections = ValueNotifier([]);
  final ValueNotifier<bool> _isAnalyzing = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _initialize();
    _scanController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _scanAnimation = Tween<double>(begin: 0, end: 256).animate(_scanController);
  }

  Future<void> _initialize() async {
    try {
      await _cameraManager.initialize();
      await _detector.loadModel(modelName: 'yolo11s.tflite');
      await _feedback.init();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Initialization Error: $e')),
        );
      }
    }
  }

  Future<void> _analyze() async {
    if (_isAnalyzing.value) return;
    _isAnalyzing.value = true;
    
    _feedback.speak('Analyzing environment...');
    
    CameraImage? capturedImage;
    final Completer<CameraImage> completer = Completer<CameraImage>();
    
    _cameraManager.startStream((image) async {
      if (!completer.isCompleted) {
        completer.complete(image);
        // Note: we can't await stopStream here as it's a stream callback
        // but we'll handle the frame in the try block
      }
    });

    try {
      capturedImage = await completer.future.timeout(const Duration(seconds: 3));
      await _cameraManager.stopStream();
      
      final detections = await _detector.detect(capturedImage);
      _detections.value = detections;
      
      if (detections.isEmpty) {
        _feedback.speak("I don't see any specific objects clearly.");
      } else {
        final labels = detections.map((d) => d.label).toSet().toList();
        _feedback.speak('I see ${labels.length} objects: ${labels.join(', ')}');
      }
    } catch (e) {
      _feedback.speak('Analysis failed. Please try again.');
    } finally {
      _isAnalyzing.value = false;
    }
  }

  @override
  void dispose() {
    _cameraManager.dispose();
    _detector.dispose();
    _scanController.dispose();
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
        title: const Text('Environment Analysis', style: TextStyle(color: Colors.white)),
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
          
          Center(
            child: Container(
              width: 256,
              height: 256,
              decoration: const BoxDecoration(
                border: Border.fromBorderSide(BorderSide.none),
              ),
              child: Stack(
                children: [
                  // Corner markers
                  _buildCorner(top: 0, left: 0),
                  _buildCorner(top: 0, right: 0, isRight: true),
                  _buildCorner(bottom: 0, left: 0, isBottom: true),
                  _buildCorner(bottom: 0, right: 0, isRight: true, isBottom: true),
                  
                  // Scanning line
                  AnimatedBuilder(
                    animation: _scanAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: _scanAnimation.value,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
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
                  const Text(
                    'Indoor Environment',
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder(
                    valueListenable: _detections,
                    builder: (context, detections, child) {
                      if (detections.isEmpty) {
                        return const Text('Tap re-analyze to scan surroundings', 
                          style: TextStyle(fontFamily: 'Lexend', fontSize: 18, color: AppColors.onSurfaceVariant));
                      }
                      final labels = detections.map((d) => d.label).join(', ');
                      return Text(
                        '${detections.length} objects detected: $labels',
                        style: const TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 18,
                          color: AppColors.onSurfaceVariant,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: Text(
                          'Confidence: 89%',
                          style: TextStyle(
                            fontFamily: 'Lexend',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ValueListenableBuilder(
                        valueListenable: _isAnalyzing,
                        builder: (context, analyzing, child) {
                          return ElevatedButton(
                            onPressed: analyzing ? null : _analyze,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(120, 56),
                            ),
                            child: analyzing
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('RE-ANALYZE'),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner({double? top, double? bottom, double? left, double? right, bool isRight = false, bool isBottom = false}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border(
            top: top != null ? const BorderSide(color: AppColors.primary, width: 4) : BorderSide.none,
            bottom: bottom != null ? const BorderSide(color: AppColors.primary, width: 4) : BorderSide.none,
            left: left != null ? const BorderSide(color: AppColors.primary, width: 4) : BorderSide.none,
            right: right != null ? const BorderSide(color: AppColors.primary, width: 4) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
