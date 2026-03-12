import 'dart:convert';

import 'package:kissu_app/network/http_managerN.dart';
import 'package:kissu_app/network/http_resultN.dart';
import 'package:kissu_app/network/public/api_request.dart';

/// 一键锁机相关 API（权限 + 锁机/解锁/随机问题/锁机记录）
class LockPermissionApi {
  // ==================== 对方权限静态缓存 ====================
  /// 缓存的对方权限数据（Mine/Chat页面预拉取，LockScreen页面直接使用）
  static Map<String, dynamic>? cachedPartnerPermission;

  /// 预拉取对方权限并缓存（供MineController/ChatController调用）
  static Future<void> prefetchPartnerPermission() async {
    try {
      final api = LockPermissionApi();
      final result = await api.getLockPermission();
      if (result.isSuccess && result.data != null) {
        cachedPartnerPermission = result.data;
      }
    } catch (_) {}
  }

  /// 获取对方的权限开启状态
  /// 返回 half_user_permission: { os, is_open_screen_use, is_open_suspend_window, relevance_app }
  Future<HttpResultN<Map<String, dynamic>>> getLockPermission() async {
    try {
      final result = await HttpManagerN.instance.executeGet(
        ApiRequest.oneKeyLockPermission,
        paramEncrypt: false,
      );
      if (result.isSuccess) {
        final data = result.getDataJson();
        final permission = data['half_user_permission'] as Map<String, dynamic>?;
        if (permission != null) {
          return result.convert(data: permission);
        }
      }
      return result.convert();
    } catch (e) {
      return HttpResultN(isSuccess: false, code: -1, msg: '获取权限状态失败: $e');
    }
  }

  // ==================== 随机问题 ====================
  /// 获取锁机随机问题列表
  /// 返回 List<Map> 每项含 question + answer[]
  Future<HttpResultN<List<dynamic>>> getLockPhoneQuestion() async {
    try {
      final result = await HttpManagerN.instance.executeGet(
        ApiRequest.oneKeyLockQuestion,
        paramEncrypt: false,
      );
      if (result.isSuccess) {
        // 优先尝试 listJson（接口直接返回数组）
        final listData = result.getListJson();
        if (listData.isNotEmpty) {
          return HttpResultN<List<dynamic>>(
            isSuccess: true, code: result.code, msg: result.msg, data: listData,
          );
        }
        // 兜底：从 dataJson 的 data 字段取
        final mapData = result.getDataJson();
        final list = mapData['data'];
        if (list is List) {
          return HttpResultN<List<dynamic>>(
            isSuccess: true, code: result.code, msg: result.msg, data: list,
          );
        }
      }
      return HttpResultN<List<dynamic>>(
        isSuccess: false, code: result.code, msg: result.msg ?? '获取随机问题失败',
      );
    } catch (e) {
      return HttpResultN<List<dynamic>>(isSuccess: false, code: -1, msg: '获取随机问题失败: $e');
    }
  }

  // ==================== 锁机 ====================
  /// 锁机接口（后端会自动发送IM消息）
  /// [lockQuestion] 锁机问题
  /// [lockAnswer] 答案JSON字符串 [{"answer":"xxx","is_answer":0/1}, ...]
  /// [lockPrompt] 锁机提示语
  /// [lockBgImage] 锁机背景图URL（仅Android对方）
  Future<HttpResultN> lockUserPhone({
    required String lockQuestion,
    required String lockAnswer,
    required String lockPrompt,
    String lockBgImage = '',
    String defaultBgImageIndex = '',
  }) async {
    try {
      final params = <String, dynamic>{
        'lock_question': lockQuestion,
        'lock_answer': lockAnswer,
        'lock_prompt': lockPrompt,
      };
      if (defaultBgImageIndex.isNotEmpty) {
        params['default_bg_image_index'] = defaultBgImageIndex;
      } else if (lockBgImage.isNotEmpty) {
        params['lock_bg_image'] = lockBgImage;
      }
      final result = await HttpManagerN.instance.executePost(
        ApiRequest.oneKeyLock,
        jsonParam: params,
        paramEncrypt: false,
      );
      return result;
    } catch (e) {
      return HttpResultN(isSuccess: false, code: -1, msg: '锁机失败: $e');
    }
  }

  // ==================== 解锁 ====================
  /// 解锁接口（后端会自动发送IM消息）
  /// [unlockType] 1=主动解锁  2=被动解锁（答题）
  /// [unlockAnswerIndex] 答题解锁时选择的答案索引，从0开始（0,1,2,3），unlockType=2时传
  Future<HttpResultN> unlockUserPhone({
    required int unlockType,
    int? unlockAnswerIndex,
  }) async {
    try {
      final params = <String, dynamic>{
        'unlock_type': unlockType,
      };
      if (unlockType == 2 && unlockAnswerIndex != null) {
        params['unlock_answer_index'] = unlockAnswerIndex;
      }
      final result = await HttpManagerN.instance.executePost(
        ApiRequest.oneKeyUnlock,
        jsonParam: params,
        paramEncrypt: false,
      );
      return result;
    } catch (e) {
      return HttpResultN(isSuccess: false, code: -1, msg: '解锁失败: $e');
    }
  }

  // ==================== 锁机记录 ====================
  /// 获取锁机记录（分页）
  /// 返回 { total, data[], has_more, latest_lock_data }
  Future<HttpResultN<Map<String, dynamic>>> getLockPhoneRecord({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final result = await HttpManagerN.instance.executeGet(
        ApiRequest.oneKeyLockRecord,
        queryParam: {'page': page, 'page_size': pageSize},
        paramEncrypt: false,
      );
      if (result.isSuccess) {
        final data = result.getDataJson();
        return result.convert(data: data);
      }
      return result.convert();
    } catch (e) {
      return HttpResultN(isSuccess: false, code: -1, msg: '获取锁机记录失败: $e');
    }
  }

  /// 上传自己的权限状态
  Future<HttpResultN> setPermission({
    required int isOpenLocation,
    required int isOpenNoticeRemind,
    required int isOpenScreenUse,
    required int isOpenBackRun,
    required int isOpenPreventProgramSleep,
    required int isOpenSelfStarting,
    required int isOpenProgramLock,
    required int isOpenSuspendWindow,
  }) async {
    try {
      var jsonValue = jsonEncode({
          'is_open_location': isOpenLocation,
          'is_open_notice_remind': isOpenNoticeRemind,
          'is_open_screen_use': isOpenScreenUse,
          'is_open_back_run': isOpenBackRun,
          'is_open_prevent_program_sleep': isOpenPreventProgramSleep,
          'is_open_self_starting': isOpenSelfStarting,
          'is_open_program_lock': isOpenProgramLock,
          'is_open_suspend_window': isOpenSuspendWindow,
        });
      final params = {
        'permission_data': jsonValue,
      };
      final result = await HttpManagerN.instance.executePost(
        ApiRequest.setPermission,
        jsonParam: params,
        paramEncrypt: false,
      );
      return result;
    } catch (e) {
      return HttpResultN(isSuccess: false, code: -1, msg: '上传权限状态失败: $e');
    }
  }
}
