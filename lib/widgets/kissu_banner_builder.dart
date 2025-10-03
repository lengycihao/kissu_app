import 'package:flutter/material.dart';

/// Kissu Banner 图片组装器
/// 
/// 根据用户的绑定状态和 VIP 状态，组装对应的 Banner 图片列表
/// 背景图规格：302×83 webp格式
class KissuBannerBuilder {
  // 背景图路径常量
  static const String _bgUnboundNonVipLocation = 'assets/3.0/kissu3_banner_weibangding_unvip_location.webp';
  static const String _bgUnboundNonVipTrack = 'assets/3.0/kissu3_banner_weibangding_unvip_track.webp';
  static const String _bgBoundNonVipLocation = 'assets/3.0/kissu_banner_bangding_unvip_location.webp';
  static const String _bgBoundNonVipTrack = 'assets/3.0/kissu_banner_bangding_unvip_track.webp';
  static const String _bgBoundVipLocation = 'assets/3.0/kissu3_banner_bangding_location_vip.webp';
  static const String _bgBoundVipTrack = 'assets/3.0/kissu3_banner_bangding_track_vip.webp';
  
  // 头像背景常量
  static const String _avatarBg = 'assets/3.0/kissu3_header_bg.webp';
  static const double _avatarBgWidth = 32.0;
  static const double _avatarBgHeight = 38.0;
  static const double _avatarSize = 26.0;
  static const double _avatarTopMargin = 2.3;

  // 另一半头像背景常量（足迹Banner专用）
  static const double _partnerAvatarBgWidth = 36.0;
  static const double _partnerAvatarBgHeight = 42.0;
  static const double _partnerAvatarSize = 30.0;
  static const double _partnerAvatarTopMargin = 2.0;

  // 出行工具图标常量
  static const String _transportBike = 'assets/3.0/kissu3_banner_bike_icon.webp';
  static const String _transportCar = 'assets/3.0/kissu3_banner_car_icon.webp';
  static const String _transportGo = 'assets/3.0/kissu3_banner_go_icon.webp';
  static const double _transportIconSize = 38.0;

  // 定位图标常量（足迹Banner专用）
  static const String _locationIcon = 'assets/3.0/kissu3_banner_location_icon.webp';
  static const double _locationIconSize = 33.0;

  // 天气 Banner 常量
  static const String _bgWeather = 'assets/3.0/kissu3_banner_weather_bg.webp';
  static const double _weatherIconSize = 33.0;
  static const double _weatherIconLeft = 22.0;
  static const double _weatherIconTop = 26.0;
  static const double _temperatureBarWidth = 110.0;
  static const double _temperatureBarHeight = 7.0;
  static const Color _temperatureBarBgColor = Colors.white;
  static const Color _temperatureBarFillColor = Color(0xFFFFDC73);

  // 距离背景常量
  static const String _distanceBg = 'assets/3.0/kissu3_banner_juli_bg.webp';
  static const double _distanceBgWidth = 64.0;
  static const double _distanceBgHeight = 18.0;
  static const double _distanceBgLeft = 153.0;
  static const double _distanceBgTop = 31.0;

  /// 1. 未绑定未开通VIP时的定位banner图
  static List<String> buildLocationBannerForUnboundNonVip([String? userAvatarUrl]) {
    // 背景图：kissu3_banner_weibangding_unvip_location.webp
    // 头像背景：kissu3_header_bg.webp，坐标 (27, 28)
    // 用户头像：坐标 (29, 30)
    List<String> bannerImages = [
      _bgUnboundNonVipLocation,
      _avatarBg, // 坐标 (27, 28)
    ];
    
    // 如果提供了用户头像，添加到列表中
    if (userAvatarUrl != null && userAvatarUrl.isNotEmpty) {
      bannerImages.add(userAvatarUrl); // 坐标 (29, 30)
    }
    
    return bannerImages;
  }

  /// 2. 未绑定未开通VIP时的足迹banner图
  static List<String> buildFootprintBannerForUnboundNonVip() {
    // 背景图：kissu3_banner_weibangding_unvip_track.webp
    // TODO: 组装其他元素
    return [
      _bgUnboundNonVipTrack,
    ];
  }

