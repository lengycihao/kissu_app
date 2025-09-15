import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

class AvatarSection extends StatelessWidget {
  final String myAvatarUrl;
  final String partnerAvatarUrl;
  final bool isBindPartner;
  final VoidCallback onAddPartner;

  const AvatarSection({
    Key? key,
    required this.myAvatarUrl,
    required this.partnerAvatarUrl,
    required this.isBindPartner,
    required this.onAddPartner,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (isBindPartner) {
        // 已绑定 - 显示两个头像
        return Stack(
          alignment: AlignmentGeometry.bottomCenter,
          children: [_buildMyAvatar(), _buildPartnerAvatar()],
        );
      } else {
        // 未绑定 - 显示头像和加号
        return Stack(
          alignment: AlignmentGeometry.bottomCenter,
          children: [
            _buildMyAvatar(),
            // const SizedBox(width: 40),
            _buildAddButton(context),
          ],
        );
      }
    });
  }

  Widget _buildMyAvatar() {
    return Container(
      width: 80,
      height: 80,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/kissu_loveinfo_header_bg.webp'),
          fit: BoxFit.fill,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: ClipOval(
          child:  myAvatarUrl.isNotEmpty
              ? Image.network(
                  myAvatarUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        color: const Color(0xFFE8B4CB),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.white,
                      ),
                    );
                  },
                )
              : Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    color: const Color(0xFFE8B4CB),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPartnerAvatar() {
    return Container(
      width: 50,
      height: 50,
      margin: EdgeInsets.only(left: 50),
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/kissu_loveinfo_header_bg.webp'),
          fit: BoxFit.fill,
        ),
      ),
      child: ClipOval(
        child:  partnerAvatarUrl.isNotEmpty
            ? Image.network(
                partnerAvatarUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      color: const Color(0xFFE8B4CB),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.white,
                    ),
                  );
                },
              )
            : Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  color: const Color(0xFFE8B4CB),
                ),
                child: const Icon(Icons.person, size: 40, color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTap: () => onAddPartner(),
      child: Container(
        width: 50,
        height: 50,
        margin: EdgeInsets.only(left: 50),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: const Color(0xFFFFB6C1), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Icon(Icons.add, size: 30, color: Color(0xFFFF69B4)),
      ),
    );
  }
}
