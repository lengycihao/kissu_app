import 'package:kissu_app/model/setting/common_question_model/common_question_model.dart';
import 'package:kissu_app/network/http_resultN.dart';
import 'package:kissu_app/network/http_managerN.dart';
import 'package:kissu_app/network/public/api_request.dart';

class SettingApi {
  // 提交意见反馈
  /// [content] 反馈内容（必填）
  /// [contactWay] 联系方式（必填）
  /// [attachment] 附件URL（选填）
  /// [logUrl] 日志文件URL（选填）
  Future<HttpResultN> submitFeedback({
    required String content,
    required String contactWay,
    String? attachment,
    String? logUrl,
  }) async {
    try {
      final params = <String, dynamic>{
        'content': content,
        'contact_way': contactWay,
      };

      if (attachment?.isNotEmpty == true) {
        params['attachment'] = attachment;
      }

      if (logUrl?.isNotEmpty == true) {
        params['log_url'] = logUrl;
      }

      final result = await HttpManagerN.instance.executePost(
        '/submit/feedback',
        jsonParam: params,
        paramEncrypt: false,
      );

      return result;
    } catch (e) {
      return HttpResultN(isSuccess: false, code: -1, msg: '提交失败: $e');
    }
  }

  /// 获取常见问题列表
  Future<HttpResultN<List<CommonQuestionModel>>> getProblemList() async {
    final result = await HttpManagerN.instance.executeGet(
      ApiRequest.problemList,
    );
    if (result.isSuccess) {
      final List<CommonQuestionModel> list = (result.listJson as List)
          .map((e) => CommonQuestionModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return result.convert(data: list);
    } else {
      return result.convert();
    }
  }

  /// 获取App图标列表
  Future<HttpResultN<List<Map<String, dynamic>>>> getLogoList() async {
    try {
      final result = await HttpManagerN.instance.executeGet(
        '/get/logo/list',
      );
      
      if (result.isSuccess && result.listJson != null) {
        final List<Map<String, dynamic>> list = (result.listJson as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
        return result.convert(data: list);
      } else {
        return result.convert();
      }
    } catch (e) {
      return HttpResultN(isSuccess: false, code: -1, msg: '获取图标列表失败: $e');
    }
  }
}
