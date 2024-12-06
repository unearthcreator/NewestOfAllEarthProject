import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:map_mvp_project/src/app.dart'; // Your app file
import 'package:map_mvp_project/services/error_handler.dart'; // Import error handling and logger
import 'package:map_mvp_project/services/orientation_util.dart'; // Import orientation utility
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

void main() {
  // Setup error handling for Flutter framework and async errors
  setupErrorHandling();

  // Start app initialization with error handling
  runAppWithErrorHandling(_initializeApp);  // Now calling the private function

    // Hide the status bar

  String ACCESS_TOKEN = const String.fromEnvironment("ACCESS_TOKEN");
  MapboxOptions.setAccessToken(ACCESS_TOKEN);
  
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
}

// App initialization function (private)
void _initializeApp() {
  WidgetsFlutterBinding.ensureInitialized();
  logger.i('Initializing app and locking orientation.');

  // Call lockOrientation from orientation_util.dart
  lockOrientation().then((_) {
    _runAppSafely();  // Now calling the private function
  }).catchError((error, stackTrace) {
    logger.e('Failed to set orientation', error: error, stackTrace: stackTrace);
  });
}

// Function to safely run the app with error handling (private)
void _runAppSafely() {
  try {
    runApp(const ProviderScope(child: MyApp()));
  } catch (e, stackTrace) {
    logger.e('Error while running the app', error: e, stackTrace: stackTrace);
  }
}