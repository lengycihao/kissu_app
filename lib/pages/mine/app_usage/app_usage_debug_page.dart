import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_usage_controller.dart';

/// App使用记录采集调试页面
class AppUsageDebugPage extends StatelessWidget {
  const AppUsageDebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppUsageController>();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF333333), size: 20),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'App使用记录采集调试',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Obx(() => controller.selectedApps.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  icon: controller.isReporting.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF839E)),
                          ),
                        )
                      : const Icon(
                          Icons.cloud_upload_outlined,
                          color: Color(0xFFFF839E),
                        ),
                  onPressed: controller.isReporting.value
                      ? null
                      : () => controller.collectAndReportUsageData(),
                  tooltip: '上报使用数据',
                ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索框
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                onChanged: (value) => controller.searchKeyword.value = value,
                decoration: const InputDecoration(
                  hintText: '搜索应用',
                  hintStyle: TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Color(0xFF999999),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          
          // 说明文字
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Color(0xFF999999),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Obx(() => Text(
                    '已筛选 ${controller.selectedApps.length} 个应用，点击右上角上传按钮上报使用数据',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  )),
                ),
              ],
            ),
          ),
          
          // 应用列表
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF839E)),
                  ),
                );
              }
              
              final apps = controller.filteredApps;
              
              if (apps.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        controller.searchKeyword.value.isEmpty 
                            ? '暂无应用' 
                            : '未找到相关应用',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF999999),
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return RefreshIndicator(
                onRefresh: controller.onRefresh,
                color: const Color(0xFFFF839E),
                child: ListView.separated(
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: apps.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    indent: 72,
                    color: Color(0xFFEEEEEE),
                  ),
                  itemBuilder: (context, index) {
                    final app = apps[index];
                    return _buildAppItem(controller, app);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
  
  /// 构建应用列表项
  Widget _buildAppItem(AppUsageController controller, AppInfo app) {
    return Obx(() {
      final isSelected = controller.selectedApps.contains(app.packageName);
      
      return Container(
        color: Colors.white,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              app.icon,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8E8E8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.apps,
                    size: 24,
                    color: Color(0xFF999999),
                  ),
                );
              },
            ),
          ),
          title: Text(
            app.appName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            app.packageName,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF999999),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: SizedBox(
            width: 80,
            child: TextButton(
              onPressed: () => controller.toggleSelection(app.packageName),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                backgroundColor: isSelected 
                    ? const Color(0xFFFF839E) 
                    : const Color(0xFFF5F5F5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                isSelected ? '已筛选' : '筛选',
                style: TextStyle(
                  fontSize: 13,
                  color: isSelected 
                      ? Colors.white 
                      : const Color(0xFF666666),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          onTap: isSelected 
              ? () async {
                  // 显示详细使用数据
                  final record = await controller.getDetailedUsageData(app.packageName);
                  if (record != null) {
                    _showDetailedUsageDialog(app.appName, record);
                  }
                }
              : null,
        ),
      );
    });
  }
  
  /// 显示详细使用数据对话框
  void _showDetailedUsageDialog(String appName, dynamic record) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题栏
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF839E),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${record.date} 使用详情',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),
              
              // 统计信息
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFFFFF5F7),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      icon: Icons.access_time,
                      label: '总时长',
                      value: _formatDuration(record.totalDuration),
                    ),
                    Container(width: 1, height: 40, color: const Color(0xFFFFD4DF)),
                    _buildStatCard(
                      icon: Icons.touch_app,
                      label: '打开次数',
                      value: '${record.sessionCount} 次',
                    ),
                  ],
                ),
              ),
              
              // 会话详情列表
              Expanded(
                child: record.allSessions.isEmpty
                    ? const Center(
                        child: Text(
                          '今日暂无使用记录',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF999999),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: record.allSessions.length,
                        separatorBuilder: (context, index) => const Divider(height: 16),
                        itemBuilder: (context, index) {
                          final session = record.allSessions[index];
                          return _buildSessionItem(session, index + 1);
                        },
                      ),
              ),
              
              // 底部按钮
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text(
                        '关闭',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFFFF839E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }
  
  /// 构建统计卡片
  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: const Color(0xFFFF839E)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF999999),
          ),
        ),
      ],
    );
  }
  
  /// 构建会话项
  Widget _buildSessionItem(dynamic session, int index) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF839E),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '第 $index 次',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.access_time, size: 14, color: Color(0xFF999999)),
              const SizedBox(width: 4),
              Text(
                _formatDuration(session.duration),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.login, size: 16, color: Color(0xFF4CAF50)),
                        const SizedBox(width: 6),
                        const Text(
                          '打开时间',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF999999),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.openTimeFormatted,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, size: 20, color: Color(0xFFCCCCCC)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.logout, size: 16, color: Color(0xFFFF5252)),
                        const SizedBox(width: 6),
                        const Text(
                          '关闭时间',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF999999),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.closeTimeFormatted,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// 格式化时长
  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '$hours小时$minutes分钟';
    } else if (minutes > 0) {
      return '$minutes分钟$seconds秒';
    } else {
      return '$seconds秒';
    }
  }
}

