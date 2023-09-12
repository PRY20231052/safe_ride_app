import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationModel {
  final double? latitude;
  final double? longitude;
  final String? name;
  final String? address;

  LocationModel({
    this.latitude,
    this.longitude,
    this.name,
    this.address,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    // Convert the JSON data to the Location object.
    return LocationModel(
      latitude: json['latitude'],
      longitude: json['longitude'],
      name: json['name'],
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    // Convert the Location object to a JSON representation.
    return {
      'latitude': latitude,
      'longitude': longitude,
      'name': name,
      'address': address,
    };
  }
  
  LatLng? toLatLng(){
    if (latitude != null && longitude != null){
      return LatLng(latitude!, longitude!);
    }
    return null;
  }
}