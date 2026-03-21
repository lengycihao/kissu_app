import 'package:kissu_app/model/face_status_model.dart';
import 'package:kissu_app/network/http_managerN.dart';
import 'package:kissu_app/network/http_resultN.dart';
import 'package:kissu_app/network/public/api_request.dart';
import 'package:kissu_app/network/enum/cache_control.dart';
import 'package:kissu_app/utils/debug_util.dart';

/// 状态表情 API
class FaceStatusApi {
  /// 获取状态表情列表和当前状态
  /// 返回所有可选表情分类和用户当前设置的状态
  Future<HttpResultN<FaceStatusResponseModel>> getFaceStatus() async {
    final result = await HttpManagerN.instance.executeGet(
      ApiRequest.getFaceStatus,
      paramEncrypt: false,
      // 每次都获取最新数据，不使用缓存
      cacheControl: CacheControl.noCache,
    );

    if (result.isSuccess) {
      final rawJson = result.getDataJson();
      // DebugUtil.info('📱 获取状态表情数据成功');
      // DebugUtil.info('  face_list 数量: ${(rawJson['face_list'] as List?)?.length ?? 0}');
      // DebugUtil.info('  now_face 是否有数据: ${rawJson['now_face'] != null}');
      
      return result.convert(data: FaceStatusResponseModel.fromJson(rawJson));
    } else {
      DebugUtil.warning('⚠️ 获取状态表情数据失败: ${result.msg}');
      return result.convert();
    }
  }

  /// 设置用户状态
  /// [faceId] 表情ID
  /// [faceExpire] 有效期（小时）：1,2,4,6,8,12
  Future<HttpResultN<void>> setFaceStatus({
    required int faceId,
    required int faceExpire,
  }) async {
    final result = await HttpManagerN.instance.executePost(
      ApiRequest.setFaceStatus,
      jsonParam: {
        'face_id': faceId,
        'face_expire': faceExpire,
      },
      paramEncrypt: false,
    );

    if (result.isSuccess) {
      // DebugUtil.info('✅ 设置状态成功: faceId=$faceId, faceExpire=$faceExpire');
    } else {
      DebugUtil.warning('⚠️ 设置状态失败: ${result.msg}');
    }

    return result.convert();
  }

  /// 删除用户状态
  Future<HttpResultN<void>> deleteFaceStatus() async {
    final result = await HttpManagerN.instance.executePost(
      ApiRequest.deleteFaceStatus,
      paramEncrypt: false,
    );

    if (result.isSuccess) {
      // DebugUtil.info('✅ 删除状态成功');
    } else {
      DebugUtil.warning('⚠️ 删除状态失败: ${result.msg}');
    }

    return result.convert();
  }
}

