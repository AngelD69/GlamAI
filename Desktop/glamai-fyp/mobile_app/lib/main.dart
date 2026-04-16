import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'utils/logger.dart';

void main() {
  // Catch synchronous Flutter framework errors (e.g. widget build errors)
  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.error(
      'FlutterError',
      details.exceptionAsString(),
      details.exception,
      details.stack,
    );
    // In release mode, suppress the red error screen and show nothing
    if (kReleaseMode) {
      FlutterError.presentError(details);
    } else {
      FlutterError.dumpErrorToConsole(details);
    }
  };

  // Catch asynchronous errors that escape Flutter's zone (e.g. isolate errors)
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error('PlatformDispatcher', 'Unhandled platform error', error, stack);
    return true; // mark as handled so Flutter does not crash
  };

  runApp(const GlamAIApp());
}

class GlamAIApp extends StatelessWidget {
  const GlamAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GlamAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE91E8C)),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE91E8C),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
