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
import '';

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
    originMarker = Marker(
      markerId: MarkerId('Origin'),
      infoWindow: InfoWindow(title: 'Origin'),
      position: origin!.toLatLng(),
      icon: BitmapDescriptor.defaultMarker,
    );
    markers.add(originMarker);
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
      markers.add(originMarker);
    }
    if(destination != null){
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
    return isLoading ? MyLoadingScreen(color: MyColors.white,) : Scaffold(
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
                  originMarker = Marker(
                    markerId: MarkerId('origin'),
                    infoWindow: InfoWindow(title: 'Origin'),
                    position: origin!.toLatLng(),
                    icon: BitmapDescriptor.defaultMarker,
                  );
                  originController.text = "${origin!.latitude}, ${origin!.longitude}";
                } else if (_editDestinationMarker) {
                  destination = LocationModel(latitude: data.latitude, longitude: data.longitude);
                  destinationMarker = Marker(
                    markerId: MarkerId('destination'),
                    infoWindow: InfoWindow(title: 'Destination'),
                    position: destination!.toLatLng(),
                    icon: BitmapDescriptor.defaultMarkerWithHue(200),
                  );
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
                                height: 130, // important, why?
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
                                          Templates.locationField(
                                            originController,
                                            "Origen",
                                            Container(
                                              width: 10,
                                              padding: EdgeInsets.all(10),
                                              child: Image.asset(
                                                'assets/thin-target.png',
                                                color: MyColors.mainTurquoise,
                                              ),
                                              
                                            ),
                                            TextInputType.streetAddress,
                                            allowOriginSelection
                                          ),
                                          Divider(
                                            thickness: 1.5, 
                                            color: MyColors.grey, 
                                            indent: 50, 
                                            height: 2,
                                          ),
                                          Templates.locationField(
                                            destinationController,
                                            "Destino",
                                            Container(
                                              padding: EdgeInsets.all(10),
                                              height: 10,
                                              child: Image.asset(
                                                'assets/market.png',
                                                color: MyColors.mainTurquoise,
                                              ),
                                            ),
                                            TextInputType.streetAddress,
                                            allowDestinationSelection
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
                                            setState(() {
                                              final tempOrigin = originMarker;
                                              originMarker = Marker(
                                                markerId: const MarkerId('origin'),
                                                infoWindow: InfoWindow(title: 'Origin'),
                                                position: destinationMarker.position,
                                                icon: BitmapDescriptor.defaultMarker,
                                              );
                                              destinationMarker = Marker(
                                                markerId: const MarkerId('destination'),
                                                infoWindow: InfoWindow(
                                                  title:'Destination',
                                                ),
                                                position: tempOrigin.position,
                                                icon: BitmapDescriptor.defaultMarkerWithHue(200),
                                              );
                                              markers = {
                                                originMarker,
                                                destinationMarker
                                              };
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 20),
                              Templates.elevatedButton(
                                "Calcular Ruta",
                                () async {
                                  if (originController.text.isNotEmpty && destinationController.text.isNotEmpty) {
                                    setState(() {isComputingRoute = true;});
                                    route = await safeRideApi.requestRoute(
                                      originMarker.position,
                                      destinationMarker.position,
                                    );
                                    log(route!.getLatLngPoints().toString());
                                    setState(() {isComputingRoute = false;});
                                  }
                                },
                              ),
                              SizedBox(height: 20),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                                decoration: BoxDecoration(
                                  color: MyColors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: MyColors.lightGrey,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '10 min',
                                          style: MyTextStyles.h1,
                                        ),
                                        Text(
                                          'Best Route',
                                          style: MyTextStyles.h2
                                        ),
                                      ],
                                    ),
                                    Templates.spaceBoxNH(8),
                                    Text(
                                      'Lorem ipsum dolor - sit amet, consectetur adipiscing elit',
                                      style: MyTextStyles.body,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Templates.spaceBoxNH(8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Templates.selectButton(
                                            "Choose", () => {}),
                                      ],
                                    ),
                                    Templates.spaceBoxNH(8),
                                    Row(
                                      children: [
                                        Templates.routeTag("Bikeway",
                                            Icons.directions_bike),
                                        SizedBox(width: 20),
                                        Templates.routeTag("shared path",
                                            CupertinoIcons.car),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // SizedBox(height: 20),
                              // Container(
                              //   padding: const EdgeInsets.symmetric(
                              //       horizontal: 16, vertical: 16),
                              //   decoration: BoxDecoration(
                              //     color: Templates.whiteColor,
                              //     borderRadius: BorderRadius.circular(10),
                              //     border: Border.all(
                              //       color: Templates.lightGreyColor,
                              //       width: 1,
                              //     ),
                              //   ),
                              //   child: Column(
                              //     children: [
                              //       const Row(
                              //         mainAxisAlignment:
                              //         MainAxisAlignment.spaceBetween,
                              //         children: [
                              //           Text('30 min',
                              //               style: Templates.subtitle),
                              //           Text('Slower Route',
                              //               style: Templates.badLabel),
                              //         ],
                              //       ),
                              //       Templates.spaceBoxNH(8),
                              //       const Text(
                              //         'Lorem ipsum dolor - sit amet, consectetur adipiscing elit',
                              //         style: Templates.body,
                              //         maxLines: 1,
                              //         overflow: TextOverflow.ellipsis,
                              //       ),
                              //       Templates.spaceBoxNH(8),
                              //       Row(
                              //         mainAxisAlignment:
                              //         MainAxisAlignment.spaceBetween,
                              //         children: [
                              //           Templates.selectButton(
                              //               "Choose", () => {}),
                              //         ],
                              //       ),
                              //       Templates.spaceBoxNH(8),
                              //       Row(
                              //         children: [
                              //           Templates.routeTag("Bikeway",
                              //               Icons.directions_bike),
                              //           SizedBox(width: 20),
                              //           Templates.routeTag("shared path",
                              //               CupertinoIcons.car),
                              //         ],
                              //       ),
                              //     ],
                              //   ),
                              // )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            isComputingRoute ? MyLoadingScreen(label: "Computing route...",):SizedBox(),
          ],
        ),
      ),
    );
  }
}