  /// 3. 未绑定开通VIP时的定位banner图
  static List<String> buildLocationBannerForUnboundVip([String? userAvatarUrl]) {
    // 背景图：kissu3_banner_weibangding_unvip_location.webp
    // 头像背景：kissu3_header_bg.webp，坐标 (27, 28)
    // 用户头像：坐标 (29, 30)
    List<String> bannerImages = [
      _bgUnboundNonVipLocation,
      _avatarBg, // 坐标 (27, 28)
    ];
    
    // 如果提供了用户头像，添加到列表中
    if (userAvatarUrl != null && userAvatarUrl.isNotEmpty) {
      bannerImages.add(userAvatarUrl); // 坐标 (29, 30)
    }
    
    return bannerImages;
  }

  /// 4. 未绑定开通VIP时的足迹banner图
  static List<String> buildFootprintBannerForUnboundVip() {
    // 背景图：kissu3_banner_weibangding_unvip_track.webp
    // TODO: 组装其他元素
    return [
      _bgUnboundNonVipTrack,
    ];
  }

  /// 5. 绑定未开通VIP时的定位banner图
  static List<String> buildLocationBannerForBoundNonVip([String? userAvatarUrl, String? partnerAvatarUrl]) {
    // 背景图：kissu_banner_bangding_unvip_location.webp
    // 自己的头像：坐标 (80, 27) - 使用原始头像背景大小 32×38
    // 另一半的头像背景：坐标 (249, 14)，大小 36×42
    // 另一半的头像：大小 30×30，在头像背景上居中，上边距 2px
    // 出行工具：坐标 (21, 30)，大小 38×38
    List<String> bannerImages = [
      _bgBoundNonVipLocation, // 背景图
      _transportBike,         // 出行工具（先用自行车图标）
      _avatarBg,             // 自己的头像背景
    ];
    
    // 如果提供了自己的头像，添加到列表中
    if (userAvatarUrl != null && userAvatarUrl.isNotEmpty) {
      bannerImages.add(userAvatarUrl); // 自己的头像
    }
    
    // 添加另一半的头像背景（使用相同的头像背景图片）
    bannerImages.add(_avatarBg); // 另一半的头像背景（复用头像背景图片）
    
    // 如果提供了另一半的头像，添加到列表中
    if (partnerAvatarUrl != null && partnerAvatarUrl.isNotEmpty) {
      bannerImages.add(partnerAvatarUrl); // 另一半的头像
    }
    
    return bannerImages;
  }

  /// 6. 绑定未开通VIP时的足迹banner图
  static List<String> buildFootprintBannerForBoundNonVip([String? userAvatarUrl, String? partnerAvatarUrl]) {
    // 背景图：kissu_banner_bangding_unvip_track.webp
    // 定位图标：坐标 (21, 30)，大小 33×33
    // 自己的头像：坐标 (94, 29) - 使用原始头像背景大小 32×38
    List<String> bannerImages = [
      _bgBoundNonVipTrack, // 背景图
      _locationIcon,       // 定位图标（33×33）
      _avatarBg,          // 自己的头像背景
    ];
    
    // 如果提供了自己的头像，添加到列表中
    if (userAvatarUrl != null && userAvatarUrl.isNotEmpty) {
      bannerImages.add(userAvatarUrl); // 自己的头像
    }
    
    return bannerImages;
  }

  /// 7. 绑定开通VIP时的定位banner图
  static List<String> buildLocationBannerForBoundVip([String? userAvatarUrl, String? partnerAvatarUrl]) {
    // 背景图：kissu3_banner_bangding_location_vip.webp
    // 出行工具：坐标 (21, 30)，大小 38×38
    // 自己的头像：坐标 (80, 28) - 使用原始头像背景大小 32×38
    // 另一半的头像背景：坐标 (249, 15)，大小 36×42
    // 另一半的头像：大小 30×30，在头像背景上居中，上边距 2px
    List<String> bannerImages = [
      _bgBoundVipLocation, // 背景图
      _transportBike,      // 出行工具（先用自行车图标）
      _avatarBg,          // 自己的头像背景
    ];
    
    // 如果提供了自己的头像，添加到列表中
    if (userAvatarUrl != null && userAvatarUrl.isNotEmpty) {
      bannerImages.add(userAvatarUrl); // 自己的头像
    }
    
    // 添加另一半的头像背景（使用相同的头像背景图片）
    bannerImages.add(_avatarBg); // 另一半的头像背景（复用头像背景图片）
    
    // 如果提供了另一半的头像，添加到列表中
    if (partnerAvatarUrl != null && partnerAvatarUrl.isNotEmpty) {
      bannerImages.add(partnerAvatarUrl); // 另一半的头像
    }
    
    return bannerImages;
  }

