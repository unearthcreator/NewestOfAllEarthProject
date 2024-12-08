import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_mvp_project/src/app.dart';
import 'package:map_mvp_project/services/error_handler.dart';
import 'package:map_mvp_project/services/orientation_util.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:map_mvp_project/models/annotation.dart';
import 'package:map_mvp_project/repositories/i_annotations_repository.dart'; // Ensure this import is present
import 'package:map_mvp_project/repositories/local_annotations_repository.dart';

void main() {
  setupErrorHandling();
  runAppWithErrorHandling(_initializeApp);

  String ACCESS_TOKEN = const String.fromEnvironment("ACCESS_TOKEN");
  MapboxOptions.setAccessToken(ACCESS_TOKEN);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
}

void _initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  logger.i('Initializing app, locking orientation, and initializing Hive.');
  
  await Hive.initFlutter();
  
  await lockOrientation().catchError((error, stackTrace) {
    logger.e('Failed to set orientation', error: error, stackTrace: stackTrace);
  });

  _runAppSafely();

  // Quick sanity check after a short delay to ensure the app has started.
  Future.delayed(const Duration(seconds: 2), () async {
    // Notice we declare `repo` as `IAnnotationsRepository` instead of `LocalAnnotationsRepository`
    IAnnotationsRepository repo = LocalAnnotationsRepository();
    final testAnnotation = Annotation(
      id: 'test-annotation-id',
      title: 'Test Annotation',
      iconName: 'test_icon',
      date: DateTime.now(),
      note: 'This is a test note',
      images: [],
      latitude: 40.6892,
      longitude: -74.0445,
    );

    await repo.addAnnotation(testAnnotation);
    final annotations = await repo.getAnnotations();
    // Because Annotation now has a toString(), this will print detailed info.
    logger.i('Annotations retrieved from local DB: $annotations');
  });
}

void _runAppSafely() {
  try {
    runApp(const ProviderScope(child: MyApp()));
  } catch (e, stackTrace) {
    logger.e('Error while running the app', error: e, stackTrace: stackTrace);
  }
}