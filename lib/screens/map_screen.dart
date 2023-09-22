// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, avoid_init_to_null, sized_box_for_whitespace, avoid_unnecessary_containers, unnecessary_brace_in_string_interps

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
import 'package:safe_ride_app/my_widgets/navigation_overlay.dart';

import '../services/safe_ride_api.dart';
import '../styles.dart';
import 'dart:developer';

import '../utils.dart';

enum Modes {
  waypointsSelection,
  routeSelection,
  navigation,
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {

  // API SERVICES
  final safeRideApi = SafeRideApi();
  late GoogleMapsPlaces placesApi;
  late GoogleMapsGeolocation geolocationApi;
  late GoogleMapsGeocoding geocodingApi;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();


  var mode = Modes.waypointsSelection;


  // WAYPOING PICKING VARIABLES
  late Position currentPosition;
  LocationModel? origin = null;
  List<LocationModel> waypoints = [];
  LocationModel? destination = null;
  RouteModel? route = null;
  List<LocationModel>? destinationSearchResults;


  // ROUTE PICKING VARIABLES
  List<RouteModel>? routeOptions = [];


  // NAVIGATION VARIABLES
  int navPathCurrentIndex = 0;
  bool isInsideNodeRadius = false;
  

  // MAP VARIABLES
  late Marker destinationMarker;
  Set<Marker> mapMarkers = {};
  Set<Polyline> mapPolylines = {};
  late CameraPosition mapCameraPosition;


  // FLAGS
  bool currentPositionAsOrigin = true;
  bool isComputingRoute = false;
  bool isLoading = true;
  bool modifyOrigin = false;
  bool modifyDestination = true;
  

  // CONTROLLERS
  late GoogleMapController googleMapsController;
  TextEditingController originInputController = TextEditingController();
  TextEditingController destinationInputController = TextEditingController();
  DraggableScrollableController draggableScrollableController = DraggableScrollableController(); 


  // DraggableScrollableSheet parameters
  double dssMinChildSize = 0.13;
  late double dssInitialChildSize;
  late List<double> dssSnapSizes;


  // location settings
  late StreamSubscription<Position> positionStream;
  

  @override
  initState() {
    asyncInit();
    super.initState();
  }

  asyncInit() async {
    log('Initializing...');
    await verifyLocationPermissions();
    await dotenv.load();
    placesApi = GoogleMapsPlaces(apiKey: dotenv.env['GOOGLE_MAPS_API_KEY']);
    geocodingApi = GoogleMapsGeocoding(apiKey: dotenv.env['GOOGLE_MAPS_API_KEY']);
    geolocationApi = GoogleMapsGeolocation(apiKey: dotenv.env['GOOGLE_MAPS_API_KEY']);

    positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      ),
    ).listen((Position position) {
      currentPosition = position;
      log('CURRENT POSITION UPDATED ${[currentPosition.latitude, currentPosition.longitude].toString()}');
      if (mode == Modes.navigation){
        handleNavigationProgress();
      } else {
        if(currentPositionAsOrigin){
          log('setting new origin');
          origin = LocationModel(
            latitude: currentPosition.latitude,
            longitude: currentPosition.longitude,
          );
        }
      }
      // db update
      //locationUpdate();
    });

    currentPosition = await Geolocator.getCurrentPosition();
    origin = LocationModel(latitude: currentPosition.latitude, longitude: currentPosition.longitude);

    mapCameraPosition = mapCameraPosition = CameraPosition(
      target: origin!.toLatLng(),
      zoom: 15,
    );
    isLoading = false;
    
