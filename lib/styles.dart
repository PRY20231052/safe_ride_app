// ignore_for_file: prefer_const_constructors

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MyColors {
  static const Color mainTurquoise = Color(0xff69D3B9);
  static const Color secondary = Color(0xff1d1d1b);

  static const Color green = Color(0xff21c25f);
  static const Color red = Color(0xffE55959);
  static const Color yellow = Color(0xffE9C546);
  static const Color blue = Color(0xff3893E8);
  static const Color purple = Color(0xffB382D1);

  static const Color black = Color(0xff000000);
  static const Color darkGrey = Color(0xFF3A3A3A);
  static const Color grey = Color(0xFF818181);
  static const Color lightGrey = Color(0xFFE7E7E7);
  static const Color lightestGrey = Color(0xFFF8F8F8);
  static const Color white = Color(0xffffffff);
}

class MyButtonStyles {
  static ButtonStyle primary = ElevatedButton.styleFrom(
    backgroundColor: MyColors.mainTurquoise,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  );
  static ButtonStyle secondary = ElevatedButton.styleFrom(
    elevation: 0,
    backgroundColor: MyColors.mainTurquoise,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  );
}

class MyTextStyles {

  static const String fontName = 'Poppins';

  static const TextStyle head = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.bold,
    fontSize: 64,
    letterSpacing: 0.8,
    color: MyColors.mainTurquoise,
  );

  static const TextStyle title = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.bold,
    fontSize: 24,
    letterSpacing: 0.18,
    color: MyColors.mainTurquoise,
  );
  static const TextStyle h1 = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w500,
    fontSize: 26,
    color: MyColors.black,
  );
  static const TextStyle h2 = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w400,
    fontSize: 20,
    color: MyColors.black,
  );
  static const TextStyle h3 = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w300,
    fontSize: 18,
    color: MyColors.black,
  );
  static const TextStyle h4 = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w200,
    fontSize: 16,
    color: MyColors.black,
  );
  static const TextStyle body = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w100,
    fontSize: 14,
    color: MyColors.grey,
  );

  static const TextStyle primaryButton = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w700,
    fontSize: 16,
    letterSpacing: 1.25,
    color: MyColors.white,
  );

  static const TextStyle button2 = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    letterSpacing: 1.25,
    color: MyColors.white,
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

class Templates {
  
  // regular = 400 || medium = 500 || bold = 700
  static const EdgeInsets paddingTop = EdgeInsets.only(top: 20);
  static const EdgeInsets paddingBottom = EdgeInsets.only(bottom: 20);
  static const EdgeInsets paddingApp = EdgeInsets.all(24);
  static const EdgeInsets paddingHorizontal = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets paddingCard = EdgeInsets.all(16);

  static const OutlineInputBorder basicIB = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: MyColors.grey));
  static const OutlineInputBorder focusedIB = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: MyColors.secondary));

  static InputDecoration inputDecoration(text, IconData icon) =>
      InputDecoration(
        fillColor: MyColors.lightGrey,
        filled: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: basicIB,
        focusedBorder: focusedIB,
        border: basicIB,
        hintText: text,
        hintStyle: MyTextStyles.hintTextStyle,
        prefixIcon: Icon(icon, color: MyColors.darkGrey),
      );

  static TextField textField(
    TextEditingController controller,
    String text,
    IconData icon,
    keyboardType,
    onTap,
    obscure,
  ) => TextField(
    controller: controller,
    obscureText: obscure,
    style: MyTextStyles.body,
    keyboardType: keyboardType,
    decoration: inputDecoration(text, icon),
    readOnly: keyboardType == TextInputType.datetime ? true : false,
    onTap: onTap,
  );

  static InputDecoration locationInputDecoration(text, Container? prefixIcon) => 
  InputDecoration(
    filled: true,
    fillColor: MyColors.lightestGrey,
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
    contentPadding: EdgeInsets.symmetric(horizontal: 20), //to avoid oversizing when putting border
    prefixIcon: prefixIcon,
    hintText: text,
    hintStyle: MyTextStyles.hintTextStyle,
  );

  static TextField locationField(
    TextEditingController controller,
    String text,
    Container prefixIcon,
    TextInputType keyboardType,
    onTap,
  ) => TextField(
    controller: controller,
    style: MyTextStyles.inputTextStyle,
    readOnly: true,
    keyboardType: keyboardType,
    decoration: locationInputDecoration(text, prefixIcon),
    onTap: onTap,
  );

  static String uppercase(String text) {
    return text.toUpperCase();
  }
}
