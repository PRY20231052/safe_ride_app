// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, avoid_init_to_null, sized_box_for_whitespace, avoid_unnecessary_containers, unnecessary_brace_in_string_interps, prefer_is_empty, use_build_context_synchronously

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:safe_ride_app/models/location_model.dart';
import 'package:safe_ride_app/models/route_model.dart';
import 'package:safe_ride_app/my_widgets/my_loading_screen.dart';
import 'package:safe_ride_app/my_widgets/navigation_overlay.dart';
import 'package:safe_ride_app/providers/map_provider.dart';
import 'package:safe_ride_app/providers/navigation_provider.dart';
import '../styles.dart';
import 'dart:developer';
import 'package:provider/provider.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {

  late MapProvider watchMapProv;
  late MapProvider readMapProv;
  late NavigationProvider watchNavigationProv;
  late NavigationProvider readNavigationProv;

  // FLAGS
  bool modifyOrigin = false;
  bool modifyDestination = true;

  // CONTROLLERS
  late GoogleMapController googleMapsController;
  TextEditingController originInputController = TextEditingController();
  TextEditingController destinationInputController = TextEditingController();
  DraggableScrollableController draggableSheetController = DraggableScrollableController();

  // DraggableScrollableSheet parameters
  double dssMinChildSize = 0.1;
  double dssInitialChildSize = 0.30;
  List<double> dssSnapSizes = [0.30];

  @override
  initState() {
    super.initState();
    asyncInit();
  }

  Future<void> asyncInit() async {
    log('Initializing...');
    await Provider.of<MapProvider>(context, listen: false).initialize();
    await Provider.of<NavigationProvider>(context, listen: false).initialize();
    updateTextInputs();
    log('Initialized!');
  }
  
  @override
  void dispose() {
    readNavigationProv.positionStream.cancel();
    googleMapsController.dispose();
    super.dispose();
  }

  void updateDraggableScrollableSheetSizes(){
    switch(watchMapProv.mode) {
      case Modes.waypointsSelection:
        dssMinChildSize = 0.1;
        dssInitialChildSize = 0.29;
        dssSnapSizes = [dssInitialChildSize];
        break; // The switch statement must be told to exit, or it will execute every case.
      case Modes.routeSelection:
        dssMinChildSize = 0.1;
        dssInitialChildSize = 0.55;
        dssSnapSizes = [dssInitialChildSize];
        break;
      case Modes.navigation:
        dssMinChildSize = 0.13;
        dssInitialChildSize = dssMinChildSize;
        dssSnapSizes = [];
        break;
    }
  }

  void updateMapCameraPosition({LatLng? target}){
    // ??= means if target is null then assign...
    target ??= watchMapProv.mode == Modes.navigation ? readNavigationProv.route!.origin.toLatLng() : readMapProv.origin!.toLatLng();
    googleMapsController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          zoom: readMapProv.mode == Modes.navigation ? 18 : 15,
          tilt: readMapProv.mode == Modes.navigation ? 50 : 0.0,
        ),
      ),
    );
  }

  updateTextInputs(){
    LatLng currentLatLng = LatLng(readMapProv.currentPosition.latitude, readMapProv.currentPosition.longitude);
    originInputController.text = readMapProv.currentPositionAsOrigin ? "Mi ubicación actual" : readMapProv.origin?.address ??  "";

    if (readMapProv.destination != null && readMapProv.destination!.toLatLng() == currentLatLng){
      destinationInputController.text = "Mi ubicación actual";
    }
    else {
      destinationInputController.text = readMapProv.destination?.address ??  "";
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

  Future<void> dropMarker(position) async {

    readMapProv.mode = Modes.waypointsSelection;
    readMapProv.searchResults = [];
    readMapProv.routeOptions = [];
    updateDraggableScrollableSheetSizes();

    if (modifyOrigin) {
      readMapProv.origin = LocationModel(
        latitude: position.latitude,
        longitude: position.longitude
      );
    } else if (modifyDestination) {
      readMapProv.destination = await readMapProv.fetchLocationByLatLng(
        position.latitude, position.longitude
      );
      readMapProv.waypoints = [readMapProv.destination!];
    } else {
      modifyDestination = false;
      modifyOrigin = false;
    }
    updateMapCameraPosition(target: LatLng(position.latitude, position.longitude));
    updateTextInputs();
    showLocationDialog(
      LocationModel(
        latitude: readMapProv.destination!.latitude,
        longitude: readMapProv.destination!.longitude,
        address: readMapProv.destination!.address, 
      )
    );
  }

  Set<Marker> getMapMarkers(){
    return watchMapProv.destination == null ? {} : {
      Marker(
        markerId: MarkerId('destination'),
        position: readMapProv.destination!.toLatLng(),
        icon: BitmapDescriptor.defaultMarker,
        onTap: () async {
          await showLocationDialog(readMapProv.destination!);
        },
      )
    };
  }

  Set<Polyline> getMapPolylines(){
    // PROBLEM CAUSE ROUTE MODEL WILL HAVE ONLY ONE ROUTE GEOJSON
    // MIGHT HAVE TO USE length == 0
    return watchMapProv.routeOptions.isEmpty ? {} : {
      for (var pathFeature in readMapProv.routeOptions[0].pathGeojson['features'])
        Polyline(
          polylineId: PolylineId(pathFeature['id']),
          color: MyColors.purple,
          jointType: JointType.round,
          endCap: Cap.roundCap,
          width: watchMapProv.mode == Modes.navigation ? 15 : 6,
          points: [
            for(var coordinate in pathFeature['geometry']['coordinates'])
              LatLng(coordinate[0], coordinate[1])
          ],
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    
    readMapProv = context.read<MapProvider>(); // Just reads the provider's data
    watchMapProv = context.watch<MapProvider>(); // Listens/watches for changes on the provider's data

    readNavigationProv = context.read<NavigationProvider>();
    watchNavigationProv = context.watch<NavigationProvider>();

    return watchMapProv.isLoading ? MyLoadingScreen() : Scaffold(
      backgroundColor: MyColors.white,
      body: SafeArea(
        child: Stack(
          alignment: AlignmentDirectional.topCenter,
          children: [
            GoogleMap(
              myLocationButtonEnabled: true,
              myLocationEnabled: true,
              zoomControlsEnabled: true,
              zoomGesturesEnabled: true,
              initialCameraPosition: CameraPosition(
                target: watchMapProv.origin!.toLatLng(),
                zoom: 15,
                tilt: 0.0,
              ),
              onMapCreated: (controller) {
                googleMapsController = controller;
              },
              markers: getMapMarkers(),
              polylines: getMapPolylines(),
              onTap: (position) {
                if (readMapProv.mode == Modes.waypointsSelection){
                  readMapProv.clearDestination();
                }
              },
              onLongPress: (position) {
                dropMarker(position);
              },
              onCameraMove: (position) {
                draggableSheetController.animateTo(
                  dssMinChildSize,
                  duration: Duration(milliseconds : 100),
                  curve: Curves.linearToEaseOut,
                );
                //log(position.toString());
              },
            ),
            watchMapProv.mode != Modes.navigation ? Container() : NavigationOverlay(
              mainInstructionImg: Image.asset('assets/turn_left.png', color: MyColors.white,),
              showFollowUpInstruction: false,
            ),
            DraggableScrollableSheet(
              controller: draggableSheetController,
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
                        SizedBox(height: 10),
                        draggableScrollableSheetContent(),
                      ],
                    ),
                  ),
                );
              },
            ),
            watchMapProv.isComputingRoute ? MyLoadingScreen(
              backgroundColor: MyColors.black,
              backgroundOpacity: 0.7,
              label: "Calculando rutas...",
            ) : SizedBox(),
          ],
        ),
      ),
    );
  }

  Widget draggableScrollableSheetContent(){
    if (watchMapProv.mode != Modes.navigation){
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
                          draggableSheetController.animateTo(
                            1,
                            duration: Duration(milliseconds : 300),
                            curve: Curves.linearToEaseOut,
                          );
                        },
                        onChanged: (text) async {
                          readMapProv.searchResults = text.length > 1 ? await readMapProv.searchPlacesByText(text) : [];
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
                      // if (origin != null && destination != null) {
                      //   // swaping origin and destination
                      //   final temp = origin;
                      //   origin = destination;
                      //   destination = temp;
                      //   waypoints = [destination!];
                      //   updateTextInputs();
                      //   setState(() {});
                      // }
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 30),
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
                onPressed: (){
                  readNavigationProv.cancelNavigation();
                  draggableSheetController.animateTo(
                    dssMinChildSize,
                    duration: Duration(milliseconds : 100),
                    curve: Curves.linearToEaseOut,
                  );
                  updateMapCameraPosition();
                  updateDraggableScrollableSheetSizes();
                },
                iconSize: 60,
                icon: Image.asset(
                  'assets/cancel_icon.png',
                  color: MyColors.red,
                ),
              ),
              Column(
                children: [
                  Text('${(watchNavigationProv.route!.etaSeconds/60).toStringAsFixed(0)} mins', style: MyTextStyles.h1,),
                  Text('${(watchNavigationProv.route!.distanceMeters/1000).toStringAsFixed(1)} km - eta time', style: MyTextStyles.h2,),
                ],
              ),
              IconButton(
                onPressed: readNavigationProv.computeAlternativeRoutes,
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
    if (watchMapProv.mode == Modes.waypointsSelection && watchMapProv.searchResults.isNotEmpty){
      return ListView.builder(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: watchMapProv.searchResults.length,
        itemBuilder: (context, index){
          return placeResultListTile(watchMapProv.searchResults[index]);
        },
      );
    }
    else if (watchMapProv.mode == Modes.routeSelection && watchMapProv.routeOptions.isNotEmpty){
      return routeOptionTile(watchMapProv.routeOptions[0]);
    }
    else if (watchMapProv.mode == Modes.navigation){
      return Container(
        //color: MyColors.red,
        height: 700, // ReorderableListView needs to be inside a Height Container, otherwise it rashes the app
        child: ReorderableListView(
          onReorder: (int oldIndex, int newIndex){
            log('$oldIndex, $newIndex');
          },
          children: List.generate(
            watchNavigationProv.route!.waypoints.length,
            (index) => ListTile(
              key: Key(index.toString()),
              tileColor: MyColors.mainBlue,
              title: Text('${watchNavigationProv.route!.waypoints[index].address}', style: MyTextStyles.h3,),
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

                    readNavigationProv.route = routeOption;
                    readNavigationProv.polyline = getMapPolylines().first;

                    readNavigationProv.route!.waypoints = [
                      readMapProv.destination!,
                      readMapProv.destination!,
                      readMapProv.destination!,
                    ]; // FOR TESTING ONLY
                    readMapProv.mode = Modes.navigation;
                    updateMapCameraPosition(
                      target: readNavigationProv.route!.origin.toLatLng(),
                    );
                    updateDraggableScrollableSheetSizes();
                    draggableSheetController.animateTo(
                      dssMinChildSize,
                      duration: Duration(milliseconds : 100),
                      curve: Curves.linearToEaseOut,
                    );
                    readNavigationProv.startNavigation();
                  },
                ),
              ],
            ),
          ), 
        ],
      ),
    );
  }

  Widget routeInfoGraphBar({
    required double width,
    required RouteModel route,
    double cornersRadius = 12
  }){
    
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
        onTap: () async {
          FocusManager.instance.primaryFocus?.unfocus();//Closese the keyboard
          readMapProv.destination = place;
          readMapProv.waypoints = [readMapProv.destination!];
          readMapProv.searchResults = [];
          await readMapProv.computeRoutes();
          updateTextInputs();
          updateDraggableScrollableSheetSizes();
          draggableSheetController.animateTo(
            dssSnapSizes[0],
            duration: Duration(milliseconds : 100),
            curve: Curves.linearToEaseOut,
          );
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
                  Container(
                    width: 280,
                    child: Text(
                      location.name ?? 'Sin nombre',
                      style: MyTextStyles.h1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    width: 280,
                    child: Text(
                      location.address ?? 'Dirección desconocida',
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
                  onPressed: () async {
                    if (readMapProv.origin != null && readMapProv.destination != null) {
                      Navigator.pop(context);
                      await readMapProv.computeRoutes();
                      updateTextInputs();
                      updateDraggableScrollableSheetSizes();
                      draggableSheetController.animateTo(
                        dssSnapSizes[0],
                        duration: Duration(milliseconds : 100),
                        curve: Curves.linearToEaseOut,
                      );
                    }
                    else {
                      Fluttertoast.showToast(
                        msg: "Defina al menos un punto de destino",
                        toastLength: Toast.LENGTH_LONG
                      );
                    }
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