import 'dart:math';

double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadius = 6371000; // 地球半径（米）
  
  double lat1Rad = lat1 * pi / 180;
  double lat2Rad = lat2 * pi / 180;
  double deltaLatRad = (lat2 - lat1) * pi / 180;
  double deltaLonRad = (lon2 - lon1) * pi / 180;
  
  double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
      cos(lat1Rad) * cos(lat2Rad) *
      sin(deltaLonRad / 2) * sin(deltaLonRad / 2);
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  
  return earthRadius * c;
}

void main() {
  // 第一个点
  double lon1 = 120.22045;
  double lat1 = 30.275746;
  
  // 第二个点  
  double lon2 = 120.22037901833573;
  double lat2 = 30.275738567173487;
  
  double distance = calculateDistance(lat1, lon1, lat2, lon2);
  
  print('点1: ($lat1, $lon1)');
  print('点2: ($lat2, $lon2)');
  print('距离: ${distance.toStringAsFixed(2)} 米');
  
  // 计算经纬度差值
  double lonDiff = (lon1 - lon2).abs();
  double latDiff = (lat1 - lat2).abs();
  
  print('经度差: ${lonDiff.toStringAsFixed(10)}');
  print('纬度差: ${latDiff.toStringAsFixed(10)}');
}