    updateTextInputs();
    setState(() {});
    log('Initialized!');
  }

  @override
  void setState(VoidCallback fn) {
    updateMap();
    updateDraggableScrollableSheetSizes();
    super.setState(fn);
  }
  

  @override
  void dispose() {
    positionStream.cancel();
    googleMapsController.dispose();
    super.dispose();
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

  void updateDraggableScrollableSheetSizes(){
    switch(mode) {
      case Modes.waypointsSelection:
        dssMinChildSize = 0.1;
        dssInitialChildSize = 0.30;
        dssSnapSizes = [0.30];
        break; // The switch statement must be told to exit, or it will execute every case.
      case Modes.routeSelection:
        dssMinChildSize = 0.1;
        dssInitialChildSize = 0.55;
        dssSnapSizes = [0.55];
        break;
      case Modes.navigation:
        dssMinChildSize = 0.13;
        dssInitialChildSize = dssMinChildSize;
        dssSnapSizes = [];
        break;
    }
  }

  void updateMapCameraPosition({LatLng? target}){
    // ??= means in if target is null then assign...
    target ??= mode == Modes.navigation ? route!.origin.toLatLng() : origin!.toLatLng();
    mapCameraPosition = CameraPosition(
      target: target,
      zoom: mode == Modes.navigation ? 18 : 15,
      tilt: mode == Modes.navigation ? 50 : 0.0,
    );
    googleMapsController.animateCamera(
      CameraUpdate.newCameraPosition(mapCameraPosition),
    );
  }

  void startNavigation() {
    if (route != null){
      mode = Modes.navigation;
      navPathCurrentIndex = 0;
      updateMapCameraPosition();
      //Navigator.push(context, MaterialPageRoute(builder: (context) => NavigationScreen(route: route!)),);
      draggableScrollableController.animateTo(
        dssMinChildSize,
        duration: Duration(milliseconds : 100),
        curve: Curves.linearToEaseOut,
      );
      setState(() { });
    }
  }

  void handleNavigationProgress(){
    double nodeThresholdRadius = 5;
    bool onPath = isLocationOnPath(
      LocationModel(latitude: currentPosition.latitude, longitude: currentPosition.longitude),
      mapPolylines.first,
      10.0,
    );
    onPath ? log('On path :)') : log('Deviated from path!');
    if(!onPath){
      // Re-compute a new route from current position to the rest of waypoints

    } else {
      log('CURRENT INDEX: $navPathCurrentIndex/${route!.pathNodes.length}');
      for (var i = navPathCurrentIndex + 1; i < route!.pathNodes.length; i++){

        double distance = computeDistanceBetweenPoints(
          LatLng(currentPosition.latitude, currentPosition.longitude),
          LatLng(route!.pathNodes[i].latitude, route!.pathNodes[i].longitude)
        );
        i == 1 ? log('Distance to next node: $distance') : null;
        // if we go pass the node's threshold radius
        if (!isInsideNodeRadius && distance <= nodeThresholdRadius){
          isInsideNodeRadius = true;
          // we have landed into the node so we have to now go to the next step
          log('Arrived to node $i/${route!.pathNodes.length}  Distance to center of node: $distance');
          break;
        }
        // for the inmidiate next node, check if we are leaving the node radius to update the current node status
        if (i == navPathCurrentIndex+1 && isInsideNodeRadius && distance > nodeThresholdRadius){
          isInsideNodeRadius = false;
          navPathCurrentIndex = i;
          log('Leaving node $i Distance to center of node: $distance');
          break;
        }
      }
    }
  }
  
  void exitNavigation() {
    mode = Modes.waypointsSelection;
    route = null;
    clearDestination();
    updateDraggableScrollableSheetSizes();
    draggableScrollableController.animateTo(
      dssMinChildSize,
      duration: Duration(milliseconds : 100),
      curve: Curves.linearToEaseOut,
    );
    updateMapCameraPosition();
    log('EXITING NAVIGATION WITH THIS ROUTE!');
    setState(() { });
  }


  Future<LocationModel?> fetchLocationByLatLng(double latitude, double longitude) async {
    var response = await geocodingApi.searchByLocation(
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

  Future<void> onMarkerTapped() async {
    showLocationDialog(destination!);
  }


  Future<List<LocationModel>?> searchPlacesByText(String textInput) async {
    var sessionToken = '0';
    List<LocationModel> placesResults = [];

    var response = await placesApi.autocomplete(
      textInput,
      sessionToken: sessionToken,
      location: Location(lat: origin!.latitude, lng: origin!.longitude),
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


  void searchDestination(text) async {
    if (text.length > 1){
      destinationSearchResults = await searchPlacesByText(text);
    }
    else{
      destinationSearchResults = [];
    }
    setState(() {});
  }

  Future<void> computeAlternativeRoutes() async {
    handleNavigationProgress();
    // for (var edge in route!.pathEdges){
    //   log(edge.attributes.toString());
    // }
  }

  Future<void> computeRoutes() async {
    if (origin != null && destination != null) {
      setState(() {isComputingRoute = true;});
      routeOptions = await safeRideApi.requestRoutes(
        origin!.toLatLng(),
        destination!.toLatLng(),
      );
      mode = Modes.routeSelection;
      updateMap();
      updateTextInputs();
      updateDraggableScrollableSheetSizes();
      draggableScrollableController.animateTo(
        dssSnapSizes[0],
        duration: Duration(milliseconds : 100),
        curve: Curves.linearToEaseOut,
      );
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
    routeOptions = null;
    mapPolylines = {};
    if (modifyOrigin) {
      origin = LocationModel(latitude: position.latitude, longitude: position.longitude);
    } else if (modifyDestination) {
      destination = await fetchLocationByLatLng(position.latitude, position.longitude);
      waypoints = [destination!];
    } else {
      modifyDestination = false;
      modifyOrigin = false;
    }
    updateMapCameraPosition(target: LatLng(position.latitude, position.longitude));
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
    routeOptions = null;
    destination = null;
    waypoints = [];
    destinationSearchResults = null;
    updateTextInputs();
  }


  updateTextInputs(){
    var currentLatLng = LatLng(currentPosition.latitude, currentPosition.longitude);
    if (currentPositionAsOrigin){
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

  updateMap(){
    updateMarkers();
    updatePolylines();
  }
  updatePolylines(){
    if (routeOptions == null || routeOptions!.isEmpty){
      mapPolylines = {};
    }
    else {
      mapPolylines = {
        Polyline(
          polylineId: PolylineId('route_0'),
          color: MyColors.purple,
          width: mode == Modes.navigation ? 15 : 5,
          points: routeOptions![0].getLatLngPoints(),
          jointType: JointType.round,
          endCap: Cap.roundCap,
        ),
      };
    }
  }
  updateMarkers(){
    mapMarkers = {};
    if(destination != null){
      destinationMarker = Marker(
        markerId: MarkerId('destination'),
        position: destination!.toLatLng(),
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
          alignment: AlignmentDirectional.topCenter,
          children: [
            GoogleMap(
              myLocationButtonEnabled: true,
              myLocationEnabled: true,
              zoomControlsEnabled: true,
              zoomGesturesEnabled: true,
              initialCameraPosition: mapCameraPosition,
              onMapCreated: (controller) {
                googleMapsController = controller;
              },
              markers: mapMarkers,
              polylines: mapPolylines,
              onTap: (position) {
                if (mode == Modes.waypointsSelection){
                  clearDestination();
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
            mode != Modes.navigation ? Container() : NavigationOverlay(
              route: route!,
              routeCurrentIndex: navPathCurrentIndex,
              polyline: mapPolylines.first,
              mainInstruction: route!.pathEdges[navPathCurrentIndex+1].attributes['name'] ?? 'Calle Desconocida',
              mainInstructionImg: Image.asset('assets/turn_left.png', color: MyColors.white,),
              showFollowUpInstruction: false,
            ),
            DraggableScrollableSheet(
              controller: draggableScrollableController,
              initialChildSize: dssInitialChildSize,
              minChildSize: dssMinChildSize,
              snap: true,
              snapSizes: dssSnapSizes,
              builder: (context, scrollController) {
                return Container(
                  padding: EdgeInsets.only(right: 16.0, top: 16.0, left: 16.0),
                  decoration: BoxDecoration(
                    color: MyColors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
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
                        SizedBox(height: 8),
                        draggableScrollableSheetContent(),
                      ],
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

  Widget draggableScrollableSheetContent(){
    if (mode != Modes.navigation){
      return Column(
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
                              color: MyColors.mainBlue,
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
                              color: MyColors.mainBlue,
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
                        waypoints = [destination!];
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
          // Container(
          //   height: 50,
          //   width: double.infinity,
          //   child: ElevatedButton(
          //     style: MyButtonStyles.primary,
          //     child: Text(
          //       'BUSCAR RUTAS',
          //       style: MyTextStyles.primaryButton,
          //     ),
          //     onPressed: () {
          //       computeRoutes();
          //     },
          //   ),
          // ),
          // SizedBox(height: 20),
          dssComplementaryBottomContent(),
        ],
      );
    }
    else {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: exitNavigation,
                iconSize: 60,
                icon: Image.asset(
                  'assets/cancel_icon.png',
                  color: MyColors.red,
                ),
              ),
              Column(
                children: [
                  Text('${(route!.etaSeconds/60).toStringAsFixed(0)} mins', style: MyTextStyles.h1,),
                  Text('${(route!.distanceMeters/1000).toStringAsFixed(1)} km - eta time', style: MyTextStyles.h2,),
                ],
              ),
              IconButton(
                onPressed: computeAlternativeRoutes,
                iconSize: 60,
                icon: Image.asset(
                  'assets/alternative_routes_icon.png',
                  color: MyColors.mainBlue,
                ),
              ),
            ],
          ),
          Divider(thickness: 2, height: 20,),
          dssComplementaryBottomContent(),          
        ],
      );
    }
  }


  Widget dssComplementaryBottomContent(){
    if (mode == Modes.waypointsSelection && destinationSearchResults != null){
      return ListView.builder(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: destinationSearchResults!.length,
        itemBuilder: (context, index){
          return placeResultListTile(destinationSearchResults![index]);
        },
      );
    }
    else if (mode == Modes.routeSelection && routeOptions != null){
      return routeOptionTile(routeOptions![0]);
    }
    else if (mode == Modes.navigation){
      waypoints = [destination!, destination!, destination!]; // FOR TESTING ONLY
      return Container(
        //color: MyColors.red,
        height: 700, // ReorderableListView needs to be inside a Height Container, otherwise it rashes the app
        child: ReorderableListView(
          onReorder: (int oldIndex, int newIndex){
            log('$oldIndex, $newIndex');
          },
          children: List.generate(
            waypoints.length,
            (index) => ListTile(
              key: Key(index.toString()),
              tileColor: MyColors.mainBlue,
              title: Text('${waypoints[index].address}', style: MyTextStyles.h3,),
              trailing: Icon(Icons.drag_handle_rounded),
            ),
          ),
        ),
      );
    }
    else {
      return Container();
    }
  }

  // Widget waypointTile(LocationModel location, String index){
  //   return ; 
  // }

  Widget routeOptionTile(RouteModel routeOption) {
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
                  'Ruta óptima',
                  style: TextStyle(
                    fontFamily: MyTextStyles.fontName,
                    fontWeight: FontWeight.w500,
                    fontSize: 20,
                    color: MyColors.turquoise,
                  ),
                ),
                SizedBox(height: 15,),
                routeInfoGraphBar(
                  width: 200,
                  route: routeOption,
                ),
                SizedBox(height: 10,),
                Row(
                  children: [
                    routeTag(Icons.directions_bike, "Ciclovía", MyColors.turquoise),
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
                  '${(routeOption.etaSeconds/60).toStringAsFixed(0)} mins',
                  style: MyTextStyles.h1,
                ),
                Text(
                  '${(routeOption.distanceMeters/1000).toStringAsFixed(1)} km',
                  style: MyTextStyles.h2,
                ),
                SizedBox(height: 10,),
                ElevatedButton(
                  style: MyButtonStyles.primary,
                  child: Text('Iniciar Ruta', style: MyTextStyles.button2),
                  onPressed: (){
                    route = routeOption;
                    startNavigation();
                  },
                ),
              ],
            ),
          ), 
        ],
      ),
    );
  }

  Widget routeInfoGraphBar({required double width, required RouteModel route, double cornersRadius = 12}){
    
    // ATTEMPT TO ELIMINATE THOSE WHITE LINES IN BETWEEN
    // var segments;
    // var currCyclewayLevel;
    // for (var i = 0; i < route.pathEdges.length; i++) {
    //   route.pathEdges[i].attributes['cycleway_level'];
    // }

    return Row(
      children: List.generate(
        route.pathEdges.length,
        (index) => Container(
          height: 12,
          width: route.pathEdges[index].attributes['length']/route.distanceMeters*width,
          decoration: BoxDecoration(
            color: route.pathEdges[index].attributes['cycleway_level'] == '2' ? MyColors.turquoise : MyColors.yellow,
            borderRadius: 
              index == 0 ? BorderRadius.only(topLeft: Radius.circular(cornersRadius), bottomLeft: Radius.circular(cornersRadius)) :
              index == route.pathEdges.length-1 ? BorderRadius.only(topRight: Radius.circular(cornersRadius), bottomRight: Radius.circular(cornersRadius)) :
              BorderRadius.zero
          ),
        ),
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
      child: GestureDetector(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();//Closese the keyboard
          destination = place;
          waypoints = [destination!];
          destinationSearchResults = null;
          computeRoutes();
        },
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