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
  static ButtonStyle secondary = ElevatedButton.styleFrom(
    elevation: 0,
    backgroundColor: MyColors.mainBlue,
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
    fontSize: 23,
    color: MyColors.black,
  );
  static const TextStyle h2 = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w500,
    fontSize: 20,
    color: MyColors.black,
  );
  static const TextStyle h3 = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w400,
    fontSize: 17,
    color: MyColors.black,
  );
  static const TextStyle h4 = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w300,
    fontSize: 15,
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
    letterSpacing: 1.25,
    color: MyColors.white,
  );

  static const TextStyle button2 = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w600,
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
        prefixIcon: Icon(icon, color: MyColors.grey),
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
