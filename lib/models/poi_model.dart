/// POI数据模型（Point of Interest - 兴趣点）
class PoiModel {
  final String id;
  final String name;
  final String address;
  final String location; // 经纬度，格式：longitude,latitude
  final String adcode;
  final String cityname;
  final String? distance; // 距离中心点的距离（米）

  PoiModel({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.adcode,
    required this.cityname,
    this.distance,
  });

  /// 获取经度
  double get longitude {
    try {
      final parts = location.split(',');
      return double.parse(parts[0]);
    } catch (e) {
      return 0.0;
    }
  }

  /// 获取纬度
  double get latitude {
    try {
      final parts = location.split(',');
      return double.parse(parts[1]);
    } catch (e) {
      return 0.0;
    }
  }

  /// 获取格式化的距离文本
  String get distanceText {
    if (distance == null || distance!.isEmpty) return '';
    
    try {
      final meters = int.parse(distance!);
      if (meters < 1000) {
        return '${meters}m';
      } else {
        final km = (meters / 1000).toStringAsFixed(1);
        return '${km}km';
      }
    } catch (e) {
      return '';
    }
  }

  factory PoiModel.fromJson(Map<String, dynamic> json) {
    return PoiModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      location: json['location'] ?? '',
      adcode: json['adcode'] ?? '',
      cityname: json['cityname'] ?? '',
      distance: json['distance']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'location': location,
      'adcode': adcode,
      'cityname': cityname,
      'distance': distance,
    };
  }
}

