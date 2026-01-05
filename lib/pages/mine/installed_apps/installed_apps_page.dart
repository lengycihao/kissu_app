import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class InstalledAppsPage extends StatefulWidget {
  const InstalledAppsPage({super.key});

  @override
  State<InstalledAppsPage> createState() => _InstalledAppsPageState();
}

class _InstalledAppsPageState extends State<InstalledAppsPage> {
  static const platform = MethodChannel('app_usage_channel');
  
  List<Map<String, dynamic>> apps = [];
  bool isLoading = true;
  String searchKeyword = '';

  @override
  void initState() {
    super.initState();
    _loadInstalledApps();
  }

  Future<void> _loadInstalledApps() async {
    setState(() {
      isLoading = true;
    });

    try {
      final List<dynamic> result = await platform.invokeMethod('getAllUsageData');
      
      setState(() {
        apps = result.map((e) {
          final map = Map<String, dynamic>.from(e as Map);
          // 转换 hourlyRecords 中的每个 Map
          final hourlyRecordsList = (map['hourlyRecords'] as List<dynamic>)
              .map((record) => Map<String, dynamic>.from(record as Map))
              .toList();
          
          return {
            'appName': map['appName'] as String,
            'packageName': map['packageName'] as String,
            'date': map['date'] as String,
            'totalSessions': map['totalSessions'] as int,
            'hourlyRecords': hourlyRecordsList,
          };
        }).toList();
        
        // 按应用名称排序
        apps.sort((a, b) => (a['appName'] as String).compareTo(b['appName'] as String));
        
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取应用列表失败: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get filteredApps {
    if (searchKeyword.isEmpty) {
      return apps;
    }
    return apps.where((app) {
      final appName = (app['appName'] as String).toLowerCase();
      final packageName = (app['packageName'] as String).toLowerCase();
      final keyword = searchKeyword.toLowerCase();
      return appName.contains(keyword) || packageName.contains(keyword);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF333333), size: 20),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          '已安装应用',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 搜索框
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchKeyword = value;
                });
              },
              decoration: InputDecoration(
                hintText: '搜索应用名称或包名',
                hintStyle: const TextStyle(color: Color(0xFF999999), fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF999999)),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          
          // 应用数量统计
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '共 ${filteredApps.length} 个应用',
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                if (!isLoading)
                  TextButton.icon(
                    onPressed: _loadInstalledApps,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('刷新'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFFF839E),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // 应用列表
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF839E),
                    ),
                  )
                : filteredApps.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              searchKeyword.isEmpty ? Icons.apps : Icons.search_off,
                              size: 64,
                              color: const Color(0xFFCCCCCC),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              searchKeyword.isEmpty ? '暂无应用数据' : '未找到匹配的应用',
                              style: const TextStyle(
                                color: Color(0xFF999999),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: filteredApps.length,
                        separatorBuilder: (context, index) => const Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                        ),
                        itemBuilder: (context, index) {
                          final app = filteredApps[index];
                          final hourlyRecords = app['hourlyRecords'] as List<dynamic>;
                          
                          // 计算总使用时长（秒）
                          int totalDuration = 0;
                          for (var record in hourlyRecords) {
                            final recordMap = record as Map<String, dynamic>;
                            totalDuration += (recordMap['totalDuration'] as int);
                          }
                          
                          // 转换为分钟
                          final minutes = (totalDuration / 1000 / 60).round();
                          
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.apps,
                                color: Color(0xFFFF839E),
                                size: 28,
                              ),
                            ),
                            title: Text(
                              app['appName'] as String,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF333333),
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  app['packageName'] as String,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF999999),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Color(0xFF999999),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${minutes}分钟',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF666666),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Icon(
                                      Icons.schedule,
                                      size: 14,
                                      color: Color(0xFF999999),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${hourlyRecords.length}个时段',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF666666),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Icon(
                                      Icons.touch_app,
                                      size: 14,
                                      color: Color(0xFF999999),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${app['totalSessions']}次',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF666666),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () {
                              _showAppDetailDialog(app);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showAppDetailDialog(Map<String, dynamic> app) {
    final hourlyRecords = app['hourlyRecords'] as List<dynamic>;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(app['appName'] as String),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '包名: ${app['packageName']}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
              ),
              const SizedBox(height: 8),
              Text(
                '日期: ${app['date']}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
              ),
              const SizedBox(height: 16),
              const Text(
                '每小时使用记录:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: hourlyRecords.length,
                  itemBuilder: (context, index) {
                    final record = hourlyRecords[index] as Map<String, dynamic>;
                    final hour = record['hour'] as int;
                    final duration = (record['totalDuration'] as int) / 1000 / 60;
                    final sessionCount = record['sessionCount'] as int;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Text(
                            '${hour.toString().padLeft(2, '0')}:00',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF666666),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              '${duration.toStringAsFixed(1)}分钟 · $sessionCount次',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
