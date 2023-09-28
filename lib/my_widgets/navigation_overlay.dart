// ignore_for_file: avoid_unnecessary_containers, prefer_const_constructors, must_be_immutable, prefer_const_literals_to_create_immutables

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safe_ride_app/providers/navigation_provider.dart';
import '../styles.dart';

class NavigationOverlay extends StatelessWidget {

  late NavigationProvider readNavigationProv;
  late NavigationProvider watchNavigationProv;

  Widget mainInstructionImg;
  bool showFollowUpInstruction;
  String? followUpInstruction;
  Widget? followUpInstructionImg;
  Color mainSignColor;
  Color followUpSignColor;
  double cornerRadius;

  NavigationOverlay({
    super.key,
    required this.mainInstructionImg,
    this.showFollowUpInstruction = false,
    this.followUpInstruction,
    this.followUpInstructionImg,
    this.mainSignColor = MyColors.mildBlue,
    this.followUpSignColor = MyColors.coldBlue,
    this.cornerRadius = 15
  });

  @override
  Widget build(BuildContext context) {
    readNavigationProv = context.read<NavigationProvider>();
    watchNavigationProv = context.watch<NavigationProvider>();

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
                    watchNavigationProv.route!.paths[0].edges[watchNavigationProv.pathCurrentIndex].attributes['name'] ?? 'Calle Desconocida',
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
  Widget directionsSignWidget(){
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
                    child: mainInstructionImg,
                  ),
                  Expanded(
                    flex: 7,
                    child: Container(
                      child: Text(
                        watchNavigationProv.route!.paths[0].edges[watchNavigationProv.pathCurrentIndex+1].attributes['name'] ?? 'Calle Desconocida',
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