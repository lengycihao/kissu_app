import 'dart:convert';

import 'package:kissu_app/model/notification_item.dart';
import 'package:kissu_app/network/http_managerN.dart';
import 'package:kissu_app/network/http_resultN.dart';

/// 通知设置API
class NotificationSettingsApi {
  /// 获取通知设置列表
  Future<HttpResultN<List<NotificationItem>>> getNotificationSettings() async {
    try {
      final result = await HttpManagerN.instance.executeGet(
        '/v3/notification/set/info',
        paramEncrypt: false,
      );

      if (result.isSuccess) {
        final listData = result.getListJson();
        final items = listData
            .map((json) => NotificationItem.fromJson(json as Map<String, dynamic>))
            .toList();
        return result.convert(data: items);
      } else {
        return result.convert();
      }
    } catch (e) {
      return HttpResultN<List<NotificationItem>>(
        isSuccess: false,
        code: -1,
        msg: '获取通知设置失败: $e',
      );
    }
  }

  /// 更新通知设置
  /// [field] 字段标识
  /// [isChecked] 是否选中 (1: 选中, 0: 未选中)
 Future<HttpResultN<void>> updateNotificationSetting({
  required String field,
  required int isChecked,
}) async {
  try {
    final params = <String, dynamic>{
       'notification_set_data': jsonEncode({field: isChecked}),
    };
print("📤 updateNotificationSetting 参数: $params");
    final result = await HttpManagerN.instance.executePost(
      '/v3/set/notification',
      jsonParam: params,
      paramEncrypt: false,
    );

    return result.convert();
  } catch (e) {
    return HttpResultN<void>(
      isSuccess: false,
      code: -1,
      msg: '更新通知设置失败: $e',
    );
  }
}

  /// 批量更新通知设置
  /// [settings] 要更新的设置映射，格式: {"change_network_notification": 1, "stay_number_notification": 0}
  Future<HttpResultN<void>> batchUpdateNotificationSettings(Map<String, int> settings) async {
    try {
      final params = <String, dynamic>{
        'notification_set_data': jsonEncode(settings),
      };
      
      print("📤 batchUpdateNotificationSettings 参数: $params");
      
      final result = await HttpManagerN.instance.executePost(
        '/v3/set/notification',
        jsonParam: params,
        paramEncrypt: false,
      );

      return result.convert();
    } catch (e) {
      return HttpResultN<void>(
        isSuccess: false,
        code: -1,
        msg: '批量更新通知设置失败: $e',
      );
    }
  }

}

