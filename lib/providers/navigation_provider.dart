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

  int? _currentSubPathIndex; // in a route with multiple waypoints, a sub path is the path in between waypoints
  int? get currentSubPathIndex => _currentSubPathIndex;
  set currentSubPathIndex(int? currentSubPathIndex){_currentSubPathIndex = currentSubPathIndex; notifyListeners();}


  int? _directionIndex;
  int? get directionIndex => _directionIndex;
  set directionIndex(int? directionIndex){_directionIndex = directionIndex; notifyListeners();}


  List<Polyline> _polylines = []; // composition of the whole route
  List<Polyline> get polylines => _polylines;
  set polylines(List<Polyline> polylines){_polylines = polylines; notifyListeners();}

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
    if (mapProvider!.computedRoute != null && mapProvider!.computedRoute!.options.length == 1){
      _currentSubPathIndex = 0;
      _directionIndex = 0;
      _lockOnCurrentPosition = true;
      log('STARTING NAVIGATION');
    }
  }

  void handleNavigationProgress(){
    log('currentSubPathIndex ${_currentSubPathIndex}/${_polylines.length - 1}');

    Polyline currentPolyline = _polylines[_currentSubPathIndex!];
    int polylinePointIndex = getPolylineIndexByLatLng(
      currentPolyline,
      LatLng(
        mapProvider!.currentPosition.latitude,
        mapProvider!.currentPosition.longitude
      ),
    );
    log('polyline point index ${polylinePointIndex}/${currentPolyline.points.length - 1}');

    for (final (i, direction) in mapProvider!.computedRoute!.options[0][_currentSubPathIndex!].directions.indexed){
      if(direction.coveredPolylinePointsIndexes.contains(polylinePointIndex)){
        _directionIndex = i;
      }
    }
    log('direction index $_directionIndex/${mapProvider!.computedRoute!.options[0][_currentSubPathIndex!].directions.length - 1}');


    if(polylinePointIndex == -1){
      log('Deviated from path!');
      
    } else if (polylinePointIndex >= currentPolyline.points.length - 1){
      if (_currentSubPathIndex! >= _polylines.length - 1){
        // no more polylines to travel
        cancelNavigation();
      } else {
        // finished subPath, go to next sub path
        _currentSubPathIndex = _polylines.length + 1;
        _directionIndex = 0;
      }
    } else{
      // Re-compute a new route from current position to the rest of waypoints
      // log('CURRENT INDEX: $_pathCurrentIndex/${mapProvider!.computedRoute!.paths[0].nodes.length}');
      // double distance = computeDistanceBetweenPoints(
      //   LatLng(
      //     mapProvider!.currentPosition.latitude,
      //     mapProvider!.currentPosition.longitude,
      //   ),
      //   LatLng(
      //     mapProvider!.computedRoute!.options[0][_currentSubPathIndex!].nodes[i].latitude,
      //     mapProvider!.computedRoute!.options[0][_currentSubPathIndex!].nodes[i].longitude,
      //   ),
      // );
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
    await mapProvider!.computeRoute();
    log('done computing');
    // notifyListeners();
  }
}