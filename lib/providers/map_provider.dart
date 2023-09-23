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
import 'package:safe_ride_app/utils.dart';
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

  // CONTROLLERS
  late GoogleMapController _googleMapsController;
  TextEditingController _originInputController = TextEditingController();
  TextEditingController _destinationInputController = TextEditingController();
  DraggableScrollableController _draggableScrollableController = DraggableScrollableController();

  Modes _mode = Modes.waypointsSelection;

  LocationModel? _origin;
  List<LocationModel>? _waypoints;
  LocationModel? _destination;
  RouteModel? _route;
  List<LocationModel> _searchResults = [];
  List<RouteModel> _routeOptions = [];
  late Position _currentPosition;
  late StreamSubscription<Position> _positionStream;
  bool _currentPositionAsOrigin = true;
  bool _isComputingRoute = false;
  bool _isLoading = true;

  ////////////////////////////////////////////////////////////////////

  GoogleMapController get googleMapsController => _googleMapsController;
  TextEditingController get originInputController => _originInputController;
  TextEditingController get destinationInputController => _destinationInputController;
  DraggableScrollableController get draggableScrollableController => _draggableScrollableController;
  Modes get mode => _mode;
  LocationModel? get origin => _origin;
  List<LocationModel>? get waypoints => _waypoints;
  LocationModel? get destination => _destination;
  RouteModel? get route => _route;
  List<LocationModel> get searchResults => _searchResults;
  List<RouteModel> get routeOptions => _routeOptions;
  Position get currentPosition => _currentPosition;
  StreamSubscription<Position> get positionStream => _positionStream;
  bool get currentPositionAsOrigin => _currentPositionAsOrigin;
  bool get isComputingRoute => _isComputingRoute;
  bool get isLoading => _isLoading;
  
  set googleMapsController(GoogleMapController googleMapsController) {_googleMapsController=googleMapsController; notifyListeners();}
  set mode(Modes mode){_mode = mode; notifyListeners();}
  set origin(LocationModel? origin){_origin = origin; notifyListeners(); }
  set waypoints(List<LocationModel>? waypoints) {_waypoints = waypoints; notifyListeners();}
  set destination(LocationModel? destination){_destination = destination; notifyListeners(); }
  set route(RouteModel? route){_route = route; notifyListeners();}
  set searchResults(List<LocationModel> searchResults){_searchResults = searchResults; notifyListeners(); }
  set routeOptions(List<RouteModel> routeOptions){_routeOptions = routeOptions; notifyListeners(); }
  set currentPositionAsOrigin(bool currentPositionAsOrigin){_currentPositionAsOrigin = currentPositionAsOrigin; notifyListeners(); }
  set isComputingRoute(bool isComputingRoute){_isComputingRoute = isComputingRoute; notifyListeners(); }
  set isLoading(bool isLoading){_isLoading = isLoading; notifyListeners();}
  

  Future<void> initialize() async {
    log('Initializing...');
    await verifyLocationPermissions();
    await dotenv.load();
    _placesApi = GoogleMapsPlaces(apiKey: dotenv.env['GOOGLE_MAPS_API_KEY']);
    _geocodingApi = GoogleMapsGeocoding(apiKey: dotenv.env['GOOGLE_MAPS_API_KEY']);
    _geolocationApi = GoogleMapsGeolocation(apiKey: dotenv.env['GOOGLE_MAPS_API_KEY']);

    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      ),
    ).listen((Position position) {
      _currentPosition = position;
      log('CURRENT POSITION UPDATED ${[_currentPosition.latitude, _currentPosition.longitude].toString()}');
      if (_mode == Modes.navigation){
        // handleNavigationProgress();
      } else {
        if(_currentPositionAsOrigin){
          // context.read()<RequestRouteProvider>().
          
          // var a = Provider.of<RequestRouteProvider>(context, listen: false).currentPositionAsOrigin;
          log('Setting new origin');
          _origin = LocationModel(
            latitude: _currentPosition.latitude,
            longitude: _currentPosition.longitude,
          );
        }
      }
      // db update
      //locationUpdate();
    });

    _currentPosition = await Geolocator.getCurrentPosition();
    _origin = LocationModel(latitude: _currentPosition.latitude, longitude: _currentPosition.longitude);
    _isLoading = false;
    
    updateTextInputs();
    
    log('Initialized!');
    notifyListeners();
  }

  Future<LocationModel?> fetchLocationByLatLng(double latitude, double longitude) async {
    var response = await _geocodingApi.searchByLocation(
      Location(lat: latitude, lng: longitude)
    );
    if (response.isOkay){
      // log(response.results.first.placeId);
      return LocationModel(
        latitude: latitude,
        longitude: longitude,
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
      location: Location(lat: _origin!.latitude, lng: _origin!.longitude),
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
            latitude: details.result.geometry!.location.lat,
            longitude: details.result.geometry!.location.lng,
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

  Future<void> computeRoutes() async {
    if (_origin != null && _destination != null) {
      _isComputingRoute = true;
      notifyListeners();
      _routeOptions = await _safeRideApi.requestRoutes(
        _origin!.toLatLng(),
        _destination!.toLatLng(),
      ) ?? [];
      _mode = Modes.routeSelection;
      updateTextInputs();
      _isComputingRoute = false;
      notifyListeners();
    }
    else {
      // Fluttertoast.showToast(
      //   msg: "Defina un punto de destino",
      //   toastLength: Toast.LENGTH_LONG
      // );
    }
  }

  clearDestination(){
    _routeOptions = [];
    _destination = null;
    _waypoints = [];
    _searchResults = [];
    notifyListeners();
  }

  void updateMapCameraPosition({LatLng? target}){
    // ??= means in if target is null then assign...
    target ??= _mode == Modes.navigation ? _route!.origin.toLatLng() : _origin!.toLatLng();
    _googleMapsController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          zoom: _mode == Modes.navigation ? 18 : 15,
          tilt: _mode == Modes.navigation ? 50 : 0.0,
        ),
      ),
    );
  }


  updateTextInputs(){
    var currentLatLng = LatLng(_currentPosition.latitude, _currentPosition.longitude);
    _originInputController.text = _currentPositionAsOrigin ? "Mi ubicación actual" : _origin?.address ??  "";

    if (_destination != null && _destination!.toLatLng() == currentLatLng){
      _destinationInputController.text = "Mi ubicación actual";
    }
    else {
      _destinationInputController.text = _destination?.address ??  "";
    }
    notifyListeners();
  }
  
}