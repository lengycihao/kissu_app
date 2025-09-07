import 'package:flutter/material.dart';

abstract class YYAppStyleColors {
  //
  //App主题色
  static const Color yyColorAppTheme = Color(0xffBA92FD);

  /*
   使用方法:
   var color1=YYAppStyleColors.yyColorWithHexString("#33428A43");
  */
  static Color yyColorWithHexString(String? hexString) {
    if (hexString == null) {
      return Colors.black;
    }
    hexString = hexString.replaceAll("#", "");
    if (hexString.length == 6) {
      return Color(int.parse(hexString, radix: 16) + 0xFF000000);
    } else if (hexString.length == 8) {
      return Color(int.parse(hexString, radix: 16));
    } else {
      return Colors.black;
    }
  }
}
