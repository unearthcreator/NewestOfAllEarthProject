// map_config.dart
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Contains the default configuration options for Mapbox maps used in the app.
/// Allows easy reconfiguration of shared settings across different map instances.
class MapConfig {
  static const String styleUri = 
      "https://api.mapbox.com/styles/v1/unearthcreator/cm2jwm74e004j01ny7osa5ve8?access_token=pk.eyJ1IjoidW5lYXJ0aGNyZWF0b3IiLCJhIjoiY20yam4yODlrMDVwbzJrcjE5cW9vcDJmbiJ9.L2tmRAkt0jKLd8-fWaMWfA";

  /// Default camera options, focused on the center of the USA with zoom level 1.
  static CameraOptions defaultCameraOptions = CameraOptions(
    center: Point(coordinates: Position(-98.0, 39.5)),
    zoom: 1.0,
    bearing: 0.0,
    pitch: 0.0,
  );

  /// Generates default annotation options for a given point.
  static PointAnnotationOptions getDefaultAnnotationOptions(Point geometry) {
    return PointAnnotationOptions(
      geometry: geometry,
      iconSize: 1.0,
      iconImage: "mapbox-check",
    );
  }
}