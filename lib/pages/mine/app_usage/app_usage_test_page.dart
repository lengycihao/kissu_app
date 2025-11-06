import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/mine/app_usage/app_usage_controller.dart';
import 'package:kissu_app/pages/mine/app_usage/models/app_usage_record.dart';

/// App使用记录测试页面
class AppUsageTestPage extends StatefulWidget {
  const AppUsageTestPage({super.key});

  @override
  State<AppUsageTestPage> createState() => _AppUsageTestPageState();
}

class _AppUsageTestPageState extends State<AppUsageTestPage> {
  final controller = Get.find<AppUsageController>();
  List<AppUsageRecord>? testRecords;
  bool isLoading = false;
  String statusMessage = '点击下方按钮测试功能';

  @override
  Widget build(BuildContext context) {
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
          'App使用记录测试',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 状态信息卡片
            _buildStatusCard(),
            const SizedBox(height: 16),
            
            // 已筛选应用列表
            _buildSelectedAppsCard(),
            const SizedBox(height: 16),
            
            // 测试按钮区域
            _buildTestButtons(),
            const SizedBox(height: 16),
            
            // 测试结果显示
            if (testRecords != null) _buildTestResults(),
          ],
        ),
      ),
    );
  }

  /// 构建状态信息卡片
  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF839E),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '测试状态',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                isLoading ? Icons.hourglass_empty : Icons.info_outline,
                size: 16,
                color: const Color(0xFF999999),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusMessage,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
              ),
            ],
          ),
          if (isLoading) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF839E)),
              backgroundColor: Color(0xFFFFE8ED),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建已筛选应用列表卡片
  Widget _buildSelectedAppsCard() {
    return Obx(() {
      final selectedApps = controller.selectedApps;
      
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF839E),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '已筛选应用',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF839E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${selectedApps.length} 个',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF839E),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (selectedApps.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '暂无筛选应用，请先在主页面筛选应用',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF999999),
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedApps.map((packageName) {
                  final app = controller.apps.firstWhereOrNull(
                    (a) => a.packageName == packageName,
                  );
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      app?.appName ?? packageName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      );
    });
  }

  /// 构建测试按钮区域
  Widget _buildTestButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF839E),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '功能测试',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 测试采集数据按钮
          _buildTestButton(
            icon: Icons.analytics_outlined,
            title: '测试采集数据',
            description: '采集已筛选应用的使用数据',
            onTap: isLoading ? null : _testCollectData,
          ),
          const SizedBox(height: 12),
          
          // 测试上报数据按钮
          _buildTestButton(
            icon: Icons.cloud_upload_outlined,
            title: '测试上报数据',
            description: '上报采集到的使用数据',
            onTap: isLoading ? null : _testReportData,
          ),
          const SizedBox(height: 12),
          
          // 测试完整流程按钮
          _buildTestButton(
            icon: Icons.play_circle_outline,
            title: '测试完整流程',
            description: '采集并上报使用数据（推荐）',
            onTap: isLoading ? null : _testFullProcess,
            highlighted: true,
          ),
          const SizedBox(height: 12),
          
          // 清除测试数据按钮
          _buildTestButton(
            icon: Icons.delete_outline,
            title: '清除测试数据',
            description: '清除当前显示的测试结果',
            onTap: _clearTestData,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  /// 构建测试按钮
  Widget _buildTestButton({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback? onTap,
    bool highlighted = false,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: highlighted 
              ? const Color(0xFFFF839E).withOpacity(0.05)
              : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
          border: highlighted 
              ? Border.all(color: const Color(0xFFFF839E).withOpacity(0.3))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color?.withOpacity(0.1) ?? 
                       (highlighted 
                           ? const Color(0xFFFF839E).withOpacity(0.1) 
                           : Colors.white),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: color ?? (highlighted ? const Color(0xFFFF839E) : const Color(0xFF666666)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: onTap == null ? const Color(0xFF999999) : const Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: color ?? const Color(0xFF999999),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建测试结果
  Widget _buildTestResults() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF839E),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '测试结果',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 结果统计
          Row(
            children: [
              Expanded(
                child: _buildStatItem('采集应用', '${testRecords?.length ?? 0}'),
              ),
              Expanded(
                child: _buildStatItem(
                  '有使用记录',
                  '${testRecords?.where((r) => r.hourlyRecords.isNotEmpty).length ?? 0}',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  '总打开次数',
                  '${testRecords?.fold<int>(0, (sum, r) => sum + r.sessionCount) ?? 0}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 详细列表
          ...testRecords!.map((record) => _buildRecordItem(record)),
        ],
      ),
    );
  }

  /// 构建统计项
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF839E),
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

  /// 构建记录项
  Widget _buildRecordItem(AppUsageRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Expanded(
                child: Text(
                  record.appName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              if (record.hourlyRecords.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '无使用',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF999999),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            record.packageName,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF999999),
            ),
          ),
          if (record.hourlyRecords.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Color(0xFF999999)),
                const SizedBox(width: 4),
                Text(
                  '使用时长: ${_formatDuration(record.totalDuration)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.touch_app, size: 14, color: Color(0xFF999999)),
                const SizedBox(width: 4),
                Text(
                  '打开: ${record.sessionCount} 次',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: record.hourlyRecords.map((hourRecord) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF839E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${hourRecord.hour.toString().padLeft(2, '0')}时 ${_formatDuration(hourRecord.totalDuration)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFFF839E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
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
      return '${hours}h${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// 测试采集数据
  Future<void> _testCollectData() async {
    if (controller.selectedApps.isEmpty) {
      Get.snackbar('提示', '请先在主页面筛选应用');
      return;
    }

    setState(() {
      isLoading = true;
      statusMessage = '正在采集数据...';
      testRecords = null;
    });

    try {
      final List<dynamic> result = await AppUsageController.platform.invokeMethod(
        'getBatchDetailedUsageData',
        {'packageNames': controller.selectedApps.toList()},
      );

      final records = <AppUsageRecord>[];
      for (final data in result) {
        final map = _convertMap(data);
        final hourlyRecords = (map['hourlyRecords'] as List<dynamic>)
            .map((e) => HourlyUsageRecord.fromJson(_convertMap(e)))
            .toList();

        records.add(AppUsageRecord(
          appName: map['appName'] as String,
          packageName: map['packageName'] as String,
          iconBase64: map['iconBase64'] as String?,
          date: map['date'] as String,
          hourlyRecords: hourlyRecords,
        ));
      }

      setState(() {
        testRecords = records;
        statusMessage = '采集完成！共采集 ${records.length} 个应用的数据';
      });

      Get.snackbar(
        '成功',
        '数据采集完成',
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      setState(() {
        statusMessage = '采集失败: $e';
      });
      Get.snackbar('错误', '数据采集失败: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// 测试上报数据
  Future<void> _testReportData() async {
    if (testRecords == null || testRecords!.isEmpty) {
      Get.snackbar('提示', '请先采集数据');
      return;
    }

    setState(() {
      isLoading = true;
      statusMessage = '正在上报数据...';
    });

    try {
      final recordsToReport = testRecords!
          .where((r) => r.hourlyRecords.isNotEmpty)
          .toList();

      if (recordsToReport.isEmpty) {
        Get.snackbar('提示', '没有需要上报的使用记录');
        return;
      }

      await controller.collectAndReportUsageData();

      setState(() {
        statusMessage = '上报完成！已上报 ${recordsToReport.length} 个应用的数据';
      });
    } catch (e) {
      setState(() {
        statusMessage = '上报失败: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// 测试完整流程
  Future<void> _testFullProcess() async {
    await _testCollectData();
    if (testRecords != null && testRecords!.isNotEmpty) {
      await Future.delayed(const Duration(seconds: 1));
      await _testReportData();
    }
  }

  /// 清除测试数据
  void _clearTestData() {
    setState(() {
      testRecords = null;
      statusMessage = '已清除测试数据';
    });
  }
  
  /// 递归转换Map类型（处理嵌套的Map和List）
  Map<String, dynamic> _convertMap(dynamic data) {
    if (data is Map) {
      return data.map((key, value) {
        if (value is Map) {
          return MapEntry(key.toString(), _convertMap(value));
        } else if (value is List) {
          return MapEntry(key.toString(), value.map((e) {
            if (e is Map) {
              return _convertMap(e);
            }
            return e;
          }).toList());
        }
        return MapEntry(key.toString(), value);
      });
    }
    return {};
  }
}

