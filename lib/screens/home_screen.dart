import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../app_theme.dart';
import '../widgets/feature_card.dart';
import '../feedback/feedback_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FeedbackManager _feedback = FeedbackManager();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _feedback.init();
    await _speech.initialize();
    await _feedback.welcome();
  }

  void _handleFeatureInteraction(String title) {
    _feedback.speak('$title. Double tap to open.');
  }

  void _openFeature(String title, String route) {
    _feedback.speak('Opening $title');
    context.push(route);
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (val) {
          if (val.finalResult) {
            setState(() => _isListening = false);
            final command = val.recognizedWords.toLowerCase();
            if (command.contains('object')) {
              _openFeature('Object Detection', '/object-detection');
            } else if (command.contains('path') || command.contains('navigation')) {
              _openFeature('Path Navigation', '/path-navigation');
            } else if (command.contains('environment') || command.contains('analysis')) {
              _openFeature('Environment Analysis', '/environment-analysis');
            } else if (command.contains('face')) {
              _openFeature('Face Detection', '/face-detection');
            } else {
              _feedback.speak('Command not recognized. Please say a feature name.');
            }
          }
        });
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double cardHeight = (screenHeight * 0.7) / 2.2;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Icon(Icons.arrow_back, color: Color(0xFF0058BC), size: 28),
        title: const Text(
          'Jnanetra',
          style: TextStyle(
            color: Color(0xFF0058BC),
            fontWeight: FontWeight.w900,
            fontSize: 28,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 0.75,
                  children: [
                    _buildAccessibleCard(
                      title: 'Object Detection',
                      icon: Icons.visibility_rounded,
                      color: const Color(0xFF0058BC),
                      route: '/object-detection',
                    ),
                    _buildAccessibleCard(
                      title: 'Path Navigation',
                      icon: Icons.arrow_upward_rounded,
                      color: const Color(0xFF006E2D),
                      route: '/path-navigation',
                    ),
                    _buildAccessibleCard(
                      title: 'Environment Analysis',
                      icon: Icons.travel_explore_rounded,
                      color: const Color(0xFF9E3D00),
                      route: '/environment-analysis',
                    ),
                    _buildAccessibleCard(
                      title: 'Face Detection',
                      icon: Icons.face_rounded,
                      color: const Color(0xFF7C3AED),
                      route: '/face-detection',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 72,
                height: 72,
                margin: const EdgeInsets.only(bottom: 30),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0058BC),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0058BC).withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: _listen,
                  icon: Icon(
                    _isListening ? Icons.mic_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccessibleCard({
    required String title,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return GestureDetector(
      onTap: () => _handleFeatureInteraction(title),
      onDoubleTap: () => _openFeature(title, route),
      child: FeatureCard(
        title: title,
        description: '', // Not used in this layout
        icon: icon,
        featureColor: color,
        onTap: () {},
      ),
    );
  }
}
