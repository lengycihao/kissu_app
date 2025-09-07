import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SpUtil {
  //Integer
  static Future<bool> putInteger(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setInt(key, value);
  }

  static Future<int> getInteger(String key, [int defaultValue = 0]) async {
    final prefs = await SharedPreferences.getInstance();
    var value = prefs.getInt(key);
    return value ?? defaultValue;
  }

  //String
  static Future<bool> putString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(key, value);
  }

  static Future<String> getString(
    String key, [
    String defaultValue = '',
  ]) async {
    final prefs = await SharedPreferences.getInstance();
    var value = prefs.getString(key);
    return value ?? defaultValue;
  }

  //Bool
  static Future<bool> putBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setBool(key, value);
  }

  static Future<bool> getBool(String key, [bool defaultValue = false]) async {
    final prefs = await SharedPreferences.getInstance();
    var value = prefs.getBool(key);
    return value ?? defaultValue;
  }

  //Double
  static Future<bool> putDouble(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setDouble(key, value);
  }

  static Future<double> getDouble(
    String key, [
    double defaultValue = 0.0,
  ]) async {
    final prefs = await SharedPreferences.getInstance();
    var value = prefs.getDouble(key);
    return value ?? defaultValue;
  }

  //StringList
  static Future<bool> putStringList(String key, List<String> value) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setStringList(key, value);
  }

  static Future<List<String>> getStringList(
    String key, [
    List<String> defaultValue = const <String>[],
  ]) async {
    final prefs = await SharedPreferences.getInstance();
    var value = prefs.getStringList(key);
    return value ?? defaultValue;
  }

  //Map
  static Future<bool> putJsonMap(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(key, jsonEncode(value));
  }

  static Future<dynamic> getJsonMap(String key) async {
    final prefs = await SharedPreferences.getInstance();
    String? value = prefs.getString(key);
    debugPrint('用户信息为--->' + (value ?? ""));
    return value == null ? null : jsonDecode(value);
  }

  static Future<bool> clear() async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.clear();
  }

  static Future<bool> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.remove(key);
  }
}
