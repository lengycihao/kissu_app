/// 天气数据模型
class WeatherModel {
  final WeatherBase? base;
  final WeatherAll? all;

  WeatherModel({
    this.base,
    this.all,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      base: json['base'] != null && (json['base'] as List).isNotEmpty
          ? WeatherBase.fromJson((json['base'] as List).first)
          : null,
      all: json['all'] != null && (json['all'] as List).isNotEmpty
          ? WeatherAll.fromJson((json['all'] as List).first)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'base': base != null ? [base!.toJson()] : [],
      'all': all != null ? [all!.toJson()] : [],
    };
  }
}

/// 基础天气数据
class WeatherBase {
  final String? province;
  final String? city;
  final String? adcode;
  final String? weather;
  final String? temperature;
  final String? winddirection;
  final String? windpower;
  final String? humidity;
  final String? reporttime;
  final String? temperatureFloat;
  final String? humidityFloat;
  final String? weatherIcon;

  WeatherBase({
    this.province,
    this.city,
    this.adcode,
    this.weather,
    this.temperature,
    this.winddirection,
    this.windpower,
    this.humidity,
    this.reporttime,
    this.temperatureFloat,
    this.humidityFloat,
    this.weatherIcon,
  });

  factory WeatherBase.fromJson(Map<String, dynamic> json) {
    return WeatherBase(
      province: json['province'] as String?,
      city: json['city'] as String?,
      adcode: json['adcode'] as String?,
      weather: json['weather'] as String?,
      temperature: json['temperature'] as String?,
      winddirection: json['winddirection'] as String?,
      windpower: json['windpower'] as String?,
      humidity: json['humidity'] as String?,
      reporttime: json['reporttime'] as String?,
      temperatureFloat: json['temperature_float'] as String?,
      humidityFloat: json['humidity_float'] as String?,
      weatherIcon: json['weather_icon'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'province': province,
      'city': city,
      'adcode': adcode,
      'weather': weather,
      'temperature': temperature,
      'winddirection': winddirection,
      'windpower': windpower,
      'humidity': humidity,
      'reporttime': reporttime,
      'temperature_float': temperatureFloat,
      'humidity_float': humidityFloat,
      'weather_icon': weatherIcon,
    };
  }
}

/// 天气预报数据
class WeatherAll {
  final String? city;
  final String? adcode;
  final String? province;
  final String? reporttime;
  final List<WeatherCast>? casts;

  WeatherAll({
    this.city,
    this.adcode,
    this.province,
    this.reporttime,
    this.casts,
  });

  factory WeatherAll.fromJson(Map<String, dynamic> json) {
    return WeatherAll(
      city: json['city'] as String?,
      adcode: json['adcode'] as String?,
      province: json['province'] as String?,
      reporttime: json['reporttime'] as String?,
      casts: json['casts'] != null
          ? (json['casts'] as List)
              .map((e) => WeatherCast.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'adcode': adcode,
      'province': province,
      'reporttime': reporttime,
      'casts': casts?.map((e) => e.toJson()).toList(),
    };
  }
}

/// 天气预报单日数据
class WeatherCast {
  final String? date;
  final String? week;
  final String? dayweather;
  final String? nightweather;
  final String? daytemp;
  final String? nighttemp;
  final String? daywind;
  final String? nightwind;
  final String? daypower;
  final String? nightpower;
  final String? daytempFloat;
  final String? nighttempFloat;

  WeatherCast({
    this.date,
    this.week,
    this.dayweather,
    this.nightweather,
    this.daytemp,
    this.nighttemp,
    this.daywind,
    this.nightwind,
    this.daypower,
    this.nightpower,
    this.daytempFloat,
    this.nighttempFloat,
  });

  factory WeatherCast.fromJson(Map<String, dynamic> json) {
    return WeatherCast(
      date: json['date'] as String?,
      week: json['week'] as String?,
      dayweather: json['dayweather'] as String?,
      nightweather: json['nightweather'] as String?,
      daytemp: json['daytemp'] as String?,
      nighttemp: json['nighttemp'] as String?,
      daywind: json['daywind'] as String?,
      nightwind: json['nightwind'] as String?,
      daypower: json['daypower'] as String?,
      nightpower: json['nightpower'] as String?,
      daytempFloat: json['daytemp_float'] as String?,
      nighttempFloat: json['nighttemp_float'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'week': week,
      'dayweather': dayweather,
      'nightweather': nightweather,
      'daytemp': daytemp,
      'nighttemp': nighttemp,
      'daywind': daywind,
      'nightwind': nightwind,
      'daypower': daypower,
      'nightpower': nightpower,
      'daytemp_float': daytempFloat,
      'nighttemp_float': nighttempFloat,
    };
  }
}

