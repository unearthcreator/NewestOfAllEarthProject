import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:map_mvp_project/src/earth_pages/utils/map_config.dart';
import 'package:map_mvp_project/src/earth_pages/utils/map_annotations_manager.dart';
import 'package:map_mvp_project/src/earth_pages/utils/map_gesture_handler.dart';
import 'package:map_mvp_project/services/error_handler.dart';

class EarthMapPage extends StatefulWidget {
  const EarthMapPage({super.key});
  @override
  EarthMapPageState createState() => EarthMapPageState();
}

class EarthMapPageState extends State<EarthMapPage> {
  late MapboxMap _mapboxMap;
  bool _isMapReady = false;
  late MapAnnotationsManager _annotationsManager;
  late MapGestureHandler _gestureHandler;

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    logger.i('Map created.');
    
    final annotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    _annotationsManager = MapAnnotationsManager(annotationManager);
    
    _gestureHandler = MapGestureHandler(
      mapboxMap: mapboxMap,
      annotationsManager: _annotationsManager,
      context: context,
    );

    setState(() {
      _isMapReady = true;
    });
  }

  @override
  void dispose() {
    _gestureHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GestureDetector(
            onLongPressStart: (LongPressStartDetails details) {
              logger.i('Long press started');
              final screenPoint = ScreenCoordinate(
                x: details.localPosition.dx,
                y: details.localPosition.dy,
              );
              _gestureHandler.handleLongPress(screenPoint);
            },
            onLongPressMoveUpdate: (LongPressMoveUpdateDetails details) {
              if (_gestureHandler.isDragging) {
                final screenPoint = ScreenCoordinate(
                  x: details.localPosition.dx,
                  y: details.localPosition.dy,
                );
                _gestureHandler.handleDrag(screenPoint);
              }
            },
            onLongPressEnd: (LongPressEndDetails details) {
              logger.i('Long press ended');
              _gestureHandler.endDrag();
              _gestureHandler.cancelTimer();
            },
            onLongPressCancel: () {
              logger.i('Long press cancelled');
              _gestureHandler.endDrag();
              _gestureHandler.cancelTimer();
            },
            child: MapWidget(
              cameraOptions: MapConfig.defaultCameraOptions,
              styleUri: MapConfig.styleUri,
              onMapCreated: _onMapCreated,
            ),
          ),
          if (_isMapReady)
            Positioned(
              top: 40,
              left: 10,
              child: BackButton(
                onPressed: () => Navigator.pop(context),
              ),
            ),
        ],
      ),
    );
  }
}