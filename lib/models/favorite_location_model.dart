import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:safe_ride_app/models/location_model.dart';

class FavoriteLocationModel extends LocationModel {
  String? id;
  String alias;

  FavoriteLocationModel({
    this.id,
    this.alias = '',
    required LatLng coordinates,
    required String name,
    required String address,
  }) : super(coordinates: coordinates, name: name, address: address);

  factory FavoriteLocationModel.fromJson(Map<String, dynamic> json) {
    return FavoriteLocationModel(
      id: json['id'],
      coordinates: LatLng(json['coordinates']['latitude'], json['coordinates']['longitude']),
      name: json['name'],
      address: json['address'],
      alias: json['alias'] ?? json['name'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = super.toJson();
    json['id'] = id;
    json['alias'] = alias;
    return json;
  }
}