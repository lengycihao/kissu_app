import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kissu_app/utils/oktoast_util.dart';

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
      previewPath: 'assets/images/kissu_icon.webp', // 之前的logo
      description: 'Kissu经典图标',
    ),
    AppIconItem(
      id: 'logo_one',
      name: '图标一',
      previewPath: 'assets/4.0/kissu4_logo_one.webp',
      description: '新设计图标一',
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
      OKToastUtil.show('当前已是该图标');
      
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
        
        OKToastUtil.show('切换成功，重启后生效');
          
      } else {
         OKToastUtil.show('图标切换失败，请重试');
      }
    } catch (e) {
      print('切换图标失败: $e');
      OKToastUtil.show('切换失败: $e');
       
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffFFF6F0),
      body: Stack(
        
        children: [
          
          SafeArea(
            
            child: Column(
              children: [
                // 顶部导航栏
                _buildAppBar(),
                // 图标列表
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // 一行3个
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75, // 宽高比，为文字预留空间
                    ),
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
              "assets/images/kissu_mine_back.webp",
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
    return GestureDetector(
      onTap: () => _changeIcon(item.id),
      child: Column(
        children: [
          // 图标图片（带边框）- 正方形
          AspectRatio(
            aspectRatio: 1.0, // 1:1 正方形
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? const Color(0xFFFFA1DB) : Colors.transparent,
                  width: 3,
                ),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.asset(
                      item.previewPath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  // 选中指示器
                  if (isSelected)
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFA1DB),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(2),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 图标名称（在边框外）
          Text(
            item.name,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF333333),
            ),
            textAlign: TextAlign.center,
          ),
        ],
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

