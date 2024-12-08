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
          // Store the original point of the annotation
          try {
            _originalPoint = Point.fromJson({
              'type': 'Point',
              'coordinates': [
                _selectedAnnotation!.geometry.coordinates[0],
                _selectedAnnotation!.geometry.coordinates[1]
              ],
            });
            logger.i('Original point stored: ${_originalPoint?.coordinates} for annotation ${_selectedAnnotation?.id}');
          } catch (e) {
            logger.e('Error storing original point: $e');
          }
          _startDragTimer();
        } else {
          logger.w('No annotation found to start dragging');
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
      return;
    }

    final annotationToUpdate = _selectedAnnotation;
    if (annotationToUpdate == null || _isProcessingDrag) {
      return;
    }

    try {
      _isProcessingDrag = true;
      _lastDragScreenPoint = screenPoint;
      final newPoint = await mapboxMap.coordinateForPixel(screenPoint);

      if (!_isDragging || _selectedAnnotation == null) {
        return;
      }

      if (newPoint != null) {
        logger.i('Updating annotation ${annotationToUpdate.id} position to $newPoint');
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
    logger.i('Original point at end drag: ${_originalPoint?.coordinates}');
    final annotationToRemove = _selectedAnnotation;
    bool removedAnnotation = false;
    bool revertedPosition = false;

    if (annotationToRemove != null &&
        _lastDragScreenPoint != null &&
        _trashCanHandler.isOverTrashCan(_lastDragScreenPoint!)) {
      
      logger.i('Annotation ${annotationToRemove.id} dropped over trash can. Showing dialog.');
      final shouldRemove = await _showRemoveConfirmationDialog();

      if (shouldRemove == true) {
        logger.i('User confirmed removal - removing annotation ${annotationToRemove.id}.');
        await annotationsManager.removeAnnotation(annotationToRemove);
        removedAnnotation = true;
      } else {
        logger.i('User cancelled removal - attempting to revert annotation to original position.');
        if (_originalPoint != null) {
          logger.i('Reverting annotation ${annotationToRemove.id} to ${_originalPoint?.coordinates}');
          await annotationsManager.updateVisualPosition(annotationToRemove, _originalPoint!);
          revertedPosition = true;
        } else {
          logger.w('No original point stored, cannot revert.');
        }
      }
    }

    // Reset state here after the user made a decision
    _selectedAnnotation = null;
    _isDragging = false;
    _isProcessingDrag = false;
    _lastDragScreenPoint = null;
    _originalPoint = null;
    _trashCanHandler.hideTrashCan();

    if (removedAnnotation) {
      logger.i('Annotation removed successfully');
    } else if (revertedPosition) {
      logger.i('Annotation reverted to original position');
    } else {
      logger.i('No removal or revert occurred');
    }
  }

  Future<bool?> _showRemoveConfirmationDialog() async {
    logger.i('Showing remove confirmation dialog');
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Remove Annotation'),
          content: const Text('Do you want to remove this annotation?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                logger.i('User selected NO in the dialog');
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                logger.i('User selected YES in the dialog');
                Navigator.of(dialogContext).pop(true);
              },
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
        // Show the initial form dialog with Title, Date, Icon (placeholder) and continue button
        final initialResult = await _showInitialFormDialog(context);
        if (initialResult == true) {
          // User pressed continue, now show the annotation form dialog (title/note)
          final result = await _showAnnotationFormDialog(context);
          if (result != null) {
            final title = result['title'] ?? '';
            final note = result['note'] ?? '';
            logger.i('User entered title: $title, note: $note');
            // Later: integrate repository calls to actually save the annotation
          } else {
            logger.i('User cancelled the annotation note dialog - no annotation added.');
          }
        } else {
          logger.i('User closed the initial form dialog - no annotation added.');
        }
      } catch (e) {
        logger.e('Error in placement dialog timer: $e');
      }
    });
  }

  Future<bool?> _showInitialFormDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final dateController = TextEditingController();

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final screenWidth = MediaQuery.of(dialogContext).size.width;
        return AlertDialog(
          content: SizedBox(
            width: screenWidth * 0.5,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // left align text
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top row with X to close
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(false),
                        child: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Title:'),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      hintText: 'Enter title',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Icon:'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star), // Placeholder icon
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          // Future: open icon selection
                        },
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Date:'),
                  TextField(
                    controller: dateController,
                    decoration: const InputDecoration(
                      hintText: 'Enter date',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Continue'),
              onPressed: () {
                // For now, just continue
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, String>?> _showAnnotationFormDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final noteController = TextEditingController();

    return showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) {
        final screenWidth = MediaQuery.of(dialogContext).size.width;
        return AlertDialog(
          content: SizedBox(
            width: screenWidth * 0.5, // 50% of screen width
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // align text to left here too
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Title:'),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      hintText: 'Enter title',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Note:'),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      hintText: 'Enter note',
                    ),
                    maxLines: 4,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(null),
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                final title = titleController.text.trim();
                final note = noteController.text.trim();
                Navigator.of(dialogContext).pop({
                  'title': title,
                  'note': note,
                });
              },
            ),
          ],
        );
      },
    );
  }

  void cancelTimer() {
    logger.i('Cancelling timers and resetting state');
    _longPressTimer?.cancel();
    _placementDialogTimer?.cancel();
    _longPressTimer = null;
    _placementDialogTimer = null;
    _longPressPoint = null;
    _selectedAnnotation = null;
    _isOnExistingAnnotation = false;
    _isDragging = false;
    _isProcessingDrag = false;
    _originalPoint = null;
    _trashCanHandler.hideTrashCan();
  }

  void dispose() {
    cancelTimer();
  }

  bool get isDragging => _isDragging;
  PointAnnotation? get selectedAnnotation => _selectedAnnotation;
}