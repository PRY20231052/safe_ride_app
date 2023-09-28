
class DirectionModel{
  String endingAction;
  String streetName;
  List<dynamic> coveredEdgesIndexes;
  List<dynamic> coveredPolylinePointsIndexes;

  DirectionModel({
    required this.endingAction,
    required this.streetName,
    required this.coveredEdgesIndexes,
    required this.coveredPolylinePointsIndexes,
  });

  factory DirectionModel.fromJson(Map<String, dynamic> json){
    return DirectionModel(
      endingAction: json['ending_action'],
      streetName: json['street_name'],
      coveredEdgesIndexes: json['covered_edges_indexes'],
      coveredPolylinePointsIndexes: json['covered_polyline_points_indexes'],
    );
  }

  Map<String, dynamic> toJson(){
    return {
      'ending_action': endingAction,
      'street_name': streetName,
      'covered_edges_indexes': coveredEdgesIndexes,
      'covered_polyline_points_indexes': coveredPolylinePointsIndexes,
    };
  }
}