  /// 8. 绑定开通VIP时的足迹banner图
  static List<String> buildFootprintBannerForBoundVip([String? userAvatarUrl, int? footprintCount]) {
    // 背景图：kissu3_banner_bangding_track_vip.webp
    // 定位图标：坐标 (21, 30)，大小 33×33
    // 自己的头像：坐标 (94, 29) - 使用原始头像背景大小 32×38
    // 计数文字："n个" 在定位图标右边，间距1px，字体14pt，颜色#7C6DFF，两者垂直居中
    List<String> bannerImages = [
      _bgBoundVipTrack, // 背景图
      _locationIcon,    // 定位图标（33×33）
      _avatarBg,       // 自己的头像背景
    ];
    
    // 如果提供了自己的头像，添加到列表中
    if (userAvatarUrl != null && userAvatarUrl.isNotEmpty) {
      bannerImages.add(userAvatarUrl); // 自己的头像
    }
    
    return bannerImages;
  }

  /// 智能获取定位 Banner 图片列表
  /// 
  /// 根据绑定状态和 VIP 状态自动选择对应的 Banner
  /// 
  /// [isBound] - 是否已绑定
  /// [isVip] - 是否开通 VIP
  /// [userAvatarUrl] - 用户头像URL（可选）
  /// [partnerAvatarUrl] - 另一半头像URL（可选）
  static List<String> getLocationBanner({
    required bool isBound,
    required bool isVip,
    String? userAvatarUrl,
    String? partnerAvatarUrl,
  }) {
    if (!isBound && !isVip) {
      return buildLocationBannerForUnboundNonVip(userAvatarUrl);
    } else if (!isBound && isVip) {
      return buildLocationBannerForUnboundVip(userAvatarUrl);
    } else if (isBound && !isVip) {
      return buildLocationBannerForBoundNonVip(userAvatarUrl, partnerAvatarUrl);
    } else {
      return buildLocationBannerForBoundVip(userAvatarUrl, partnerAvatarUrl);
    }
  }

  /// 智能获取足迹 Banner 图片列表
  /// 
  /// 根据绑定状态和 VIP 状态自动选择对应的 Banner
  /// 
  /// [isBound] - 是否已绑定
  /// [isVip] - 是否开通 VIP
  /// [userAvatarUrl] - 用户头像URL（可选）
  /// [partnerAvatarUrl] - 另一半头像URL（可选）
  /// [footprintCount] - 足迹数量（仅在绑定开通VIP时使用）
  static List<String> getFootprintBanner({
    required bool isBound,
    required bool isVip,
    String? userAvatarUrl,
    String? partnerAvatarUrl,
    int? footprintCount,
  }) {
    if (!isBound && !isVip) {
      return buildFootprintBannerForUnboundNonVip();
    } else if (!isBound && isVip) {
      return buildFootprintBannerForUnboundVip();
    } else if (isBound && !isVip) {
      return buildFootprintBannerForBoundNonVip(userAvatarUrl, partnerAvatarUrl);
    } else {
      return buildFootprintBannerForBoundVip(userAvatarUrl, footprintCount);
    }
  }

  // ========== Widget 构建方法（可直接调用显示）==========

