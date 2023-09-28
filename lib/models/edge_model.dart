import 'package:google_maps_flutter/google_maps_flutter.dart';

class EdgeModel {
  
  LatLng source;
  LatLng target;
  Map<String, dynamic> attributes;

  EdgeModel({
    required this.source,
    required this.target,
    required this.attributes,
  });

  factory EdgeModel.fromJson(Map<String, dynamic> json){
    return EdgeModel(
      source: LatLng(json['source']['latitude'], json['source']['longitude']),
      target: LatLng(json['target']['latitude'], json['target']['longitude']),
      attributes: json['attributes'],
    );
  }

  Map<String, dynamic> toJson(){
    return {
      'source': {'latitude': source.latitude, 'longitude': source.longitude},
      'target': {'latitude': target.latitude, 'longitude': target.longitude},
      'attributes': attributes,
    };
  }

}