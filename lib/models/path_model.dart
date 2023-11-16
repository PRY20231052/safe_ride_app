
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:safe_ride_app/models/direction_model.dart';
import 'package:safe_ride_app/models/edge_model.dart';

class PathModel{

  List<LatLng> nodes;
  List<EdgeModel> edges;
  List<DirectionModel> directions;
  List<LatLng> polylinePoints;
  double distanceMeters;
  double etaSeconds;
  DateTime arrivalTime;

  PathModel({
    required this.nodes,
    required this.edges,
    required this.directions,
    required this.polylinePoints,
    required this.distanceMeters,
    required this.etaSeconds,
    required this.arrivalTime,
  });
  factory PathModel.fromJson(Map<String, dynamic> json){
    return PathModel(
      nodes: (json['nodes'] as List).map((nodeJson) => LatLng(nodeJson['latitude'], nodeJson['longitude'])).toList(),
      edges: (json['edges'] as List).map((edgeJson) => EdgeModel.fromJson(edgeJson)).toList(),
      directions: (json['directions'] as List).map((directionJson) => DirectionModel.fromJson(directionJson)).toList(),
      polylinePoints: (json['polyline_points'] as List).map((pointJson) => LatLng(pointJson['latitude'], pointJson['longitude'])).toList(),
      distanceMeters: json['distance_meters'],
      etaSeconds: json['eta_seconds'],
      arrivalTime: DateTime.parse(json['arrival_time']),
    );
  }

  Map<String, dynamic> toJson(){
    return {
      'nodes': nodes.map((node) => {'latitude': node.latitude, 'longitude': node.longitude}).toList(),
      'edges': edges.map((edge) => edge.toJson()).toList(),
      'directions': directions.map((direction) => direction.toJson()).toList(),
      'polyline_points': polylinePoints.map((point) => {'latitude': point.latitude, 'longitude': point.longitude}).toList(),
      'distance_meters': distanceMeters,
      'eta_seconds': etaSeconds,
      'arrival_time': arrivalTime,
    };
  }
}