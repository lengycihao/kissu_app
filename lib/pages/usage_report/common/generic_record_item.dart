import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/models/usage_record_api_model.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/services/tracking_service.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/utils/vip_navigation_helper.dart';

/// 通用记录列表项组件（用于敏感记录、定位异常等）
/// 根据event_type和ext动态渲染不同的UI
class GenericRecordItemWidget extends StatelessWidget {
  final RecordItem record;
  final VoidCallback? onTap;
  final bool showTimeLabel; // 是否显示时间标签（用于全部记录页面）
  final bool showSensitiveLevel; // 是否显示敏感等级标签
  final VoidCallback? onVipStatusChanged; // VIP状态变化回调
  
  // 新增参数
  final List<Color>? backgroundGradientColors; // 背景渐变色
  final double? backgroundWidth; // 背景宽度
  final String? backgroundText; // 背景文案
  final String? backgroundImage; // 背景图片路径

  const GenericRecordItemWidget({
    super.key,
    required this.record,
    this.onTap,
    this.showTimeLabel = false,
    this.showSensitiveLevel = false,
    this.onVipStatusChanged,
    this.backgroundGradientColors,
    this.backgroundWidth,
    this.backgroundText,
    this.backgroundImage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 时间标签（仅在全部记录页面显示）
        if (showTimeLabel) ...[
          const SizedBox(height: 8),
        _buildTimeLabel(),
          const SizedBox(height: 8),
        ],
        _buildRecordContent(),
      ],
    );
  }

  /// 构建时间标签
  Widget _buildTimeLabel() {
    return Center(
      child: Text(
        record.createTime,
        style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
      ),
    );
  }

  /// 构建记录内容
  Widget _buildRecordContent() {
    // 非会员状态下，类型9,17,18,19,20显示毛玻璃效果（优先级最高）
    print('🔍 Debug: eventType=${record.eventType}, isVip=${UserManager.isVip}, shouldShowBlur=${_shouldShowBlurOverlay()}');
    if (!UserManager.isVip && _shouldShowBlurOverlay()) {
      print('✅ 显示毛玻璃效果');
      // 根据不同类型返回对应的毛玻璃效果
      if (backgroundGradientColors != null && backgroundWidth != null && backgroundText != null) {
        return _buildType20BlurContent();
      } else if (record.eventType == 20) {
        return _buildType20BlurContent();
      } else {
        return _buildBlurOverlayContent();
      }
    }

    // 如果传入了背景参数，使用特殊UI（类型17、18、9、20）
    if (backgroundGradientColors != null && backgroundWidth != null && backgroundText != null) {
      return _buildType20Content();
    }
    
    // 类型20使用特殊UI（兼容旧代码）
    if (record.eventType == 20) {
      return _buildType20Content();
    }

    // 其他类型使用通用UI
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row( 
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 图标
                _buildIcon(),
                const SizedBox(width: 4),
                // 文本内容（支持高亮）
                Flexible(child: _buildContentText()),
                // 非会员状态下，为指定类型添加会员可查看按钮
                if (_shouldShowVipViewButton()) ...[
                  const SizedBox(width: 8),
                  _buildVipViewButton(),
                ],
              ],
            ),
            // 扩展信息（如果有特殊显示需求）
            if (_hasExtendedInfo()) ...[
              const SizedBox(height: 12),
              _buildExtendedInfo(),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建内容文本（支持 var_data 高亮）
  Widget _buildContentText() {
    // 如果没有 var_data，直接显示 content
    if (record.varData.isEmpty) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
        record.content,
          textAlign: TextAlign.left,
          style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    // 有 var_data，需要对文本进行分段高亮
    List<TextSpan> spans = [];
    String remainingText = record.content;

    for (var varItem in record.varData) {
      // 找到需要高亮的文本位置
      int index = remainingText.indexOf(varItem.changeText);
      if (index == -1) continue;

      // 添加前面的普通文本
      if (index > 0) {
        spans.add(
          TextSpan(
          text: remainingText.substring(0, index),
            style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
          ),
        );
      }

      // 添加高亮文本
      spans.add(
        TextSpan(
          text: _getLimitedText(varItem.changeText),
          style: TextStyle(fontSize: 13, color: _parseColor(varItem.color)),
        ),
      );

      // 更新剩余文本
      remainingText = remainingText.substring(
        index + varItem.changeText.length,
      );
    }

    // 添加剩余的普通文本
    if (remainingText.isNotEmpty) {
      spans.add(
        TextSpan(
        text: remainingText,
          style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: RichText(
        textAlign: TextAlign.left,
      text: TextSpan(children: spans),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// 解析颜色字符串（支持 #RRGGBB 格式）
  Color _parseColor(String colorStr) {
    try {
      // 去掉 # 号
      String hexColor = colorStr.replaceAll('#', '');
      // 如果是6位，添加FF作为完全不透明
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      // 解析失败返回默认颜色
      return const Color(0xFF333333);
    }
  }

  /// 是否有扩展信息需要显示
  bool _hasExtendedInfo() {
    // event_type 19: 解锁->锁定时段记录（在解锁记录页面已经有专门组件处理）
    // 这里只处理一些特殊的扩展信息展示
    return false;
  }

  /// 构建扩展信息
  Widget _buildExtendedInfo() {
    return const SizedBox.shrink();
  }

  /// 构建类型20的特殊UI
  Widget _buildType20Content() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 17),
        height: 78,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          image: DecorationImage(
            image: AssetImage(
              backgroundImage ?? 'assets/phone_history/kissu3_history_blue_map.webp',
            ),
            fit: BoxFit.fill,
          ),
        ),
        child: Stack(
          children: [
            // 背景上的图标 - 居右，距离右边距50px
            Positioned(
              left: 25,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildSpecialIcon(),
              ),
            ),
            // 左对齐的Column，距离左边100px
            Padding(
              padding: const EdgeInsets.only(left: 90),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildContentText(),
                  const SizedBox(height: 10),
                  if (backgroundGradientColors != null && backgroundWidth != null && backgroundText != null)
                    Container(
                      width: backgroundWidth,
                      height: 22,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: backgroundGradientColors!,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _getLimitedText(backgroundText!),
                        style: const TextStyle(fontSize: 13, color: Color(0xffFFFDFD)),
                      ),
                    ),
                ],
              ),
            ),
            // 居右边的查看模块
            _buildViewButton(),
          ],
        ),
      ),
    );
  }

  /// 构建查看按钮模块
  Widget _buildViewButton() {
    return Positioned(
      right: 0,
      top: 30,
      bottom: 0,
      child: GestureDetector(
        onTap: () => _handleViewButtonTap(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '查看',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2289FF),
              ),
            ),
            Image.asset(
              'assets/phone_history/kissu3_arrow_blue.webp',
              width: 12,
              height: 12,
            ),
          ],
        ),
      ),
    );
  }

  /// 处理查看按钮点击事件
  /// 开通会员的情况下：
  /// - 类型 20：跳转到定位页面
  /// - 类型 9, 17, 18：跳转到轨迹页面
  void _handleViewButtonTap() {
    // 只有会员才能查看
    if (!UserManager.isVip) {
      _navigateToVipPage();
      return;
    }

    // 根据类型跳转到不同页面
    if (record.eventType == 20) {
      // 类型20跳转到定位页面（添加会员检查）
      VipNavigationHelper.navigateToLocationWithVipCheck();
    } else if ([9, 17, 18].contains(record.eventType)) {
      // 类型9, 17, 18跳转到轨迹页面
      Get.toNamed(KissuRoutePath.track);
    }
  }

  /// 获取限制长度的文字（类型9、17、18超过5个字符时显示省略号）
  String _getLimitedText(String text) {
    // 检查是否为类型9、17、18
    if (record.eventType == 9 || record.eventType == 17 || record.eventType == 18) {
      // 如果文字超过5个字符，只显示前5个字符加省略号
      if (text.length > 5) {
        return '${text.substring(0, 5)}...';
      }
    }
    return text;
  }

  /// 判断是否应该显示VIP图标
  /// 当用户非会员且记录类型为3-8, 10-16, 21时，显示VIP图标
  bool _shouldShowVipIcon() {
    // 检查用户是否为非会员
    if (UserManager.isVip) {
      return false;
    }
    
    // 检查记录类型是否在指定范围内（3-8, 10-16, 21），排除9
    return ((record.eventType >= 3 && record.eventType <= 8) || 
            (record.eventType >= 10 && record.eventType <= 16) || 
            record.eventType == 21);
  }

  /// 判断是否应该显示会员可查看按钮
  /// 当用户非会员且记录类型为除了1,2之外的其他类型时，显示会员可查看按钮
  /// 当用户是会员且记录类型为10,11时，显示查看按钮
  bool _shouldShowVipViewButton() {
    // 会员状态下，只为类型10和11显示查看按钮
    if (UserManager.isVip) {
      return [10, 11].contains(record.eventType);
    }
    
    // 非会员状态下，排除的类型：1,2
    List<int> excludedTypes = [1, 2];
    return !excludedTypes.contains(record.eventType);
  }

  /// 构建图标组件
  Widget _buildIcon() {
    // 如果应该显示VIP图标，使用本地VIP图标
    if (_shouldShowVipIcon()) {
      return Image.asset(
        'assets/phone_history/kissu3_vip_logo.webp',
        width: 16,
        height: 16,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.star,
          size: 16,
          color: Colors.orange,
        ),
      );
    }
    
    // 否则使用原来的逻辑
    if (record.icon.isNotEmpty) {
      return Image.network(
        record.icon,
        width: 16,
        height: 16,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.image_not_supported,
          size: 16,
          // color: Colors.grey[400],
        ),
      );
    } else {
      return Icon(Icons.info_outline, size: 20, color: Colors.grey[400]);
    }
  }

  /// 构建特殊UI中的图标组件（类型20等）
  Widget _buildSpecialIcon() {
    // 如果应该显示VIP图标，使用本地VIP图标
    if (_shouldShowVipIcon()) {
      return Image.asset(
        'assets/phone_history/kissu3_vip_logo.webp',
        width: 18,
        height: 18,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.star,
          size: 18,
          color: Colors.orange.withOpacity(0.8),
        ),
      );
    }
    
    // 否则使用原来的逻辑
    if (record.icon.isNotEmpty) {
      return Image.network(
        record.icon,
        width: 18,
        height: 18,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.image_not_supported,
          size: 18,
          color: Colors.white.withOpacity(0.3),
        ),
      );
    } else {
      return Icon(
        Icons.info_outline,
        size: 18,
        color: Colors.white.withOpacity(0.3),
      );
    }
  }

  /// 判断是否应该显示毛玻璃效果
  /// 类型9,17,18,19,20在非会员状态下显示毛玻璃效果
  bool _shouldShowBlurOverlay() {
    return [9, 17, 18, 19, 20].contains(record.eventType);
  }

  /// 构建类型20的毛玻璃遮罩内容（固定高度78）
  Widget _buildType20BlurContent() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
        height: 78, // 固定高度78，与特殊类型保持一致
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          image: DecorationImage(
            image: AssetImage(
              backgroundImage ?? 'assets/phone_history/kissu3_history_blue_map.webp',
            ),
            fit: BoxFit.fill,
          ),
        ),
        child: Stack(
          children: [
            // 原始内容（隐藏在毛玻璃下）
            Positioned(
              left: 42, // 25 + 17 (原来的padding)
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildSpecialIcon(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 107), // 90 + 17 (原来的padding)
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildContentText(),
                  const SizedBox(height: 10),
                  if (backgroundGradientColors != null && backgroundWidth != null && backgroundText != null)
                    Container(
                      width: backgroundWidth,
                      height: 22,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: backgroundGradientColors!,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _getLimitedText(backgroundText!),
                        style: const TextStyle(fontSize: 13, color: Color(0xffFFFDFD)),
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              right: 17, // 添加右边距补偿
              top: 0,
              bottom: 0,
              child: _buildViewButton(),
            ),
            // 毛玻璃遮罩层 - 覆盖整个容器（包括边距）
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 显示文字内容
                      _buildBlurOverlayText(),
                      const SizedBox(height: 8),
                      // 会员可查看按钮
                      _buildVipViewButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建毛玻璃效果的内容
  Widget _buildBlurOverlayContent() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Stack(
          children: [
            // 原始内容
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 图标
                    _buildIcon(),
                    const SizedBox(width: 4),
                    // 文本内容（支持高亮）
                    Flexible(child: _buildContentText()),
                  ],
                ),
                // 扩展信息（如果有特殊显示需求）
                if (_hasExtendedInfo()) ...[
                  const SizedBox(height: 12),
                  _buildExtendedInfo(),
                ],
              ],
            ),
            // 毛玻璃遮罩层
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 显示文字内容
                      _buildBlurOverlayText(),
                      const SizedBox(height: 8),
                      // 会员可查看按钮
                      _buildVipViewButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建毛玻璃遮罩上的文字
  Widget _buildBlurOverlayText() {
    if (record.eventType == 19) {
      // 类型19特殊处理：固定文字
      return RichText(
        textAlign: TextAlign.center,
        text: const TextSpan(
          children: [
            TextSpan(
              text: '对方',
              style: TextStyle(fontSize: 13, color: Color(0xFF333333)),
            ),
            TextSpan(
              text: '手机产生了一条敏感记录',
              style: TextStyle(fontSize: 13, color: Color(0xFFB66CF2)),
            ),
          ],
        ),
      );
    } else {
      // 其他类型：从接口获取change_text并添加颜色
      if (record.varData.isNotEmpty) {
        List<TextSpan> spans = [];
        String remainingText = record.content;

        for (var varItem in record.varData) {
          // 找到需要高亮的文本位置
          int index = remainingText.indexOf(varItem.changeText);
          if (index == -1) continue;

          // 添加前面的普通文本
          if (index > 0) {
            spans.add(
              TextSpan(
                text: remainingText.substring(0, index),
                style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
              ),
            );
          }

          // 添加高亮文本
          spans.add(
            TextSpan(
              text: _getLimitedText(varItem.changeText),
              style: TextStyle(fontSize: 13, color: _parseColor(varItem.color)),
            ),
          );

          // 更新剩余文本
          remainingText = remainingText.substring(
            index + varItem.changeText.length,
          );
        }

        // 添加剩余的普通文本
        if (remainingText.isNotEmpty) {
          spans.add(
            TextSpan(
              text: remainingText,
              style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
            ),
          );
        }

        return RichText(
          textAlign: TextAlign.center,
          text: TextSpan(children: spans),
        );
      } else {
        // 没有varData，直接显示content
        return Text(
          record.content,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
        );
      }
    }
  }

  /// 构建会员可查看按钮
  Widget _buildVipViewButton() {
    // 会员状态下显示"查看"，非会员状态下显示"会员可查看"
    final isVip = UserManager.isVip;
    final buttonText = isVip ? '查看' : '会员可查看';
    
    return GestureDetector(
      onTap: () {
        if (isVip) {
          // 会员状态下，类型10和11点击查看按钮的行为（可以根据需要自定义）
          onTap?.call();
        } else {
          // 非会员状态下，跳转到VIP页面
          _navigateToVipPage();
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            buttonText,
            style: const TextStyle(fontSize: 13, color: Color(0xFFFF9500)),
          ),
          const SizedBox(width: 4),
          Image.asset(
            'assets/phone_history/kissu3_vip_go.webp',
            width: 6,
            height: 6,
          ),
        ],
      ),
    );
  }

  /// 跳转到VIP页面
  void _navigateToVipPage() async {
    // 上报会员可见按钮埋点
    try {
      await TrackingService.trackMembershipOnly();
      print('✅ 会员可见按钮埋点上报成功');
    } catch (e) {
      print('❌ 会员可见按钮埋点上报失败: $e');
    }
    
    Get.toNamed(
      KissuRoutePath.vip,
      arguments: {
        'previousPageName': '用机记录页面',
        'previousPageId': 'device_usage_record_page',
      },
    )?.then((_) {
      // VIP页面返回后，刷新会员状态
      _refreshVipStatus();
    });
  }

  /// 刷新会员状态
  void _refreshVipStatus() {
    // 刷新用户信息以获取最新的会员状态
    UserManager.refreshUserInfo().then((success) {
      if (success) {
        print('✅ 会员状态刷新成功');
        // 通知父组件刷新UI
        if (onVipStatusChanged != null) {
          onVipStatusChanged!();
        }
      }
    });
  }
}
