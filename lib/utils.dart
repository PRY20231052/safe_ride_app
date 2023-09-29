import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:safe_ride_app/models/location_model.dart';
import 'package:google_maps_utils/google_maps_utils.dart';

double getDistanceBetweenPoints(LatLng point1, LatLng point2){
  const double earthRadius = 6371009.0; // Earth's radius in meters

  // Convert degrees to radians
  double lat1 = degreesToRadians(point1.latitude);
  double lon1 = degreesToRadians(point1.longitude);
  double lat2 = degreesToRadians(point2.latitude);
  double lon2 = degreesToRadians(point2.longitude);

  // Haversine formula
  double dLat = lat2 - lat1;
  double dLon = lon2 - lon1;
  double a = sin(dLat / 2) * sin(dLat / 2) + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  double distance = earthRadius * c;

  return distance;
}

double degreesToRadians(double degrees) {
  return degrees * (pi / 180.0);
}

double computeDistanceBetweenPoints(LatLng point1, LatLng point2){
  return SphericalUtils.computeDistanceBetween(
    Point(point1.latitude, point1.longitude),
    Point(point2.latitude, point2.longitude)
  ); 
}

int getPolylineIndexByLatLng(Polyline polyline, LatLng latlng){
  return PolyUtils.locationIndexOnEdgeOrPath(
    Point(latlng.latitude, latlng.longitude),
    [for (var point in polyline.points) Point(point.latitude, point.longitude)],
    false,
    false,
    20,
  );
}

bool isLatLngOnPath(LatLng latlng, Polyline polyline, double tolerance){
  return PolyUtils.isLocationOnPathTolerance(
    Point(latlng.latitude, latlng.longitude),
    [for (var point in polyline.points) Point(point.latitude, point.longitude)],
    false,
    tolerance,
  );
}