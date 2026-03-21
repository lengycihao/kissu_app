import 'package:kissu_app/network/http_managerN.dart';
import 'package:kissu_app/network/public/api_request.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';

/// 版本信息模型
class VersionInfo {
  /// 更新类型: 1=静默更新, 2=弱更新, 3=强更新
  final int upgradeType;
  
  /// 版本号（字符串格式，如：1.0.2）
  final String version;
  
  /// 版本号（数字格式，如：1000200）
  final int versionNum;
  
  /// 更新内容（HTML格式）
  final String contentTxt;
  
  /// 下载地址
  final String url;

  VersionInfo({
    required this.upgradeType,
    required this.version,
    required this.versionNum,
    required this.contentTxt,
    required this.url,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    return VersionInfo(
      upgradeType: json['upgrade_type'] ?? 1,
      version: json['version'] ?? '',
      versionNum: json['version_num'] ?? 0,
      contentTxt: json['content_txt'] ?? '',
      url: json['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'upgrade_type': upgradeType,
      'version': version,
      'version_num': versionNum,
      'content_txt': contentTxt,
      'url': url,
    };
  }
  
  /// 是否是静默更新
  bool get isSilent => upgradeType == 1;
  
  /// 是否是弱更新（可取消）
  bool get isOptional => upgradeType == 2;
  
  /// 是否是强更新（必须更新）
  bool get isForced => upgradeType == 3;
}

class VersionApi {
  /// 检查版本更新
  static Future<VersionInfo?> checkVersion() async {
    try {
      final response = await HttpManagerN.instance.executeGet(
        ApiRequest.checkVersion,
      );

      if (response.isSuccess && response.dataJson != null) {
        return VersionInfo.fromJson(response.dataJson);
      }
      return null;
    } catch (e) {
      logError('检查版本更新失败: $e');
      return null;
    }
  }
}

