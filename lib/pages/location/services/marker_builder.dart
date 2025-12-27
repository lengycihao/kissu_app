import 'dart:ui' as ui;
import 'dart:math' as math;
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
    double size = 800.0, // 底座大小（向后兼容）
    double? designSize, // 可选：直接传入设计稿尺寸（如14或200）
  }) async {
    final pedestal = await _imageService.loadImageFromAsset(pedestalAsset);
    if (pedestal == null) {
      return BitmapDescriptor.defaultMarker;
    }

    // 🔧 基于375px设计稿的比例计算，按屏幕比例缩放后直接乘以DPI
    final dpr = ui.window.devicePixelRatio;
    final screenWidth = ui.window.physicalSize.width / dpr;

    // 根据请求的尺寸判断是大底座还是小底座
    const designWidth = 375.0;
    final screenScale = screenWidth / designWidth;

    // 支持直接传入 designSize，否则使用向后兼容的阈值逻辑
    final resolvedDesignSize = designSize ?? (size > 100 ? 200.0 : 21.0);
    final adjustedSize = resolvedDesignSize * screenScale * dpr;

    debugPrint('📱 ============ 底座Marker创建 ============');
    debugPrint('📱 设备像素比(DPI): $dpr');
    debugPrint('📱 屏幕宽度: ${screenWidth.toStringAsFixed(0)}px');
    debugPrint(
      '📱 设计稿比例: ${screenScale.toStringAsFixed(3)}x (${screenWidth.toStringAsFixed(0)} / $designWidth)',
    );
    debugPrint('📱 请求底座尺寸: ${size}px');
    debugPrint('📱 设计稿尺寸: ${resolvedDesignSize}px');
    debugPrint(
      '📱 实际底座尺寸: ${adjustedSize.toStringAsFixed(1)}px (${resolvedDesignSize}px × ${screenScale.toStringAsFixed(2)} × $dpr)',
    );
    debugPrint('📱 ==========================================');

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
    final dstRect = Rect.fromLTWH(0, 0, adjustedSize, adjustedSize);
    canvas.drawImageRect(pedestal, srcRect, dstRect, paint);

    // 转换为图片
    final picture = pictureRecorder.endRecording();

    final image = await picture.toImage(
      adjustedSize.toInt(),
      adjustedSize.toInt(),
    );
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

      // 🔧 基于375px设计稿的比例计算，确保在不同设备上按比例缩放
      final dpr = ui.window.devicePixelRatio;
      final screenWidth = ui.window.physicalSize.width / dpr; // 逻辑像素宽度

      debugPrint('📱 ============ Marker创建调试信息 ============');
      debugPrint('📱 设备像素比(DPI): $dpr');
      debugPrint(
        '📱 屏幕宽度: ${screenWidth.toStringAsFixed(0)}逻辑像素 (${ui.window.physicalSize.width.toStringAsFixed(0)}物理像素)',
      );

      // 设计稿基准：375px屏幕宽度，头像60px，大底座128px，小底座40px
      const designWidth = 375.0;
      const designAvatarSize = 50.0;
      const designLargePedestalSize = 200.0;
      const designSmallPedestalSize = 14.0;

      // 按屏幕宽度比例计算，然后直接乘以DPI
      final screenScale = screenWidth / designWidth;

      // 先按屏幕比例缩放，再乘以DPI
      final avatarSize = designAvatarSize * screenScale * dpr;
      final pedestalWidth = useLargePedestal
          ? designLargePedestalSize * screenScale * dpr
          : designSmallPedestalSize * screenScale * dpr;

      debugPrint(
        '📱 设计稿比例: ${screenScale.toStringAsFixed(3)}x (${screenWidth.toStringAsFixed(0)} / $designWidth)',
      );
      debugPrint(
        '📱 头像尺寸: ${avatarSize.toStringAsFixed(1)}px (设计稿${designAvatarSize}px × ${screenScale.toStringAsFixed(2)} × $dpr)',
      );
      debugPrint(
        '📱 底座尺寸: ${pedestalWidth.toStringAsFixed(1)}px (设计稿${useLargePedestal ? designLargePedestalSize : designSmallPedestalSize}px × ${screenScale.toStringAsFixed(2)} × $dpr)',
      );

      // 所有尺寸都基于60px设计稿按比例缩放
      // 设计稿中：边框3.67px，表情背景26.67px，边距3.33px，padding 3.33-6.67px
      final avatarBorderWidth = avatarSize * (3.67 / 60.0);

      final emojiBgHeight = (face != null && face.isValid)
          ? avatarSize * (26.67 / 60.0)
          : 0.0;
      final emojiBgMargin = (face != null && face.isValid)
          ? avatarSize * (3.33 / 60.0)
          : 0.0;
      final avatarTopPadding = (face != null && face.isValid)
          ? 0.0
          : avatarBorderWidth + avatarSize * (3.33 / 60.0);

      final padding = avatarSize * (6.67 / 60.0); // 设计稿中padding约6.67px
      final canvasWidth =
          (pedestalWidth > avatarSize ? pedestalWidth : avatarSize) + padding;

      // 🎯 修复：canvas只包含头像部分，不包含底座（底座是独立marker）
      final canvasHeight =
          avatarTopPadding +
          emojiBgHeight +
          emojiBgMargin +
          avatarSize +
          padding;
      final size = Size(canvasWidth, canvasHeight);

      debugPrint(
        '📱 Canvas尺寸: ${canvasWidth.toStringAsFixed(1)} x ${canvasHeight.toStringAsFixed(1)}px',
      );
      debugPrint('📱 边框宽度: ${avatarBorderWidth.toStringAsFixed(2)}px');

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

      // 🎯 修复：锚点要对准头像底部，让头像底部吸附在实际位置
      // 因为canvas包含padding，所以需要动态计算
      final avatarBottomY = avatarTop + avatarSize;
      final anchorY = avatarBottomY / size.height;

      debugPrint('📱 图片尺寸: ${size.width.toInt()} x ${size.height.toInt()}px');
      debugPrint('📱 头像底部Y: ${avatarBottomY.toStringAsFixed(1)}px');
      debugPrint('📱 锚点位置: (0.5, ${anchorY.toStringAsFixed(3)})');
      debugPrint('📱 创建耗时: ${createDuration.inMilliseconds}ms');
      debugPrint('📱 ============================================');

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

    // 单层白色边框（宽度 1），移除原有粉色/内层双重边框
    final outerBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, size / 2, outerBorderPaint);

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
      // 头像应该在白色边框内侧，留出少量内间距
      final avatarRadius = size / 2 - 4;
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

  /// 🌊 创建波纹圆环Marker（用于叠加在头像上）
  /// 
  /// 创建一个透明的圆环，只有边框，用于波纹动画
  Future<BitmapDescriptor> createRippleRingMarker({
    required double size, // 圆环大小（逻辑像素）
    Color color = const Color(0xFFFFA1C7), // 波纹颜色
    double strokeWidth = 1.0, // 线宽
  }) async {
    final dpr = ui.window.devicePixelRatio;
    final screenWidth = ui.window.physicalSize.width / dpr;
    const designWidth = 375.0;
    final screenScale = screenWidth / designWidth;

    // 根据屏幕缩放计算实际尺寸
    final actualSize = size * screenScale * dpr;
    final actualStrokeWidth = strokeWidth * screenScale * dpr;

    // 创建画布
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    // 绘制填充渐变圆
    final center = Offset(actualSize / 2, actualSize / 2);
    final radius = actualSize / 2;

    final fillPaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius,
        const [
          Color(0xFFFFA1C7),
          Color(0xFFFFA1C7),
        ],
      )
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius, fillPaint);

    // 绘制白色边框
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = actualStrokeWidth
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius - actualStrokeWidth / 2, borderPaint);

    // 转换为图片
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(
      actualSize.toInt(),
      actualSize.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(bytes);
  }

  /// 创建距离标签Marker（黑色背景 + 白色文字）
  /// 固定尺寸：64px × 21px
  Future<BitmapDescriptor> createDistanceLabelMarker({
    required String distanceText,
  }) async {
    final dpr = ui.window.devicePixelRatio;
    final screenWidth = ui.window.physicalSize.width / dpr;
    const designWidth = 375.0;
    final screenScale = screenWidth / designWidth;

    // 固定标签尺寸（设计稿尺寸）
    const designLabelWidth = 64.0;
    const designLabelHeight = 21.0;
    final width = designLabelWidth * screenScale * dpr;
    final height = designLabelHeight * screenScale * dpr;

    // 文字样式
    final textStyle = TextStyle(
      color: Color(0xffF3ACC9),
      fontSize: 10 * screenScale,
      fontWeight: FontWeight.bold,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: distanceText, style: textStyle),
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();

    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    // 绘制黑色圆角矩形背景
    final rect = Rect.fromLTWH(0, 0, width, height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(15 * screenScale * dpr));
    final bgPaint = Paint()
      ..color = const Color(0xFF000000)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawRRect(rrect, bgPaint);

    // 绘制白色文字（居中）
    canvas.save();
    canvas.scale(dpr, dpr);
    final textX = (width / dpr - textPainter.width) / 2;
    final textY = (height / dpr - textPainter.height) / 2;
    textPainter.paint(
      canvas,
      Offset(textX, textY),
    );
    canvas.restore();

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(bytes);
  }

  Future<BitmapDescriptor> createRippleBackgroundMarker({
    required double size,
  }) async {
    final dpr = ui.window.devicePixelRatio;
    final screenWidth = ui.window.physicalSize.width / dpr;
    const designWidth = 375.0;
    final screenScale = screenWidth / designWidth;

    final actualSize = size * screenScale * dpr;

    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    final center = Offset(actualSize / 2, actualSize / 2);
    final radius = actualSize / 2;

    final fillPaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius,
        const [
          Color(0x99F8D7DF),
          Color(0x99FBE8ED),
        ],
      )
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius, fillPaint);

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(
      actualSize.toInt(),
      actualSize.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(bytes);
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

  /// 🎯 创建带背景图的头像Marker（用于并排展示）
  /// 
  /// 头像会被绘制在背景图上，无边框
  /// [avatarUrl] 头像URL或本地路径
  /// [defaultAsset] 默认头像资源
  /// [bgAsset] 背景图资源路径
  /// [designAvatarSize] 设计稿中头像尺寸（逻辑像素）
  /// [designBgSize] 设计稿中背景图尺寸（逻辑像素）
  /// [avatarOffsetY] 头像在背景图中的Y偏移（相对于背景图顶部的比例，0-1）
  Future<Map<String, dynamic>> createAvatarWithBgMarker(
    String avatarUrl, {
    String? defaultAsset,
    required String bgAsset,
    double designAvatarSize = 50.0,
    double designBgWidth = 60.0,   // 背景图宽度
    double designBgHeight = 65.0,  // 背景图高度
    double avatarOffsetY = 5, // 头像顶部距离背景图顶部的比例
    double rotationDegrees = 0.0, // 旋转角度（度），正数顺时针，负数逆时针
  }) async {
    try {
      // 加载背景图
      final bgImage = await _imageService.loadImageFromAsset(bgAsset);
      if (bgImage == null) {
        debugPrint('❌ 加载背景图失败: $bgAsset');
        return {
          'descriptor': BitmapDescriptor.defaultMarker,
          'anchor': const Offset(0.5, 1.0),
        };
      }

      // 🔧 基于375px设计稿的比例计算
      final dpr = ui.window.devicePixelRatio;
      final screenWidth = ui.window.physicalSize.width / dpr;
      const designWidth = 375.0;
      final screenScale = screenWidth / designWidth;

      // 计算实际尺寸
      final bgWidth = designBgWidth * screenScale * dpr;
      final bgHeight = designBgHeight * screenScale * dpr;
      final avatarSize = designAvatarSize * screenScale * dpr;
      final spaceHeight = avatarOffsetY * screenScale * dpr;
      
      // 旋转后需要更大的画布来容纳旋转后的图像
      final rotationRadians = rotationDegrees * 3.14159265359 / 180.0;
      
      // 计算旋转后的边界框大小（使用对角线长度作为画布大小）
      final diagonal = (bgWidth * bgWidth + bgHeight * bgHeight);
      final diagonalSqrt = diagonal > 0 ? math.sqrt(diagonal) : bgWidth;
      final canvasWidth = rotationDegrees.abs() > 0.1 ? diagonalSqrt : bgWidth;
      final canvasHeight = rotationDegrees.abs() > 0.1 ? diagonalSqrt : bgHeight;
      
      debugPrint('📱 ============ 带背景头像Marker创建 ============');
      debugPrint('📱 背景图尺寸: ${bgWidth.toStringAsFixed(1)} x ${bgHeight.toStringAsFixed(1)}px');
      debugPrint('📱 头像尺寸: ${avatarSize.toStringAsFixed(1)}px');
      debugPrint('📱 旋转角度: $rotationDegrees°');
      debugPrint('📱 画布尺寸: ${canvasWidth.toStringAsFixed(1)} x ${canvasHeight.toStringAsFixed(1)}px');

      // 创建画布
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      
      // 如果需要旋转，先移动到画布中心，旋转，再移动回来
      if (rotationDegrees.abs() > 0.1) {
        canvas.save();
        // 移动到画布中心
        canvas.translate(canvasWidth / 2, canvasHeight / 2);
        // 旋转
        canvas.rotate(rotationRadians);
        // 移动回来，使背景图中心对准画布中心
        canvas.translate(-bgWidth / 2, -bgHeight / 2);
      }

      // 1. 绘制背景图
      final bgSrcRect = Rect.fromLTWH(
        0, 0,
        bgImage.width.toDouble(),
        bgImage.height.toDouble(),
      );
      final bgDstRect = Rect.fromLTWH(0, 0, bgWidth, bgHeight);
      canvas.drawImageRect(bgImage, bgSrcRect, bgDstRect, Paint()..isAntiAlias = true);

      // 2. 计算头像位置（在背景图中心偏上）
      final avatarCenterX = bgWidth / 2;
      final avatarCenterY = bgHeight / 2 - spaceHeight;
      final avatarCenter = Offset(avatarCenterX, avatarCenterY);

      // 3. 加载并绘制头像（无边框，直接圆形裁剪）
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
        // 圆形裁剪
        final avatarRect = Rect.fromCenter(
          center: avatarCenter,
          width: avatarSize,
          height: avatarSize,
        );
        final clipPath = Path()..addOval(avatarRect);
        canvas.clipPath(clipPath);
        
        // 绘制头像
        final srcRect = Rect.fromLTWH(
          0, 0,
          avatarImage.width.toDouble(),
          avatarImage.height.toDouble(),
        );
        canvas.drawImageRect(avatarImage, srcRect, avatarRect, Paint()..isAntiAlias = true);
        canvas.restore();
      }
      
      // 如果有旋转，恢复canvas状态
      if (rotationDegrees.abs() > 0.1) {
        canvas.restore();
      }

      // 转换为图片
      final picture = pictureRecorder.endRecording();
      final image = await picture.toImage(canvasWidth.toInt(), canvasHeight.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      // 计算锚点：旋转后需要根据背景图尖尖的实际位置计算
      // 背景图尖尖原本在底部中心(bgWidth/2, bgHeight)
      // 旋转后，尖尖位置会改变
      Offset anchor;
      if (rotationDegrees.abs() > 0.1) {
        // 旋转后，背景图中心在画布中心
        // 尖尖相对于背景图中心的偏移是(0, bgHeight/2)
        // 旋转后尖尖的新位置
        final tipOffsetX = (bgHeight / 2) * math.sin(rotationRadians);
        final tipOffsetY = (bgHeight / 2) * math.cos(rotationRadians);
        // 尖尖在画布中的位置
        final tipX = canvasWidth / 2 + tipOffsetX;
        final tipY = canvasHeight / 2 + tipOffsetY;
        // 锚点是尖尖位置相对于画布的比例
        anchor = Offset(tipX / canvasWidth, tipY / canvasHeight);
        debugPrint('📱 旋转后锚点: (${anchor.dx.toStringAsFixed(3)}, ${anchor.dy.toStringAsFixed(3)})');
      } else {
        anchor = const Offset(0.5, 1.0);
      }

      debugPrint('📱 ============================================');

      return {
        'descriptor': BitmapDescriptor.fromBytes(bytes),
        'anchor': anchor,
      };
    } catch (e) {
      debugPrint('Create avatar with bg marker error: $e');
      return {
        'descriptor': BitmapDescriptor.defaultMarker,
        'anchor': const Offset(0.5, 1.0),
      };
    }
  }
}