  /// 构建定位 Banner Widget
  /// 
  /// 直接返回可以显示的 Widget，无需在调用处组装
  /// 
  /// [isBound] - 是否已绑定
  /// [isVip] - 是否开通 VIP
  /// [userAvatarUrl] - 用户头像URL（可选）
  /// [partnerAvatarUrl] - 另一半头像URL（可选）
  /// [distance] - 距离信息（格式如 "1.5KM"，仅在绑定开通VIP时显示）
  /// [width] - Banner 宽度（默认 302）
  /// [height] - Banner 高度（默认 83）
  static Widget buildLocationBannerWidget({
    required bool isBound,
    required bool isVip,
    String? userAvatarUrl,
    String? partnerAvatarUrl,
    String? distance,
    double width = 302,
    double height = 83,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          // 背景图
          _buildBackgroundImage(getLocationBanner(
            isBound: isBound,
            isVip: isVip,
            userAvatarUrl: userAvatarUrl,
            partnerAvatarUrl: partnerAvatarUrl,
          )[0], width, height),
          
          // 如果需要显示头像（未绑定状态）
          if (!isBound && userAvatarUrl != null && userAvatarUrl.isNotEmpty) ...[
            // 头像背景（坐标 27, 28）
            Positioned(
              left: 27,
              top: 28,
              child: Image.asset(
                _avatarBg,
                width: _avatarBgWidth,
                height: _avatarBgHeight,
                fit: BoxFit.fill,
              ),
            ),
            // 用户头像（坐标 29, 30）
            Positioned(
              left: 29,
              top: 30,
              child: ClipOval(
                child: _buildAvatarImage(userAvatarUrl),
              ),
            ),
          ],
          
          // 如果是绑定未开通VIP状态，显示新的UI元素
          if (isBound && !isVip) ...[
            // 出行工具图标（坐标 21, 30）
            Positioned(
              left: 21,
              top: 30,
              child: Image.asset(
                _transportBike,
                width: _transportIconSize,
                height: _transportIconSize,
                fit: BoxFit.fill,
              ),
            ),
            
            // 自己的头像背景（坐标 80, 27）
            Positioned(
              left: 80,
              top: 27,
              child: Image.asset(
                _avatarBg,
                width: _avatarBgWidth,
                height: _avatarBgHeight,
                fit: BoxFit.fill,
              ),
            ),
            
            // 自己的头像（坐标 82, 29）
            if (userAvatarUrl != null && userAvatarUrl.isNotEmpty)
              Positioned(
                left: 83.5, // 80 + (32-26)/2 = 83, 调整到82居中
                top: 30,  // 27 + 2 = 29
                child: ClipOval(
                  child: _buildAvatarImage(userAvatarUrl),
                ),
              ),
            
            // 另一半的头像背景（坐标 249, 14）
            Positioned(
              left: 249,
              top: 14,
              child: Image.asset(
                _avatarBg,
                width: _partnerAvatarBgWidth,
                height: _partnerAvatarBgHeight,
                fit: BoxFit.fill,
              ),
            ),
            
            // 另一半的头像（在头像背景上居中）
            if (partnerAvatarUrl != null && partnerAvatarUrl.isNotEmpty)
              Positioned(
                left: 252, // 249 + (36-30)/2 = 252
                top: 16,   // 14 + 2 = 16
                child: ClipOval(
                  child: Container(
                    width: _partnerAvatarSize,
                    height: _partnerAvatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: NetworkImage(partnerAvatarUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
          ],
          
          // 绑定开通VIP的定位Banner元素
          if (isBound && isVip) ...[
            // 获取Banner元素列表
            ...() {
              List<String> bannerElements = getLocationBanner(
                isBound: isBound,
                isVip: isVip,
                userAvatarUrl: userAvatarUrl,
                partnerAvatarUrl: partnerAvatarUrl,
              );
              
              List<Widget> widgets = [];
              
              // 出行工具图标（坐标 21, 30）
              if (bannerElements.length > 1) {
                widgets.add(Positioned(
                  left: 21,
                  top: 30,
                  child: Image.asset(
                    bannerElements[1], // _transportBike
                    width: _transportIconSize,
                    height: _transportIconSize,
                    fit: BoxFit.fill,
                  ),
                ));
              }
              
              // 自己的头像背景（坐标 80, 28）
              if (bannerElements.length > 2) {
                widgets.add(Positioned(
                  left: 80,
                  top: 28,
                  child: Image.asset(
                    bannerElements[2], // _avatarBg
                    width: _avatarBgWidth,
                    height: _avatarBgHeight,
                    fit: BoxFit.fill,
                  ),
                ));
              }
              
              // 自己的头像（如果有）
              if (bannerElements.length > 3 && userAvatarUrl != null && userAvatarUrl.isNotEmpty) {
                widgets.add(Positioned(
                  left: 80 + (_avatarBgWidth - _avatarSize) / 2,
                  top: 28 + _avatarTopMargin,
                  child: ClipOval(
                    child: _buildAvatarImage(bannerElements[3]),
                  ),
                ));
              }
              
              // 另一半的头像背景（坐标 249, 15）
              if (bannerElements.length > 4) {
                widgets.add(Positioned(
                  left: 249,
                  top: 15,
                  child: Image.asset(
                    bannerElements[4], // _avatarBg
                    width: _partnerAvatarBgWidth,
                    height: _partnerAvatarBgHeight,
                    fit: BoxFit.fill,
                  ),
                ));
              }
              
              // 另一半的头像（如果有）
              if (bannerElements.length > 5 && partnerAvatarUrl != null && partnerAvatarUrl.isNotEmpty) {
                widgets.add(Positioned(
                  left: 249 + (_partnerAvatarBgWidth - _partnerAvatarSize) / 2,
                  top: 15 + _partnerAvatarTopMargin,
                  child: ClipOval(
                    child: Container(
                      width: _partnerAvatarSize,
                      height: _partnerAvatarSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: NetworkImage(bannerElements[5]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ));
              }
              
              // 距离背景（坐标 153, 31）
              widgets.add(Positioned(
                left: _distanceBgLeft,
                top: _distanceBgTop,
                child: Image.asset(
                  _distanceBg,
                  width: _distanceBgWidth,
                  height: _distanceBgHeight,
                  fit: BoxFit.fill,
                ),
              ));
              
              // 距离文字（在距离背景上显示）
              if (distance != null && distance.isNotEmpty) {
                widgets.add(Positioned(
                  left: _distanceBgLeft,
                  top: _distanceBgTop,
                  child: Container(
                    width: _distanceBgWidth,
                    height: _distanceBgHeight,
                    alignment: Alignment.center,
                    child: _buildDistanceText(distance),
                  ),
                ));
              }
              
              return widgets;
            }(),
          ],
        ],
      ),
    );
  }

  /// 构建足迹 Banner Widget
  /// 
  /// 直接返回可以显示的 Widget，无需在调用处组装
  /// 
  /// [isBound] - 是否已绑定
  /// [isVip] - 是否开通 VIP
  /// [userAvatarUrl] - 用户头像URL（可选）
  /// [partnerAvatarUrl] - 另一半头像URL（可选）
  /// [width] - Banner 宽度（默认 302）
  /// [height] - Banner 高度（默认 83）
  static Widget buildFootprintBannerWidget({
    required bool isBound,
    required bool isVip,
    String? userAvatarUrl,
    String? partnerAvatarUrl,
    int? footprintCount,
    double width = 302,
    double height = 83,
  }) {
    List<String> bannerElements = getFootprintBanner(
      isBound: isBound,
      isVip: isVip,
      userAvatarUrl: userAvatarUrl,
      partnerAvatarUrl: partnerAvatarUrl,
      footprintCount: footprintCount,
    );

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          // 背景图
          _buildBackgroundImage(bannerElements[0], width, height),
          
          // 绑定未开通VIP的足迹Banner元素
          if (isBound && !isVip && bannerElements.length > 1) ...[
            // 定位图标（坐标 21, 30，大小 33×33）
            Positioned(
              left: 21,
              top: 30,
              child: Image.asset(
                bannerElements[1], // _locationIcon
                width: _locationIconSize,
                height: _locationIconSize,
                fit: BoxFit.fill,
              ),
            ),
            
            // 另一半的头像背景（坐标 94, 29）
            Positioned(
              left: 94,
              top: 29,
              child: Image.asset(
                bannerElements[2], // _avatarBg
                width: _avatarBgWidth,
                height: _avatarBgHeight,
                fit: BoxFit.fill,
              ),
            ),
            
            // 另一半的头像（如果有）
            if (bannerElements.length > 3 && partnerAvatarUrl != null && partnerAvatarUrl.isNotEmpty)
              Positioned(
                left: 94 + (_avatarBgWidth - _avatarSize) / 2,
                top: 29 + _avatarTopMargin,
                child: ClipOval(
                  child: _buildAvatarImage(bannerElements[3]),
                ),
              ),
          ],
          
          // 绑定开通VIP的足迹Banner元素
          if (isBound && isVip && bannerElements.length > 1) ...[
            // 定位图标（坐标 21, 30，大小 33×33）
            Positioned(
              left: 21,
              top: 30,
              child: Image.asset(
                bannerElements[1], // _locationIcon
                width: _locationIconSize,
                height: _locationIconSize,
                fit: BoxFit.fill,
              ),
            ),
            
            // 计数文字："n个" 在定位图标右边，间距1px，字体14pt，颜色#7C6DFF，两者垂直居中
            if (footprintCount != null && footprintCount > 0)
              Positioned(
                left: 21 + _locationIconSize + 1, // 定位图标右边，间距1px
                top: 30 + (_locationIconSize - 14) / 2, // 垂直居中（14pt字体高度估算）
                child: Text(
                  '$footprintCount个',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7C6DFF),
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            
            // 另一半的头像背景（坐标 94, 29）
            Positioned(
              left: 94,
              top: 29,
              child: Image.asset(
                bannerElements[2], // _avatarBg
                width: _avatarBgWidth,
                height: _avatarBgHeight,
                fit: BoxFit.fill,
              ),
            ),
            
            // 另一半的头像（如果有）
            if (bannerElements.length > 3 && partnerAvatarUrl != null && partnerAvatarUrl.isNotEmpty)
              Positioned(
                left: 94 + (_avatarBgWidth - _avatarSize) / 2,
                top: 29 + _avatarTopMargin,
                child: ClipOval(
                  child: _buildAvatarImage(bannerElements[3]),
                ),
              ),
          ],
        ],
      ),
    );
  }

  /// 构建自己的头像（带背景）
  /// 
  /// 规格：
  /// - 头像背景：32×38 webp
  /// - 头像大小：26×26
  /// - 头像位置：居中，顶部间距 2px
  /// 
  /// [avatarUrl] - 头像 URL
  static Widget buildMyAvatar(String avatarUrl) {
    return _buildAvatarWithBackground(avatarUrl);
  }

  /// 构建另一半的头像（带背景）
  /// 
  /// 规格：
  /// - 头像背景：32×38 webp
  /// - 头像大小：26×26
  /// - 头像位置：居中，顶部间距 2px
  /// 
  /// [avatarUrl] - 头像 URL
  static Widget buildPartnerAvatar(String avatarUrl) {
    return _buildAvatarWithBackground(avatarUrl);
  }

  /// 内部方法：构建带背景的头像
  static Widget _buildAvatarWithBackground(String avatarUrl) {
    return SizedBox(
      width: _avatarBgWidth,
      height: _avatarBgHeight,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // 头像背景
          Image.asset(
            _avatarBg,
            width: _avatarBgWidth,
            height: _avatarBgHeight,
            fit: BoxFit.fill,
          ),
          // 头像
          Positioned(
            top: _avatarTopMargin,
            child: ClipOval(
              child: _buildAvatarImage(avatarUrl),
            ),
          ),
        ],
      ),
    );
  }

  /// 内部方法：构建背景图片
  static Widget _buildBackgroundImage(String imagePath, double width, double height) {
    return Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: BoxFit.fill,
    );
  }

