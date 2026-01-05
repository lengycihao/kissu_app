import 'package:kissu_app/network/http_managerN.dart';
import 'package:kissu_app/network/http_resultN.dart';
import 'package:kissu_app/network/enum/cache_control.dart';
import 'package:kissu_app/network/public/api_request.dart';
import 'package:kissu_app/utils/debug_util.dart';
import 'package:kissu_app/models/usage_record_api_model.dart'
    as usage_record_model;

/// 首页数据响应模型
class IndexResponseModel {
  final int isRedDot;
  final int isSystemNoticeRedDot;
  final int isInteractionNoticeRedDot;
  final ActivityData activity;
  final LocationData location;
  final UserData user;
  final PhotoData photo;
  final WeatherData weather;
  final VipData? vipData;
  final usage_record_model.HalfUserData? halfUserData;
  final CrapGameData? crapGame;
  final SeedingData? seeding;

  IndexResponseModel({
    required this.isRedDot,
    required this.isSystemNoticeRedDot,
    required this.isInteractionNoticeRedDot,
    required this.activity,
    required this.location,
    required this.user,
    required this.photo,
    required this.weather,
    this.vipData,
    this.halfUserData,
    this.crapGame,
    this.seeding,
  });

  factory IndexResponseModel.fromJson(Map<String, dynamic> json) {
    return IndexResponseModel(
      isRedDot: json['is_red_dot'] ?? 0,
      isSystemNoticeRedDot: json['is_system_notice_red_dot'] ?? 0,
      isInteractionNoticeRedDot: json['is_interaction_notice_red_dot'] ?? 0,
      activity: ActivityData.fromJson(json['activity'] ?? {}),
      location: LocationData.fromJson(json['location'] ?? {}),
      user: UserData.fromJson(json['user'] ?? {}),
      photo: PhotoData.fromJson(json['photo'] ?? {}),
      weather: WeatherData.fromJson(json['weather'] ?? {}),
      vipData: json['vip_data'] != null
          ? VipData.fromJson(json['vip_data'])
          : null,
      halfUserData: json['half_user_data'] != null
          ? usage_record_model.HalfUserData.fromJson(
              json['half_user_data'] as Map<String, dynamic>)
          : null,
      crapGame: json['crap_game'] != null
          ? CrapGameData.fromJson(json['crap_game'] as Map<String, dynamic>)
          : null,
      seeding: json['seeding'] != null
          ? SeedingData.fromJson(json['seeding'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// 活动数据模型
class ActivityData {
  final int isPopAds;
  final int watchAdsNums;
  final int isAdsExempt;
  final int isAdsCountDown;
  final int adsCountDown;
  final int isActivity;
  final String isActivityIcon;
  final String activityLink;
  final String activityTitle;

  ActivityData({
    required this.isPopAds,
    required this.watchAdsNums,
    required this.isAdsExempt,
    required this.isAdsCountDown,
    required this.adsCountDown,
    required this.isActivity,
    required this.isActivityIcon,
    required this.activityLink,
    required this.activityTitle,
  });

  factory ActivityData.fromJson(Map<String, dynamic> json) {
    return ActivityData(
      isPopAds: json['is_pop_ads'] ?? 0,
      watchAdsNums: json['watch_ads_nums'] ?? 0,
      isAdsExempt: json['is_ads_exempt'] ?? 0,
      isAdsCountDown: json['is_ads_count_down'] ?? 0,
      adsCountDown: json['ads_count_down'] ?? 0,
      isActivity: json['is_activity'] ?? 0,
      isActivityIcon: json['is_activity_icon'] ?? '',
      activityLink: json['activity_link'] ?? '',
      activityTitle: json['activity_title'] ?? '',
    );
  }
}

/// 位置数据模型
class LocationData {
  final int stayCount;
  final String distance;
  final int travelTool; // 1=行走, 2=骑车, 3=坐车

  LocationData({
    required this.stayCount,
    required this.distance,
    required this.travelTool,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      stayCount: json['stay_count'] ?? 0,
      distance: json['distance'] ?? '未知',
      travelTool: json['travel_tool'] ?? 1, // 默认为行走
    );
  }
}

/// 用户数据模型
class UserData {
  final int loverDays;
  final String headPortrait;
  final String halfHeadPortrait;
  final int isBind;

  UserData({
    required this.loverDays,
    required this.headPortrait,
    required this.halfHeadPortrait,
    required this.isBind,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      loverDays: json['lover_days'] ?? 0,
      headPortrait: json['head_portrait'] ?? '',
      halfHeadPortrait: json['half_head_portrait'] ?? '',
      isBind: json['is_bind'] ?? 0,
    );
  }
}

/// 照片数据模型
class PhotoData {
  final String photoWall;

  PhotoData({required this.photoWall});

  factory PhotoData.fromJson(Map<String, dynamic> json) {
    return PhotoData(photoWall: json['photo_wall'] ?? '');
  }
}

/// VIP数据模型
class VipData {
  final int type;
  final String desc;
  final int expireDays;

  VipData({required this.type, required this.desc, required this.expireDays});

  factory VipData.fromJson(Map<String, dynamic> json) {
    return VipData(
      type: json['type'] ?? 0,
      desc: json['desc'] ?? '',
      expireDays: json['expireDays'] ?? 0,
    );
  }
}

/// 拉屎游戏数据模型
class CrapGameData {
  final String crapLink;
  final String crapStatus; // "1"展示 "0"不展示

  CrapGameData({
    required this.crapLink,
    required this.crapStatus,
  });

  factory CrapGameData.fromJson(Map<String, dynamic> json) {
    return CrapGameData(
      crapLink: json['crap_link'] ?? '',
      crapStatus: json['crap_status'] ?? '0',
    );
  }
}

/// 种草数据模型
class SeedingData {
  final String seedingLink;
  final String seedingStatus; // "1"展示 "0"不展示
  final String seedingIcon;

  SeedingData({
    required this.seedingLink,
    required this.seedingStatus,
    required this.seedingIcon,
  });

  factory SeedingData.fromJson(Map<String, dynamic> json) {
    return SeedingData(
      seedingLink: json['seeding_link'] ?? '',
      seedingStatus: json['seeding_status'] ?? '0',
      seedingIcon: json['seeding_icon'] ?? '',
    );
  }
}

/// 天气数据模型
class WeatherData {
  final List<WeatherBase> base;
  final List<WeatherAll> all;

  WeatherData({required this.base, required this.all});

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      base:
          (json['base'] as List?)
              ?.map((e) => WeatherBase.fromJson(e))
              .toList() ??
          [],
      all:
          (json['all'] as List?)?.map((e) => WeatherAll.fromJson(e)).toList() ??
          [],
    );
  }
}

/// 基础天气数据
class WeatherBase {
  final String province;
  final String city;
  final String adcode;
  final String weather;
  final String temperature;
  final String winddirection;
  final String windpower;
  final String humidity;
  final String reporttime;
  final String temperatureFloat;
  final String humidityFloat;
  final String weatherIcon;

  WeatherBase({
    required this.province,
    required this.city,
    required this.adcode,
    required this.weather,
    required this.temperature,
    required this.winddirection,
    required this.windpower,
    required this.humidity,
    required this.reporttime,
    required this.temperatureFloat,
    required this.humidityFloat,
    required this.weatherIcon,
  });

  factory WeatherBase.fromJson(Map<String, dynamic> json) {
    return WeatherBase(
      province: json['province'] ?? '',
      city: json['city'] ?? '',
      adcode: json['adcode'] ?? '',
      weather: json['weather'] ?? '',
      temperature: json['temperature'] ?? '',
      winddirection: json['winddirection'] ?? '',
      windpower: json['windpower'] ?? '',
      humidity: json['humidity'] ?? '',
      reporttime: json['reporttime'] ?? '',
      temperatureFloat: json['temperature_float'] ?? '',
      humidityFloat: json['humidity_float'] ?? '',
      weatherIcon: json['weather_icon'] ?? '',
    );
  }
}

/// 详细天气数据
class WeatherAll {
  final String city;
  final String adcode;
  final String province;
  final String reporttime;
  final List<WeatherCast> casts;

  WeatherAll({
    required this.city,
    required this.adcode,
    required this.province,
    required this.reporttime,
    required this.casts,
  });

  factory WeatherAll.fromJson(Map<String, dynamic> json) {
    return WeatherAll(
      city: json['city'] ?? '',
      adcode: json['adcode'] ?? '',
      province: json['province'] ?? '',
      reporttime: json['reporttime'] ?? '',
      casts:
          (json['casts'] as List?)
              ?.map((e) => WeatherCast.fromJson(e))
              .toList() ??
          [],
    );
  }
}

/// 天气预报数据
class WeatherCast {
  final String date;
  final String week;
  final String dayweather;
  final String nightweather;
  final String daytemp;
  final String nighttemp;
  final String daywind;
  final String nightwind;
  final String daypower;
  final String nightpower;
  final String daytempFloat;
  final String nighttempFloat;

  WeatherCast({
    required this.date,
    required this.week,
    required this.dayweather,
    required this.nightweather,
    required this.daytemp,
    required this.nighttemp,
    required this.daywind,
    required this.nightwind,
    required this.daypower,
    required this.nightpower,
    required this.daytempFloat,
    required this.nighttempFloat,
  });

  factory WeatherCast.fromJson(Map<String, dynamic> json) {
    return WeatherCast(
      date: json['date'] ?? '',
      week: json['week'] ?? '',
      dayweather: json['dayweather'] ?? '',
      nightweather: json['nightweather'] ?? '',
      daytemp: json['daytemp'] ?? '',
      nighttemp: json['nighttemp'] ?? '',
      daywind: json['daywind'] ?? '',
      nightwind: json['nightwind'] ?? '',
      daypower: json['daypower'] ?? '',
      nightpower: json['nightpower'] ?? '',
      daytempFloat: json['daytemp_float'] ?? '',
      nighttempFloat: json['nighttemp_float'] ?? '',
    );
  }
}

class IndexApi {
  /// 获取首页所有数据
  /// 包含红点信息、活动信息、位置信息、用户信息、照片信息、天气信息
  Future<HttpResultN<IndexResponseModel>> getIndexData() async {
    try {
      DebugUtil.info('🏠 开始请求首页数据...');

      final result = await HttpManagerN.instance.executeGet(
        ApiRequest.index,
        paramEncrypt: false,
        networkDebounce: false, // 首页请求不去抖，确保实时性
        cacheControl: CacheControl.noCache, // 首页数据不使用缓存，确保最新
      );

      if (result.isSuccess) {
        final rawJson = result.getDataJson();
        DebugUtil.success('🏠 首页数据请求成功');
        DebugUtil.info('首页数据结构: ${rawJson.keys.toList()}');

        return result.convert(data: IndexResponseModel.fromJson(rawJson));
      } else {
        DebugUtil.error('🏠 首页数据请求失败: ${result.msg}');
        return result.convert();
      }
    } catch (e, stackTrace) {
      DebugUtil.error('🏠 首页数据请求异常: $e');
      DebugUtil.error('堆栈信息: $stackTrace');
      return HttpResultN.failure(-1, '首页数据加载失败: $e');
    }
  }
}
