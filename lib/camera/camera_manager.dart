import 'dart:async';
import 'package:camera/camera.dart';

class CameraManager {
  CameraController? _controller;
  bool _isProcessing = false;
  int _frameCount = 0;
  static const int _frameSkip = 3; // process every 3rd frame

  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  Future<void> initialize() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) throw Exception('No cameras available');

    _controller = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await _controller!.initialize();
  }

  void startStream(Future<void> Function(CameraImage) onFrame) {
    _controller?.startImageStream((image) {
      _frameCount++;
      if (_frameCount % _frameSkip != 0) return;
      if (_isProcessing) return;
      _isProcessing = true;
      onFrame(image).whenComplete(() => _isProcessing = false);
    });
  }

  Future<void> stopStream() async {
    await _controller?.stopImageStream();
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }
}
