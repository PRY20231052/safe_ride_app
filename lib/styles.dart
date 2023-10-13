// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

class MyColors {
  static const Color mainBlue = Color.fromARGB(255, 75, 161, 238);
  static const Color secondary = Color.fromARGB(255, 29, 29, 27);
  
  static const Color paleBlue = Color.fromARGB(255, 132, 167, 207);
  static const Color mildBlue = Color.fromARGB(255, 64, 128, 203);
  static const Color coldBlue = Color.fromARGB(255, 32, 95, 172);
  static const Color red = Color.fromARGB(255, 229, 89, 89);
  static const Color yellow = Color.fromARGB(255, 242, 206, 80);
  static const Color turquoise = Color.fromARGB(255, 72, 203, 171);
  static const Color darkTurquoise = Color.fromARGB(255, 0, 194, 145);
  static const Color purple = Color.fromARGB(255, 179, 130, 209);

  static const Color black = Color.fromARGB(255, 0, 0, 0);
  static const Color grey = Color.fromARGB(255, 92, 92, 92);
  static const Color lightGrey = Color.fromARGB(255, 231, 231, 231);
  static const Color lightestGrey = Color.fromARGB(255, 248, 248, 248);
  static const Color white = Color.fromARGB(255, 255, 255, 255);
}

class MyButtonStyles {
  static ButtonStyle primary = ElevatedButton.styleFrom(
    backgroundColor: MyColors.mainBlue,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  );
  static ButtonStyle primaryNoElevation = ElevatedButton.styleFrom(
    elevation: 0,
    backgroundColor: MyColors.mainBlue,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  );
  static ButtonStyle outlined = OutlinedButton.styleFrom(
    elevation: 0,
    side: BorderSide(width: 1.5, color: MyColors.mainBlue),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );
  static ButtonStyle outlinedRed = OutlinedButton.styleFrom(
    elevation: 0,
    side: BorderSide(width: 1.5, color: MyColors.red),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ); 
}

class MyTextStyles {

  static const String fontName = 'Poppins';

  static const TextStyle head = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.bold,
    fontSize: 64,
    letterSpacing: 0.8,
    color: MyColors.mainBlue,
  );

  static const TextStyle title = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.bold,
    fontSize: 24,
    letterSpacing: 0.18,
    color: MyColors.mainBlue,
  );
  static const TextStyle h1 = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w600,
    fontSize: 25,
    color: MyColors.black,
  );
  static const TextStyle h2 = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w500,
    fontSize: 21,
    color: MyColors.black,
  );
  static const TextStyle h3 = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w400,
    fontSize: 18,
    color: MyColors.black,
  );
  static const TextStyle h4 = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w300,
    fontSize: 16,
    color: MyColors.black,
  );
  static const TextStyle body = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w200,
    fontSize: 13,
    color: MyColors.grey,
  );

  static const TextStyle button1 = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w700,
    fontSize: 18,
    letterSpacing: 1,
    color: MyColors.white,
  );

  static const TextStyle button2 = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    letterSpacing: 0.5,
    color: MyColors.white,
  );
  static const TextStyle outlined = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    letterSpacing: 0.5,
    color: MyColors.mainBlue,
  );
  static const TextStyle outlinedRed = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    letterSpacing: 0.5,
    color: MyColors.red,
  );

  static const TextStyle hintTextStyle = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    color: MyColors.grey,
  );

  static const TextStyle inputTextStyle = TextStyle(
    fontFamily: MyTextStyles.fontName,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    color: MyColors.black,
  );
}

class MyTextFieldStyles {
  
  static InputDecoration mainInput({String? hintText, Widget? prefixIcon}) => 
  InputDecoration(
    filled: true,
    fillColor: MyColors.lightestGrey,
    contentPadding: EdgeInsets.symmetric(horizontal: 20), //to avoid oversizing when putting border
    prefixIcon: prefixIcon,
    hintText: hintText,
    hintStyle: MyTextStyles.hintTextStyle,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(25),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(25),
      borderSide: BorderSide(
        color: MyColors.grey,
        width: 2,
      ),
    ),
  );
}
