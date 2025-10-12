import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kissu_app/models/city_model.dart';

/// 城市本地存储服务
/// 负责保存最近访问的城市列表（最多3个）
class CityStorageService extends GetxService {
  static const String _recentCitiesKey = 'recent_visited_cities';
  static const int _maxRecentCities = 3;

  late final SharedPreferences _prefs;

  /// 初始化服务
  Future<CityStorageService> init() async {
    _prefs = await SharedPreferences.getInstance();
    return this;
  }

  /// 获取最近访问的城市列表
  List<CityModel> getRecentCities() {
    try {
      final String? jsonString = _prefs.getString(_recentCitiesKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((item) => CityModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ 获取最近城市失败: $e');
      return [];
    }
  }

  /// 添加城市到最近访问列表
  /// 规则：
  /// 1. 如果城市已存在，将其移到第一位
  /// 2. 如果城市不存在，添加到第一位
  /// 3. 最多保存3个城市
  Future<bool> addRecentCity(CityModel city) async {
    try {
      List<CityModel> recentCities = getRecentCities();

      // 移除已存在的相同城市
      recentCities.removeWhere((c) => c.adcode == city.adcode);

      // 添加到列表开头
      recentCities.insert(0, city);

      // 只保留前3个
      if (recentCities.length > _maxRecentCities) {
        recentCities = recentCities.sublist(0, _maxRecentCities);
      }

      // 保存到本地
      final String jsonString =
          json.encode(recentCities.map((c) => c.toJson()).toList());
      return await _prefs.setString(_recentCitiesKey, jsonString);
    } catch (e) {
      debugPrint('❌ 保存最近城市失败: $e');
      return false;
    }
  }

  /// 清空最近访问的城市列表
  Future<bool> clearRecentCities() async {
    try {
      return await _prefs.remove(_recentCitiesKey);
    } catch (e) {
      debugPrint('❌ 清空最近城市失败: $e');
      return false;
    }
  }
}

