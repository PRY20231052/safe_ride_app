// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, avoid_init_to_null, sized_box_for_whitespace

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_google_maps_webservices/geocoding.dart';
import 'package:flutter_google_maps_webservices/geolocation.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:safe_ride_app/models/location_model.dart';
import 'package:safe_ride_app/models/route_model.dart';
import 'package:safe_ride_app/my_widgets/my_loading_screen.dart';
import '../services/safe_ride_api.dart';
import '../styles.dart';
import 'dart:developer';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {

  final safeRideApi = SafeRideApi();
  late GoogleMapsPlaces placesApi;
  late GoogleMapsGeolocation geolocationApi;
  late GoogleMapsGeocoding geocodingApi;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late CameraPosition currentCameraPosition;

  Future<RouteModel>? futureRoute;
  RouteModel? route = null;
  Position? currentPosition = null;
  LocationModel? origin = null;
  List<LocationModel>? waypoints = [];
  LocationModel? destination = null;
  List<LocationModel>? destinationSearchResults;
  
  late Marker destinationMarker;
  Set<Marker> mapMarkers = {};
  Set<Polyline> mapPolylines = {};

  // Flags
  bool isComputingRoute = false;
  bool isLoading = true;
  bool modifyOrigin = false;
  bool modifyDestination = true;

  // Controllers
  late GoogleMapController googleMapsController;
  TextEditingController originInputController = TextEditingController();
  TextEditingController destinationInputController = TextEditingController();
  DraggableScrollableController draggableScrollableController = DraggableScrollableController(); 

  // DraggableScrollableSheet parameters
  final double dssMinChildSize = 0.1;
  final double dssLocationPickerComponentSize = 0.38;
  final double dssRouteSelectionComponentSize = 0.55;
  List<double> dssSnapSizes = [0.38];
  
  
  @override
  initState() {
    log('Initializing...');
    asyncInit();
    super.initState();
    log('Initialized!');
  }

  asyncInit() async {
    await dotenv.load();
    placesApi = GoogleMapsPlaces(apiKey: dotenv.env['GOOGLE_MAPS_API_KEY']);
    geocodingApi = GoogleMapsGeocoding(apiKey: dotenv.env['GOOGLE_MAPS_API_KEY']);
    geolocationApi = GoogleMapsGeolocation(apiKey: dotenv.env['GOOGLE_MAPS_API_KEY']);

    await setCurrentPositionAsOrigin();

    currentCameraPosition = CameraPosition(
      target: LatLng(origin!.latitude!, origin!.longitude!),
      zoom: 15,
    );
    isLoading = false;
    updateTextInputs();
    setState(() {});
  }

  @override
  void setState(VoidCallback fn) {
    updateMarkers();
    super.setState(fn);
  }

  @override
  void dispose() {
    googleMapsController.dispose();
    super.dispose();
  }


  Future<void> requestRoute(LatLng origin, LatLng destination) async {
    route = await safeRideApi.requestRoute(origin, destination);
    log(route!.getLatLngPoints().toString());
  }


  Future<Position> getCurrentPosition() async {
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
    return await Geolocator.getCurrentPosition();
  }


  Future<void> setCurrentPositionAsOrigin() async {
    currentPosition = await getCurrentPosition();
    origin = LocationModel(latitude: currentPosition!.latitude, longitude: currentPosition!.longitude);
  }


  Future<LocationModel?> fetchLocationByLatLng(double latitude, double longitude) async {
    var response = await geocodingApi.searchByLocation(
      Location(lat: latitude, lng: longitude)
    );
    log(response.status);
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

  Future<void> onMarkerTapped() async {
    showLocationDialog(destination!);
  }


  Future<List<LocationModel>?> searchPlacesByText(String textInput) async {
    var sessionToken = '0';
    List<LocationModel> placesResults = [];

    var response = await placesApi.autocomplete(
      textInput,
      sessionToken: sessionToken,
      location: Location(lat: origin!.latitude!, lng: origin!.longitude!),
      radius: 5000, // in meters
    );

    if (response.isOkay) {
      // list autocomplete prediction
      for (var prediction in response.predictions) {
        var details = await placesApi.getDetailsByPlaceId(
          prediction.placeId!,
          sessionToken: sessionToken,
        );
        //if (prediction.placeId == null) return;
        placesResults.add(
          LocationModel(
            latitude: details.result.geometry?.location.lat,
            longitude: details.result.geometry?.location.lng,
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


  void searchDestination(text) async {
    if (text.length > 2){
      destinationSearchResults = await searchPlacesByText(text);
    }
    else{
      destinationSearchResults = [];
    }
    setState(() {});
  }


  Future<void> computeRoutes() async {
    if (origin != null && destination != null) {
      setState(() {isComputingRoute = true;});
      route = await safeRideApi.requestRoute(
        origin!.toLatLng()!,
        destination!.toLatLng()!,
      );
      mapPolylines = {
        Polyline(
          polylineId: PolylineId('route_0'),
          color: Colors.blue,
          width: 5,
          points: route!.getLatLngPoints(),
          jointType: JointType.round,
        ),
      };
      dssSnapSizes = [dssRouteSelectionComponentSize];
      draggableScrollableController.animateTo(
        dssRouteSelectionComponentSize,
        duration: Duration(milliseconds : 100),
        curve: Curves.linearToEaseOut,
      );
      updateTextInputs();
      setState(() {isComputingRoute = false;});
    }
    else {
      Fluttertoast.showToast(
        msg: "Defina un punto de destino",
        toastLength: Toast.LENGTH_LONG
      );
    }
  }

  Future<void> dropMarker(position) async {
    route = null;
    mapPolylines = {};
    if (modifyOrigin) {
      origin = LocationModel(latitude: position.latitude, longitude: position.longitude);
    } else if (modifyDestination) {
      destination = await fetchLocationByLatLng(position.latitude, position.longitude);
    } else {
      modifyDestination = false;
      modifyOrigin = false;
    }
    currentCameraPosition = CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: currentCameraPosition.zoom,
    );
    googleMapsController.animateCamera(
      CameraUpdate.newCameraPosition(currentCameraPosition),
    );
    showLocationDialog(
      LocationModel(
        latitude: destination!.latitude,
        longitude: destination!.longitude,
        address: destination!.address, 
      )
    );
    updateTextInputs();
    setState(() {});
  }

  clearDestination(){
    route = null;
    destination = null;
    waypoints = [];
    destinationSearchResults = null;
  }


  updateTextInputs(){
    var currentLatLng = LatLng(currentPosition!.latitude, currentPosition!.longitude);
    if (origin!.toLatLng() == currentLatLng){
      originInputController.text = "Mi ubicación actual";
    }
    else {
      originInputController.text = origin?.address ??  "";
    }
    if (destination != null && destination!.toLatLng() == currentLatLng){
      destinationInputController.text = "Mi ubicación actual";
    }
    else {
      destinationInputController.text = destination?.address ??  "";
    }
  }
  updateMarkers(){
    mapMarkers = {};
    if(destination != null){
      destinationMarker = Marker(
        markerId: MarkerId('destination'),
        position: destination!.toLatLng()!,
        icon: BitmapDescriptor.defaultMarker,
        onTap: onMarkerTapped,
      );
      mapMarkers.add(destinationMarker);
    }
  }
  allowOriginSelection() {
    modifyDestination = false;
    modifyOrigin = true;
  }
  allowDestinationSelection() {
    modifyDestination = true;
    modifyOrigin = false;
  }

  @override
  Widget build(BuildContext context) {
    return isLoading ? MyLoadingScreen() : Scaffold(
      backgroundColor: MyColors.white,
      key: _scaffoldKey,
      body: SafeArea(
        child: Stack(
          children: [
            GoogleMap(
              myLocationButtonEnabled: true,
              myLocationEnabled: true,
              zoomControlsEnabled: true,
              zoomGesturesEnabled: true,
              initialCameraPosition: currentCameraPosition,
              onMapCreated: (controller) {
                googleMapsController = controller;
              },
              markers: mapMarkers,
              polylines: mapPolylines,
              onTap: (position) {
                if (route == null){
                  clearDestination();
                  updateTextInputs();
                  setState(() {});
                }
              },
              onLongPress: (position) {
                dropMarker(position);
              },
              onCameraMove: (position) {
                draggableScrollableController.animateTo(
                  dssMinChildSize,
                  duration: Duration(milliseconds : 100),
                  curve: Curves.linearToEaseOut,
                );
                //log(position.toString());
              },
            ),
            DraggableScrollableSheet(
              controller: draggableScrollableController,
              initialChildSize: dssLocationPickerComponentSize,
              minChildSize: dssMinChildSize,
              snap: true,
              snapSizes: dssSnapSizes,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: MyColors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Container(
                            width: 50,
                            height: 5,
                            decoration: BoxDecoration(
                              color: MyColors.lightGrey,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          SizedBox(height: 20),
                          Column(
                            children: [
                              Text(
                                '¿A dónde quieres ir?',
                                style: MyTextStyles.h1,
                              ),
                              SizedBox(height: 20),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                                decoration: BoxDecoration(
                                  color: MyColors.lightGrey,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      flex: 7,
                                      child: Column(
                                        children: [
                                          TextField(
                                            controller: originInputController,
                                            style: MyTextStyles.inputTextStyle,
                                            readOnly: true,
                                            keyboardType: TextInputType.streetAddress,
                                            textAlignVertical: TextAlignVertical.center,
                                            decoration: Templates.locationInputDecoration(
                                              "Origen",
                                              Container(
                                                padding: EdgeInsets.all(10),
                                                height: 10,
                                                child: Image.asset(
                                                  'assets/thin-target.png',
                                                  color: MyColors.mainTurquoise,
                                                ),
                                              ),
                                            ),
                                            onTap: allowOriginSelection,
                                          ),
                                          SizedBox(height: 10,),
                                          TextField(
                                            controller: destinationInputController,
                                            style: MyTextStyles.inputTextStyle,
                                            keyboardType: TextInputType.streetAddress,
                                            textAlignVertical: TextAlignVertical.center,
                                            decoration: Templates.locationInputDecoration(
                                              "Destino",
                                              Container(
                                                padding: EdgeInsets.all(10),
                                                height: 10,
                                                child: Image.asset(
                                                  'assets/market.png',
                                                  color: MyColors.mainTurquoise,
                                                ),
                                              ),
                                            ),
                                            onTap: (){
                                              draggableScrollableController.animateTo(
                                                1,
                                                duration: Duration(milliseconds : 300),
                                                curve: Curves.linearToEaseOut,
                                              );
                                            },
                                            onChanged: (text) {
                                              searchDestination(text);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      flex: 1,
                                      child: IconButton(
                                        icon: Icon(
                                          CupertinoIcons.arrow_2_squarepath,
                                          color: MyColors.darkGrey,
                                          size: 30,
                                        ),
                                        onPressed: () {
                                          if (origin != null && destination != null) {
                                            // swaping origin and destination
                                            final temp = origin;
                                            origin = destination;
                                            destination = temp;
                                            updateTextInputs();
                                            setState(() {});
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 20),
                              Container(
                                height: 50,
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: MyButtonStyles.primary,
                                  child: Text(
                                    'BUSCAR RUTAS',
                                    style: MyTextStyles.primaryButton,
                                  ),
                                  onPressed: () {
                                    computeRoutes();
                                  },
                                ),
                              ),
                              SizedBox(height: 20),
                              destinationSearchResults == null ? Container() : ListView.builder(
                                physics: NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: destinationSearchResults!.length,
                                itemBuilder: (context, index){
                                  return placeResultListTile(destinationSearchResults![index]);
                                },
                              ),
                              route == null ? Container() : routeOptionTile(route!),
                              // FutureBuilder(
                              //   future: futureRoute,
                              //   builder: (context, AsyncSnapshot<RouteModel> snapshot){
                              //     if (snapshot.connectionState == ConnectionState.waiting){
                              //       return CircularProgressIndicator();
                              //     }
                              //     log(snapshot.data.toString());
                              //     return routeOptionTile();
                              //   },
                              // ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            isComputingRoute ? MyLoadingScreen(
              backgroundColor: MyColors.black,
              backgroundOpacity: 0.7,
              label: "Computing route...",
            ) : SizedBox(),
          ],
        ),
      ),
    );
  }

  Widget routeOptionTile(RouteModel route) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(
        color: MyColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: MyColors.lightGrey,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ruta más óptima',
                  style:TextStyle(
                    fontFamily: MyTextStyles.fontName,
                    fontWeight: FontWeight.w400,
                    fontSize: 20,
                    color: MyColors.blue,
                  ),
                ),
                SizedBox(height: 15,),
                Container(
                  height: 10,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: MyColors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                SizedBox(height: 10,),
                Row(
                  children: [
                    routeTag(Icons.directions_bike, "Ciclovía", MyColors.blue),
                    SizedBox(width: 8),
                    routeTag(CupertinoIcons.car, "Autopista", MyColors.yellow),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${route.eatSeconds!~/60} mins',
                  style: MyTextStyles.h1,
                ),
                Text(
                  '${route.distanceMeters!/1000} Km',
                  style: MyTextStyles.h2,
                ),
                ElevatedButton(
                  style: MyButtonStyles.primary,
                  child: Text('Iniciar Ruta', style: MyTextStyles.button2),
                  onPressed: (){
                    log('STARTING NAVIGATION WITH THIS ROUTE!');
                  },
                ),
              ],
            ),
          ), 
        ],
      ),
    );
  }

  Widget routeTag(IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: color,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18,),
          SizedBox(width: 8,),
          Text(
            label, 
            style: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 14,
              letterSpacing: 0.2,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget placeResultListTile(LocationModel place){
    return Container(
      padding: EdgeInsets.only(left: 10, top: 10, right: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(place.name!, style: MyTextStyles.h2, overflow: TextOverflow.ellipsis,),
          Text(place.address!, style: MyTextStyles.h3, overflow: TextOverflow.ellipsis,),
          // Text(place.latitude!.toString()),
          // Text(place.longitude!.toString()),
          Divider(thickness: 2, height: 20,),
        ],
      ),
    );
  }

  Future<void> showLocationDialog(LocationModel location) async {
    showDialog(
      anchorPoint: Offset(double.maxFinite, 0),
      barrierColor: Color(0x00000000),
      context: context,
      builder: (context) {
        return Stack(
          children: [
            // FOR SOME REASON PUTTING A COLORED CONTAINER BEHIND THE ALERTDIALOG
            // NEGATES THE TAP OUTSIDE TO CLOSE FUNCTIONALITY
            // Container(
            //   decoration: BoxDecoration(
            //     gradient: LinearGradient(
            //       begin: Alignment.bottomCenter,
            //       end: Alignment.topCenter,
            //       stops: [0,0.5],
            //       colors: [
            //         Color(0x78000000),
            //         Color(0x00FFFFFF)
            //       ],
            //     ),
            //   ),
            // ),
            AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 30,
              insetPadding: EdgeInsets.only(top: 175), // NO TOCAR
              contentPadding: EdgeInsets.only(left: 20, top: 20, right: 20, bottom: 5),
              actionsPadding: EdgeInsets.all(8),
              content: Wrap(
                direction: Axis.vertical,
                children: [
                  Text(location.name ?? 'Name', style: MyTextStyles.h1,),
                  Container(
                    width: 280,
                    child: Text(
                      location.address ?? 'Address',
                      style: MyTextStyles.h3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.spaceEvenly,
              actions: [
                ElevatedButton(
                  style: MyButtonStyles.secondary,
                  child: Text('Estrella'),
                  onPressed: (){
                    Navigator.pop(context);
                  },
                ),
                ElevatedButton(
                  style: MyButtonStyles.secondary,
                  child: Text('Buscar Rutas'),
                  onPressed: () {
                    Navigator.pop(context);
                    computeRoutes();
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}