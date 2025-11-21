import 'package:flutter/material.dart';
import 'package:kissu_app/services/amap_static_map_service.dart';
import 'package:kissu_app/pages/location/location_reminder/location_reminder_controller.dart';
import 'dart:math' as math;

/// 位置地图快照组件
/// 显示高德静态地图，并叠加自定义标记图标和围栏圆圈
/// 
/// 性能优化：
/// - 使用 const 构造函数
/// - 添加缓存配置
/// - 减少不必要的日志输出
class LocationMapSnapshot extends StatelessWidget {
  final double longitude;
  final double latitude;
  final int radius; // 围栏半径（米）
  final int iconId; // 图标ID (1-公司, 2-家, 3-娱乐, 4-健身房, 5-商场)
  final ReminderType reminderType; // 提醒类型（到达/离开）
  final String size; // 地图尺寸
  final double height; // 组件高度
  final bool isSatellite; // 是否为卫星地图
  
  const LocationMapSnapshot({
    Key? key,
    required this.longitude,
    required this.latitude,
    required this.radius,
    required this.iconId,
    required this.reminderType,
    this.size = '800*160',
    this.height = 80,
    this.isSatellite = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 生成静态地图URL（不带标记）
    final mapUrl = AMapStaticMapService.getStaticMapUrlWithCircle(
      longitude: longitude,
      latitude: latitude,
      radius: radius,
      size: size,
      isSatellite: isSatellite,
    );
    
    // 仅在调试模式下输出日志
    // print('🗺️ 地图URL: $mapUrl');
    
    return Container(
      height: height,
      width: double.infinity,
      color: const Color(0xFFF5F5F5),
      child: Stack(
        children: [
          // 背景地图
          Positioned.fill(
            child: Image.network(
              mapUrl,
              fit: BoxFit.cover,
              // 添加缓存配置，避免重复下载
              cacheWidth: 800, // 缓存宽度
              cacheHeight: 160, // 缓存高度
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  // 移除频繁的日志输出
                  // print('✅ 地图加载成功');
                  return child;
                }
                // 移除频繁的日志输出
                // print('⏳ 地图加载中: ${loadingProgress.cumulativeBytesLoaded} / ${loadingProgress.expectedTotalBytes}');
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF4D9FFF),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                // 仅在错误时输出日志（保留）
                debugPrint('❌ 地图加载失败: $error');
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.map_outlined,
                        size: 32,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '地图加载失败',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // 围栏圆圈（半透明）
          Positioned.fill(
            child: CustomPaint(
              painter: _CirclePainter(
                radius: radius,
                zoom: AMapStaticMapService.calculateZoomByRadius(radius),
                reminderType: reminderType,
              ),
            ),
          ),
          
          // 中心标记图标
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _getLocationIcon(iconId),
                // // 图标下方的小三角指示器
                // CustomPaint(
                //   size: const Size(8, 4),
                //   painter: _TrianglePainter(),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// 获取位置图标
  Widget _getLocationIcon(int iconId) {
    // 统一使用位置图标，不再根据 iconId 区分
    const assetPath = 'assets/images/home_list_type_location.webp';

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        // shape: BoxShape.circle,
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withOpacity(0.2),
        //     blurRadius: 4,
        //     offset: const Offset(0, 2),
        //   ),
        // ],
      ),
      padding: const EdgeInsets.all(6),
      child: Image.asset(
        assetPath,
        width: 16,
        height: 16,
        errorBuilder: (context, error, stackTrace) {
          // 如果图标加载失败，显示默认图标
          return const Icon(
            Icons.location_on,
            size: 24,
            color: Color(0xFFFF88AA),
          );
        },
      ),
    );
  }
}

/// 绘制圆圈的画笔
/// 
/// 性能优化：
/// - 缓存 Paint 对象
/// - 优化 shouldRepaint 判断
class _CirclePainter extends CustomPainter {
  final int radius; // 实际半径（米）
  final int zoom; // 缩放级别
  final ReminderType reminderType; // 提醒类型
  
  const _CirclePainter({
    required this.radius,
    required this.zoom,
    required this.reminderType,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // 计算屏幕上的像素半径
    // 根据缩放级别和实际半径计算像素半径
    // 公式：像素半径 = 实际半径（米） * 2^(缩放级别-15) * 0.3（经验系数）
    final pixelRadius = radius * math.pow(2, zoom - 15) * 0.3;
    
    // 限制最大和最小半径
    final clampedRadius = pixelRadius.clamp(20.0, size.width / 2.5);
    
    // 根据提醒类型选择颜色：到达=蓝色，离开=粉色
    final baseColor = reminderType == ReminderType.arrive 
        ? const Color(0xFF4D9FFF) // 蓝色
        : const Color(0xFFFF88AA); // 粉色
    
    // 圆圈画笔
    final circlePaint = Paint()
      ..color = baseColor.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    
    // 圆圈边框画笔
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    final center = Offset(size.width / 2, size.height / 2);
    
    // 绘制填充圆圈
    canvas.drawCircle(center, clampedRadius, circlePaint);
    
    // 绘制边框
    canvas.drawCircle(center, clampedRadius, borderPaint);
  }
  
  @override
  bool shouldRepaint(_CirclePainter oldDelegate) {
    return oldDelegate.radius != radius || 
           oldDelegate.zoom != zoom ||
           oldDelegate.reminderType != reminderType;
  }
}

/// 绘制三角形指示器的画笔
class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final path = Path()
      ..moveTo(size.width / 2, size.height) // 底部中心
      ..lineTo(0, 0) // 左上
      ..lineTo(size.width, 0) // 右上
      ..close();
    
    canvas.drawPath(path, paint);
    
    // 添加阴影效果
    canvas.drawShadow(path, Colors.black.withOpacity(0.2), 2, true);
  }
  
  @override
  bool shouldRepaint(_TrianglePainter oldDelegate) => false;
}

