import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../app_theme.dart';
import '../camera/camera_manager.dart';
import '../ml/tflite_detector.dart';
import '../ml/detection.dart';
import '../engine/decision_engine.dart';
import '../feedback/feedback_manager.dart';

class PathNavigationScreen extends StatefulWidget {
  const PathNavigationScreen({super.key});

  @override
  State<PathNavigationScreen> createState() => _PathNavigationScreenState();
}

class _PathNavigationScreenState extends State<PathNavigationScreen> {
  final CameraManager _cameraManager = CameraManager();
  final TfliteDetector _detector = TfliteDetector();
  final DecisionEngine _engine = DecisionEngine();
  final FeedbackManager _feedback = FeedbackManager();
  final stt.SpeechToText _speech = stt.SpeechToText();

  final ValueNotifier<NavigationCommand> _command = ValueNotifier(NavigationCommand.clear);
  final ValueNotifier<String?> _targetObject = ValueNotifier(null);
  final ValueNotifier<double?> _distanceToTarget = ValueNotifier(null);
  final ValueNotifier<bool> _isListening = ValueNotifier(false);
  DetectionZone? _lastKnownZone;

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
      await _speech.initialize();

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
    
    if (_targetObject.value != null) {
      final targetLabel = _targetObject.value!.toLowerCase();
      final targets = detections.where((d) => d.label.toLowerCase() == targetLabel).toList();
      
      if (targets.isNotEmpty) {
        // Target is in frame
        final d = targets.first;
        
        // Refined Distance Estimation for 416x416 input
        // Using a more realistic height for typical indoor targets
        // Laptop height is ~0.2m (20cm) when open
        final double realHeight = 0.25; 
        final distance = (realHeight * image.height) / d.boundingBox.height;
        _distanceToTarget.value = distance;
        _lastKnownZone = d.zone;

        if (distance < 0.8) { // Increased threshold to 0.8m for earlier arrival detection
          // Arrival: intense haptics and specific audio
          await _feedback.reachedTarget(_targetObject.value!);
          _targetObject.value = null;
          _distanceToTarget.value = null;
          _lastKnownZone = null;
          _command.value = NavigationCommand.clear;
        } else {
          // Directional guidance
          String dir;
          NavigationCommand cmd;
          if (d.zone == DetectionZone.left) {
            dir = 'to your left';
            cmd = NavigationCommand.moveLeft;
          } else if (d.zone == DetectionZone.right) {
            dir = 'to your right';
            cmd = NavigationCommand.moveRight;
          } else {
            dir = 'straight ahead';
            cmd = NavigationCommand.moveForward;
          }
          _command.value = cmd;
          
          await _feedback.speak('${_targetObject.value} is ${distance.toStringAsFixed(1)} meters ahead. Move $dir.');
        }
      } else {
        // Target NOT in frame: guide user to scan based on last known position
        _distanceToTarget.value = null;
        _command.value = NavigationCommand.clear;
        
        String hint = _lastKnownZone == DetectionZone.left 
            ? 'Move camera further to the left.' 
            : (_lastKnownZone == DetectionZone.right 
                ? 'Move camera further to the right.' 
                : 'Move camera slowly to find the ${_targetObject.value}.');
        await _feedback.speak(hint);
      }
    } else {
      // No target locked: keep quiet as requested
      _distanceToTarget.value = null;
      _command.value = NavigationCommand.clear;
    }
  }

  void _listen() async {
    if (!_isListening.value) {
      bool available = await _speech.initialize();
      if (available) {
        _isListening.value = true;
        _speech.listen(onResult: (val) {
          if (val.finalResult) {
            final text = val.recognizedWords.toLowerCase();
            // Match "navigate to {object}" or just "{object}"
            String target = text.replaceFirst('navigate to', '').trim().split(' ').last;
            
            if (target.isNotEmpty) {
              _targetObject.value = target;
              _feedback.speak('Locking target: $target. Please scan the room.');
            }
            _isListening.value = false;
          }
        });
      }
    } else {
      _isListening.value = false;
      _speech.stop();
    }
  }

  @override
  void dispose() {
    _cameraManager.dispose();
    _detector.dispose();
    _feedback.dispose();
    _speech.stop();
    WakelockPlus.disable();
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
        title: const Text('Path Navigation', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          CameraPreview(_cameraManager.controller!),

          Center(
            child: ValueListenableBuilder(
              valueListenable: _command,
              builder: (context, command, child) {
                return _buildNavigationIndicator(command);
              },
            ),
          ),

          Positioned(
            bottom: 30, // Mic button at bottom center
            left: 0,
            right: 0,
            child: Center(
              child: ValueListenableBuilder(
                valueListenable: _isListening,
                builder: (context, listening, child) {
                  return Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: listening ? AppColors.error : AppColors.primary,
                      boxShadow: [
                        BoxShadow(
                          color: (listening ? AppColors.error : AppColors.primary).withValues(alpha: 0.4),
                          blurRadius: 15,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _listen,
                      icon: Icon(
                        listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          Positioned(
            bottom: 120, // Guidance panel above the mic button
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ValueListenableBuilder(
                    valueListenable: _targetObject,
                    builder: (context, target, child) {
                      if (target == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'TARGET: ${target.toUpperCase()}',
                          style: const TextStyle(
                            fontFamily: 'Lexend',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    },
                  ),
                  ValueListenableBuilder(
                    valueListenable: _distanceToTarget,
                    builder: (context, dist, child) {
                      if (dist == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          'DISTANCE: ${dist.toStringAsFixed(1)}m',
                          style: const TextStyle(
                            fontFamily: 'Lexend',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    },
                  ),
                  ValueListenableBuilder(
                    valueListenable: _command,
                    builder: (context, command, child) {
                      if (_targetObject.value == null) {
                        return const Text(
                          'READY FOR NAVIGATION',
                          style: TextStyle(fontFamily: 'Lexend', fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant),
                        );
                      }
                      return Column(
                        children: [
                          Text(
                            _getCommandText(command),
                            style: TextStyle(
                              fontFamily: 'Lexend',
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: _getCommandColor(command),
                            ),
                          ),
                          Text(
                            _getCommandSubtext(command),
                            style: const TextStyle(
                              fontFamily: 'Lexend',
                              fontSize: 18,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationIndicator(NavigationCommand command) {
    IconData icon;
    Color color;
    Color bgColor;

    switch (command) {
      case NavigationCommand.stop:
        icon = Icons.block_rounded;
        color = AppColors.error;
        bgColor = AppColors.errorContainer;
        break;
      case NavigationCommand.moveLeft:
        icon = Icons.arrow_back_rounded;
        color = AppColors.tertiary;
        bgColor = AppColors.tertiaryContainer;
        break;
      case NavigationCommand.moveRight:
        icon = Icons.arrow_forward_rounded;
        color = AppColors.tertiary;
        bgColor = AppColors.tertiaryContainer;
        break;
      case NavigationCommand.moveForward:
      case NavigationCommand.clear:
        icon = Icons.arrow_upward_rounded;
        color = AppColors.secondary;
        bgColor = AppColors.secondaryContainer;
        break;
    }

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor.withValues(alpha: 0.6),
        border: Border.all(color: color, width: 3),
      ),
      child: Icon(icon, size: 60, color: color),
    );
  }

  Color _getCommandColor(NavigationCommand command) {
    switch (command) {
      case NavigationCommand.stop: return AppColors.error;
      case NavigationCommand.moveLeft:
      case NavigationCommand.moveRight: return AppColors.tertiary;
      case NavigationCommand.moveForward:
      case NavigationCommand.clear: return AppColors.secondary;
    }
  }

  String _getCommandText(NavigationCommand command) {
    switch (command) {
      case NavigationCommand.stop: return 'STOP';
      case NavigationCommand.moveLeft: return 'MOVE LEFT';
      case NavigationCommand.moveRight: return 'MOVE RIGHT';
      case NavigationCommand.moveForward: return 'MOVE FORWARD';
      case NavigationCommand.clear: return 'PATH CLEAR';
    }
  }

  String _getCommandSubtext(NavigationCommand command) {
    switch (command) {
      case NavigationCommand.stop: return 'Obstacle ahead';
      case NavigationCommand.moveLeft: return 'Move to the left side';
      case NavigationCommand.moveRight: return 'Move to the right side';
      case NavigationCommand.moveForward: return 'Path is clear';
      case NavigationCommand.clear: return 'Ready for navigation';
    }
  }
}
