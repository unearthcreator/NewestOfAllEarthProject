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
  late MapAnnotationsManager _annotationsManager;
  late MapGestureHandler _gestureHandler;
  
  bool _isMapReady = false;
  bool _isError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    logger.i('Initializing EarthMapPage');
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    try {
      logger.i('Starting map initialization');
      _mapboxMap = mapboxMap;
      
      final annotationManager = await mapboxMap.annotations
          .createPointAnnotationManager()
          .onError((error, stackTrace) {
        logger.e('Failed to create annotation manager', 
          error: error, 
          stackTrace: stackTrace);
        throw Exception('Failed to initialize map annotations');
      });

      _annotationsManager = MapAnnotationsManager(annotationManager);
      
      _gestureHandler = MapGestureHandler(
        mapboxMap: mapboxMap,
        annotationsManager: _annotationsManager,
        context: context,
      );

      logger.i('Map initialization completed successfully');
      
      if (mounted) {
        setState(() => _isMapReady = true);
      }
    } catch (e, stackTrace) {
      logger.e('Error during map initialization', 
        error: e, 
        stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = 'Failed to initialize map: ${e.toString()}';
        });
      }
    }
  }

  void _handleLongPress(LongPressStartDetails details) {
    try {
      logger.i('Long press started at: ${details.localPosition}');
      final screenPoint = ScreenCoordinate(
        x: details.localPosition.dx,
        y: details.localPosition.dy,
      );
      _gestureHandler.handleLongPress(screenPoint);
    } catch (e, stackTrace) {
      logger.e('Error handling long press', 
        error: e, 
        stackTrace: stackTrace);
    }
  }

  void _handleLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    try {
      if (_gestureHandler.isDragging) {
        final screenPoint = ScreenCoordinate(
          x: details.localPosition.dx,
          y: details.localPosition.dy,
        );
        _gestureHandler.handleDrag(screenPoint);
      }
    } catch (e, stackTrace) {
      logger.e('Error handling drag update', 
        error: e, 
        stackTrace: stackTrace);
    }
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    try {
      logger.i('Long press ended');
      _gestureHandler.endDrag();
      _gestureHandler.cancelTimer();
    } catch (e, stackTrace) {
      logger.e('Error handling long press end', 
        error: e, 
        stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    try {
      logger.i('Disposing EarthMapPage');
      _gestureHandler.dispose();
      super.dispose();
    } catch (e, stackTrace) {
      logger.e('Error disposing EarthMapPage', 
        error: e, 
        stackTrace: stackTrace);
      super.dispose();
    }
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(_errorMessage, 
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildMapWidget() {
    return GestureDetector(
      onLongPressStart: _handleLongPress,
      onLongPressMoveUpdate: _handleLongPressMoveUpdate,
      onLongPressEnd: _handleLongPressEnd,
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
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      top: 40,
      left: 10,
      child: BackButton(
        onPressed: () {
          logger.i('Navigating back from EarthMapPage');
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isError 
        ? _buildErrorWidget()
        : Stack(
            children: [
              _buildMapWidget(),
              if (_isMapReady) _buildBackButton(),
            ],
          ),
    );
  }
}