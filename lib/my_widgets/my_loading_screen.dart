// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, avoid_unnecessary_containers

import 'package:flutter/material.dart';
import 'package:safe_ride_app/styles.dart';

class MyLoadingScreen extends StatelessWidget {

  Color barrierColor;
  Color backgroundColor;
  double backgroundOpacity;
  Color indicatorColor;
  String label;

  MyLoadingScreen({
    super.key,
    this.barrierColor = Colors.white,
    this.backgroundColor = Colors.white,
    this.backgroundOpacity = 1.0,
    this.indicatorColor = MyColors.mainBlue,
    this.label = "",
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Opacity(
          opacity: backgroundOpacity,
          child: ModalBarrier(
            color: backgroundColor,
            dismissible: false,
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: MyColors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: indicatorColor,),
                    SizedBox(height: 10,),
                    Text(label, style: MyTextStyles.h2,),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}