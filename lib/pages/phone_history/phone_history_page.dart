import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'phone_history_controller.dart';

class PhoneHistoryPage extends GetView<PhoneHistoryController> {
  const PhoneHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    controller.pageContext = context; // ✅ 保存 Scaffold 的 context
    return Scaffold(
      body: Stack(
        children: [
          // 背景图
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/phone_history/kissu_phone_bg.webp'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // 顶部标题栏
                _buildHeader(),
                // 日期选择器
                _buildDateSelector(),
                // 内容区域
                Expanded(
                  child: Obx(
                    () =>
                        controller.isBinding.value
                            ? _buildUsageList()
                            : _buildEmptyState(),
                  ),
                ),
                // 底部提示文字（始终显示）
                Container(
                  padding: const EdgeInsets.only(bottom: 20, top: 20),
                  child: const Text(
                    'Kissu统计也可能存在偏差，仅提供参考哦',
                    style: TextStyle(fontSize: 10, color: Color(0xFFD1CDCD)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 构建顶部标题栏
  Widget _buildHeader() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child:   Image.asset(
              'assets/kissu_mine_back.webp',
              width: 24,
              height: 24,
            ),
          ), 
          const Expanded(
            child: Center(
              child: Text(
                '敏感记录',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => controller.showSettingDialog(),
            child: Image.asset(
              'assets/phone_history/kissu_phone_setting.webp',
              width: 24,
              height: 24,
            ),
          ),
        ],
      ),
    );
  }

  // 构建日期选择器
  Widget _buildDateSelector() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      margin: EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          // 反转索引，让最新日期在右边
          final reversedIndex = 6 - index;
          final date = controller.recentDates[reversedIndex];
          return Obx(
            () => GestureDetector(
              onTap: () => controller.selectDate(reversedIndex),
              child: Container(
                width: 44,
                height: 60,
                decoration: BoxDecoration(
                  color:
                      controller.selectedDateIndex.value == reversedIndex
                          ? const Color(0xFFFF6B9D)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      controller.getDateText(date),
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            controller.selectedDateIndex.value == reversedIndex
                                ? Colors.white
                                : const Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.getDateNumber(date),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color:
                            controller.selectedDateIndex.value == reversedIndex
                                ? Colors.white
                                : const Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // 构建空状态
  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        // height: MediaQuery.of(Get.context!).size.height * 0.5,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Image.asset(
              'assets/phone_history/kissu_phone_placeholder.webp',
              //  fit: BoxFit.cover,
            ),
            Positioned(
              bottom: 44,
              // left: 0,
              child: Container(
                width: 110,
                height: 35,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Color(0xffFF88AA),
                ),
                alignment: Alignment.center,
                child: Text(
                  "立即绑定",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建使用记录列表
  Widget _buildUsageList() {
    final records = controller.getUsageRecords();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Stack(
        children: [
          // 背景容器
          Column(
            children: [
              // 顶部信息栏 - 根据UI调整样式
              _buildInfoHeader(),
              // 记录列表
              Expanded(
                child:
                    records.isEmpty
                        ? _buildEmptyList()
                        : _buildRecordsList(records),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 构建顶部信息栏
 // 构建顶部信息栏
Widget _buildInfoHeader() {
  return Obx(() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 20),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/phone_history/kissu_phone_list_bg.webp'),
              fit: BoxFit.fill,
            ),
          ),
          child: Column(
            children: [
              // 距离和更新时间
              Row(
                children: [
                  const Text(
                    '当前相距',
                    style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '12KM',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B9D),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    decoration: BoxDecoration(
                      border: Border.all(width: 1, color: Color(0xffFFEDF2)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Color(0xFF4CAF50)),
                        SizedBox(width: 4),
                        Text('1分钟前更新',
                            style: TextStyle(fontSize: 12, color: Color(0xFF47493C))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 设备信息行
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: _buildDeviceInfo('Vivo iQOO ', 'assets/phone_history/kissu_phone_type.webp', true)),
                    Expanded(child: _buildDeviceInfo('90%', 'assets/phone_history/kissu_phone_barry.webp', false)),
                    Expanded(child: _buildDeviceInfo('ChinaNet', 'assets/phone_history/kissu_phone_wifi.webp', false)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 🔽 浮层提示（显示在 InfoHeader 顶部）
        if (controller.tooltipText.value != null)
          Positioned(
            top: -60, // 调整距离
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      controller.tooltipText.value!,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => controller.hideTooltip(),
                    child: const Icon(Icons.close, size: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  });
}

  // 构建设备信息项（支持长按提示）
Widget _buildDeviceInfo(String text, String icon, bool isDevice) {
  return GestureDetector(
    onLongPressStart: (details) {
      // details.globalPosition 获取手指长按的全局坐标
      controller.showTooltip(
         text, 
        details.globalPosition + const Offset(0, -40), // 提示框显示在组件上方一点
      );
    },
    onLongPressEnd: (_) {
      // 长按松开也可以选择自动关闭，或者保留直到点 X
      // controller.hideTooltip();
    },
    child: Container(
      color: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(icon, width: 22, height: 22),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: Color(0xFF666666), fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}


 

  // 构建空列表
  Widget _buildEmptyList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/phone_history/kissu_phone_list_empty.webp',
            width: 150,
            height: 150,
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无记录',
            style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
          ),
        ],
      ),
    );
  }

  // 构建记录列表
  Widget _buildRecordsList(List<PhoneUsageRecord> records) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/phone_history/kissu_phone_list_bg.webp'),
          fit: BoxFit.fill,
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 30,vertical: 5),
        itemCount: records.length,
        itemBuilder: (context, index) {
          final record = records[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        record.time,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF999999),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 4,horizontal: 15),
                        decoration: BoxDecoration(
                          color: Color(0xffF6F6F6),
                          borderRadius: BorderRadius.circular(1000)
                        ),
                        child: Text(
                          record.action,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF333333),fontWeight: FontWeight.w500
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
