// ignore_for_file: prefer_final_fields, prefer_const_constructors

import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_google_maps_webservices/geocoding.dart';
import 'package:flutter_google_maps_webservices/geolocation.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/location_model.dart';
import '../models/route_model.dart';
import '../services/safe_ride_api.dart';

enum Modes {
  waypointsSelection,
  routeSelection,
  navigation,
}

class MapProvider with ChangeNotifier {
  // API SERVICES
  final _safeRideApi = SafeRideApi();
  late GoogleMapsPlaces _placesApi;
  late GoogleMapsGeolocation _geolocationApi;
  late GoogleMapsGeocoding _geocodingApi;

  late GoogleMapController _googleMapsController;
  GoogleMapController get googleMapsController => _googleMapsController;
  set googleMapsController(GoogleMapController googleMapsController){_googleMapsController = googleMapsController; notifyListeners();}

  Modes _mode = Modes.waypointsSelection;
  Modes get mode => _mode;
  set mode(Modes mode){_mode = mode; notifyListeners();}

  LocationModel? _origin;
  LocationModel? get origin => _origin;
  set origin(LocationModel? origin){_origin = origin; notifyListeners(); }

  List<LocationModel> _waypoints = [];
  List<LocationModel> get waypoints => _waypoints;
  set waypoints(List<LocationModel> waypoints) {_waypoints = waypoints; notifyListeners();}

  List<LocationModel> _searchResults = [];
  List<LocationModel> get searchResults => _searchResults;
  set searchResults(List<LocationModel> searchResults){_searchResults = searchResults; notifyListeners(); }

  RouteModel? _route;
  RouteModel? get route => _route;
  set route(RouteModel? route){_route = route; notifyListeners(); }

  int _selectedRouteOptionIndex = 0;
  int get selectedRouteOptionIndex => _selectedRouteOptionIndex;
  set selectedRouteOptionIndex(int selectedRouteOptionIndex){_selectedRouteOptionIndex = selectedRouteOptionIndex; notifyListeners();}

  bool _currentPositionAsOrigin = true;
  bool get currentPositionAsOrigin => _currentPositionAsOrigin;
  set currentPositionAsOrigin(bool currentPositionAsOrigin){_currentPositionAsOrigin = currentPositionAsOrigin; notifyListeners(); }

  bool _isComputingRoute = false;
  bool get isComputingRoute => _isComputingRoute;
  set isComputingRoute(bool isComputingRoute){_isComputingRoute = isComputingRoute; notifyListeners(); }

  bool _isLoading = true;
  bool get isLoading => _isLoading;
  set isLoading(bool isLoading){_isLoading = isLoading; notifyListeners();}

  late Position _currentPosition;
  Position get currentPosition => _currentPosition;
  set currentPosition(Position currentPosition){_currentPosition = currentPosition; notifyListeners();}
  
  // LAYOUT AND DESIGN RELATED VARIABLES
  double _dssMinChildSize = 0.16;
  double get dssMinChildSize => _dssMinChildSize;
  set dssMinChildSize(double dssMinChildSize){_dssMinChildSize = dssMinChildSize; notifyListeners();}

  double _dssMainChildSize = 0.16;
  double get dssMainChildSize => _dssMainChildSize;
  set dssMainChildSize(double dssMainChildSize){_dssMainChildSize = dssMainChildSize; notifyListeners();}

  List<double> _dssSnapSizes = [0.16];
  List<double> get dssSnapSizes => _dssSnapSizes;
  set dssSnapSizes(List<double> dssSnapSizes){_dssSnapSizes = dssSnapSizes; notifyListeners();}

  DraggableScrollableController _draggableSheetController = DraggableScrollableController();
  DraggableScrollableController get draggableSheetController => _draggableSheetController;
  set draggableSheetController(DraggableScrollableController draggableSheetController){_draggableSheetController = draggableSheetController; notifyListeners();}

  Future<void> initialize() async {
    await verifyLocationPermissions();
    await dotenv.load();
    _placesApi = GoogleMapsPlaces(apiKey: dotenv.env['GOOGLE_MAPS_API_KEY']);
    _geocodingApi = GoogleMapsGeocoding(apiKey: dotenv.env['GOOGLE_MAPS_API_KEY']);
    _geolocationApi = GoogleMapsGeolocation(apiKey: dotenv.env['GOOGLE_MAPS_API_KEY']);

    _currentPosition = await Geolocator.getCurrentPosition();
    _origin = LocationModel(coordinates: LatLng(_currentPosition.latitude, _currentPosition.longitude));
    notifyListeners();
  }