  /// 内部方法：构建头像图片组件
  /// 处理本地 assets 图片和网络图片
  static Widget _buildAvatarImage(String avatarUrl) {
    // 如果是本地 assets 图片
    if (avatarUrl.startsWith('assets/')) {
      return Image.asset(
        avatarUrl,
        width: _avatarSize,
        height: _avatarSize,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultAvatar();
        },
      );
    }
    
    // 如果是网络图片
    if (avatarUrl.startsWith('http')) {
      return Image.network(
        avatarUrl,
        width: _avatarSize,
        height: _avatarSize,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultAvatar();
        },
      );
    }
    
    // 其他情况显示默认头像
    return _buildDefaultAvatar();
  }

  /// 内部方法：构建另一半的头像图片组件（30×30尺寸）
  /// 处理本地 assets 图片和网络图片
  static Widget _buildPartnerAvatarImage(String avatarUrl) {
    // 如果是本地 assets 图片
    if (avatarUrl.startsWith('assets/')) {
      return Image.asset(
        avatarUrl,
        width: _partnerAvatarSize,
        height: _partnerAvatarSize,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultPartnerAvatar();
        },
      );
    }
    
    // 如果是网络图片
    if (avatarUrl.startsWith('http')) {
      return Image.network(
        avatarUrl,
        width: _partnerAvatarSize,
        height: _partnerAvatarSize,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultPartnerAvatar();
        },
      );
    }
    
    // 其他情况显示默认头像
    return _buildDefaultPartnerAvatar();
  }

  /// 内部方法：构建默认头像
  static Widget _buildDefaultAvatar() {
    return Image.asset(
      'assets/3.0/kissu3_love_avater.webp',
      width: _avatarSize,
      height: _avatarSize,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: _avatarSize,
          height: _avatarSize,
          color: Colors.grey[300],
          child: Icon(
            Icons.person,
            size: _avatarSize * 0.6,
            color: Colors.grey[600],
          ),
        );
      },
    );
  }

  /// 内部方法：构建另一半的默认头像（30×30尺寸）
  static Widget _buildDefaultPartnerAvatar() {
    return Image.asset(
      'assets/3.0/kissu3_love_avater.webp',
      width: _partnerAvatarSize,
      height: _partnerAvatarSize,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: _partnerAvatarSize,
          height: _partnerAvatarSize,
          color: Colors.grey[300],
          child: Icon(
            Icons.person,
            size: _partnerAvatarSize * 0.6,
            color: Colors.grey[600],
          ),
        );
      },
    );
  }

  /// 构建天气 Banner Widget
  /// 
  /// [weatherIconUrl] 天气图标 URL（从 API 的 base.weather_icon 获取）
  /// [weather] 天气详情（从 API 的 base.weather 获取）
  /// [minTemp] 最低温度（从 API 的 all.casts[0].nighttemp 获取）
  /// [maxTemp] 最高温度（从 API 的 all.casts[0].daytemp 获取）
  /// [currentTemp] 当前温度（从 API 的 base.temperature 获取）
  /// [isLoading] 是否正在加载（未请求到数据或请求失败时为 true）
  /// [width] Banner 宽度，默认 302
  /// [height] Banner 高度，默认 83
  static Widget buildWeatherBannerWidget({
    String? weatherIconUrl,
    String? weather,
    String? minTemp,
    String? maxTemp,
    String? currentTemp,
    bool isLoading = false,
    double width = 302.0,
    double height = 83.0,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(_bgWeather),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // 天气图标（22, 36）大小 33×33
          if (!isLoading && weatherIconUrl != null && weatherIconUrl.isNotEmpty)
            Positioned(
              left: _weatherIconLeft,
              top: _weatherIconTop,
              child: Image.network(
                weatherIconUrl,
                width: _weatherIconSize,
                height: _weatherIconSize,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return SizedBox(
                    width: _weatherIconSize,
                    height: _weatherIconSize,
                  );
                },
              ),
            ),
          
          // 天气详情（距离图标 10px）12pt #333333
          if (!isLoading && weather != null && weather.isNotEmpty)
            Positioned(
              left: _weatherIconLeft + _weatherIconSize + 10,
              top: _weatherIconTop + (_weatherIconSize - 12 * 1.2) / 2, // 垂直居中对齐图标
              child: Text(
                weather,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          
          // 温度条和温度文字的布局（居中显示）
          if (!isLoading && minTemp != null && maxTemp != null && currentTemp != null)
            _buildTemperatureBar(
              minTemp: minTemp,
              maxTemp: maxTemp,
              currentTemp: currentTemp,
              bannerWidth: width,
              bannerHeight: height,
            )
          else
            // 只显示白色背景条（居中显示）
            _buildEmptyTemperatureBar(
              bannerWidth: width,
              bannerHeight: height,
            ),
        ],
      ),
    );
  }

  /// 构建温度条（包含最低温度、颜色块、最高温度）
  static Widget _buildTemperatureBar({
    required String minTemp,
    required String maxTemp,
    required String currentTemp,
    required double bannerWidth,
    required double bannerHeight,
  }) {
    // 计算百分比
    final minTempValue = double.tryParse(minTemp) ?? 0;
    final maxTempValue = double.tryParse(maxTemp) ?? 0;
    final currentTempValue = double.tryParse(currentTemp) ?? 0;
    
    double percentage = 0.0;
    if (maxTempValue > minTempValue) {
      percentage = (currentTempValue - minTempValue) / (maxTempValue - minTempValue);
      percentage = percentage.clamp(0.0, 1.0);
    }

    // 计算整个组件的宽度
    // 最低温度宽度(22) + 间距(15) + 颜色块(110) + 间距(6) + 最高温度宽度(22)
    const tempTextWidth = 22.0;
    const spacing1 = 15.0;
    const spacing2 = 6.0;
    final totalWidth = tempTextWidth + spacing1 + _temperatureBarWidth + spacing2 + tempTextWidth;
    
    // 水平居中
    final leftPosition = (bannerWidth - totalWidth) / 2 + 30;
    // 垂直居中（基于温度条的高度和字体高度）
    final topPosition =  _weatherIconTop + (_weatherIconSize - 12 * 1.2) / 2;

    return Positioned(
      left: leftPosition,
      top: topPosition,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 最低温度
          SizedBox(
            width: tempTextWidth,
            child: Text(
              '$minTemp°',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          SizedBox(width: spacing1),
          
          // 颜色块
          Container(
            width: _temperatureBarWidth,
            height: _temperatureBarHeight,
            decoration: BoxDecoration(
              color: _temperatureBarBgColor,
              borderRadius: BorderRadius.circular(_temperatureBarHeight / 2),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: _temperatureBarWidth * percentage,
                height: _temperatureBarHeight,
                decoration: BoxDecoration(
                  color: _temperatureBarFillColor,
                  borderRadius: BorderRadius.circular(_temperatureBarHeight / 2),
                ),
              ),
            ),
          ),
          
          SizedBox(width: spacing2),
          
          // 最高温度
          SizedBox(
            width: tempTextWidth,
            child: Text(
              '$maxTemp°',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建空的温度条（只显示白色背景）
  static Widget _buildEmptyTemperatureBar({
    required double bannerWidth,
    required double bannerHeight,
  }) {
    // 水平居中
    final leftPosition = (bannerWidth - _temperatureBarWidth) / 2;
    // 垂直居中
    final topPosition = (bannerHeight - _temperatureBarHeight) / 2;

    return Positioned(
      left: leftPosition,
      top: topPosition,
      child: Container(
        width: _temperatureBarWidth,
        height: _temperatureBarHeight,
        decoration: BoxDecoration(
          color: _temperatureBarBgColor,
          borderRadius: BorderRadius.circular(_temperatureBarHeight / 2),
        ),
      ),
    );
  }

  /// 构建距离文字（nKM格式，n用12pt #FF4B99，KM用10pt #333333）
  static Widget _buildDistanceText(String distance) {
    // 解析距离字符串，例如 "1.5KM" -> number: "1.5", unit: "KM"
    String number = '';
    String unit = '';
    
    // 查找第一个字母的位置
    int unitStartIndex = distance.length;
    for (int i = 0; i < distance.length; i++) {
      if (RegExp(r'[A-Za-z]').hasMatch(distance[i])) {
        unitStartIndex = i;
        break;
      }
    }
    
    number = distance.substring(0, unitStartIndex);
    unit = distance.substring(unitStartIndex);
    
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: number,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFFFF4B99),
              fontWeight: FontWeight.normal,
            ),
          ),
          TextSpan(
            text: unit,
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFF333333),
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

