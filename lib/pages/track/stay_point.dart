import 'package:latlong2/latlong.dart';

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


class StopRecord {
  final String time;
  final String leftTime;
  final String location;
  final String stayDuration; // 停留时间，如果是当前停留可写"停留中"
  final bool isCurrent;

  StopRecord({
    required this.time,
    required this.leftTime,
    required this.location,
    required this.stayDuration,
    this.isCurrent = false,
  });
}