import 'location_model.dart';

class EdgeModel {

  LocationModel source;
  LocationModel target;
  Map<String, dynamic> attributes;

  EdgeModel({
    required this.source,
    required this.target,
    required this.attributes,
  });

  factory EdgeModel.fromJson(Map<String, dynamic> json){
    return EdgeModel(
      source: LocationModel.fromJson(json['source']),
      target: LocationModel.fromJson(json['target']),
      attributes: json['attributes'],
    );
  }

  Map<String, dynamic> toJson(){
    return {
      'source': source.toJson(),
      'target': target.toJson(),
      'attributes': attributes,
    };
  }

}