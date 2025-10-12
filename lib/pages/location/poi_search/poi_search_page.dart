import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/models/poi_model.dart';
import 'package:kissu_app/pages/location/poi_search/poi_search_controller.dart';
import 'package:kissu_app/widgets/dash_line_widget.dart';

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
        top: MediaQuery.of(Get.context!).padding.top + 19,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
         
         
      ),
      child: Row(
        children: [
          // 返回按钮
          GestureDetector(
            onTap: () => controller.goBack(),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Image(
                image: AssetImage('assets/location/kissu3_back.webp'),
                width: 20,
                height: 20,
              ),
            ),
          ),

          // 搜索框
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFffffff),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFFBBB5), width: 1),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: controller.searchController,
                      autofocus: true,
                      textInputAction: TextInputAction.search, // 使用搜索键盘
                      onSubmitted: (value) {
                        // 点击键盘上的搜索按钮时触发
                        controller.search(showLoading: true);
                      },
                      decoration: InputDecoration(
                        hintText: '请输入',
                        
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8).copyWith(bottom: 10),
                      ),
                      
                      style: const TextStyle(fontSize: 14),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Image(
                      image: AssetImage('assets/location/kissu3_location_pink.webp'),
                      width: 16,
                      height: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      city?.cityName.replaceAll('市', '') ?? '选择城市',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
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
            if (!hasCity) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => controller.selectCity(),
                child: const Text(
                  '点击选择城市',
                  style: TextStyle(fontSize: 14, color: Color(0xFFFF408D)),
                ),
              ),
            ],
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
                  DashedLine(color: Color(0xFFE6E2E3),dashSpace: 3,),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

