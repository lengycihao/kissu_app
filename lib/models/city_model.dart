/// 城市数据模型
class CityModel {
  final String cityName;
  final String adcode;

  CityModel({
    required this.cityName,
    required this.adcode,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      cityName: json['city_name'] ?? '',
      adcode: json['adcode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'city_name': cityName,
      'adcode': adcode,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CityModel &&
        other.cityName == cityName &&
        other.adcode == adcode;
  }

  @override
  int get hashCode => cityName.hashCode ^ adcode.hashCode;
}

/// 城市分组模型（按首字母分组）
class CityGroupModel {
  final String firstLetter;
  final List<CityModel> cityList;

  CityGroupModel({
    required this.firstLetter,
    required this.cityList,
  });

  factory CityGroupModel.fromJson(Map<String, dynamic> json) {
    return CityGroupModel(
      firstLetter: json['first_letter'] ?? '',
      cityList: (json['city_list'] as List?)
              ?.map((item) => CityModel.fromJson(item))
              .toList() ??
          [],
    );
  }
}

/// 热门城市列表
class HotCitiesModel {
  final List<CityModel> hotCities;

  HotCitiesModel({required this.hotCities});

  factory HotCitiesModel.fromJson(Map<String, dynamic> json) {
    return HotCitiesModel(
      hotCities: (json['hot_cities'] as List?)
              ?.map((item) => CityModel.fromJson(item))
              .toList() ??
          [],
    );
  }
}

/// 城市列表响应模型
class CityListResponse {
  final List<CityGroupModel> region;
  final List<CityModel> hotCities;

  CityListResponse({
    required this.region,
    required this.hotCities,
  });

  factory CityListResponse.fromJson(Map<String, dynamic> json) {
    return CityListResponse(
      region: (json['region'] as List?)
              ?.map((item) => CityGroupModel.fromJson(item))
              .toList() ??
          [],
      hotCities: (json['hot_city'] as List?)
              ?.map((item) => CityModel.fromJson(item))
              .toList() ??
          [],
    );
  }
}

