import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:map_mvp_project/services/error_handler.dart';
import 'package:map_mvp_project/src/earth_pages/utils/map_dialog_handler.dart';
import 'package:map_mvp_project/src/earth_pages/utils/map_annotations_manager.dart';
import 'package:map_mvp_project/src/earth_pages/utils/trash_can_handler.dart';

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
  bool _isProcessingDrag = false;
  final TrashCanHandler _trashCanHandler;

  ScreenCoordinate? _lastDragScreenPoint;
  
  // Store the original point of the annotation before dragging
  Point? _originalPoint;

  MapGestureHandler({
    required this.mapboxMap,
    required this.annotationsManager,
    required this.context,
  }) : _trashCanHandler = TrashCanHandler(context: context);

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
        _startPlacementDialogTimer(pressPoint);
      } else {
        _selectedAnnotation = await annotationsManager.findNearestAnnotation(pressPoint);
        if (_selectedAnnotation != null) {
          // Store the original point of the annotation before it starts to drag
          _originalPoint = _selectedAnnotation?.geometry;
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
      _isProcessingDrag = false;
      _trashCanHandler.showTrashCan();
    });
  }

  Future<void> handleDrag(ScreenCoordinate screenPoint) async {
    if (!_isDragging || _selectedAnnotation == null) {
      logger.i('Skipping drag, either not dragging or annotation is null now');
      return;
    }

    final annotationToUpdate = _selectedAnnotation;
    if (annotationToUpdate == null) {
      logger.i('Skipping drag: annotation is null');
      return;
    }

    if (_isProcessingDrag) {
      logger.i('Skipping drag, already processing');
      return;
    }

    try {
      _isProcessingDrag = true;
      _lastDragScreenPoint = screenPoint;
      final newPoint = await mapboxMap.coordinateForPixel(screenPoint);

      if (!_isDragging || _selectedAnnotation == null) {
        logger.i('Skipping drag update after async call because dragging ended or annotation is null');
        return;
      }

      if (newPoint != null) {
        await annotationsManager.updateVisualPosition(annotationToUpdate, newPoint);
      }
    } catch (e) {
      logger.e('Error during drag: $e');
    } finally {
      _isProcessingDrag = false;
    }
  }

  Future<void> endDrag() async {
    logger.i('Ending drag');

    // Keep a local reference in case we need to revert
    final annotationToRemove = _selectedAnnotation;

    bool removedAnnotation = false;
    bool revertedPosition = false;

    if (annotationToRemove != null &&
        _lastDragScreenPoint != null &&
        _trashCanHandler.isOverTrashCan(_lastDragScreenPoint!)) {
      
      final shouldRemove = await _showRemoveConfirmationDialog();
      if (shouldRemove == true) {
        logger.i('User confirmed removal - removing annotation.');
        annotationsManager.removeAnnotation(annotationToRemove);
        removedAnnotation = true;
      } else {
        logger.i('User cancelled - revert annotation to original position.');
        if (_originalPoint != null) {
          // Revert the annotation's position to the original point
          await annotationsManager.updateVisualPosition(annotationToRemove, _originalPoint!);
          revertedPosition = true;
        }
      }
    }

    // Reset state
    _selectedAnnotation = null;
    _isDragging = false;
    _isProcessingDrag = false;
    _lastDragScreenPoint = null;
    _trashCanHandler.hideTrashCan();
    _originalPoint = null;

    if (removedAnnotation) {
      logger.i('Annotation removed successfully');
    } else if (revertedPosition) {
      logger.i('Annotation reverted to original position');
    }
  }

  Future<bool?> _showRemoveConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Remove Annotation'),
          content: const Text('Do you want to remove this annotation?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );
  }

  void _startPlacementDialogTimer(Point point) {
    _placementDialogTimer?.cancel();
    logger.i('Starting placement dialog timer');

    _placementDialogTimer = Timer(const Duration(milliseconds: 400), () async {
      try {
        final shouldAddAnnotation = await MapDialogHandler.showNewAnnotationDialog(context);
        if (shouldAddAnnotation) {
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
    _isProcessingDrag = false;
    _trashCanHandler.hideTrashCan();
    _originalPoint = null;
  }

  void dispose() {
    cancelTimer();
  }

  bool get isDragging => _isDragging;
  PointAnnotation? get selectedAnnotation => _selectedAnnotation;
}