// ignore_for_file: avoid_unnecessary_containers, prefer_const_constructors, must_be_immutable, prefer_const_literals_to_create_immutables

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safe_ride_app/providers/map_provider.dart';
import 'package:safe_ride_app/providers/navigation_provider.dart';
import '../styles.dart';

class NavigationOverlay extends StatelessWidget {

  late NavigationProvider readNavigationProv;
  late NavigationProvider watchNavigationProv;
  late MapProvider readMapProv;
  late MapProvider watchMapProv;

  bool showFollowUpInstruction;
  Color mainSignColor;
  Color followUpSignColor;
  double cornerRadius;

  NavigationOverlay({
    super.key,
    this.showFollowUpInstruction = false,
    this.mainSignColor = MyColors.mildBlue,
    this.followUpSignColor = MyColors.coldBlue,
    this.cornerRadius = 15
  });

  @override
  Widget build(BuildContext context) {
    readNavigationProv = context.read<NavigationProvider>();
    watchNavigationProv = context.watch<NavigationProvider>();
    readMapProv = context.read<MapProvider>();
    watchMapProv = context.watch<MapProvider>();

    return Container(
      padding: EdgeInsets.all(15),
      child: Column(
        children: [
          directionsSignWidget(),

          SizedBox(height: MediaQuery.of(context).size.height - 310,),
          IntrinsicWidth(
            child: Material(
              elevation: 3.5,
              borderRadius: BorderRadius.circular(15),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 13),
                decoration: BoxDecoration(
                  color: MyColors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    width: 2,
                    color: MyColors.lightGrey,
                  ),
                ),
                child: Center(
                  child: Text(
                    watchMapProv.computedRoute!.paths[0].directions[watchNavigationProv.directionIndex!].streetName,
                    style: TextStyle(
                      fontFamily: MyTextStyles.fontName,
                      fontWeight: FontWeight.w500,
                      fontSize: 20,
                      color: MyColors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget getDirectionImg(){
    switch(watchMapProv.computedRoute!.paths[0].directions[watchNavigationProv.directionIndex!].endingAction){
      case 'turn_left':
        return Image.asset('assets/turn_left.png', color: MyColors.white,);
      
      case 'turn_right':
        return Image.asset('assets/turn_right.png', color: MyColors.white,);
      
      case 'go_straight':
        return Image.asset('assets/go_straight.png', color: MyColors.white,);
    }
    return SizedBox();
  }

  Widget directionsSignWidget(){
    String nextStreetName = "";
    if (watchNavigationProv.directionIndex! >= watchMapProv.computedRoute!.paths[0].directions.length - 1){
      nextStreetName = 'Llegando a tu destino';
    } else {
      nextStreetName = watchMapProv.computedRoute!.paths[0].directions[watchNavigationProv.directionIndex! + 1].streetName;
    }
    return Material(
      elevation: 5,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(cornerRadius),
        topRight: Radius.circular(cornerRadius),
        bottomRight: Radius.circular(cornerRadius),
        bottomLeft: showFollowUpInstruction ? Radius.zero : Radius.circular(cornerRadius)
      ),
      child: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(15),
              height: 100,
              decoration: BoxDecoration(
                color: mainSignColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(cornerRadius),
                  topRight: Radius.circular(cornerRadius),
                  bottomRight: Radius.circular(cornerRadius),
                  bottomLeft: showFollowUpInstruction ? Radius.zero : Radius.circular(cornerRadius)
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: getDirectionImg(),
                  ),
                  SizedBox(width: 15,),
                  Expanded(
                    flex: 7,
                    child: Container(
                      child: Text(
                        nextStreetName,
                        style: TextStyle(
                          fontFamily: MyTextStyles.fontName,
                          fontWeight: FontWeight.w600,
                          fontSize: 25,
                          color: MyColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),                    
            ),
            showFollowUpInstruction ? Container(
              padding: EdgeInsets.all(15),
              height: 60,
              width: 150,
              decoration: BoxDecoration(
                color: followUpSignColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 30,
                      color: MyColors.turquoise,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: 30,
                      color: MyColors.purple,
                    ),
                  ),
                ],
              ),
            ): Container(),
          ],
        ),
      ),
    );
  }
}