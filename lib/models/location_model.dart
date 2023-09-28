import 'dart:developer';

import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationModel {
  final LatLng coordinates;
  final String? name;
  final String? address;

  LocationModel({
    required this.coordinates,
    this.name,
    this.address,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    // Convert the JSON data to the Location object.
    log(json['coordinates'].toString());
    return LocationModel(
      coordinates: LatLng(json['coordinates']['latitude'], json['coordinates']['longitude']),
      name: json['name'] ?? '',
      address: json['address'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    // Convert the Location object to a JSON representation.
    return {
      'coordinates': {'latitude': coordinates.latitude, 'longitude': coordinates.longitude},
      'name': name,
      'address': address,
    };
  }
}