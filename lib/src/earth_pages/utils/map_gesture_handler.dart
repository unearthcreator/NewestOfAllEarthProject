import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:map_mvp_project/services/error_handler.dart';
import 'package:map_mvp_project/src/earth_pages/utils/map_dialog_handler.dart';
import 'package:map_mvp_project/src/earth_pages/utils/map_annotations_manager.dart';

class MapGestureHandler {
  final MapboxMap mapboxMap;
  final MapAnnotationsManager annotationsManager;
  final BuildContext context;

  Timer? _longPressTimer;
  Timer? _placementDialogTimer;
  Point? _longPressPoint;
  bool _isOnExistingAnnotation = false;
  PointAnnotation? _selectedAnnotation;
  bool _isDragging = false;

  MapGestureHandler({
    required this.mapboxMap,
    required this.annotationsManager,
    required this.context,
  });

  Future<void> handleLongPress(ScreenCoordinate screenPoint) async {
    try {
      final features = await mapboxMap.queryRenderedFeatures(
        RenderedQueryGeometry.fromScreenCoordinate(screenPoint),
        RenderedQueryOptions(layerIds: [annotationsManager.annotationLayerId]),
      );
      
      logger.i('Features found: ${features.length}');
      
      final pressPoint = await mapboxMap.coordinateForPixel(screenPoint);
      if (pressPoint == null) {
        logger.w('Could not convert screen coordinate to map coordinate');
        return;
      }
      
      _longPressPoint = pressPoint;
      _isOnExistingAnnotation = features.isNotEmpty;
      
      if (!_isOnExistingAnnotation) {
        // Start with dialog first
        _startPlacementDialogTimer(pressPoint);
      } else {
        _selectedAnnotation = await annotationsManager.findNearestAnnotation(pressPoint);
        if (_selectedAnnotation != null) {
          _startDragTimer();
        }
      }
    } catch (e) {
      logger.e('Error during feature query: $e');
    }
  }

  void _startDragTimer() {
    _longPressTimer?.cancel();
    logger.i('Starting drag timer');
    
    _longPressTimer = Timer(const Duration(seconds: 1), () {
      logger.i('Drag timer completed - annotation can now be dragged');
      _isDragging = true;
    });
  }

  Future<void> handleDrag(ScreenCoordinate screenPoint) async {
    if (!_isDragging || _selectedAnnotation == null) return;

    try {
      final newPoint = await mapboxMap.coordinateForPixel(screenPoint);
      if (newPoint != null) {
        await annotationsManager.updateVisualPosition(_selectedAnnotation!, newPoint);
      } else {
        logger.w('Could not convert screen coordinate to map coordinate during drag');
      }
    } catch (e) {
      logger.e('Error during drag: $e');
    }
  }

  void endDrag() {
    if (_isDragging && _selectedAnnotation != null) {
      logger.i('Ending drag');
      _isDragging = false;
      _selectedAnnotation = null;
    }
  }

  void _startPlacementDialogTimer(Point point) {
    _placementDialogTimer?.cancel();
    logger.i('Starting placement dialog timer');
    
    _placementDialogTimer = Timer(const Duration(milliseconds: 400), () async {
      try {
        final shouldAddAnnotation = await MapDialogHandler.showNewAnnotationDialog(context);
        
        if (shouldAddAnnotation) {
          // Only create annotation if user confirms
          logger.i('User confirmed - adding annotation.');
          await annotationsManager.addAnnotation(point);
          logger.i('Annotation added successfully');
        } else {
          logger.i('User cancelled - no annotation added.');
        }
      } catch (e) {
        logger.e('Error in placement dialog timer: $e');
      }
    });
  }

  void cancelTimer() {
    logger.i('Cancelling timers');
    _longPressTimer?.cancel();
    _placementDialogTimer?.cancel();
    _longPressTimer = null;
    _placementDialogTimer = null;
    _longPressPoint = null;
    _selectedAnnotation = null;
    _isOnExistingAnnotation = false;
    _isDragging = false;
  }

  void dispose() {
    cancelTimer();
  }

  bool get isDragging => _isDragging;
  PointAnnotation? get selectedAnnotation => _selectedAnnotation;
}