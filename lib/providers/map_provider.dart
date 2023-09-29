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

  Modes _mode = Modes.waypointsSelection;

  LocationModel? _origin;
  List<LocationModel>? _waypoints;
  LocationModel? _destination;
  List<LocationModel> _searchResults = [];
  RouteModel? _computedRoute;
  bool _currentPositionAsOrigin = true;
  bool _isComputingRoute = false;
  bool _isLoading = true;
  // READ ONLY ATTRIBUTES
  late Position _currentPosition;


  /////////////////////GETTERS////////////////////////////////////
  Modes get mode => _mode;
  LocationModel? get origin => _origin;
  List<LocationModel>? get waypoints => _waypoints;
  LocationModel? get destination => _destination;
  List<LocationModel> get searchResults => _searchResults;
  RouteModel? get computedRoute => _computedRoute;
  bool get currentPositionAsOrigin => _currentPositionAsOrigin;
  bool get isComputingRoute => _isComputingRoute;
  bool get isLoading => _isLoading;
  Position get currentPosition => _currentPosition;

  
  set mode(Modes mode){_mode = mode; notifyListeners();}
  set origin(LocationModel? origin){_origin = origin; notifyListeners(); }
  set waypoints(List<LocationModel>? waypoints) {_waypoints = waypoints; notifyListeners();}
  set destination(LocationModel? destination){_destination = destination; notifyListeners(); }
  set searchResults(List<LocationModel> searchResults){_searchResults = searchResults; notifyListeners(); }
  set computedRoute(RouteModel? computedRoute){_computedRoute = computedRoute; notifyListeners(); }
  set currentPositionAsOrigin(bool currentPositionAsOrigin){_currentPositionAsOrigin = currentPositionAsOrigin; notifyListeners(); }
  set isComputingRoute(bool isComputingRoute){_isComputingRoute = isComputingRoute; notifyListeners(); }
  set isLoading(bool isLoading){_isLoading = isLoading; notifyListeners();}
  set currentPosition(Position currentPosition){_currentPosition = currentPosition; notifyListeners();}
  

  Future<void> initialize() async {
    await verifyLocationPermissions();
    await dotenv.load();
    _placesApi = GoogleMapsPlaces(apiKey: dotenv.env['GOOGLE_MAPS_API_KEY']);
    _geocodingApi = GoogleMapsGeocoding(apiKey: dotenv.env['GOOGLE_MAPS_API_KEY']);
    _geolocationApi = GoogleMapsGeolocation(apiKey: dotenv.env['GOOGLE_MAPS_API_KEY']);

    _currentPosition = await Geolocator.getCurrentPosition();
    _origin = LocationModel(coordinates: LatLng(_currentPosition.latitude, _currentPosition.longitude));
    _isLoading = false;
    notifyListeners();
  }

  Future<LocationModel?> fetchLocationByLatLng(double latitude, double longitude) async {
    var response = await _geocodingApi.searchByLocation(
      Location(lat: latitude, lng: longitude)
    );
    if (response.isOkay){
      // log(response.results.first.placeId);
      return LocationModel(
        coordinates: LatLng(latitude, longitude),
        address: response.results.first.formattedAddress,
      );
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
    _computedRoute = await _safeRideApi.requestRoute(
      _origin!.coordinates,
      _destination!.coordinates,
    );
    _mode = Modes.routeSelection;
    _isComputingRoute = false;
    notifyListeners();
  }

  Future<void> computeAlternativeRouteFromCurrentPosition() async {
    _isComputingRoute = true;
    notifyListeners();
    _computedRoute = await _safeRideApi.requestRoute(
      LatLng(_currentPosition.latitude, _currentPosition.longitude),
      _destination!.coordinates,
    );
    _isComputingRoute = false;
    // _mode = Modes.routeSelection;
    // log('notifying');
    // notifyListeners();
  }

  clearDestination(){
    _computedRoute = null;
    _destination = null;
    _waypoints = [];
    _searchResults = [];
    notifyListeners();
  }
}