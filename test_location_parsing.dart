import 'dart:convert';
import 'lib/model/location_model/location_model.dart';

void main() {
  // 使用你提供的真实JSON数据
  final jsonString = '''
{
        "user_location_mobile_device": {
            "power": "0%",
            "network_name": "",
            "mobile_model": "",
            "is_wifi": "0",
            "longitude": "120.220376",
            "latitude": "30.275558",
            "location": "浙江省杭州市上城区运河东路149-151号靠近中豪·湘和国际 附近",
            "speed": "0m/s",
            "location_time": "1758362810",
            "calculate_location_time": "1分钟2秒",
            "is_open_location": 1,
            "is_oneself": 1,
            "distance": "61米",
            "stops": [
                {
                    "latitude": "30.275528",
                    "longitude": "120.22039",
                    "location_name": "浙江省杭州市上城区四季青街道中豪湘悦中心 附近",
                    "start_time": "当前",
                    "end_time": "",
                    "duration": "47分钟47秒",
                    "status": "staying",
                    "point_type": "stop",
                    "serial_number": "4"
                },
                {
                    "latitude": "30.275576",
                    "longitude": "120.220393",
                    "location_name": "浙江省杭州市上城区四季青街道中豪湘悦中心 附近",
                    "start_time": "当前",
                    "end_time": "",
                    "duration": "17小时17分钟",
                    "status": "staying",
                    "point_type": "stop",
                    "serial_number": "3"
                }
            ],
            "stay_collect": {
                "stay_count": 4,
                "stay_time": "2天4小时",
                "move_distance": ""
            },
            "head_portrait": "https://kissustatic.yuluojishu.com/uploads/2025/09/20/0a90e6a660589b31f57aac1f161b25a7."
        },
        "half_location_mobile_device": {
            "power": "40%",
            "network_name": "wifi-yuluo-5G",
            "mobile_model": "iPhone 16 Pro",
            "is_wifi": "1",
            "longitude": "120.22075059678819",
            "latitude": "30.27511501736111",
            "location": "浙江省杭州市上城区中豪·湘和国际 附近",
            "location_time": "1758275998",
            "speed": "0m/s",
            "calculate_location_time": "1天7分钟",
            "is_open_location": 1,
            "is_oneself": 0,
            "distance": "61米",
            "stops": [],
            "stay_collect": {
                "stay_count": 0,
                "stay_time": "0秒",
                "move_distance": "0米"
            },
            "head_portrait": "https://kissustatic.yuluojishu.com/uploads/2025/09/11/e00b3be4bb4801e07a62ff4080fb6d13.png"
        }
    }
''';

  try {
    final jsonData = jsonDecode(jsonString);
    print('🔍 开始解析JSON数据...');
    
    final locationModel = LocationResponseModel.fromJson(jsonData);
    
    print('✅ 解析成功！');
    print('userLocationMobileDevice: ${locationModel.userLocationMobileDevice != null ? "存在" : "为空"}');
    print('halfLocationMobileDevice: ${locationModel.halfLocationMobileDevice != null ? "存在" : "为空"}');
    
    if (locationModel.userLocationMobileDevice?.stops != null) {
      print('userLocationMobileDevice stops数量: ${locationModel.userLocationMobileDevice!.stops!.length}');
      for (int i = 0; i < locationModel.userLocationMobileDevice!.stops!.length; i++) {
        final stop = locationModel.userLocationMobileDevice!.stops![i];
        print('  stops[$i]: ${stop.locationName} - ${stop.startTime}~${stop.endTime}');
      }
    } else {
      print('❌ userLocationMobileDevice stops为空！');
    }
    
    if (locationModel.halfLocationMobileDevice?.stops != null) {
      print('halfLocationMobileDevice stops数量: ${locationModel.halfLocationMobileDevice!.stops!.length}');
    } else {
      print('halfLocationMobileDevice stops为空（这是正常的，因为API返回的是空数组）');
    }
    
  } catch (e, stackTrace) {
    print('❌ 解析失败: $e');
    print('Stack trace: $stackTrace');
  }
}

