import 'package:kissu_app/network/http_managerN.dart';
import 'package:kissu_app/network/http_resultN.dart';
import 'package:kissu_app/utils/debug_util.dart';

/// 照片墙API
class PhotoWallApi {
  /// 保存照片墙
  /// [photoWallUrl] 照片墙图片URL
  Future<HttpResultN<void>> savePhotoWall(String photoWallUrl) async {
    try {
      // DebugUtil.info('📸 开始保存照片墙: $photoWallUrl');
      
      final result = await HttpManagerN.instance.executePost(
        '/save/photo/wall',
        jsonParam: {
          'photo_wall': photoWallUrl,
        },
        paramEncrypt: false,
        networkDebounce: false,
      );

      if (result.isSuccess) {
        // DebugUtil.success('📸 照片墙保存成功');
        return result.convert();
      } else {
        DebugUtil.error('📸 照片墙保存失败: ${result.msg}');
        return result.convert();
      }
    } catch (e, stackTrace) {
      DebugUtil.error('📸 照片墙保存异常: $e');
      DebugUtil.error('堆栈信息: $stackTrace');
      return HttpResultN.failure(-1, '照片墙保存失败: $e');
    }
  }
}

