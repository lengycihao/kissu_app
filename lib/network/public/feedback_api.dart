import 'package:kissu_app/network/http_resultN.dart';
import 'package:kissu_app/network/http_managerN.dart';

class FeedbackApi {
  /// 提交意见反馈
  /// [content] 反馈内容（必填）
  /// [contactWay] 联系方式（必填）
  /// [attachment] 附件URL（选填）
  Future<HttpResultN> submitFeedback({
    required String content,
    required String contactWay,
    String? attachment,
  }) async {
    try {
      final params = <String, dynamic>{
        'content': content,
        'contact_way': contactWay,
      };
      
      if (attachment?.isNotEmpty == true) {
        params['attachment'] = attachment;
      }

      final result = await HttpManagerN.instance.executePost(
        '/submit/feedback',
        jsonParam: params,
        paramEncrypt: false,
      );

      return result;
    } catch (e) {
      return HttpResultN(
        isSuccess: false,
        code: -1,
        msg: '提交失败: $e',
      );
    }
  }
}
