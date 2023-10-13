// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, avoid_init_to_null, sized_box_for_whitespace, avoid_unnecessary_containers, unnecessary_brace_in_string_interps, prefer_is_empty, use_build_context_synchronously

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:safe_ride_app/models/favorite_location_model.dart';
import 'package:safe_ride_app/providers/user_provider.dart';
import 'package:safe_ride_app/screens/user_profile_screen.dart';
import 'package:safe_ride_app/utils/asset_to_bytes.dart';
import 'package:safe_ride_app/models/location_model.dart';
import 'package:safe_ride_app/models/path_model.dart';
import 'package:safe_ride_app/my_widgets/my_loading_screen.dart';
import 'package:safe_ride_app/my_widgets/navigation_overlay.dart';
import 'package:safe_ride_app/providers/map_provider.dart';
import 'package:safe_ride_app/providers/navigation_provider.dart';
import '../models/edge_model.dart';
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

  late UserProvider watchUserProv;
  late UserProvider readUserProv;

  // CONTROLLERS
  
  TextEditingController originInputController = TextEditingController();
  TextEditingController searchPlaceInputController = TextEditingController();

  Marker? tempMarker;
  Set<Marker> mapMarkers = {};

  // MARKERS
  List<BitmapDescriptor> enumeratedMarkersIcons = [];
  BitmapDescriptor? starMarkerIcon;
  BitmapDescriptor? tempMarkerIcon;

  @override
  initState() {
    super.initState();
    asyncInit();
  }

  Future<void> asyncInit() async {
    log('Initializing...');

    await Provider.of<UserProvider>(context, listen: false).initialize(); 
    await Provider.of<MapProvider>(context, listen: false).initialize();
    await Provider.of<NavigationProvider>(context, listen: false).initialize();

    var markerSize = 85;
    tempMarkerIcon = BitmapDescriptor.fromBytes(await assetToBytes('assets/marker_red.png', width: markerSize,));
    starMarkerIcon = BitmapDescriptor.fromBytes(await assetToBytes('assets/marker_purple_solid_white_star.png', width: (markerSize*0.9).round(),));
    enumeratedMarkersIcons = [
      for(var i=1; i < 10; i++)
        BitmapDescriptor.fromBytes(await assetToBytes('assets/marker_red_$i.png', width: markerSize,))
    ];
    updateTextInputs();
    Provider.of<MapProvider>(context, listen: false).isLoading = false;
    log('Initialized!');
  }
  
  @override
  void dispose() {
    readNavigationProv.positionStream.cancel();
    readMapProv.googleMapsController.dispose();
    super.dispose();
  }

  updateTextInputs(){
    // LatLng currentLatLng = LatLng(readMapProv.currentPosition.latitude, readMapProv.currentPosition.longitude);
    originInputController.text = readMapProv.currentPositionAsOrigin ? "Mi ubicación actual" : readMapProv.origin?.address ??  "";

    // if (readMapProv.waypoints.isNotEmpty && readMapProv.waypoints[-1].coordinates == currentLatLng){
    //   destinationInputController.text = "Mi ubicación actual";
    // }
    // else if(readMapProv.waypoints.isNotEmpty) {
    //   destinationInputController.text = readMapProv.waypoints[-1].address ??  "";
    // }
  }

  Future<void> dropMarker({LatLng? latLngPoint, dynamic location}) async {
    // You can either provide a latlng point and it will request the rest of the location details'
    // or provide the location with full details for faster response

    readMapProv.searchResults = [];
    if (watchMapProv.waypoints.length >= 5){
      Fluttertoast.showToast(
        msg: "Máximo número de destinos alcanzados",
        toastLength: Toast.LENGTH_LONG
      );
      return;
    }
    // readMapProv.mode = Modes.waypointsSelection;
    // readMapProv.computedRoute = null;

    location ??= await readMapProv.fetchLocationByLatLng(latLngPoint!);
    String? markerId;
    if(watchMapProv.mode == Modes.routeSelection || watchMapProv.mode == Modes.navigation){
      markerId = 'temp';
      tempMarker = Marker(
        markerId: MarkerId(markerId),
        position: location!.coordinates,
        icon: tempMarkerIcon!,
        onTap: () async {
          await showMarkerDialog(location!, markerId!);
        },
      );
    }
    else if(watchMapProv.mode == Modes.waypointsSelection){
      readMapProv.waypoints.add(location!);
      markerId = '${readMapProv.waypoints.length - 1}';
    }
    readMapProv.updateDraggableScrollableSheetSizes();
    readNavigationProv.updateMapCameraPosition(target: location!.coordinates);
    updateTextInputs();

    showMarkerDialog(location, markerId!);
    setState(() {});
  }

  Future<void> updateMapMarkers() async {
    mapMarkers = {
      for (var (i, waypoint) in watchMapProv.waypoints.indexed)
        Marker(
          markerId: MarkerId('$i'),
          position: waypoint.coordinates,
          icon: enumeratedMarkersIcons[i],
          onTap: () async {
            await showMarkerDialog(waypoint, '$i');
          },
        )
    };
    if (watchUserProv.user != null && starMarkerIcon != null ) {
      mapMarkers.addAll(
        {
          for (var (i, favoriteLocation) in watchUserProv.user!.favoriteLocations.indexed)
            Marker(
              markerId: MarkerId('fl$i'),
              position: favoriteLocation.coordinates,
              icon: starMarkerIcon!,
              onTap: () async {
                await showMarkerDialog(favoriteLocation, 'fl$i');
              },
            )
        }
      );
    }
    if (watchMapProv.mode == Modes.routeSelection && tempMarker != null){
      mapMarkers.add(tempMarker!);
    }
  }

  Set<Polyline> getMapPolylines(){
    if (readMapProv.route == null){
      return {};
    }
    // polylines are drawed in order so the last one is the one being seen
    // so we are reversing it so the first path, the generated one, is on top
    Set<Polyline> polylines = {};
    int polyId = 0;
    for (var (i, option) in readMapProv.route!.pathOptions.indexed){
      for (var subPath in option){
        polylines.add(
          Polyline(
            polylineId: PolylineId(polyId.toString()),
            color: i == watchMapProv.selectedRouteOptionIndex ? MyColors.coldBlue : MyColors.paleBlue,
            jointType: JointType.round,
            endCap: Cap.roundCap,
            width: watchMapProv.mode == Modes.navigation ? 15 : i == watchMapProv.selectedRouteOptionIndex ? 7 : 5,
            points: subPath.polylinePoints,
          ),
        );
        polyId+=1;
      }
    }
    return polylines;
  }

  @override
  Widget build(BuildContext context) {
    
    readMapProv = context.read<MapProvider>(); // Just reads the provider's data
    watchMapProv = context.watch<MapProvider>(); // Listens/watches for changes on the provider's data

    readNavigationProv = context.read<NavigationProvider>();
    watchNavigationProv = context.watch<NavigationProvider>();

    readUserProv = context.read<UserProvider>();
    watchUserProv = context.watch<UserProvider>();

    updateMapMarkers();
    
    return watchMapProv.isLoading ? MyLoadingScreen() : Scaffold(
      backgroundColor: MyColors.white,
      body: SafeArea(
        child: Stack(
          alignment: AlignmentDirectional.topCenter,
          children: [
            GoogleMap(
              // padding: EdgeInsets.all(200),
              myLocationButtonEnabled: false,
              myLocationEnabled: true,
              zoomControlsEnabled: true,
              zoomGesturesEnabled: true,
              initialCameraPosition: CameraPosition(
                target: watchMapProv.origin!.coordinates,
                zoom: 15,
                tilt: 0.0,
              ),
              onMapCreated: (controller) {
                readMapProv.googleMapsController = controller;
              },
              cameraTargetBounds: CameraTargetBounds(
                // Limiting to only be able to navigate in these boundaries
                LatLngBounds(
                  northeast: LatLng(-12.08013, -76.98038),
                  southwest: LatLng(-12.11198, -77.06152),
                ),
              ),
              markers: mapMarkers,
              polylines: getMapPolylines(),
              onTap: (position) {
                if (readMapProv.mode == Modes.waypointsSelection){
                  readMapProv.clearRoute();
                }
              },
              onLongPress: (position) {
                dropMarker(latLngPoint: LatLng(position.latitude, position.longitude),);
                updateMapMarkers();
              },
              onCameraMoveStarted: () {
                // readNavigationProv.lockCameraOnCurrentPosition = false;
                if(readMapProv.mode != Modes.navigation) {
                  readMapProv.draggableSheetController.animateTo(
                    readMapProv.dssMinChildSize,
                    duration: Duration(milliseconds : 100),
                    curve: Curves.linearToEaseOut,
                  );
                }
              },
              onCameraMove: (position) {

              },
              onCameraIdle: () {
                readNavigationProv.isAnimating = false;
              },
            ),
            watchMapProv.mode != Modes.navigation ? Container() : NavigationOverlay(
              showFollowUpInstruction: false,
            ),
            mapOverlay(),
            DraggableScrollableSheet(
              controller: watchMapProv.draggableSheetController,
              initialChildSize: watchMapProv.dssMainChildSize,
              minChildSize: watchMapProv.dssMinChildSize,
              snapSizes: watchMapProv.dssSnapSizes,
              snap: true,
              builder: (context, scrollController) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 15.0),
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
                          margin: EdgeInsets.all(15),
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: MyColors.lightGrey,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
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

  Widget mapOverlay(){
    return Container(
      margin: EdgeInsets.only(bottom: 155, left: 15, right: 15, top: 15),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          watchMapProv.mode != Modes.navigation ? Row(
            children: [
              FloatingActionButton(
                heroTag: null,
                backgroundColor: MyColors.grey,
                onPressed: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfileScreen(
                        dropMarker: (selectedFavoriteLocation){
                          dropMarker(location: selectedFavoriteLocation);
                        },
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(10),
                  child: Image.asset(
                    'assets/user1.png',
                    color: MyColors.white,
                  ),
                ),
              ),
            ],
          ) : Container(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                heroTag: null,
                backgroundColor: MyColors.grey,
                onPressed: (){
                  if(readMapProv.mode == Modes.navigation){
                    readNavigationProv.lockCameraOnCurrentPosition = true;
                  } else {
                    readNavigationProv.updateMapCameraPosition();
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(10),
                  child: Image.asset(
                    'assets/thin-target.png',
                    color: MyColors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget draggableScrollableSheetContent(){
    if (watchMapProv.mode != Modes.navigation){
      return waypointsAndRouteSelectionContent();
    }
    else {
      return navigationContent();
    }
  }

  void exitNavigation(){
    readNavigationProv.cancelNavigation();
    
  }

  Widget navigationContent(){
    List<PathModel> currentRoute = watchMapProv.route!.pathOptions[0];
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              iconSize: 60,
              onPressed: exitNavigation,
              icon: Image.asset(
                'assets/cancel_icon.png',
                color: MyColors.red,
              ),
            ),
            Column(
              children: [
                Text('${(currentRoute[watchNavigationProv.currentSubPathIndex!].etaSeconds/60).toStringAsFixed(0)} mins', style: MyTextStyles.h1,),
                Text('${(currentRoute[watchNavigationProv.currentSubPathIndex!].distanceMeters/1000).toStringAsFixed(1)} km - eta time', style: MyTextStyles.h3,),
              ],
            ),
            IconButton(
              iconSize: 60,
              onPressed: () async {
                log('Alternative Routes not implemented :()');
                // await readNavigationProv.computeAlternativeRouteFromCurrentPosition();
                // await readMapProv.computeRoute();
                // draggableSheetController.animateTo(
                //   dssSnapSizes[0],
                //   duration: Duration(milliseconds : 100),
                //   curve: Curves.linearToEaseOut,
                // );
                // updateMapCameraPosition();
              },
              icon: Image.asset(
                'assets/alternative_routes_icon.png',
                color: MyColors.mainBlue,
              ),
            ),
          ],
        ),
        SizedBox(height: 10,),
        Divider(thickness: 2, height: 20,),
        dssComplementaryBottomContent(),          
      ],
    );
  }

  Widget waypointsAndRouteSelectionContent(){
    return Column(
      children: [
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
                flex: 8,
                child: Column(
                  children: [
                    // TextField(
                    //   controller: originInputController,
                    //   style: MyTextStyles.inputTextStyle,
                    //   readOnly: true,
                    //   keyboardType: TextInputType.streetAddress,
                    //   textAlignVertical: TextAlignVertical.center,
                    //   decoration: Templates.locationInputDecoration(
                    //     "Origen",
                    //     Container(
                    //       padding: EdgeInsets.all(10),
                    //       height: 10,
                    //       child: Image.asset(
                    //         'assets/thin-target.png',
                    //         color: MyColors.mainBlue,
                    //       ),
                    //     ),
                    //   ),
                    //   onTap: (){},
                    // ),
                    // SizedBox(height: 10,),
                    TextField(
                      controller: searchPlaceInputController,
                      style: MyTextStyles.inputTextStyle,
                      keyboardType: TextInputType.streetAddress,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: MyTextFieldStyles.mainInput(
                        hintText: "Buscar Ubicación",
                        prefixIcon: Container(
                          padding: EdgeInsets.all(10),
                          height: 10,
                          child: Image.asset(
                            'assets/marker.png',
                            color: MyColors.mainBlue,
                          ),
                        ),
                      ),
                      onTap: (){
                        readMapProv.draggableSheetController.animateTo(
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
              // Expanded(
              //   flex: 1,
              //   child: IconButton(
              //     icon: Icon(
              //       CupertinoIcons.arrow_2_squarepath,
              //       color: MyColors.grey,
              //       size: 30,
              //     ),
              //     onPressed: () {
              //       // if (origin != null && destination != null) {
              //       //   // swaping origin and destination
              //       //   final temp = origin;
              //       //   origin = destination;
              //       //   destination = temp;
              //       //   waypoints = [destination!];
              //       //   updateTextInputs();
              //       //   setState(() {});
              //       // }
              //     },
              //   ),
              // ),
            ],
          ),
        ),
        
        watchMapProv.mode == Modes.waypointsSelection && watchMapProv.waypoints.length > 1 ? Container(
          margin: EdgeInsets.symmetric(vertical: 17),
          height: 50,
          width: double.infinity,
          child: ElevatedButton(
            style: MyButtonStyles.primary,
            child: Text(
              'BUSCAR RUTAS',
              style: MyTextStyles.button1,
            ),
            onPressed: () async {
              if(readMapProv.waypoints.length > 0){
                await readMapProv.computeRoute();
                readMapProv.mode = Modes.routeSelection;
                readMapProv.updateDraggableScrollableSheetSizes();
                updateTextInputs();
              }
              else {
                Fluttertoast.showToast(
                  msg: "Defina al menos un punto de destino",
                  toastLength: Toast.LENGTH_LONG
                );
              }
            },
          ),
        ) : Container(),
        watchMapProv.searchResults.isNotEmpty ? ListView.builder(
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: searchPlaceInputController.text.isNotEmpty ? watchMapProv.searchResults.length : 0,
          itemBuilder: (context, index){
            return placeResultListTile(watchMapProv.searchResults[index]);
          },
        ) : Container(),
        SizedBox(height: 20),
        dssComplementaryBottomContent(),
      ],
    );
  }


  Widget dssComplementaryBottomContent(){
    if (watchMapProv.mode == Modes.routeSelection && watchMapProv.route != null){
      return ListView.separated(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: readMapProv.route!.pathOptions.length,
        itemBuilder: (context, index){
          return pathOptionTile(
            optionIndex: index,
            title: index == 0 ? 'Ruta óptima' : 'Ruta alternativa',
            titleColor: index == 0 ? MyColors.coldBlue : MyColors.paleBlue,
            outOfFocus: false,
          );
        },
        separatorBuilder: (context, index){
          return SizedBox(height: 13,);
        },
      );
    }
    else if (watchMapProv.mode == Modes.navigation && watchMapProv.route != null){
      return Container(
        //color: MyColors.red,
        height: 700, // ReorderableListView needs to be inside a Height Container, otherwise it rashes the app
        child: ReorderableListView(
          onReorder: (int oldIndex, int newIndex) async {
            if(newIndex > oldIndex) newIndex--;
            final waypoint = readMapProv.waypoints.removeAt(oldIndex);
            readMapProv.waypoints.insert(newIndex, waypoint);
            await readMapProv.computeRoute();
            setState(() {});
          },
          children: List.generate(
            watchMapProv.waypoints.length,
            (index) {
              return ListTile(
                key: Key(index.toString()),
                tileColor: MyColors.mainBlue,
                title: Text('${watchMapProv.waypoints[index].name}', style: MyTextStyles.h3,),
                trailing: Icon(Icons.drag_handle_rounded),
              );
            }
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

  Widget pathOptionTile({
    required int optionIndex,
    required String title,
    Color titleColor = MyColors.black,
    bool outOfFocus = false
  }) {
    // log(pathIndex.toString());
    // log(readMapProv.computedRoute!.paths[pathIndex].distanceMeters.toString());
    double totalEtaSeconds = 0;
    double totalDistanceMeters = 0;
    List<EdgeModel> totalEdges = [];
    for (var subPath in readMapProv.route!.pathOptions[optionIndex]){
      totalEdges.addAll(subPath.edges);
      totalEtaSeconds += subPath.etaSeconds;
      totalDistanceMeters += subPath.distanceMeters;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      foregroundDecoration: outOfFocus ? BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Color.fromARGB(106, 0, 0, 0),
        backgroundBlendMode: BlendMode.color,
      ) : null,
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
            flex: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: MyTextStyles.fontName,
                    fontWeight: FontWeight.w600,
                    fontSize: 19,
                    color: titleColor,
                  ),
                ),
                SizedBox(height: 10,),
                pathInfoGraphBar(
                  width: 180,
                  edges: totalEdges,
                  distance: totalDistanceMeters,
                ),
                SizedBox(height: 10,),
                Row(
                  children: [
                    routeTag(Icons.directions_bike, "Ciclovía", MyColors.turquoise),
                    SizedBox(width: 5),
                    routeTag(CupertinoIcons.car, "Autopista", MyColors.yellow),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${(totalEtaSeconds/60).toStringAsFixed(0)} mins',
                      style: MyTextStyles.h2,
                    ),
                    SizedBox(width: 10,),
                    Text(
                      '${(totalDistanceMeters/1000).toStringAsFixed(1)} km',
                      style: MyTextStyles.h3,
                    ),
                  ],
                ),
                SizedBox(height: 8,),
                Container(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    style: MyButtonStyles.primary,
                    child: Text('INICIAR RUTA', style: MyTextStyles.button2),
                    onPressed: () async {
                      if(optionIndex == 1){
                        await showDialog(
                          context: context,
                          builder: (context){
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 30,
                              title: Text('Ruta Insegura', style: MyTextStyles.h1,),
                              content: Text(
                                'La ruta seleccionada es menos segura, ¿Desea continuar con esta ruta?',
                                style: MyTextStyles.h3,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: (){
                                    Navigator.pop(context);
                                    return;
                                  },
                                  child: Text('No', style: MyTextStyles.outlinedRed,),
                                ),
                                TextButton(
                                  onPressed: (){
                                    Navigator.pop(context);
                                    startRoute(optionIndex);
                                  },
                                  child: Text('Si', style: MyTextStyles.outlined,),
                                ),
                              ],
                            );
                          },
                        );
                      }
                      else {
                        startRoute(optionIndex);
                      }
                      
                    },
                  ),
                ),
              ],
            ),
          ), 
        ],
      ),
    );
  }

  void startRoute(int optionIndex){
    // Removing the rest of unselected routes, just to leave the selected one
    readMapProv.route!.pathOptions = [readMapProv.route!.pathOptions[optionIndex]];
    // Since we only hace one path in paths, this will get that polyline
    readNavigationProv.polylines = getMapPolylines().toList();

    readMapProv.mode = Modes.navigation;
    readMapProv.updateDraggableScrollableSheetSizes();
    readNavigationProv.startNavigation();
  }

  Widget pathInfoGraphBar({
    required double width,
    required double distance,
    required List<EdgeModel> edges,
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
        edges.length,
        (index) => Container(
          height: 12,
          width: edges[index].attributes['length']/distance*width,

          decoration: BoxDecoration(
            color: 
            edges[index].attributes['cycleway_level'] != '0' ? MyColors.turquoise : 
            // int.parse(edges[index].attributes['maxspeed'] ?? '0') >= 40 ? MyColors.red : 
            MyColors.yellow,

            borderRadius: 
              index == 0 ? BorderRadius.only(
                topLeft: Radius.circular(cornersRadius),
                bottomLeft: Radius.circular(cornersRadius),
              ) : index == edges.length-1 ? BorderRadius.only(
                topRight: Radius.circular(cornersRadius),
                bottomRight: Radius.circular(cornersRadius),
              ) : BorderRadius.zero
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
          Icon(icon, color: color, size: 14,),
          SizedBox(width: 5,),
          Text(
            label, 
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
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
          
          setState(() {});   
          dropMarker(location: place);
          searchPlaceInputController.text = '';
          updateTextInputs();
          readMapProv.updateDraggableScrollableSheetSizes();
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


  Future<void> showMarkerDialog(dynamic location, String markerId) async {

    handleMarkerDeletion() async {
      Navigator.pop(context);
      if(markerId == 'temp'){
        tempMarker = null;
      }
      else {
        if (int.parse(markerId) == readMapProv.waypoints.length - 1){
          // If we are removing the last waypoint we can safely just took out the last subpath
          readMapProv.waypoints.removeAt(int.parse(markerId));
          if (readMapProv.route != null){
            readMapProv.route!.waypoints.removeAt(int.parse(markerId));
            for(var pathOpt in readMapProv.route!.pathOptions){
              pathOpt.removeLast();
            }
          }
        } else {
          readMapProv.waypoints.removeAt(int.parse(markerId));
          if (readMapProv.waypoints.length != 0 && readMapProv.mode != Modes.waypointsSelection){
            await readMapProv.computeRoute();
          }
        }

        // Clean up
        if (readMapProv.waypoints.length == 0){
          readMapProv.route = null;
          readMapProv.mode = Modes.waypointsSelection;
        } 
        
        readMapProv.updateDraggableScrollableSheetSizes(forceAnimationToMainSize: true);
      }
      setState(() {});
    }

    List<Widget> actions = [];
    if (watchMapProv.mode == Modes.waypointsSelection){
      if(watchMapProv.waypoints.length == 1 || location is FavoriteLocationModel){
        actions.add(
          Container(
            width: double.infinity,
            child: ElevatedButton(
              style: MyButtonStyles.primaryNoElevation,
              child: Text('Buscar Rutas', style: MyTextStyles.button2,),
              onPressed: () async {
                Navigator.pop(context);
                location is FavoriteLocationModel ? readMapProv.waypoints.add(location):(){};
                await readMapProv.computeRoute();
                readMapProv.mode = Modes.routeSelection;
                readMapProv.updateDraggableScrollableSheetSizes();
                updateTextInputs();
              },
            ),
          ),
        );
      }
    }
    if(watchMapProv.mode != Modes.waypointsSelection && markerId == 'temp'){
      actions.add(
        Container(
          width: double.infinity,
          child: OutlinedButton(
            style: MyButtonStyles.outlined,
            child: Text('Añadir destino', style: MyTextStyles.outlined,),
            onPressed: () async {
              Navigator.pop(context);
              readMapProv.waypoints.add(location);
              await readMapProv.computeRoute();
              if(readMapProv.mode == Modes.navigation){
                startRoute(0); // always start on the first one
              }
              readMapProv.updateDraggableScrollableSheetSizes(forceAnimationToMainSize: true);
            },
          ),
        ),
      );
    }
    if(location is !FavoriteLocationModel){
      actions.add(
        Container(
          width: double.infinity,
          child: OutlinedButton(
            style: MyButtonStyles.outlinedRed,
            onPressed: handleMarkerDeletion,
            child: Text('Eliminar Marcador', style: MyTextStyles.outlinedRed,),
          ),
        ),
      );
    }

    return await showDialog(
      anchorPoint: Offset(double.maxFinite, 0),
      barrierColor: Color(0x00000000),
      context: context,
      builder: (context) {
        double dialogContentWidth = 280;
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
            Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 30,
              insetPadding: EdgeInsets.only(top: 220), // NO TOCAR
              // contentPadding: EdgeInsets.only(left: 20, top: 15, right: 20),
              // actionsPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Wrap(
                  direction: Axis.vertical,
                  children: [
                    Container(
                      width: dialogContentWidth,
                      child: Text(
                        location is FavoriteLocationModel ? location.alias : location.name ?? 'Sin nombre',
                        style: MyTextStyles.h1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      width: dialogContentWidth,
                      child: Text(
                        location.address ?? 'Dirección desconocida',
                        style: MyTextStyles.h3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: 15,),
                    Container(
                      width: dialogContentWidth,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          watchUserProv.user != null ? IconButton(
                            padding: EdgeInsets.only(right: 15),
                            iconSize: 40,
                            icon: Image.asset(
                              location is FavoriteLocationModel ? 'assets/starred.png' : 'assets/outlined_star.png',
                              color: MyColors.purple,
                            ),
                            onPressed: (){
                              if(location is FavoriteLocationModel){
                                readUserProv.deleteFavoriteLocation(location.id!);
                                Navigator.pop(context);
                              } else {
                                readUserProv.addFavoriteLocation(
                                  FavoriteLocationModel(
                                    coordinates: location.coordinates,
                                    name: location.name,
                                    address: location.address,
                                  ),
                                );
                                handleMarkerDeletion(); // this one already pops out of the dialog
                              }
                            },
                          ) : SizedBox(),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: actions,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}