import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';
import '../ml/detection.dart';

class FeedbackManager {
  final FlutterTts _tts = FlutterTts();
  DateTime? _lastFeedback;
  static const _cooldown = Duration(milliseconds: 3500); // Increased for clarity
  DateTime? _lastObjectAnnouncement;
  static const _objectAnnounceCooldown = Duration(seconds: 4); // Increased for clarity

  Future<void> init() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5); // Slightly slower for better understanding
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);
  }

  Future<void> announce(NavigationCommand command) async {
    // Handled via specific speak calls now
  }

  Future<void> announceObjects(List<Detection> detections) async {
    if (detections.isEmpty) return;

    final now = DateTime.now();
    if (_lastObjectAnnouncement != null && 
        now.difference(_lastObjectAnnouncement!) < _objectAnnounceCooldown) return;

    final currentLabels = detections.map((d) => d.label).toSet().toList();
    if (currentLabels.isEmpty) return;

    _lastObjectAnnouncement = now;

    String text = currentLabels.join(', ');
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> speak(String text) async {
    final now = DateTime.now();
    if (_lastFeedback != null && now.difference(_lastFeedback!) < _cooldown) return;
    _lastFeedback = now;

    await _tts.stop(); 
    await _tts.speak(text);
  }

  Future<void> welcome() async {
    await _tts.stop();
    await _tts.speak('Welcome to Jnanetra. I am your vision assistant. The available features are: Object Detection, Path Navigation, Environment Analysis, and Face Detection. Tap any card to hear more, or double tap to open.');
  }

  Future<void> reachedTarget(String label) async {
    await _tts.stop();
    await _tts.speak('You have reached the $label.');
    
    // Fallback to simple vibration if pattern fails, ensuring feedback
    if (await Vibration.hasVibrator() ?? false) {
      await Vibration.vibrate(duration: 1000); // 1 second solid vibration for arrival
      await Future.delayed(const Duration(milliseconds: 200));
      await Vibration.vibrate(pattern: [0, 500, 200, 500, 200, 500]);
    }
  }

  void dispose() {
    _tts.stop();
  }
}
