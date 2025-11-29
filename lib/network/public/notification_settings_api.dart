import 'package:kissu_app/model/notification_settings_response.dart';
import 'package:kissu_app/network/http_managerN.dart';
import 'package:kissu_app/network/http_resultN.dart';

/// 通知设置API
class NotificationSettingsApi {
  /// 获取通知设置列表
  Future<HttpResultN<List<NotificationSettingsResponse>>> getNotificationSettings() async {
    try {
      final result = await HttpManagerN.instance.executeGet(
        '/v4/notification/set/info',
        paramEncrypt: false,
      );

      if (result.isSuccess) {
        final listData = result.getListJson();
        final items = listData
            .map((json) => NotificationSettingsResponse.fromJson(json as Map<String, dynamic>))
            .toList();
        return result.convert(data: items);
      } else {
        return result.convert();
      }
    } catch (e) {
      return HttpResultN<List<NotificationSettingsResponse>>(
        isSuccess: false,
        code: -1,
        msg: '获取通知设置失败: $e',
      );
    }
  }

  /// 更新通知设置
  /// [field] 字段标识
  /// [status] 状态 (1: 开启, 0: 关闭)
  Future<HttpResultN<void>> updateNotificationSetting({
    required String field,
    required int status,
  }) async {
    try {
      final params = <String, dynamic>{
        'field': field,
        'status': status,
      };
      
      final result = await HttpManagerN.instance.executePost(
        '/v4/set/notification',
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
}
