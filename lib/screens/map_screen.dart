// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, avoid_init_to_null, sized_box_for_whitespace

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
  late GoogleMapController _googleMapsController;
  
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late CameraPosition cameraPosition;

  Future<RouteModel>? futureRoute;
  RouteModel? route = null;
  LocationModel? origin = null;
  LocationModel? destination = null;
  
  late Marker originMarker;
  late Marker destinationMarker;
  Set<Marker> markers = {};

  bool isComputingRoute = false;
  bool isLoading = true;
  bool _editOriginMarker = false;
  bool _editDestinationMarker = true;

  TextEditingController originController = TextEditingController();
  TextEditingController destinationController = TextEditingController();
  DraggableScrollableController draggableScrollableController = DraggableScrollableController(); 
  
  @override
  initState() {
    log('Initializing...');
    asyncInit();
    super.initState();
    log('Initialized!');
  }

  asyncInit() async {
    await setCurrentPositionAsOrigin();
    setCameraPosition(origin!);
    updateMarkers();
    originController.text = "Mi ubicación actual";
    isLoading = false;
    setState(() {});
  }

  @override
  void dispose() {
    _googleMapsController.dispose();
    super.dispose();
  }

  Future<void> requestRoute(LatLng origin, LatLng destination) async {
    route = await safeRideApi.requestRoute(origin, destination);
    log(route!.getLatLngPoints().toString());
  }

  void setCameraPosition(LocationModel location) {
    // LatLng currentPosition = LatLng(-12.100333555286838, -76.9946046452263);
    LatLng target = LatLng(location.latitude, location.longitude);
    cameraPosition = CameraPosition(
      target: target,
      zoom: 15,
    );
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
    Position position = await getCurrentPosition();
    origin = LocationModel(latitude: position.latitude, longitude: position.longitude);
  }

  updateMarkers(){
    markers = {};
    if(origin != null){
      originMarker = Marker(
        markerId: MarkerId('origin'),
        infoWindow: InfoWindow(title: 'Origin'),
        position: origin!.toLatLng(),
        icon: BitmapDescriptor.defaultMarkerWithHue(200),
      );
      markers.add(originMarker);
    }
    if(destination != null){
      destinationMarker = Marker(
        markerId: MarkerId('destination'),
        infoWindow: InfoWindow(title:'Destination'),
        position: destination!.toLatLng(),
        icon: BitmapDescriptor.defaultMarker,
      );
      markers.add(destinationMarker);
    }
  }

  allowOriginSelection() {
    setState(() {
      _editDestinationMarker = false;
      _editOriginMarker = true;
    });
  }

  allowDestinationSelection() {
    _editDestinationMarker = true;
    _editOriginMarker = false;
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
              initialCameraPosition: cameraPosition,
              onMapCreated: (controller) {
                _googleMapsController = controller;
              },
              markers: markers,
              polylines: {
                Polyline(
                  polylineId: PolylineId('route'),
                  color: Colors.blue,
                  width: 5,
                  points: route == null ? [] : route!.getLatLngPoints(),
                ),
              },
              onTap: (data) {
                if (_editOriginMarker) {
                  origin = LocationModel(latitude: data.latitude, longitude: data.longitude);
                  originController.text = "${origin!.latitude}, ${origin!.longitude}";
                } else if (_editDestinationMarker) {
                  destination = LocationModel(latitude: data.latitude, longitude: data.longitude);
                  destinationController.text = "${destination!.latitude}, ${destination!.longitude}";
                } else {
                  _editDestinationMarker = false;
                  _editOriginMarker = false;
                }
                updateMarkers();
                setState(() {});
              },
            ),
            DraggableScrollableSheet(
              controller: draggableScrollableController,
              initialChildSize: 0.38,
              minChildSize: 0.1,
              maxChildSize: 1,
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
                                            controller: originController,
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
                                            controller: destinationController,
                                            style: MyTextStyles.inputTextStyle,
                                            readOnly: true,
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
                                            onTap: allowDestinationSelection,
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
                                          if (originController.text.isNotEmpty && destinationController.text.isNotEmpty) {

                                            final tempText = originController.text;
                                            originController.text = destinationController.text;
                                            destinationController.text = tempText;

                                            // swaping origin and destination
                                            final temp = origin;
                                            origin = destination;
                                            destination = temp;

                                            updateMarkers();
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
                                  child: Text('CALCULAR RUTAS', style: MyTextStyles.primaryButton,),
                                  onPressed: () async {
                                    if (originController.text.isNotEmpty && destinationController.text.isNotEmpty) {
                                      setState(() {isComputingRoute = true;});
                                      route = await safeRideApi.requestRoute(
                                        origin!.toLatLng(),
                                        destination!.toLatLng(),
                                      );
                                      //log(route!.getLatLngPoints().toString());
                                      draggableScrollableController.animateTo(
                                        0.6,
                                        duration: Duration(milliseconds : 500),
                                        curve: Curves.linearToEaseOut,
                                      );
                                      setState(() {isComputingRoute = false;});
                                    }
                                  },
                                ),
                              ),
                              SizedBox(height: 20),
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
                  style: MyTextStyles.h1,
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
}