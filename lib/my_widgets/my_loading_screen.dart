// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';

class MyLoadingScreen extends StatelessWidget {
  Color color;
  String label;
  MyLoadingScreen({
    super.key,
    this.color = Colors.black,
    this.label = "",
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Opacity(
          opacity: 0.8,
          child: ModalBarrier(
            color: color,
            dismissible: false,
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: CircularProgressIndicator(),
            ),
            Text(label),
          ],
        ),
      ],
    );
  }
}