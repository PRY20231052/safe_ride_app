// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:safe_ride_app/providers/navigation_provider.dart';
import 'package:safe_ride_app/providers/map_provider.dart';
import 'package:safe_ride_app/providers/user_provider.dart';
import 'package:safe_ride_app/screens/map_screen.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => MapProvider()),
        ChangeNotifierProxyProvider<MapProvider, NavigationProvider>(
          create: (context) => NavigationProvider(),
          update: (context, mapProvider, navigationProvider) {
            navigationProvider!.mapProvider = mapProvider;
            return navigationProvider;
          },
        ),
      ],
      child: MyApp(),
    ),
  );
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
