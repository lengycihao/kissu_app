import 'package:flutter/material.dart';

class LocaleConstants {
  static Locale locale = const Locale('en', 'US');

  static String get localeName =>
      '${locale.languageCode}_${locale.countryCode}';
}
