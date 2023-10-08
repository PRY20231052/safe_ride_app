// ignore_for_file: avoid_init_to_null, prefer_const_constructors, unnecessary_brace_in_string_interps

import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:safe_ride_app/models/location_model.dart';
import 'package:safe_ride_app/providers/map_provider.dart';
import '../services/safe_ride_api.dart';
import '../utils.dart';
import 'package:flutter_compass/flutter_compass.dart';

class NavigationProvider with ChangeNotifier{
  final _safeRideApi = SafeRideApi();

  MapProvider? mapProvider;

  NavigationProvider({
    this.mapProvider,
  });

  double _currentBearing = 0.0;
  double get currentBearing => _currentBearing;
  set currentBearing(double currentBearing){_currentBearing = currentBearing; notifyListeners();}


  int? _currentSubPathIndex; // in a route with multiple waypoints, a sub path is the path in between waypoints
  int? get currentSubPathIndex => _currentSubPathIndex;
  set currentSubPathIndex(int? currentSubPathIndex){_currentSubPathIndex = currentSubPathIndex; notifyListeners();}


  int? _directionIndex;
  int? get directionIndex => _directionIndex;
  set directionIndex(int? directionIndex){_directionIndex = directionIndex; notifyListeners();}


  List<Polyline> _polylines = []; // composition of the whole route
  List<Polyline> get polylines => _polylines;
  set polylines(List<Polyline> polylines){_polylines = polylines; notifyListeners();}

  bool _lockCameraOnCurrentPosition = false;
  bool get lockCameraOnCurrentPosition => _lockCameraOnCurrentPosition;
  set lockCameraOnCurrentPosition(bool lockOnCurrentPosition){_lockCameraOnCurrentPosition = lockOnCurrentPosition; notifyListeners();}
  
  late StreamSubscription<Position> _positionStream;
  StreamSubscription<Position> get positionStream => _positionStream;

  bool _isAnimating = false;
  bool get isAnimating => _isAnimating;
  set isAnimating(bool isAnimating){_isAnimating = isAnimating; notifyListeners();}


  Future<void> initialize() async {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      ),
    ).listen(
      (Position position) {
        mapProvider!.currentPosition = position;
        log('CURRENT POSITION UPDATED ${[mapProvider!.currentPosition.latitude, mapProvider!.currentPosition.longitude].toString()}');
        if (mapProvider!.mode == Modes.navigation){
          handleNavigationProgress();
        } else {
          if(mapProvider!.currentPositionAsOrigin){
            log('Setting current position as origin');
            mapProvider!.origin = LocationModel(
              coordinates: LatLng(
                mapProvider!.currentPosition.latitude,
                mapProvider!.currentPosition.longitude,
              ),
            );
          }
        }
        // if (_lockCameraOnCurrentPosition){
        //   log('BEARING: ${_currentBearing} _lockCameraOnCurrentPosition $_lockCameraOnCurrentPosition');
        //   updateMapCameraPosition(
        //     target: LatLng(
        //       mapProvider!.currentPosition.latitude,
        //       mapProvider!.currentPosition.longitude,
        //     ),
        //     bearing: _currentBearing,
        //     animate: true,
        //   );
        // }
      }
    );

    final bearingStream = FlutterCompass.events!;
    final subscription = bearingStream.listen(
      (data) {
        _currentBearing = data.heading!;
        if (_lockCameraOnCurrentPosition){
          log('BEARING: ${_currentBearing} _lockCameraOnCurrentPosition $_lockCameraOnCurrentPosition');
          updateMapCameraPosition(
            target: LatLng(
              mapProvider!.currentPosition.latitude,
              mapProvider!.currentPosition.longitude,
            ),
            bearing: _currentBearing,
          );
        }
      }
    );
  }

  Future<void> updateMapCameraPosition({LatLng? target, double? bearing, bool animate = true}) async {
    // If target not provided means it will center the camera to the current position
    // ??= means if target is null then assign...
    var newCameraPosition = CameraUpdate.newCameraPosition(
      CameraPosition(
        target: target ??= LatLng(mapProvider!.currentPosition.latitude, mapProvider!.currentPosition.longitude),
        zoom: mapProvider!.mode == Modes.navigation ? 18 : 15,
        tilt: mapProvider!.mode == Modes.navigation ? 50 : 0.0,
        bearing: mapProvider!.mode == Modes.navigation && _lockCameraOnCurrentPosition ? bearing ?? 0 : 0,
      ),
    );

    // Decides if show the animation or just move the camera on an instant
    if (animate && _isAnimating == false){
      _isAnimating = true;
      await mapProvider!.googleMapsController.animateCamera(newCameraPosition);
    } else if (animate == false) {
      await mapProvider!.googleMapsController.moveCamera(newCameraPosition);
    }
  }

  Future<void> startNavigation() async {
    // we require that paths only have one element, the selected one.
    if (mapProvider!.route != null && mapProvider!.route!.pathOptions.length == 1){
      log('STARTING NAVIGATION...');
      _currentSubPathIndex = 0;
      _directionIndex = 0;
      updateMapCameraPosition(); //move camera to current position
      _lockCameraOnCurrentPosition = true;
      log('NAVIGATION SUCCESSFULLY STARTED!');
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

    for (final (i, direction) in mapProvider!.route!.pathOptions[0][_currentSubPathIndex!].directions.indexed){
      if(direction.coveredPolylinePointsIndexes.contains(polylinePointIndex)){
        _directionIndex = i;
      }
    }
    log('direction index $_directionIndex/${mapProvider!.route!.pathOptions[0][_currentSubPathIndex!].directions.length - 1}');


    if(polylinePointIndex == -1){
      log('Deviated from path!');
    
    // If we have reached the end of the current sub Path
    } else if (polylinePointIndex >= currentPolyline.points.length - 2){
      if (_currentSubPathIndex! >= _polylines.length - 1){
        // no more polylines to travel
        cancelNavigation();
      } else {
        // finished subPath, go to next sub path
        _currentSubPathIndex = _currentSubPathIndex! + 1;
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
    mapProvider!.route = null;
    _lockCameraOnCurrentPosition = false;
    mapProvider!.clearDestination();
    notifyListeners();
  }

  Future<void> computeAlternativeRouteFromCurrentPosition() async {
    _lockCameraOnCurrentPosition = false;
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