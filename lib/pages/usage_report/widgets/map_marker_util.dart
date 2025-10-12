import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';

/// 地图标记工具类
/// 用于创建自定义地图标记（如圆形头像标记）
class MapMarkerUtil {
  /// 创建圆形头像标记
  /// 
  /// [avatarUrl] 头像图片 URL
  /// [size] 标记大小（默认 80.0）
  /// [borderWidth] 边框宽度（默认 4.0）
  static Future<BitmapDescriptor> createCircleAvatarMarker(
    String? avatarUrl, {
    double size = 80.0,
    double borderWidth = 4.0,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..isAntiAlias = true;

    // 绘制外圈白色边框
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, borderPaint);

    // 绘制头像（内圈）
    final avatarRadius = size / 2 - borderWidth;
    final avatarCenter = Offset(size / 2, size / 2);

    // 裁剪为圆形
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: avatarCenter, radius: avatarRadius)),
    );

    // 加载并绘制头像
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      try {
        final ui.Image avatarImage = await _loadNetworkImage(avatarUrl);
        final srcRect = Rect.fromLTWH(
          0,
          0,
          avatarImage.width.toDouble(),
          avatarImage.height.toDouble(),
        );
        final dstRect = Rect.fromCircle(center: avatarCenter, radius: avatarRadius);
        canvas.drawImageRect(avatarImage, srcRect, dstRect, paint);
      } catch (e) {
        // 加载失败，绘制默认图标
        _drawDefaultAvatar(canvas, avatarCenter, avatarRadius);
      }
    } else {
      // 没有头像URL，绘制默认图标
      _drawDefaultAvatar(canvas, avatarCenter, avatarRadius);
    }

    canvas.restore();

    // 转换为图片
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }

  /// 绘制默认头像（person 图标）
  static void _drawDefaultAvatar(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, paint);

    // 绘制简单的人形图标
    final iconPaint = Paint()
      ..color = Colors.grey[600]!
      ..style = PaintingStyle.fill;

    // 头部
    canvas.drawCircle(
      Offset(center.dx, center.dy - radius * 0.2),
      radius * 0.25,
      iconPaint,
    );

    // 身体
    final path = Path();
    path.moveTo(center.dx - radius * 0.4, center.dy + radius * 0.6);
    path.quadraticBezierTo(
      center.dx,
      center.dy + radius * 0.1,
      center.dx + radius * 0.4,
      center.dy + radius * 0.6,
    );
    canvas.drawPath(path, iconPaint);
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

