import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/network/public/version_api.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/services/version_service.dart';

/// 版本更新弹窗
class VersionUpdateDialog extends StatelessWidget {
  final VersionInfo versionInfo;

  const VersionUpdateDialog({
    Key? key,
    required this.versionInfo,
  }) : super(key: key);

  /// 移除HTML标签
  String _stripHtmlTags(String htmlString) {
    // 将换行相关标签转为换行符
    String result = htmlString
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<p>', caseSensitive: false), '');
    // 移除剩余HTML标签
    result = result.replaceAll(RegExp(r'<[^>]*>'), '');
    // 替换HTML实体
    result = result
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
    return result.trim();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth * 0.8;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        margin: EdgeInsets.only(bottom: 80), 
        width: dialogWidth,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 顶部装饰图片
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Image.asset(
                'assets/3.0/kissu3_update_dialog_top.webp',
                fit: BoxFit.contain,
              ),
            ),
            // 主体内容背景
            Container(
              margin: EdgeInsets.only(top: 120), // 为顶部装饰留出空间
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/3.0/kissu3_update_dialog.webp'),
                  fit: BoxFit.fill,
                ),
                borderRadius: BorderRadius.all(Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: versionInfo.upgradeType == 1 
                    ? CrossAxisAlignment.center  // 静默更新：居中
                    : CrossAxisAlignment.start,  // 强更新和弱更新：左对齐
                children: [
                  SizedBox(height: 30), // 顶部留白
                  
                  // 标题和版本号区域
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      crossAxisAlignment: versionInfo.upgradeType == 1
                          ? CrossAxisAlignment.center  // 静默更新：居中
                          : CrossAxisAlignment.start,  // 强更新和弱更新：左对齐
                      children: [
                        // 标题
                        Text(
                          versionInfo.upgradeType == 1 ? '提示' : '版本更新',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        
                        SizedBox(height: 8),
                        
                        // 版本号
                        Text(
                          'V${versionInfo.version}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 10),
                  
                  // 更新内容
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: 200,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: SingleChildScrollView(
                      child: Text(
                        _stripHtmlTags(versionInfo.contentTxt),
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF333333),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 30),
                  
                  // 按钮区域
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: _buildButtons(context),
                  ),
                  
                  SizedBox(height: 30),
                ],
              ),
            ),
            
            
            
            // 火箭图片（右侧）
            Positioned(
              top: 100,
              right: 0,
              child: Image.asset(
                'assets/3.0/kissu3_update_dialog_huojian.webp',
                width: 72,

                fit: BoxFit.fill,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建按钮区域
  Widget _buildButtons(BuildContext context) {
    if (versionInfo.isForced) {
      // 强更新：只有一个"立即更新"按钮
      return _buildUpdateButton(
        text: '立即更新',
        onTap: () => _openDownloadUrl(context),
      );
    } else {
      // 弱更新和静默更新：两个按钮
      return Row(
        children: [
          // 稍后更新按钮
          Expanded(
            child: _buildCancelButton(
              text: '稍后更新',
              onTap: () async {
                final versionService = Get.find<VersionService>();
                await versionService.dismissUpdateToday();
                Get.back();
              },
            ),
          ),
          
          SizedBox(width: 12),
          
          // 立即更新按钮
          Expanded(
            child: _buildUpdateButton(
              text: '立即更新',
              onTap: () => _openDownloadUrl(context),
            ),
          ),
        ],
      );
    }
  }

  /// 立即更新按钮
  Widget _buildUpdateButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF6B9D), Color(0xFFFF4081)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// 稍后更新按钮
  Widget _buildCancelButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Color(0xFFE6E2E3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF999999),
          ),
        ),
      ),
    );
  }

  /// 跳转到对应渠道的应用市场
  Future<void> _openDownloadUrl(BuildContext context) async {
    try {
      await VersionService.openAppStore();
      
      // 如果不是强更新，跳转后关闭弹窗
      if (!versionInfo.isForced) {
        Get.back();
      }
    } catch (e) {
      logError('跳转应用市场失败: $e', tag: 'VersionUpdateDialog', error: e);
      OKToastUtil.show('无法打开应用市场');
    }
  }
}

