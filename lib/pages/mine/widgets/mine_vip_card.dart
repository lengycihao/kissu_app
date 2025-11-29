import 'package:flutter/material.dart';

/// 会员卡片类型
enum VipCardType {
  foreverVip, // 永久会员
  normalVip, // 普通会员
  unbound, // 未绑定
  nonVip, // 非会员
}

/// 我的页面-会员卡片
class MineVipCard extends StatelessWidget {
  final VipCardType cardType;
  final String? vipEndDate; // 会员到期日期（普通会员需要）
  final VoidCallback onRenewTap;
  final VoidCallback onPermissionSettingTap;
  final bool areAllPermissionsGranted; // 4个权限是否全部开启

  const MineVipCard({
    super.key,
    required this.cardType,
    this.vipEndDate,
    required this.onRenewTap,
    required this.onPermissionSettingTap,
    required this.areAllPermissionsGranted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 115,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Color(0xffffffff),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopContent(),
          ),
          _buildPermissionSettingBottom(),
        ],
      ),
    );
  }

  Widget _buildTopContent() {
    return Container(
      height: 73,
      padding: EdgeInsets.only(left: 12, right: 12, top: 0),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/4.0/kissu4_mine_vip_bg.webp"),
          fit: BoxFit.fill,
        ),
      ),
      child: Row(
        children: [
          Image(
            image: AssetImage("assets/4.0/kissu4_mine_vip.webp"),
            fit: BoxFit.contain,
            width: 48,
            height: 48,
          ),
          SizedBox(width: 5),
          Expanded(
            child: _buildMiddleContent(),
          ),
          // SizedBox(width: 0),
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildMiddleContent() {
    switch (cardType) {
      case VipCardType.foreverVip:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "kissu 会员中心",
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xffffffff),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  width: 53,
                  height: 16,
                  margin: EdgeInsets.only(left: 13),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(
                        "assets/4.0/kissu4_forever_vip.webp",
                      ),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              "双人永久会员",
              style: TextStyle(
                fontSize: 11,
                color: Color(0xffffffff),
              ),
            ),
          ],
        );
      case VipCardType.normalVip:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "kissu 会员中心",
              style: TextStyle(
                fontSize: 13,
                color: Color(0xffffffff),
                 fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 3),
            // 进度条
            Container(
              height: 4,
              margin: EdgeInsets.only(right: 16),
              child: Stack(
                children: [
                  // 背景
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFD9D9D9),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // 进度
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.5, // 暂时显示50%的进度
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF3AD9F7),
                            Color(0xFFF66D9F),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 3),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "双人月度会员 ",
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xffffffff),
                    ),
                  ),
                  TextSpan(
                    text: vipEndDate ?? "",
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xffFF94D6),
                    ),
                  ),
                  TextSpan(
                    text: " 到期",
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xffffffff),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      case VipCardType.unbound:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "kissu 会员中心",
              style: TextStyle(
                fontSize: 13,
                color: Color(0xffffffff),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "还",
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xffffffff),
                    ),
                  ),
                  TextSpan(
                    text: "未绑定",
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xffFF94D6),
                    ),
                  ),
                  TextSpan(
                    text: "另一半",
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xffffffff),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      case VipCardType.nonVip:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "kissu 会员中心",
              style: TextStyle(
                fontSize: 13,
                color: Color(0xffffffff),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "开通双人Vip享受会员特权",
              style: TextStyle(
                fontSize: 11,
                color: Color(0xffffffff),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildActionButton() {
    String buttonText;
    switch (cardType) {
      case VipCardType.foreverVip:
      case VipCardType.normalVip:
        buttonText = "会员中心";
        break;
      case VipCardType.unbound:
        buttonText = "立即绑定";
        break;
      case VipCardType.nonVip:
        buttonText = "立即开通";
        break;
    }

    return GestureDetector(
      onTap: onRenewTap,
      child: Container(
        width: 72,
        height: 29,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              "assets/4.0/kissu4_mine_member_center.webp",
            ),
            fit: BoxFit.contain,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          buttonText,
          style: TextStyle(
            fontSize: 11,
            color: Color(0xff462229),
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // 通用的底部权限设置组件
  Widget _buildPermissionSettingBottom() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onTap: onPermissionSettingTap,
        child: Container(
          height: 51,
          padding: EdgeInsets.only(left: 16, right: 16),
          decoration: BoxDecoration(
            color: Color(0xffffffff),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "权限设置",
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xff333333),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              Text(
                "开通对应权限，体验会更流畅！",
                style: TextStyle(fontSize: 11, color: Color(0xff999999)),
              ),
              // 只有当4个权限都未全部开启时才显示图标
              if (!areAllPermissionsGranted) ...[
                SizedBox(width: 5),
                Image(
                  image: AssetImage(
                    "assets/4.0/kissu4_notice_setting_new.webp",
                  ),
                  width: 10,
                  height: 10,
                ),
              ],
              SizedBox(width: 10),
              Image(
                image: AssetImage(
                  "assets/4.0/kissu4_mine_arrow_right_small.webp",
                ),
                width: 10,
                height: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

