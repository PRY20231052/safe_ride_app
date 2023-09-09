// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:safe_ride_app/styles.dart';

class MyLoadingScreen extends StatelessWidget {

  Color backgroundColor;
  double backgroundOpacity;
  Color indicatorColor;
  String label;

  MyLoadingScreen({
    super.key,
    this.backgroundColor = Colors.white,
    this.backgroundOpacity = 1.0,
    this.indicatorColor = MyColors.mainTurquoise,
    this.label = "",
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Opacity(
          opacity: 0.8,
          child: ModalBarrier(
            color: backgroundColor,
            dismissible: false,
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: CircularProgressIndicator(color: indicatorColor,),
            ),
            Text(label),
          ],
        ),
      ],
    );
  }
}