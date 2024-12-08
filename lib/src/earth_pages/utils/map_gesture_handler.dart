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
        // Now _showInitialFormDialog returns a map with title, icon, date
        final initialData = await _showInitialFormDialog(context);
        if (initialData != null) {
          // User pressed continue and we have title, chosenIcon, date
          final result = await _showAnnotationFormDialog(
            context,
            title: initialData['title'] as String,
            chosenIcon: initialData['icon'] as IconData,
            date: initialData['date'] as String,
          );
          if (result != null) {
            final note = result['note'] ?? '';
            logger.i('User entered note: $note');
            // Later: integrate repository calls to actually save the annotation with all data
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

  // Now returns a map with 'title', 'icon', 'date' or null if canceled
  Future<Map<String, dynamic>?> _showInitialFormDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final dateController = TextEditingController();

    IconData chosenIcon = Icons.star;

    return showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (dialogContext) {
        final screenWidth = MediaQuery.of(dialogContext).size.width;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              content: SizedBox(
                width: screenWidth * 0.5,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // align left
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top row with X to close
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(dialogContext).pop(null),
                            child: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Title:', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextField(
                        controller: titleController,
                        maxLength: 25,
                        decoration: InputDecoration(
                          hintText: 'Max 25 characters',
                          hintStyle: TextStyle(
                            color: Colors.black.withOpacity(0.5),
                          ),
                          counterText: '',
                        ),
                        buildCounter: (context, {required int currentLength, required bool isFocused, required int? maxLength}) {
                          if (maxLength == null) return null;
                          if (currentLength == 0) {
                            return null; // No counter if no characters typed
                          } else {
                            // Show currentLength/maxLength with 50% opacity
                            return Text(
                              '$currentLength/$maxLength',
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text('Icon:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(chosenIcon),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              final selectedIcon = await _showIconSelectionDialog(dialogContext);
                              if (selectedIcon != null) {
                                setState(() {
                                  chosenIcon = selectedIcon;
                                });
                              }
                            },
                            child: const Text('Change'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Date:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    // Return the chosen data
                    Navigator.of(dialogContext).pop({
                      'title': titleController.text.trim(),
                      'icon': chosenIcon,
                      'date': dateController.text.trim(),
                    });
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Now, we show chosen icon at top left, title center top, date top right, and note field below
  Future<Map<String, String>?> _showAnnotationFormDialog(BuildContext context, {
    required String title,
    required IconData chosenIcon,
    required String date,
  }) async {
    final noteController = TextEditingController();

    return showDialog<Map<String, String>?>(
      context: context,
      builder: (dialogContext) {
        final screenWidth = MediaQuery.of(dialogContext).size.width;
        return AlertDialog(
          content: SizedBox(
            width: screenWidth * 0.5, // 50% of screen width
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top row with icon (left), title (center), date (right)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(chosenIcon),
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        date,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Note:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                final note = noteController.text.trim();
                Navigator.of(dialogContext).pop({
                  'note': note,
                });
              },
            ),
          ],
        );
      },
    );
  }

  Future<IconData?> _showIconSelectionDialog(BuildContext dialogContext) async {
    // A small set of icons to choose from
    final icons = [
      Icons.star,
      Icons.flag,
      Icons.home,
      Icons.camera,
      Icons.map,
      Icons.favorite,
    ];

    return showDialog<IconData>(
      context: dialogContext,
      builder: (iconDialogContext) {
        return AlertDialog(
          title: const Text('Select an Icon'),
          content: SizedBox(
            width: MediaQuery.of(iconDialogContext).size.width * 0.5,
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: icons.map((icon) {
                return GestureDetector(
                  onTap: () {
                    // When tapped, return this icon
                    Navigator.of(iconDialogContext).pop(icon);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 32),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
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