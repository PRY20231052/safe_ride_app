// ignore_for_file: avoid_init_to_null, prefer_const_constructors, unnecessary_brace_in_string_interps

import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:safe_ride_app/models/location_model.dart';
import 'package:safe_ride_app/models/route_model.dart';
import 'package:safe_ride_app/providers/map_provider.dart';
import '../services/safe_ride_api.dart';
import '../utils.dart';

class NavigationProvider with ChangeNotifier{
  final _safeRideApi = SafeRideApi();

  MapProvider? mapProvider;

  NavigationProvider({
    this.mapProvider,
  });
  
  RouteModel? _route;
  int _pathCurrentIndex = 0;
  bool _isInsideNodeRadius = false;
  Polyline? _polyline;
  late StreamSubscription<Position> _positionStream;

  RouteModel? get route => _route;
  int get pathCurrentIndex => _pathCurrentIndex;
  bool get isInsideNodeRadius => _isInsideNodeRadius;
  Polyline? get polyline => _polyline;
  StreamSubscription<Position> get positionStream => _positionStream;

  set route(RouteModel? route){_route = route; notifyListeners();}
  set pathCurrentIndex(int pathCurrentIndex){_pathCurrentIndex = pathCurrentIndex; notifyListeners();}
  set isInsideNodeRadius(bool isInsideNodeRadius){_isInsideNodeRadius = isInsideNodeRadius; notifyListeners();}
  set polyline(Polyline? polyline){_polyline = polyline; notifyListeners();}

  Future<void> initialize() async {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      ),
    ).listen((Position position) {
      mapProvider!.currentPosition = position;
      log('CURRENT POSITION UPDATED ${[mapProvider!.currentPosition.latitude, mapProvider!.currentPosition.longitude].toString()}');
      if (mapProvider!.mode == Modes.navigation){
        handleNavigationProgress();
      } else {
        if(mapProvider!.currentPositionAsOrigin){
          log('Setting new origin');
          mapProvider!.origin = LocationModel(
            coordinates: LatLng(
              mapProvider!.currentPosition.latitude,
              mapProvider!.currentPosition.longitude,
            ),
          );
        }
      }
    });
  }


  void startNavigation() {
    if (_route != null){
      // mode = Modes.navigation;
      _pathCurrentIndex = 0;
    }
  }

  void handleNavigationProgress(){
    //////////////////////////////////////////
    log('path nodes len ${_route!.paths[0].nodes.length}');
    log('path edges len ${_route!.paths[0].edges.length}');
    
    var polylineIndex = getPolylineIndexByLatLng(
      _polyline!,
      LatLng(mapProvider!.currentPosition.latitude, mapProvider!.currentPosition.longitude),
    );
    log('polyline index ${polylineIndex}/${_polyline!.points.length}');
    //////////////////////////////////////////

    double nodeThresholdRadius = 5;

    if(polylineIndex != -1){

      log('CURRENT INDEX: $_pathCurrentIndex/${_route!.paths[0].nodes.length}');
      for (var i = _pathCurrentIndex + 1; i < _route!.paths[0].nodes.length; i++){
        double distance = computeDistanceBetweenPoints(
          LatLng(mapProvider!.currentPosition.latitude, mapProvider!.currentPosition.longitude),
          LatLng(_route!.paths[0].nodes[i].latitude, _route!.paths[0].nodes[i].longitude)
        );
        i == 1 ? log('Distance to next node: $distance') : null;
        // if we go pass the node's threshold radius
        if (!_isInsideNodeRadius && distance <= nodeThresholdRadius){
          _isInsideNodeRadius = true;
          // we have landed into the node so we have to now go to the next step
          log('Arrived to node $i/${_route!.paths[0].nodes.length}  Distance to center of node: $distance');
          break;
        }
        // for the inmidiate next node, check if we are leaving the node radius to update the current node status
        if (i == _pathCurrentIndex+1 && _isInsideNodeRadius && distance > nodeThresholdRadius){
          _isInsideNodeRadius = false;
          _pathCurrentIndex = i;
          log('Leaving node $i Distance to center of node: $distance');
          break;
        }
      }
    } else {
      log('Deviated from path!');
      // Re-compute a new route from current position to the rest of waypoints
      
    }
  }
  
  void cancelNavigation() {
    mapProvider!.mode = Modes.waypointsSelection;
    _route = null;
    mapProvider!.clearDestination();
  }

  void computeAlternativeRoutes() {
    log(mapProvider!.mode.toString());
    // for (var edge in route!.pathEdges){
    //   log(edge.attributes.toString());
    // }
  }
}