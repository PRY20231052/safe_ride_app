// ignore_for_file: avoid_init_to_null

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:safe_ride_app/models/location_model.dart';
import 'package:safe_ride_app/models/route_model.dart';

class NavigationProvider with ChangeNotifier{
  
  RouteModel? _route;
  int _pathCurrentIndex = 0;
  bool _isInsideNodeRadius = false;

  RouteModel? get route => _route;
  int get pathCurrentIndex => _pathCurrentIndex;
  bool get isInsideNodeRadius => _isInsideNodeRadius;

  set route(RouteModel? route){_route = route; notifyListeners();}
  set pathCurrentIndex(int pathCurrentIndex){_pathCurrentIndex = pathCurrentIndex; notifyListeners();}
  set isInsideNodeRadius(bool isInsideNodeRadius){_isInsideNodeRadius = isInsideNodeRadius; notifyListeners();}


  void startNavigation() {
    if (_route != null){
      // mode = Modes.navigation;
      _pathCurrentIndex = 0;
    }
  }

  // void handleNavigationProgress(){
  //   double nodeThresholdRadius = 5;
  //   bool onPath = isLocationOnPath(
  //     LocationModel(latitude: currentPosition.latitude, longitude: currentPosition.longitude),
  //     mapPolylines.first,
  //     10.0,
  //   );
  //   onPath ? log('On path :)') : log('Deviated from path!');
  //   if(!onPath){
  //     // Re-compute a new route from current position to the rest of waypoints

  //   } else {
  //     log('CURRENT INDEX: $navPathCurrentIndex/${route!.pathNodes.length}');
  //     for (var i = navPathCurrentIndex + 1; i < route!.pathNodes.length; i++){

  //       double distance = computeDistanceBetweenPoints(
  //         LatLng(currentPosition.latitude, currentPosition.longitude),
  //         LatLng(route!.pathNodes[i].latitude, route!.pathNodes[i].longitude)
  //       );
  //       i == 1 ? log('Distance to next node: $distance') : null;
  //       // if we go pass the node's threshold radius
  //       if (!isInsideNodeRadius && distance <= nodeThresholdRadius){
  //         isInsideNodeRadius = true;
  //         // we have landed into the node so we have to now go to the next step
  //         log('Arrived to node $i/${route!.pathNodes.length}  Distance to center of node: $distance');
  //         break;
  //       }
  //       // for the inmidiate next node, check if we are leaving the node radius to update the current node status
  //       if (i == navPathCurrentIndex+1 && isInsideNodeRadius && distance > nodeThresholdRadius){
  //         isInsideNodeRadius = false;
  //         navPathCurrentIndex = i;
  //         log('Leaving node $i Distance to center of node: $distance');
  //         break;
  //       }
  //     }
  //   }
  // }
  
  // void exitNavigation() {
  //   mode = Modes.waypointsSelection;
  //   route = null;
  //   clearDestination();
  //   updateDraggableScrollableSheetSizes();
  //   draggableScrollableController.animateTo(
  //     dssMinChildSize,
  //     duration: Duration(milliseconds : 100),
  //     curve: Curves.linearToEaseOut,
  //   );
  //   updateMapCameraPosition();
  //   log('EXITING NAVIGATION WITH THIS ROUTE!');
  // }


}