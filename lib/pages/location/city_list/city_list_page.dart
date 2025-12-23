import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/models/city_model.dart';
import 'package:kissu_app/pages/location/city_list/city_list_controller.dart';
// dash line widget not used here anymore

/// 城市列表选择页面
class CityListPage extends GetView<CityListController> {
  const CityListPage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => CityListController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // 主内容区域
            Column(
              children: [
                // 搜索框
                _buildSearchBar(context),

                // 内容区域
                Expanded(
                  child: Obx(() {
                    if (controller.isSearching.value) {
                      return _buildSearchResults();
                    } else {
                      return _buildCityList();
                    }
                  }),
                ),
              ],
            ),

            // 右侧字母索引（只在非搜索状态显示）
            Obx(() {
              if (!controller.isSearching.value &&
                  controller.letterIndex.isNotEmpty) {
                return _buildLetterIndex();
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  /// 搜索栏
  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),

      child: Row(
        children: [
          // 返回按钮
          GestureDetector(
            onTap: () => Get.back(),
            child: Image(
              image: AssetImage('assets/location/kissu3_back.webp'),
              color: Color(0xff333333),
              width: 20,
              height: 20,
            ),
          ),
          const SizedBox(width: 8),

          // 搜索输入框（与添加地点/POI搜索页保持一致：左图标、输入框、右侧“搜索”按钮）
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8E8E8), width: 1),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
              ).copyWith(right: 8),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Image.asset(
                    'assets/3.0/kissu3_search_icon.webp',
                    color: Color(0xff333333),
                    width: 16,
                    height: 16,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: TextField(
                      controller: controller.searchController,
                      decoration: InputDecoration(
                        hintText: '请输入要添加的地点',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF999999),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 8,
                        ).copyWith(bottom: 13),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => controller.triggerSearchFromInput(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFA9E0),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        '搜索',
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          // 当前定位城市（放在输入框外部，右侧显示，不可点击）
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 90),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/location/kissu3_location_pink.webp',color: Color(0xff777777),
                    width: 16,
                    height: 16,
                  ),
                  const SizedBox(width: 4),
                  Obx(() {
                    final current = controller.currentCity.value;
                    return Text(
                      current?.cityName.replaceAll('市', '') ?? '定位中',
                      style: const TextStyle(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 城市列表（非搜索状态）
  Widget _buildCityList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return CustomScrollView(
        controller: controller.scrollController,
        slivers: [
          // 定位/最近访问
          _buildRecentSection(),

          // 热门城市
          _buildHotCitiesSection(),

          // 城市列表（按字母分组）
          _buildGroupedCities(),
        ],
      );
    });
  }

  /// 最近访问/定位城市
  Widget _buildRecentSection() {
    return Obx(() {
      final currentCity = controller.currentCity.value;

      // 仅显示当前定位城市；如果为空则不显示该模块
      if (currentCity == null) {
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      }

      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image(
                    image: AssetImage(
                      'assets/location/kissu3_location_pink.webp',
                    ),
                    color: Color(0xff777777),
                    width: 10,
                    height: 10,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '定位/最近访问',
                    style: TextStyle(fontSize: 12, color: Color(0xFF333333)),
                  ),
                  const SizedBox(width: 8),
                  // 当前城市（放在标题右侧）
                  Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(6),
                       ),
                      child: Text(
                        currentCity.cityName.replaceAll('市', ''),
                        style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
    });
  }

  /// 热门城市
  Widget _buildHotCitiesSection() {
    return Obx(() {
      if (controller.hotCities.isEmpty) {
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      }

      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(22).copyWith(top: 0,right: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '热门城市',
                style: TextStyle(fontSize: 12, color: Color(0xFF777777)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: controller.hotCities.map((city) {
                  return GestureDetector(
                    onTap: () => controller.selectCity(city),
                    child: Container(
                      width: (Get.width - 70) / 4,
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(6),
                       ),
                      child: Text(
                        city.cityName ,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );
    });
  }

  /// 分组城市列表
  Widget _buildGroupedCities() {
    return Obx(() {
      return SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final group = controller.allCities[index];
          return _buildCityGroup(group);
        }, childCount: controller.allCities.length),
      );
    });
  }

  /// 城市分组
  Widget _buildCityGroup(CityGroupModel group) {
    final key = controller.groupHeaderKeys[group.firstLetter];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 字母索引
        Container(
          key: key,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8) ,
          color: const Color(0xFFffffff),
          child: Text(
            group.firstLetter,
            style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
          ),
        ),

        // 城市列表
        ...group.cityList.map((city) {
          return InkWell(
            onTap: () => controller.selectCity(city),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 14,
              ).copyWith(right: 30,bottom: 0),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    city.cityName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF333333),
                    ),
                  ),
                  SizedBox(height: 10),
                  // 使用实线替代虚线
                  Container(
                    height: 0.6,
                    color: const Color(0xffE8E8E8),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  /// 搜索结果列表
  Widget _buildSearchResults() {
    return Obx(() {
      if (controller.searchResults.isEmpty) {
        return const Center(
          child: Text(
            '未找到相关城市',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        );
      }

      return ListView.builder(
        itemCount: controller.searchResults.length,
        itemBuilder: (context, index) {
          final city = controller.searchResults[index];
          return InkWell(
            onTap: () => controller.selectCity(city),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
                ),
              ),
              child: Text(city.cityName, style: const TextStyle(fontSize: 15)),
            ),
          );
        },
      );
    });
  }

  /// 右侧字母索引导航
  Widget _buildLetterIndex() {
    return Positioned(
      right: 0,
      top: 0, // 给搜索框留出空间
      bottom: 0,
      child: GestureDetector(
        // 支持垂直滑动选择
        onVerticalDragUpdate: (details) {
          _handleLetterDrag(details.globalPosition);
        },
        onVerticalDragEnd: (_) {
          // 延迟关闭提示
          Future.delayed(const Duration(milliseconds: 200), () {
            Get.closeAllSnackbars();
          });
        },
        child:  Container(
              width: 20,
              alignment: Alignment.center,
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(), // 禁止滚动，只作展示
                itemCount: controller.letterIndex.length,
                itemBuilder: (context, index) {
                  final letter = controller.letterIndex[index];
                  return _buildLetterItem(letter, index);
                },
              ),
            ),
      ),
    );
  }

