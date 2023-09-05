import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationModel {
  final double latitude;
  final double longitude;
  final String? address;

  LocationModel({
    required this.latitude,
    required this.longitude,
    this.address, // 'address' is now optional
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    // Convert the JSON data to the Location object.
    return LocationModel(
      latitude: json['latitude'],
      longitude: json['longitude'],
      address: json['address'], // No need for the null-aware operator '?'
    );
  }

  Map<String, dynamic> toJson() {
    // Convert the Location object to a JSON representation.
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address, // 'address' can be null in the JSON
    };
  }
  
  LatLng toLatLng(){
    return LatLng(latitude, longitude);
  }
}