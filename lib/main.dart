import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/object_detection_screen.dart';
import 'screens/path_navigation_screen.dart';
import 'screens/environment_analysis_screen.dart';
import 'screens/face_detection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  await _requestPermissions();
  runApp(const JnanetraApp());
}

Future<void> _requestPermissions() async {
  await [Permission.camera, Permission.microphone].request();
}

final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/object-detection', builder: (_, __) => const ObjectDetectionScreen()),
    GoRoute(path: '/path-navigation', builder: (_, __) => const PathNavigationScreen()),
    GoRoute(path: '/environment-analysis', builder: (_, __) => const EnvironmentAnalysisScreen()),
    GoRoute(path: '/face-detection', builder: (_, __) => const FaceDetectionScreen()),
  ],
);

class JnanetraApp extends StatelessWidget {
  const JnanetraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Jnanetra',
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
