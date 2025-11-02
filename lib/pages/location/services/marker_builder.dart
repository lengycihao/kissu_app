import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:kissu_app/model/location_model/location_model.dart';
import 'map_image_service.dart';

/// 地图标记构建器
/// 
/// 负责创建地图上的头像标记，包括：
/// - 头像圆形裁剪
/// - 边框绘制
/// - 表情背景绘制
/// - 底座绘制
class MarkerBuilder {
  final MapImageService _imageService = MapImageService.instance;

  /// 创建头像标记
  Future<BitmapDescriptor> createAvatarMarker(
    String avatarUrl, {
    String? defaultAsset,
    required String baseAsset,
    Face? face,
  }) async {
    final createStartTime = DateTime.now();
    
    try {
      final pedestal = await _imageService.loadImageFromAsset(baseAsset);
      if (pedestal == null) {
        return BitmapDescriptor.defaultMarker;
      }

      final avatarSize = 180.0;
      final pedestalScale = 0.8;
      final pedestalWidth = pedestal.width.toDouble() * pedestalScale;
      final pedestalHeight = pedestal.height.toDouble() * pedestalScale;
      final avatarBorderWidth = 20.0;

      final emojiBgHeight = (face != null && face.isValid) ? 80.0 : 0.0;
      final emojiBgMargin = (face != null && face.isValid) ? 10.0 : 0.0;
      final avatarTopPadding = (face != null && face.isValid) ? 0.0 : avatarBorderWidth + 10;

      final canvasWidth = (pedestalWidth > avatarSize ? pedestalWidth : avatarSize) + 20;
      final canvasHeight = avatarTopPadding + emojiBgHeight + emojiBgMargin + avatarSize + pedestalHeight / 2 + 10;
      final size = Size(canvasWidth, canvasHeight);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final emojiBgTop = avatarTopPadding;
      final emojiBgLeft = (size.width - avatarSize) / 2;

      final avatarTop = (face != null && face.isValid)
          ? emojiBgTop + emojiBgHeight + emojiBgMargin
          : avatarTopPadding;
      final avatarCenterX = size.width / 2;
      final avatarCenterY = avatarTop + avatarSize / 2;

      final avatarBottom = avatarTop + avatarSize;
      final pedestalTop = avatarBottom - pedestalHeight / 2;
      final pedestalLeft = (size.width - pedestalWidth) / 2;

      // 绘制底座
      _drawPedestal(canvas, pedestal, pedestalLeft, pedestalTop, pedestalWidth, pedestalHeight);

      // 绘制表情背景
      if (face != null && face.isValid) {
        await _drawEmojiBackground(canvas, emojiBgLeft, emojiBgTop, avatarSize, emojiBgHeight, face);
      }

      final avatarCenter = Offset(avatarCenterX, avatarCenterY);

      // 绘制头像
      await _drawAvatar(canvas, avatarUrl, defaultAsset, avatarCenter, avatarSize);

      final picture = recorder.endRecording();
      final image = await picture.toImage(size.width.toInt(), size.height.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final createDuration = DateTime.now().difference(createStartTime);
      debugPrint('📊 创建Marker耗时: ${createDuration.inMilliseconds}ms');
      
      return BitmapDescriptor.fromBytes(bytes);
    } catch (e) {
      debugPrint('Create avatar marker error: $e');
      return await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(44, 46)),
        'assets/kissu_location_start.webp',
      );
    }
  }

  /// 绘制底座
  void _drawPedestal(Canvas canvas, ui.Image pedestal, double left, double top, double width, double height) {
    final srcRect = Rect.fromLTWH(0, 0, pedestal.width.toDouble(), pedestal.height.toDouble());
    final dstRect = Rect.fromLTWH(left, top, width, height);
    canvas.drawImageRect(pedestal, srcRect, dstRect, Paint());
  }

  /// 绘制头像
  Future<void> _drawAvatar(
    Canvas canvas,
    String avatarUrl,
    String? defaultAsset,
    Offset center,
    double size,
  ) async {
    final avatarRect = Rect.fromCenter(
      center: center,
      width: size,
      height: size,
    );

    // 绘制白色背景
    final avatarPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size / 2, avatarPaint);

    // 绘制边框
    final borderPaint = Paint()
      ..color = const Color(0xFFFF9AD8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20;
    canvas.drawCircle(center, size / 2, borderPaint);

    // 加载并绘制头像图片
    ui.Image? avatarImage;
    if (avatarUrl.isNotEmpty) {
      try {
        if (avatarUrl.startsWith('http')) {
          avatarImage = await _imageService.loadImageFromNetwork(avatarUrl);
        } else {
          avatarImage = await _imageService.loadImageFromAsset(avatarUrl);
        }
      } catch (e) {
        debugPrint('Load avatar error: $e');
      }
    }

    if (avatarImage == null && defaultAsset != null) {
      avatarImage = await _imageService.loadImageFromAsset(defaultAsset);
    }

    if (avatarImage != null) {
      canvas.save();
      final clipPath = Path()..addOval(avatarRect);
      canvas.clipPath(clipPath);
      final srcRect = Rect.fromLTWH(0, 0, avatarImage.width.toDouble(), avatarImage.height.toDouble());
      final dstRect = avatarRect;
      canvas.drawImageRect(avatarImage, srcRect, dstRect, Paint());
      canvas.restore();
    } else {
      // 绘制占位符
      final iconPaint = Paint()..color = const Color(0xFFE8B4CB);
      canvas.drawCircle(center, size / 2 - 12.5, iconPaint);
      final textPainter = TextPainter(
        text: TextSpan(
          text: '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 125,
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
  }

  /// 绘制表情背景
  Future<void> _drawEmojiBackground(
    Canvas canvas,
    double left,
    double top,
    double width,
    double height,
    Face face,
  ) async {
    try {
      final emojiBg = await _imageService.loadImageFromAsset('assets/3.0/kissu3_emoij_bg.webp');
      if (emojiBg == null) return;

      final bgSrcRect = Rect.fromLTWH(0, 0, emojiBg.width.toDouble(), emojiBg.height.toDouble());
      final bgDstRect = Rect.fromLTWH(left, top, width, height);
      canvas.drawImageRect(emojiBg, bgSrcRect, bgDstRect, Paint());

      if (face.faceUrl != null && face.faceUrl!.isNotEmpty) {
        final emojiIcon = await _imageService.loadImageFromNetwork(face.faceUrl!);
        if (emojiIcon != null) {
          final iconSize = height * 0.45;
          TextPainter? textPainter;
          
          if (face.faceText != null && face.faceText!.isNotEmpty) {
            textPainter = TextPainter(
              text: TextSpan(
                text: face.faceText!,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'LiuHuanKaTongShouShu',
                ),
              ),
              textDirection: ui.TextDirection.ltr,
            );
            textPainter.layout();
          }

          final spacing = (textPainter != null) ? 6.0 : 0.0;
          final textWidth = textPainter?.width ?? 0.0;
          final totalWidth = iconSize + spacing + textWidth;
          final startLeft = left + (width - totalWidth) / 2;

          final iconTop = top + (height - iconSize) / 2;
          final iconSrcRect = Rect.fromLTWH(0, 0, emojiIcon.width.toDouble(), emojiIcon.height.toDouble());
          final iconDstRect = Rect.fromLTWH(startLeft, iconTop, iconSize, iconSize);
          canvas.drawImageRect(emojiIcon, iconSrcRect, iconDstRect, Paint());

          if (textPainter != null) {
            final textLeft = startLeft + iconSize + spacing;
            final textTop = top + (height - textPainter.height) / 2;
            textPainter.paint(canvas, Offset(textLeft, textTop));
          }
        }
      }
    } catch (e) {
      debugPrint('Draw emoji background error: $e');
    }
  }
}

