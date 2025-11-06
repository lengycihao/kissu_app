import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// App图标选择页面
class AppIconSelectorPage extends StatefulWidget {
  const AppIconSelectorPage({super.key});

  @override
  State<AppIconSelectorPage> createState() => _AppIconSelectorPageState();
}

class _AppIconSelectorPageState extends State<AppIconSelectorPage> {
  static const platform = MethodChannel('app_icon_channel');
  
  // 当前选中的图标
  String _currentIcon = 'default';
  bool _isLoading = false;

  // 可用的图标列表
  final List<AppIconItem> _iconItems = [
    AppIconItem(
      id: 'default',
      name: '原始图标',
      previewPath: 'assets/kissu_icon.webp', // 之前的logo
      description: 'Kissu经典图标',
    ),
    AppIconItem(
      id: 'logo_one',
      name: '图标一',
      previewPath: 'assets/4.0/kissu4_logo_one.webp',
      description: '新设计图标一',
    ),
    AppIconItem(
      id: 'logo_two',
      name: '图标二',
      previewPath: 'assets/4.0/kissu4_logo_two.jpg',
      description: '新设计图标二',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentIcon();
  }

  /// 获取当前使用的图标
  Future<void> _getCurrentIcon() async {
    try {
      final String result = await platform.invokeMethod('getCurrentIcon');
      setState(() {
        _currentIcon = result;
      });
    } catch (e) {
      print('获取当前图标失败: $e');
    }
  }

  /// 切换图标
  Future<void> _changeIcon(String iconId) async {
    if (_currentIcon == iconId) {
      Get.snackbar(
        '提示',
        '当前已是该图标',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final bool success = await platform.invokeMethod('changeIcon', {'iconId': iconId});
      
      if (success) {
        setState(() {
          _currentIcon = iconId;
        });
        
        Get.snackbar(
          '成功',
          '图标切换成功，重启App后生效',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFFF9DC4).withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(16),
        );
      } else {
        Get.snackbar(
          '失败',
          '图标切换失败，请重试',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(16),
        );
      }
    } catch (e) {
      print('切换图标失败: $e');
      Get.snackbar(
        '错误',
        '切换失败: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景
          Positioned.fill(
            child: Image.asset(
              "assets/3.0/kissu3_view_bg.webp",
              fit: BoxFit.fill,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // 顶部导航栏
                _buildAppBar(),
                // 图标列表
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _iconItems.length,
                    itemBuilder: (context, index) {
                      final item = _iconItems[index];
                      final isSelected = _currentIcon == item.id;
                      return _buildIconItem(item, isSelected);
                    },
                  ),
                ),
              ],
            ),
          ),
          // 加载遮罩
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9DC4)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建顶部导航栏
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Image.asset(
              "assets/kissu_mine_back.webp",
              width: 22,
              height: 22,
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                "更换APP图标",
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xff333333),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 22), // 占位保持居中
        ],
      ),
    );
  }

  /// 构建图标项
  Widget _buildIconItem(AppIconItem item, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFFFF9DC4) : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _changeIcon(item.id),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // 图标预览
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      item.previewPath,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // 图标信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9DC4),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                '使用中',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF999999),
                        ),
                      ),
                    ],
                  ),
                ),
                // 选中指示器
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? const Color(0xFFFF9DC4) : const Color(0xFFCCCCCC),
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 图标项数据模型
class AppIconItem {
  final String id;
  final String name;
  final String previewPath;
  final String description;

  AppIconItem({
    required this.id,
    required this.name,
    required this.previewPath,
    required this.description,
  });
}

