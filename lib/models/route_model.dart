import 'location_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteModel {
  final LocationModel origin;
  final List<LocationModel> waypoints;
  final int? distanceMeters;
  final int? eatSeconds;
  final Map<String, dynamic> pathGeojson;

  RouteModel({
    required this.origin,
    required this.waypoints,
    this.distanceMeters,
    this.eatSeconds,
    required this.pathGeojson,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    // Convert the JSON data to the Route object.
    return RouteModel(
      origin: LocationModel.fromJson(json['origin']),
      waypoints: (json['waypoints'] as List)
          .map((waypointJson) => LocationModel.fromJson(waypointJson))
          .toList(),
      distanceMeters: json['distance_meters'] ?? 0,
      eatSeconds: json['eat_seconds'] ?? 0,
      pathGeojson: json['path_geojson'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    // Convert the Route object to a JSON representation.
    return {
      'origin': origin.toJson(),
      'waypoints': waypoints.map((waypoint) => waypoint.toJson()).toList(),
      'distance_meters': distanceMeters,
      'eat_seconds': eatSeconds,
      'path_geojson': pathGeojson,
    };
  }
  List<LatLng> getLatLngPoints(){
    return [
      for (List coordinate in pathGeojson['features'][0]['geometry']['coordinates']) LatLng(coordinate[0], coordinate[1])
    ];
  }
}