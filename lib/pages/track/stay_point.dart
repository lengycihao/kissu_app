import 'package:x_amap_base/x_amap_base.dart';

/// 停留点数据模型
class StayPoint {
  final LatLng position;
  final String title;
  final String duration;
  final int index;

  const StayPoint({
    required this.position,
    required this.title,
    required this.duration,
    required this.index,
  });
}

/// 假数据（杭州地区）
const List<StayPoint> stayPoints = [
  StayPoint(
    position: LatLng(30.2641, 120.1651),
    title: "中豪五福天地",
    duration: "停留 45分钟",
    index: 1,
  ),
  StayPoint(
    position: LatLng(30.2521, 120.1771),
    title: "钱塘府",
    duration: "停留 30分钟",
    index: 2,
  ),
  StayPoint(
    position: LatLng(30.2741, 120.1551),
    title: "杭州东站",
    duration: "停留 20分钟",
    index: 3,
  ),
  StayPoint(
    position: LatLng(30.2581, 120.1711),
    title: "元宝塘",
    duration: "停留 1小时15分钟",
    index: 4,
  ),
  StayPoint(
    position: LatLng(30.2401, 120.1891),
    title: "星花庭路",
    duration: "停留 1小时5分钟",
    index: 5,
  ),
];

/// 测试数据 - 根据JSON结构创建的停留记录
final List<StopRecord> testStopRecords = [
  StopRecord(
    latitude: 30.274905327690973,
    longitude: 120.22095160590278,
    locationName: "浙江省杭州市上城区中豪·湘和国际",
    startTime: "23:59",
    endTime: "",
    duration: "",
    status: "",
    pointType: "end",
    serialNumber: "终",
  ),
  StopRecord(
    latitude: 30.27518744574653,
    longitude: 120.22067518446181,
    locationName: "浙江省杭州市上城区中豪湘悦中心",
    startTime: "23:03",
    endTime: "",
    duration: "56分钟",
    status: "staying",
    pointType: "stop",
    serialNumber: "1",
  ),
  StopRecord(
    latitude: 30.280328776041667,
    longitude: 120.22582980685763,
    locationName: "浙江省杭州市上城区云峰家园",
    startTime: "22:09",
    endTime: "22:26",
    duration: "17分钟1秒",
    status: "ended",
    pointType: "stop",
    serialNumber: "2",
  ),
  StopRecord(
    latitude: 30.27518744574653,
    longitude: 120.22067572699653,
    locationName: "浙江省杭州市上城区中豪·湘和国际",
    startTime: "21:44",
    endTime: "22:00",
    duration: "16分钟2秒",
    status: "ended",
    pointType: "stop",
    serialNumber: "3",
  ),
  StopRecord(
    latitude: 30.27518744574653,
    longitude: 120.22067572699653,
    locationName: "浙江省杭州市上城区中豪·湘和国际",
    startTime: "21:44",
    endTime: "",
    duration: "",
    status: "",
    pointType: "start",
    serialNumber: "起",
  ),
];

class StopRecord {
  final double latitude;
  final double longitude;
  final String locationName;
  final String startTime;
  final String endTime;
  final String duration;
  final String status; // "staying", "ended", 或空字符串
  final String pointType; // "start", "end", "stop"
  final String serialNumber; // "起", "终", "1", "2", "3"...
  
  // 计算出的显示字段
  final String time; // 时间文案
  final String leftTime; // 左边时间text
  final String stayDuration; // 文字文案

  StopRecord({
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.status,
    required this.pointType,
    required this.serialNumber,
  }) : 
    time = _calculateTimeText(pointType, status, startTime, endTime, duration),
    leftTime = _calculateLeftTime(pointType, startTime, endTime),
    stayDuration = _calculateStayDuration(pointType, status, duration);
  
  // 工厂构造函数，从JSON创建
  factory StopRecord.fromJson(Map<String, dynamic> json) {
    return StopRecord(
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      locationName: json['location_name'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      duration: json['duration'] ?? '',
      status: json['status'] ?? '',
      pointType: json['point_type'] ?? '',
      serialNumber: json['serial_number'] ?? '',
    );
  }
  
  // 计算时间文案
  static String _calculateTimeText(String pointType, String status, String startTime, String endTime, String duration) {
    switch (pointType) {
      case 'start':
        return startTime; // 时间文案显示 start_time
      case 'end':
        return endTime; // 时间文案显示 end_time
      case 'stop':
        if (status == 'ended') {
          return '$startTime ~ $endTime'; // 时间文案显示 start_time ~ end_time
        } else if (status == 'staying') {
          return '已停留$duration'; // 时间文案显示 已停留+duration
        }
        break;
    }
    return '';
  }
  
  // 计算左边时间text
  static String _calculateLeftTime(String pointType, String startTime, String endTime) {
    switch (pointType) {
      case 'start':
        return startTime; // 左边时间text 显示 start_time
      case 'end':
        return endTime; // 左边时间text 显示 end_time
      case 'stop':
        return endTime; // 左边时间text 显示 end_time
    }
    return '';
  }
  
  // 计算文字文案
  static String _calculateStayDuration(String pointType, String status, String duration) {
    switch (pointType) {
      case 'start':
        return ''; // 文字文案不显示
      case 'end':
        return ''; // 文字文案显示空（根据需求可能需要调整）
      case 'stop':
        if (status == 'ended') {
          return '停留$duration'; // 文字文案显示 停留+duration
        } else if (status == 'staying') {
          return '停留中'; // 文字文案显示 停留中
        }
        break;
    }
    return '';
  }
}
