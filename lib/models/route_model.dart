import 'package:safe_ride_app/models/path_model.dart';
import 'location_model.dart';

class RouteModel {
  LocationModel origin;
  List<LocationModel> waypoints;
  DateTime departureTime;
  List<List<PathModel>> options;
  Map<String, dynamic> pathsGeojson;

  RouteModel({
    required this.origin,
    required this.waypoints,
    required this.departureTime,
    required this.options,
    required this.pathsGeojson,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    // Convert the JSON data to the Route object.
    return RouteModel(
      origin: LocationModel.fromJson(json['origin']),
      waypoints: (json['waypoints'] as List)
        .map((waypointJson) => LocationModel.fromJson(waypointJson))
        .toList(),
      departureTime: DateTime.parse(json['departure_time']),
      options: [
        // So far, the backend only returns a maximum of 3 options, the third one being always empty
        (json['option1'] as List).map((pathJson) => PathModel.fromJson(pathJson)).toList(),
        (json['option2'] as List).map((pathJson) => PathModel.fromJson(pathJson)).toList(),
      ],
      pathsGeojson: json['path_geojson'],
    );
  }

  Map<String, dynamic> toJson() {
    // Convert the Route object to a JSON representation.
    return {
      'origin': origin.toJson(),
      'waypoints': waypoints.map((waypoint) => waypoint.toJson()).toList(),
      'departure_time': "",
      'options': [
        for (var option in options)
          option.map((path) => path.toJson()).toList()
      ],
      'path_geojson': pathsGeojson,
    };
  }
}