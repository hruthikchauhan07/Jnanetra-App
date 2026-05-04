import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../app_theme.dart';
import '../camera/camera_manager.dart';
import '../ml/tflite_detector.dart';
import '../ml/detection.dart';
import '../engine/decision_engine.dart';
import '../feedback/feedback_manager.dart';
import '../widgets/bounding_box_painter.dart';

class ObjectDetectionScreen extends StatefulWidget {
  const ObjectDetectionScreen({super.key});

  @override
  State<ObjectDetectionScreen> createState() => _ObjectDetectionScreenState();
}

class _ObjectDetectionScreenState extends State<ObjectDetectionScreen> {
  final CameraManager _cameraManager = CameraManager();
  final TfliteDetector _detector = TfliteDetector();
  final DecisionEngine _engine = DecisionEngine();
  final FeedbackManager _feedback = FeedbackManager();
  
  final ValueNotifier<List<Detection>> _detections = ValueNotifier([]);
  final ValueNotifier<NavigationCommand> _command = ValueNotifier(NavigationCommand.clear);
  final ValueNotifier<bool> _isDetecting = ValueNotifier(true);
  
  int _fps = 0;
  final Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _initialize();
    WakelockPlus.enable();
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
          SnackBar(content: Text('Initialization Error: $e'), duration: const Duration(seconds: 5)),
        );
      }
    }
  }

  Future<void> _processFrame(CameraImage image) async {
    if (!_isDetecting.value) return;
    
    _stopwatch.reset();
    _stopwatch.start();
    
    final detections = await _detector.detect(image);
    _detections.value = detections;
    
    final command = _engine.decide(detections);
    _command.value = command;
    
    await _feedback.announce(command);
    await _feedback.announceObjects(detections);
    
    _stopwatch.stop();
    if (_stopwatch.elapsedMilliseconds > 0) {
      _fps = 1000 ~/ _stopwatch.elapsedMilliseconds;
    }
  }

  @override
  void dispose() {
    _cameraManager.dispose();
    _detector.dispose();
    _feedback.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraManager.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Object Detection', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
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
              );
            },
          ),
          
          Positioned(
            bottom: 20,
            left: 20,
            child: Text(
              'FPS: $_fps',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
                fontFamily: 'Lexend',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
