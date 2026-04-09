import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';

/// 地图标记工具类
/// 用于创建自定义地图标记（如圆形头像标记）
class MapMarkerUtil {
  /// 创建圆形头像标记（与定位页面完全一致）
  /// 
  /// [avatarUrl] 头像图片 URL
  /// [size] 标记大小（默认 80.0）
  /// [borderWidth] 边框宽度（已废弃，使用固定双层边框）
  static Future<BitmapDescriptor> createCircleAvatarMarker(
    String? avatarUrl, {
    double size = 80.0,
    double borderWidth = 4.0, // 此参数已废弃，保留仅为兼容性
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..isAntiAlias = true;

    final center = Offset(size / 2, size / 2);
    
    // 🔧 修复：圆的半径要减去粉色边框宽度的一半，确保边框不超出canvas
    final circleRadius = size / 2 - 2; // 减去粉色边框的一半（4/2=2）

    // 绘制白色底色（与定位页面完全一致）
    final avatarPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, circleRadius, avatarPaint);

    // 第一层：外层边框，改为白色以满足统一视觉
    final outerBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, circleRadius, outerBorderPaint);

    // 移除内层大白边，保留单层细白边框

    // 加载并绘制头像图片
    ui.Image? avatarImage;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      try {
        avatarImage = await _loadNetworkImage(avatarUrl);
      } catch (e) {
        // 加载失败，使用默认图标
        avatarImage = null;
      }
    }

    if (avatarImage != null) {
      canvas.save();
      // 头像应该在白色边框内侧，留出少量内间距
      final avatarRadius = circleRadius - 4;
      final avatarInnerRect = Rect.fromCenter(
        center: center,
        width: avatarRadius * 2,
        height: avatarRadius * 2,
      );
      final clipPath = Path()..addOval(avatarInnerRect);
      canvas.clipPath(clipPath);
      final srcRect = Rect.fromLTWH(0, 0, avatarImage.width.toDouble(), avatarImage.height.toDouble());
      final dstRect = avatarInnerRect;
      canvas.drawImageRect(avatarImage, srcRect, dstRect, paint);
      canvas.restore();
    } else {
      // 绘制占位符（与定位页面完全一致）
      final iconPaint = Paint()..color = const Color(0xFFE8B4CB);
      canvas.drawCircle(center, circleRadius - 11 - 12.5, iconPaint);
      final textPainter = TextPainter(
        text: TextSpan(
          text: '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.7, // 根据size动态调整字体大小
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          center.dx - textPainter.width / 2,
          center.dy - textPainter.height / 2,
        ),
      );
    }

    // 转换为图片
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }

  /// 加载网络图片
  static Future<ui.Image> _loadNetworkImage(String url) async {
    final completer = Completer<ui.Image>();
    final imageProvider = NetworkImage(url);
    final stream = imageProvider.resolve(const ImageConfiguration());

    stream.addListener(ImageStreamListener((ImageInfo info, bool _) {
      completer.complete(info.image);
    }, onError: (exception, stackTrace) {
      completer.completeError(exception);
    }));

    return completer.future;
  }
}

