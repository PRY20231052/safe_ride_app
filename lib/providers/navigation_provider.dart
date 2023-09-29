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
  
  int? _pathCurrentIndex;
  int? get pathCurrentIndex => _pathCurrentIndex;
  set pathCurrentIndex(int? pathCurrentIndex){_pathCurrentIndex = pathCurrentIndex; notifyListeners();}

  int? _directionIndex;
  int? get directionIndex => _directionIndex;
  set directionIndex(int? directionIndex){_directionIndex = directionIndex; notifyListeners();}


  bool _isInsideNodeRadius = false;
  bool get isInsideNodeRadius => _isInsideNodeRadius;
  set isInsideNodeRadius(bool isInsideNodeRadius){_isInsideNodeRadius = isInsideNodeRadius; notifyListeners();}
  
  Polyline? _polyline;
  Polyline? get polyline => _polyline;
  set polyline(Polyline? polyline){_polyline = polyline; notifyListeners();}

  bool _lockOnCurrentPosition = false;
  bool get lockOnCurrentPosition => _lockOnCurrentPosition;
  set lockOnCurrentPosition(bool lockOnCurrentPosition){_lockOnCurrentPosition = lockOnCurrentPosition; notifyListeners();}
  
  late StreamSubscription<Position> _positionStream;
  StreamSubscription<Position> get positionStream => _positionStream;


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
    // we require that paths only have one element, the selected one.
    if (mapProvider!.computedRoute != null && mapProvider!.computedRoute!.paths.length == 1){
      _pathCurrentIndex = 0;
      _directionIndex = 0;
      _lockOnCurrentPosition = true;
      log('STARTING NAVIGATION');
    }
  }

  void handleNavigationProgress(){
    int polylineIndex = getPolylineIndexByLatLng(
      _polyline!,
      LatLng(
        mapProvider!.currentPosition.latitude,
        mapProvider!.currentPosition.longitude
      ),
    );
    log('polyline index ${polylineIndex}/${_polyline!.points.length - 1}');

    for (final (i, direction) in mapProvider!.computedRoute!.paths[0].directions.indexed){
      if(direction.coveredPolylinePointsIndexes.contains(polylineIndex)){
        directionIndex = i;
      }
    }
    log('direction index $directionIndex/${mapProvider!.computedRoute!.paths[0].directions.length - 1}');


    if(polylineIndex != -1){
      // log('CURRENT INDEX: $_pathCurrentIndex/${mapProvider!.computedRoute!.paths[0].nodes.length}');
      for (var i = _pathCurrentIndex! + 1; i < mapProvider!.computedRoute!.paths[0].nodes.length; i++){
        double distance = computeDistanceBetweenPoints(
          LatLng(mapProvider!.currentPosition.latitude, mapProvider!.currentPosition.longitude),
          LatLng(mapProvider!.computedRoute!.paths[0].nodes[i].latitude, mapProvider!.computedRoute!.paths[0].nodes[i].longitude)
        );
      }
    } else {
      log('Deviated from path!');
      // Re-compute a new route from current position to the rest of waypoints
    }
  }
  
  void cancelNavigation() {
    mapProvider!.mode = Modes.waypointsSelection;
    mapProvider!.computedRoute = null;
    _lockOnCurrentPosition = false;
    mapProvider!.clearDestination();
    notifyListeners();
  }

  Future<void> computeAlternativeRouteFromCurrentPosition() async {
    _lockOnCurrentPosition = false;
    // mapProvider!.mode = Modes.routeSelection;
    // LocationModel ori = mapProvider!.origin!;
    // LocationModel des = mapProvider!.destination!;
    // cancelNavigation();
    // mapProvider!.origin = ori;
    // mapProvider!.destination = des;
    log('computing');
    var a = await mapProvider!.computeRoute();
    log('done computing');
    // notifyListeners();
  }
}