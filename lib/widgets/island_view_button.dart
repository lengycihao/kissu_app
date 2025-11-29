import 'package:flutter/material.dart';
import 'package:kissu_app/utils/network_image_helper.dart';

/// 屏视图按钮组件（定位、足迹、天气）
class IslandViewButton extends StatelessWidget {
  final String? iconAsset;
  final String? iconUrl;
  final String title;
  final String value;
  final Color valueColor;
  final VoidCallback? onTap;
  final bool showArrow; // 是否显示箭头

  const IslandViewButton({
    Key? key,
    this.iconAsset,
    this.iconUrl,
    required this.title,
    required this.value,
    required this.valueColor,
    this.onTap,
    this.showArrow = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 303,
        height: 36,
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xFFFFD4D0), width: 1),
          borderRadius: BorderRadius.circular(18),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(width: 22),
            _buildIcon(),
            SizedBox(width: 20),
            Text(
              title,
              style: TextStyle(
                color: Color(0xFF333333),
                fontSize: 12,
              ),
            ),
            Spacer(),
            Container(
              width: 88,
              height: 28,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFAF4FF), Color(0x00FAF4FF)],
                ),
                borderRadius: BorderRadius.circular(44),
              ),
              child: Center(
                child: Text(
                  value,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            SizedBox(width: 1),
            if (showArrow) ...[
              Image(
                image: AssetImage("assets/images/kissu_mine_arrow.webp"),
                width: 16,
                height: 16,
              ),
              SizedBox(width: 12),
            ] else ...[
              SizedBox(width: 29),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (iconUrl != null && iconUrl!.isNotEmpty) {
      // 使用网络图片（天气图标）
      return NetworkImageHelper.loadImage(
        imageUrl: iconUrl!,
        width: 20,
        height: 20,
        fit: BoxFit.cover,
        errorWidget: Image(
          image: AssetImage(iconAsset ?? "assets/images/home_list_type_location.webp"),
          width: 20,
          height: 20,
        ),
      );
    } else if (iconAsset != null && iconAsset!.isNotEmpty) {
      // 使用本地资源图片
      return Image(
        image: AssetImage(iconAsset!),
        width: 20,
        height: 20,
      );
    } else {
      // 默认图标
      return Image(
        image: AssetImage("assets/home_list_type_location.webp"),
        width: 20,
        height: 20,
      );
    }
  }
}

