import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/models/poi_model.dart';
import 'package:kissu_app/pages/location/poi_search/poi_search_controller.dart';
// dash line widget not used here anymore

/// POI搜索页面
class PoiSearchPage extends GetView<PoiSearchController> {
  const PoiSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
          children: [
            // 自定义导航栏
            _buildCustomAppBar(),

            // 搜索结果列表
            Expanded(
              child: Obx(() {
                if (controller.isSearching.value) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFFFBBB5),));
                }

                if (!controller.hasSearched.value) {
                  return _buildEmptyState();
                }

                if (controller.searchResults.isEmpty) {
                  return _buildNoResults();
                }

                return _buildSearchResults();
              }),
            ),
          ],
        ),
     
    );
  }

  /// 自定义导航栏
  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 19).copyWith(
        top: MediaQuery.of(Get.context!).padding.top + 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,


      ),
      child: SizedBox(
        height: 44,
        child: Row(
        children: [
          // 返回按钮
          GestureDetector(
            onTap: () => controller.goBack(),
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              child: Image.asset(
                'assets/images/kissu_mine_back.webp',
                width: 22,
                height: 22,
              ),
            ),
          ),

          // 搜索框（与添加地点页面保持一致的样式：左侧图标、文本输入、右侧“搜索”按钮）
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8E8E8), width: 1),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10).copyWith(right: 8),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/kissu_search_icon.webp',
                    width: 16,
                    height: 16,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: TextField(
                      controller: controller.searchController,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (value) => controller.search(showLoading: true),
                      decoration: InputDecoration(
                        hintText: '请输入要添加的地点',
                        hintStyle: TextStyle(fontSize: 12, color: Color(0xff999999)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8).copyWith(bottom: 13),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => controller.search(showLoading: true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFA9E0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '搜索',
                        style: TextStyle(fontSize: 14, color: Color(0xFFFFFFFF)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 城市定位按钮
          Obx(() {
            final city = controller.selectedCity.value;
            return GestureDetector(
              onTap: () => controller.selectCity(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Image(
                      image: AssetImage('assets/location/kissu3_location_pink.webp'),
                      width: 16,
                      color: Color(0xff777777),
                      height: 16,
                    ),
                    const SizedBox(width: 4),
                    // 限制城市名称最大宽度，防止挤压搜索框
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 90),
                      child: Text(
                        city?.cityName.replaceAll('市', '') ?? '选择城市',
                        style: const TextStyle(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    ),
  );
}

  /// 空状态
  Widget _buildEmptyState() {
    return Obx(() {
      final hasCity = controller.selectedCity.value != null;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              hasCity ? '输入关键词搜索地点' : '请先选择城市',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            // if (!hasCity) ...[
            //   const SizedBox(height: 12),
            //   TextButton(
            //     onPressed: () => controller.selectCity(),
            //     child: const Text(
            //       '点击选择城市',
            //       style: TextStyle(fontSize: 14, color: Color(0xFFFF408D)),
            //     ),
            //   ),
            // ],
          ],
        ),
      );
    });
  }

  /// 无结果
  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            '未找到相关地点',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  /// 搜索结果列表
  Widget _buildSearchResults() {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        // 判断是否滚动到底部
        if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
          // 触发加载更多
          controller.loadMore();
        }
        return false;
      },
      child: ListView.builder(
        itemCount: controller.searchResults.length + 1, // +1 用于显示加载更多提示
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          // 最后一项显示加载状态
          if (index == controller.searchResults.length) {
            return _buildLoadMoreIndicator();
          }
          
          final poi = controller.searchResults[index];
          return _buildPoiItem(poi);
        },
      ),
    );
  }
  
  /// 加载更多指示器
  Widget _buildLoadMoreIndicator() {
    return Obx(() {
      if (controller.isLoadingMore.value) {
        // 正在加载
        return Container(
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFFFBBB5),
            ),
          ),
        );
      } else if (!controller.hasMore.value && controller.searchResults.isNotEmpty) {
        // 没有更多数据
        return Container(
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
          child: Text(
            '没有更多数据了',
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
        );
      } else {
        // 还有更多数据但未加载
        return const SizedBox(height: 16);
      }
    });
  }

  /// POI列表项
  Widget _buildPoiItem(PoiModel poi) {
    return InkWell(
      onTap: () => controller.selectPoi(poi),
      child: Container(
        padding: const EdgeInsets.all(16).copyWith(left: 22,right: 22,top: 0),
        // decoration: BoxDecoration(
        //   border: Border(
        //     bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
        //   ),
        // ),
        child: Row(
          children: [
            // POI信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // POI名称
                  Text(
                    poi.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // 距离 + POI地址
                  Row(
                    children: [
                      // 距离（如果有）
                      if (poi.distanceText.isNotEmpty) ...[
                        Text(
                          poi.distanceText,
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xffFF888A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                          
                        const SizedBox(width: 8),
                      ],
                      // 地址
                      Expanded(
                        child: Text(
                          poi.address,
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF333333),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height:11),
                  // 使用实线替代虚线
                  Container(
                    height: 1,
                    color: const Color(0xFFE6E2E3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

