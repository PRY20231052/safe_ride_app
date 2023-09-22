import 'package:safe_ride_app/models/edge_model.dart';

import 'location_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteModel {
  LocationModel origin;
  List<LocationModel> waypoints;
  DateTime departureTime;
  DateTime? arrivalTime;
  double distanceMeters;
  double etaSeconds;
  List<LocationModel> pathNodes;
  List<EdgeModel> pathEdges;
  Map<String, dynamic> pathGeojson;

  RouteModel({
    required this.origin,
    required this.waypoints,
    required this.departureTime,
    this.arrivalTime,
    required this.distanceMeters,
    required this.etaSeconds,
    required this.pathNodes,
    required this.pathEdges,
    required this.pathGeojson,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    // Convert the JSON data to the Route object.
    return RouteModel(
      origin: LocationModel.fromJson(json['origin']),
      waypoints: (json['waypoints'] as List)
        .map((waypointJson) => LocationModel.fromJson(waypointJson))
        .toList(),
      departureTime: DateTime.parse(json['departure_time']),
      arrivalTime: json['arrival_time'] != null ? DateTime.parse(json['arrival_time']) : null,
      distanceMeters: json['distance_meters'] ?? 0.0,
      etaSeconds: json['eta_seconds'] ?? 0.0,
      pathNodes: (json['path_nodes'] as List)
        .map((locationJson) => LocationModel.fromJson(locationJson))
        .toList(),
      pathEdges: (json['path_edges'] as List)
        .map((edgeJson) => EdgeModel.fromJson(edgeJson))
        .toList(),
      pathGeojson: json['path_geojson'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    // Convert the Route object to a JSON representation.
    return {
      'origin': origin.toJson(),
      'waypoints': waypoints.map((waypoint) => waypoint.toJson()).toList(),
      'departureTime': "",
      'arrivalTime': "",
      'distance_meters': distanceMeters,
      'eat_seconds': etaSeconds,
      'path_nodes': pathNodes.map((node) => node.toJson()).toList(),
      'path_edges': pathEdges.map((edge) => edge.toJson()).toList(),
      'path_geojson': pathGeojson,
    };
  }
  List<LatLng> getLatLngPoints(){
    return [
      for (List coordinate in pathGeojson['features'][0]['geometry']['coordinates']) LatLng(coordinate[0], coordinate[1])
    ];
  }
}