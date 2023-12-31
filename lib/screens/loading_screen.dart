// ignore_for_file: prefer_const_constructors

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../styles.dart';
import 'user_profile_screen.dart';


class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});
  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}
class _LoadingScreenState extends State<LoadingScreen> {
  // bool loading = false;

  void _checkLoginStatus() {
    // setState(() {
    //   loading = true;
    // });
    // await Future.delayed(const Duration(seconds: 2));
    // setState(() {
    //   loading = false;
    // });
    Navigator.pushReplacement(
        context, CupertinoPageRoute(builder: (context) => const UserProfileScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      backgroundColor: MyColors.white,
      // body: loading ? LoadingEffect.loading: Center(
      body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Safe\nRide', style: MyTextStyles.head),
              SizedBox(height: MediaQuery.of(context).size.height * 0.1,),
              IconButton(onPressed: ()=> _checkLoginStatus(),
                  icon: const Icon(CupertinoIcons.arrow_right_circle_fill),
                  iconSize: 60, color: MyColors.mainBlue)
            ],
          )
      ),
    );
  }
}