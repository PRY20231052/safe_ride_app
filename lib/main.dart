// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:safe_ride_app/screens/loading_screen.dart';
import 'package:safe_ride_app/screens/map_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: MapScreen(),
    );
  }
}
