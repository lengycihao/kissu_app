import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/widgets/dialogs/dialog_manager.dart';

class BreakRelationshipPage extends StatelessWidget {
  const BreakRelationshipPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F4F0),
        elevation: 0,
        leading: IconButton(
          icon: Image.asset(
              'assets/kissu_mine_back.webp',
              width: 24,
              height: 24,
            ),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          '解除关系',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 头像部分
            _buildAvatarSection(),
            const SizedBox(height: 30),
            
            // 在一起天数卡片
            _buildTogetherCard(),
            const SizedBox(height: 20),
            
            // 提示文字
            _buildWarningText(),
            const SizedBox(height: 30),
            
            // 解除须知
            _buildNoticeSection(),
            const SizedBox(height: 40),
            
            // 解除关系按钮
            _buildBreakButton(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 左侧头像
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipOval(
                child: Container(
                  color: const Color(0xFFE8B4CB),
                  child: const Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 40),
            // 右侧头像
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipOval(
                child: Container(
                  color: const Color(0xFFE8B4CB),
                  child: const Icon(
                    Icons.person,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTogetherCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE4E8), Color(0xFFFFF0F2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFB6C1), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.favorite,
            color: Color(0xFFFF69B4),
            size: 20,
          ),
          const SizedBox(width: 10),
          const Text(
            '在一起',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            '6',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF69B4),
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            '天',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.favorite,
            color: Color(0xFFFF69B4),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildWarningText() {
    return const Text(
      '任意一方可以发起解除关系，请务必查阅解除关系的代价后再进行操作',
      style: TextStyle(
        fontSize: 14,
        color: Color(0xFF999999),
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildNoticeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '解除须知',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 15),
          ..._buildNoticeItems(),
        ],
      ),
    );
  }

  List<Widget> _buildNoticeItems() {
    final notices = [
      '清空365打卡记录',
      '清空聊天记录',
      '清空恋爱日记',
      '清空恋爱清单',
      '会员权益(未购买方)失效',
      '清空情侣定制记录',
      '清空对方用机记录',
      '清空活动步数',
      '清空相册里全部照片/视频',
    ];

    return notices.asMap().entries.map((entry) {
      int index = entry.key;
      String notice = entry.value;
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${index + 1}.',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                notice,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildBreakButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        onPressed: () {
           DialogManager.showUnbindConfirm(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6B6B),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: const Text(
          '解除关系',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  

  void _handleBreakRelationship() {
    // 这里处理解除关系的逻辑
    Get.snackbar(
      '提示',
      '关系已解除',
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFFFF6B6B),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
    
    // 返回上一页或跳转到其他页面
    Get.back();
  }
}
