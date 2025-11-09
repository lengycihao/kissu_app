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

  /// 🚀 创建纯底座Marker（用于实时旋转）
  Future<BitmapDescriptor> createPedestalMarker({
    required String pedestalAsset,
    double size = 800.0, // 底座大小
  }) async {
    final pedestal = await _imageService.loadImageFromAsset(pedestalAsset);
    if (pedestal == null) {
      return BitmapDescriptor.defaultMarker;
    }

    // 创建画布（只包含底座）
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()..isAntiAlias = true;

    // 绘制底座（居中）
    final srcRect = Rect.fromLTWH(
      0,
      0,
      pedestal.width.toDouble(),
      pedestal.height.toDouble(),
    );
    final dstRect = Rect.fromLTWH(0, 0, size, size);
    canvas.drawImageRect(pedestal, srcRect, dstRect, paint);

    // 转换为图片
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(bytes);
  }

  /// 创建头像标记
  /// [skipPedestal] = true 时不绘制底座（底座将作为独立marker）
  /// 返回: Map包含 'descriptor' (BitmapDescriptor) 和 'anchor' (Offset)
  Future<Map<String, dynamic>> createAvatarMarker(
    String avatarUrl, {
    String? defaultAsset,
    required String baseAsset,
    Face? face,
    bool useLargePedestal = false, // 是否使用大底座（用于计算anchor）
    bool skipPedestal = false, // 是否跳过底座绘制
  }) async {
    final createStartTime = DateTime.now();

    try {
      final pedestal = await _imageService.loadImageFromAsset(baseAsset);
      if (pedestal == null) {
        return {
          'descriptor': BitmapDescriptor.defaultMarker,
          'anchor': const Offset(0.5, 1.0),
        };
      }

      // 头像和底座尺寸配置
      final avatarSize = 180.0; // 保持头像大小不变
      final pedestalScale = 0.8;
      final pedestalWidth = useLargePedestal
          ? 800.0 // 🎯 改成800x800
          : pedestal.width.toDouble() * pedestalScale;
      // 双层边框（不重叠）：外层粉色4px（向外2px）+ 内层白色9px = 从中心到头像边缘11px
      final avatarBorderWidth = 11.0;

      final emojiBgHeight = (face != null && face.isValid) ? 80.0 : 0.0;
      final emojiBgMargin = (face != null && face.isValid) ? 10.0 : 0.0;
      final avatarTopPadding = (face != null && face.isValid)
          ? 0.0
          : avatarBorderWidth + 10;

      final canvasWidth =
          (pedestalWidth > avatarSize ? pedestalWidth : avatarSize) + 20;
      // 🎯 修复：canvas只包含头像部分，不包含底座（底座是独立marker）
      final canvasHeight =
          avatarTopPadding +
          emojiBgHeight +
          emojiBgMargin +
          avatarSize +
          20; // 底部留一点padding即可
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

      // 🎯 底座作为独立marker，这里不绘制
      // 底座中心点对齐头像底部（用于计算anchor）

      // 绘制表情背景
      if (face != null && face.isValid) {
        await _drawEmojiBackground(
          canvas,
          emojiBgLeft,
          emojiBgTop,
          avatarSize,
          emojiBgHeight,
          face,
        );
      }

      final avatarCenter = Offset(avatarCenterX, avatarCenterY);

      // 绘制头像
      await _drawAvatar(
        canvas,
        avatarUrl,
        defaultAsset,
        avatarCenter,
        avatarSize,
      );

      final picture = recorder.endRecording();
      final image = await picture.toImage(
        size.width.toInt(),
        size.height.toInt(),
      );
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final createDuration = DateTime.now().difference(createStartTime);
      debugPrint('📊 创建Marker耗时: ${createDuration.inMilliseconds}ms');

      // 🎯 修复：锚点要对准头像底部，让头像底部吸附在实际位置
      // 因为canvas包含padding，所以需要动态计算
      final avatarBottomY = avatarTop + avatarSize;
      final anchorY = avatarBottomY / size.height;

      debugPrint(
        '🎯 Marker锚点: (0.5, ${anchorY.toStringAsFixed(3)}), 头像底部Y: $avatarBottomY, canvas高度: ${size.height}',
      );

      return {
        'descriptor': BitmapDescriptor.fromBytes(bytes),
        'anchor': Offset(0.5, anchorY),
      };
    } catch (e) {
      debugPrint('Create avatar marker error: $e');
      return {
        'descriptor': BitmapDescriptor.defaultMarker,
        'anchor': const Offset(0.5, 1.0),
      };
    }
  }

  /// 绘制底座（带旋转）
  // 🗑️ 已删除_drawPedestal方法，底座现在作为独立marker绘制和旋转

  /// 绘制头像
  Future<void> _drawAvatar(
    Canvas canvas,
    String avatarUrl,
    String? defaultAsset,
    Offset center,
    double size,
  ) async {
    // size参数是avatarSize（180），canvas有足够的padding容纳边框

    // 绘制白色背景
    final avatarPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size / 2, avatarPaint);

    // 第一层：外层粉色边框 (#FF88AA, 4px)
    final outerBorderPaint = Paint()
      ..color = const Color(0xFFFF88AA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, size / 2, outerBorderPaint);

    // 第二层：内层白色边框 (白色, 9px)
    // 白色边框要在粉色边框内侧，不能覆盖粉色
    // 粉色边框外半径 = size/2，内半径 = size/2 - 2
    // 白色边框应该从 size/2 - 2 开始往内，宽度9px，所以中心线在 size/2 - 2 - 4.5 = size/2 - 6.5
    final innerBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9;
    canvas.drawCircle(center, size / 2 - 6.5, innerBorderPaint);

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
      // 头像应该在白色边框内侧
      // 白色边框中心线在 size/2 - 6.5，宽度9px，所以内半径 = size/2 - 6.5 - 4.5 = size/2 - 11
      final avatarRadius = size / 2 - 11;
      final avatarInnerRect = Rect.fromCenter(
        center: center,
        width: avatarRadius * 2,
        height: avatarRadius * 2,
      );
      final clipPath = Path()..addOval(avatarInnerRect);
      canvas.clipPath(clipPath);
      final srcRect = Rect.fromLTWH(
        0,
        0,
        avatarImage.width.toDouble(),
        avatarImage.height.toDouble(),
      );
      final dstRect = avatarInnerRect;
      canvas.drawImageRect(avatarImage, srcRect, dstRect, Paint());
      canvas.restore();
    } else {
      // 绘制占位符（同样需要在白色边框内侧）
      final iconPaint = Paint()..color = const Color(0xFFE8B4CB);
      canvas.drawCircle(center, size / 2 - 11 - 12.5, iconPaint);
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
      final emojiBg = await _imageService.loadImageFromAsset(
        'assets/3.0/kissu3_emoij_bg.webp',
      );
      if (emojiBg == null) return;

      final bgSrcRect = Rect.fromLTWH(
        0,
        0,
        emojiBg.width.toDouble(),
        emojiBg.height.toDouble(),
      );
      final bgDstRect = Rect.fromLTWH(left, top, width, height);
      canvas.drawImageRect(emojiBg, bgSrcRect, bgDstRect, Paint());

      if (face.faceUrl != null && face.faceUrl!.isNotEmpty) {
        final emojiIcon = await _imageService.loadImageFromNetwork(
          face.faceUrl!,
        );
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
          final iconSrcRect = Rect.fromLTWH(
            0,
            0,
            emojiIcon.width.toDouble(),
            emojiIcon.height.toDouble(),
          );
          final iconDstRect = Rect.fromLTWH(
            startLeft,
            iconTop,
            iconSize,
            iconSize,
          );
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
