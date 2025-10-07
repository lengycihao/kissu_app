import 'package:kissu_app/network/http_managerN.dart';
import 'package:kissu_app/network/http_resultN.dart';
import 'package:kissu_app/network/public/api_request.dart';
import 'package:kissu_app/utils/debug_util.dart';

/// 地理围栏（位置提醒）API服务
class GeofenceApi {
  /// 获取地理围栏列表
  /// 返回用户设置的所有位置提醒
  Future<HttpResultN<List<Map<String, dynamic>>>> getGeofencingList() async {
    DebugUtil.info('🌐 开始获取地理围栏列表...');
    
    final result = await HttpManagerN.instance.executeGet(
      ApiRequest.getGeofencing,
      paramEncrypt: false,
      networkDebounce: false,
    );

    if (result.isSuccess) {
      DebugUtil.success('✅ 获取地理围栏列表成功');
      
      List<Map<String, dynamic>> list = [];
      
      // 优先尝试从 listJson 获取数据
      final listJsonData = result.getListJson();
      if (listJsonData.isNotEmpty) {
        list = listJsonData.map((e) => e as Map<String, dynamic>).toList();
        DebugUtil.info('📍 从 listJson 获取了 ${list.length} 个地理围栏');
      } else {
        // 如果 listJson 为空，尝试从 dataJson 获取
        final dynamic rawData = result.getDataJson();
        DebugUtil.info('📦 原始数据: $rawData');
        
        // 如果返回的是数组，直接转换
        if (rawData is List) {
          list = rawData.map((e) => e as Map<String, dynamic>).toList();
          DebugUtil.info('📍 从 dataJson (数组) 获取了 ${list.length} 个地理围栏');
        } 
        // 如果返回的是对象，尝试从data字段获取
        else if (rawData is Map) {
          final data = rawData['data'];
          if (data is List) {
            list = data.map((e) => e as Map<String, dynamic>).toList();
            DebugUtil.info('📍 从 data 字段获取了 ${list.length} 个地理围栏');
          } else {
            DebugUtil.warning('⚠️ data字段不是数组');
          }
        } 
        // 如果都不是，使用空列表
        else {
          DebugUtil.warning('⚠️ 返回数据格式异常，使用空列表');
        }
      }
      
      return HttpResultN<List<Map<String, dynamic>>>(
        isSuccess: true,
        code: result.code,
        data: list,
        msg: result.msg,
      );
    } else {
      DebugUtil.error('❌ 获取地理围栏列表失败: ${result.msg}');
      return HttpResultN<List<Map<String, dynamic>>>(
        isSuccess: false,
        code: result.code,
        data: <Map<String, dynamic>>[],
        msg: result.msg,
      );
    }
  }
  
  /// 保存地理围栏
  /// 
  /// 参数:
  /// - [geoIcon] 图标类型 (1-5)
  ///   1: 公司, 2: 家, 3: 娱乐, 4: 健身房, 5: 商场
  /// - [geoAction] 提醒类型
  ///   1: 离开位置提醒, 2: 到达位置提醒
  /// - [longitude] 经度
  /// - [latitude] 纬度
  /// - [geoRadius] 围栏半径（米），固定100
  /// - [remark] 备注（可选）
  Future<HttpResultN<Map<String, dynamic>>> saveGeofencing({
    required int geoIcon,
    required int geoAction,
    required double longitude,
    required double latitude,
    int geoRadius = 100,
    String? remark,
  }) async {
    DebugUtil.info('🌐 开始保存地理围栏...');
    DebugUtil.info('📍 参数: icon=$geoIcon, action=$geoAction, lng=$longitude, lat=$latitude, radius=$geoRadius, remark=$remark');
    
    final params = {
      'geo_icon': geoIcon,
      'geo_action': geoAction,
      'longitude': longitude.toString(),
      'latitude': latitude.toString(),
      'geo_radius': geoRadius.toString(),
    };
    
    // 如果有备注，添加到参数中
    if (remark != null && remark.isNotEmpty) {
      params['remark'] = remark;
    }
    
    final result = await HttpManagerN.instance.executePost(
      ApiRequest.saveGeofencing,
      jsonParam: params,
      paramEncrypt: false,
      networkDebounce: false,
    );

    if (result.isSuccess) {
      DebugUtil.success('✅ 保存地理围栏成功');
      final data = result.getDataJson();
      DebugUtil.info('📦 返回数据: $data');
      return result.convert(data: data);
    } else {
      DebugUtil.error('❌ 保存地理围栏失败: ${result.msg}');
      return result.convert();
    }
  }
  
  /// 删除地理围栏
  /// 
  /// 参数:
  /// - [geofencingId] 地理围栏ID
  Future<HttpResultN<void>> deleteGeofencing({
    required String geofencingId,
  }) async {
    DebugUtil.info('🌐 开始删除地理围栏: $geofencingId');
    
    final params = {
      'geofencing_id': geofencingId,
    };
    
    final result = await HttpManagerN.instance.executePost(
      ApiRequest.deleteGeofencing,
      jsonParam: params,
      paramEncrypt: false,
      networkDebounce: false,
    );

    if (result.isSuccess) {
      DebugUtil.success('✅ 删除地理围栏成功');
      return result.convert();
    } else {
      DebugUtil.error('❌ 删除地理围栏失败: ${result.msg}');
      return result.convert();
    }
  }
}