  /// 单个字母索引项
  Widget _buildLetterItem(String letter, int index) {
    return Obx(() {
      final isSelected = controller.selectedLetter.value == letter;
      return GestureDetector(
        onTap: () => _onLetterTap(letter),
        child: Container(
          height: 20,
          width: 20,
          alignment: Alignment.center,
          decoration: isSelected
              ? BoxDecoration(
                  color: const Color(0xFFFFA9E0),
                 )
              : null,
          child: Text(
            letter,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.white : const Color(0xFF777777),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    });
  }

  /// 处理滑动选择字母
  void _handleLetterDrag(Offset globalPosition) {
    // 计算触摸位置对应的字母索引
    final screenHeight = Get.height;
    final topOffset = 60.0; // 顶部搜索框高度
    final indexHeight =
        (screenHeight - topOffset) / controller.letterIndex.length;

    final relativeY = globalPosition.dy - topOffset;
    final index = (relativeY / indexHeight).floor().clamp(
      0,
      controller.letterIndex.length - 1,
    );

    if (index >= 0 && index < controller.letterIndex.length) {
      final letter = controller.letterIndex[index];
      _onLetterTap(letter);
    }
  }

  /// 点击字母索引
  void _onLetterTap(String letter) {
    // 滚动到指定字母
    controller.scrollToLetter(letter);

    // 显示字母提示
    _showLetterIndicator(letter);
  }

  /// 显示字母提示气泡
  void _showLetterIndicator(String letter) {
    // 移除之前的提示
    Get.closeAllSnackbars();

    // 创建居中的字母提示（无背景）
    Get.rawSnackbar(
      duration: const Duration(milliseconds: 300),
      backgroundColor: Colors.transparent,
      snackPosition: SnackPosition.TOP,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      messageText: Center(
        child: Container(
          margin: EdgeInsets.only(top: Get.height / 2 - 50),
          alignment: Alignment.center,
          child: Text(
            letter,
            style: const TextStyle(
              fontSize: 60,
              color: Color(0xFFFF6B6B),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