  Future<LocationModel?> fetchLocationByLatLng(LatLng latLng) async {
    var response = await _geocodingApi.searchByLocation(
      Location(lat: latLng.latitude, lng: latLng.longitude)
    );
    if (response.isOkay){
      var detailsResponse = await _placesApi.getDetailsByPlaceId(response.results.first.placeId);
      if (detailsResponse.isOkay){
        log('DETAILS for first: ${detailsResponse.result.name}');
        return LocationModel(
          coordinates: latLng,
          name: detailsResponse.result.name,
          address: response.results.first.formattedAddress,
        );
      }
    }
    return null;
  }

  Future<List<LocationModel>> searchPlacesByText(String textInput) async {
    var sessionToken = '0';
    List<LocationModel> placesResults = [];

    var response = await _placesApi.autocomplete(
      textInput,
      sessionToken: sessionToken,
      location: Location(lat: _origin!.coordinates.latitude, lng: _origin!.coordinates.longitude),
      radius: 3000, // in meters
    );

    if (response.isOkay) {
      // list autocomplete prediction
      for (var prediction in response.predictions) {
        var details = await _placesApi.getDetailsByPlaceId(
          prediction.placeId!,
          sessionToken: sessionToken,
        );
        //if (prediction.placeId == null) return;
        placesResults.add(
          LocationModel(
            coordinates: LatLng(
              details.result.geometry!.location.lat,
              details.result.geometry!.location.lng,
            ),
            name: prediction.description,
            address: details.result.formattedAddress,
          ),
        );
      }
    } else {
      log(response.errorMessage ?? 'Not found');
    }
    // for (var p in placesResults) {
    //   log(p.name!);
    //   log(p.address!);
    // }
    //placesApi.dispose();
    return placesResults;
  }

  Future<void> verifyLocationPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permission denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permission is denied forever, we cannot request permission');
    }
  }

  Future<void> computeRoute() async {
    _isComputingRoute = true;
    notifyListeners();
    _route = await _safeRideApi.requestRoute(
      _origin!.coordinates,
      [for(var waypoint in _waypoints) waypoint.coordinates],
    );
    _isComputingRoute = false;
    notifyListeners();
  }

  Future<void> computeAlternativeRouteFromCurrentPosition() async {
    _isComputingRoute = true;
    notifyListeners();
    _route = await _safeRideApi.requestRoute(
      LatLng(_currentPosition.latitude, _currentPosition.longitude),
      [for(var waypoint in _waypoints) waypoint.coordinates],
    );
    _isComputingRoute = false;
    // _mode = Modes.routeSelection;
    // log('notifying');
    // notifyListeners();
  }

  clearRoute(){
    _route = null;
    _waypoints = [];
    _searchResults = [];
    notifyListeners();
  }

  void updateDraggableScrollableSheetSizes({bool forceAnimationToMainSize = false}){
    // var oldMin = _dssMinChildSize;
    var oldMain = _dssMainChildSize;
    switch(_mode) {
      case Modes.waypointsSelection:      // Size to incldue the Compute Routes button
        _dssMinChildSize = _waypoints.length > 1 ? 0.24 : 0.15; 
        _dssMainChildSize = _dssMinChildSize;
        _dssSnapSizes = [];
        break; // The switch statement must be told to exit, or it will execute every case.
      case Modes.routeSelection:
        _dssMinChildSize = 0.15;
        _dssMainChildSize = 0.43;
        _dssSnapSizes = [_dssMainChildSize];
        break;
      case Modes.navigation:
        _dssMinChildSize = 0.15;
        _dssMainChildSize = _dssMinChildSize;
        _dssSnapSizes = [];
        break;
    }
    // MIGH CAUSE ISSUES
    if (forceAnimationToMainSize || _draggableSheetController.isAttached && oldMain != _dssMainChildSize){
      _draggableSheetController.animateTo(
        _dssMainChildSize,
        duration: Duration(milliseconds : 100),
        curve: Curves.linearToEaseOut,
      );
    }
  }
}