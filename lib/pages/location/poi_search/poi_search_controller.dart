import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/models/city_model.dart';
import 'package:kissu_app/models/poi_model.dart';
import 'package:kissu_app/services/amap_poi_service.dart';
import 'package:kissu_app/services/simple_location_service.dart';
import 'package:kissu_app/pages/location/city_list/city_list_page.dart';
import 'package:kissu_app/utils/oktoast_util.dart';

/// POI搜索Controller
class PoiSearchController extends GetxController {
  final CityModel? initialCity;
  final String? initialLocation; // 🔥 初始位置（格式：经度,纬度）

  PoiSearchController({this.initialCity, this.initialLocation});

  final AMapPoiService _poiService = AMapPoiService();

  // 搜索框控制器
  final TextEditingController searchController = TextEditingController();

  // 当前选中的城市
  final Rx<CityModel?> selectedCity = Rx<CityModel?>(null);
  
  // 城市是否发生过变化（用于返回时同步）
  final RxBool cityChanged = false.obs;

  // 搜索结果列表
  final RxList<PoiModel> searchResults = <PoiModel>[].obs;

  // 是否正在搜索
  final RxBool isSearching = false.obs;

  // 是否有搜索结果
  final RxBool hasSearched = false.obs;
  
  // 是否正在加载更多
  final RxBool isLoadingMore = false.obs;
  
  // 是否还有更多数据
  final RxBool hasMore = true.obs;

  // 当前页码
  int currentPage = 1;

  // 每页数量
  static const int pageSize = 20;
  
  // 防抖定时器
  Timer? _debounceTimer;

  @override
  void onInit() {
    super.onInit();
    selectedCity.value = initialCity;
    
    // 监听输入框变化
    searchController.addListener(_onSearchTextChanged);
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    searchController.removeListener(_onSearchTextChanged);
    searchController.dispose();
    super.onClose();
  }
  
  /// 输入框文本变化监听
  void _onSearchTextChanged() {
    // 取消之前的定时器
    _debounceTimer?.cancel();
    
    final keyword = searchController.text.trim();
    debugPrint('🔍 输入框变化: "$keyword"');
    
    // 如果输入为空，清空搜索结果
    if (keyword.isEmpty) {
      searchResults.clear();
      hasSearched.value = false;
      debugPrint('✅ 已清空搜索结果');
      return;
    }
    
    // 设置新的防抖定时器（500ms后执行搜索）
    debugPrint('⏱️ 设置500ms后自动搜索');
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      debugPrint('🚀 开始自动搜索: "$keyword"');
      search(showLoading: false); // 自动搜索不显示loading
    });
  }

  /// 获取当前位置字符串（格式：经度,纬度）
  String? _getCurrentLocationString() {
    // 🔥 优先使用传入的初始位置
    if (initialLocation != null && initialLocation!.isNotEmpty) {
      debugPrint('✅ 使用传入的初始位置: $initialLocation');
      return initialLocation;
    }
    
    // 其次尝试从定位服务获取
    try {
      final locationService = Get.find<SimpleLocationService>();
      final currentLoc = locationService.currentLocation.value;
      
      if (currentLoc != null) {
        return '${currentLoc.longitude},${currentLoc.latitude}';
      }
    } catch (e) {
      debugPrint('⚠️ 获取当前位置失败: $e');
    }
    return null;
  }

  /// 执行搜索
  /// [showLoading] 是否显示loading状态（自动搜索时不显示，手动搜索时显示）
  Future<void> search({bool showLoading = true}) async {
    final keyword = searchController.text.trim();

    if (keyword.isEmpty) {
      debugPrint('⚠️ 关键词为空，跳过搜索');
      return; // 静默返回，不显示提示
    }

    if (selectedCity.value == null) {
      debugPrint('⚠️ 未选择城市，跳过搜索');
      return; // 静默返回，不显示提示
    }

    try {
      debugPrint('🔍 开始搜索 POI: 关键词="$keyword", 城市=${selectedCity.value!.cityName}');
      if (showLoading) {
        isSearching.value = true;
      }
      currentPage = 1;

      // 获取当前位置（用于计算距离）
      final currentLocation = _getCurrentLocationString();
      debugPrint('📍 当前位置: $currentLocation');

      final results = await _poiService.searchPoi(
        keyword: keyword,
        city: selectedCity.value!.adcode,
        page: currentPage,
        pageSize: pageSize,
        location: currentLocation, // 传递当前位置
      );

      debugPrint('✅ 搜索完成，找到 ${results.length} 条结果');
      searchResults.value = results;
      hasSearched.value = true;
      
      // 判断是否还有更多数据
      hasMore.value = results.length >= pageSize;
    } catch (e) {
      debugPrint('❌ POI搜索失败: $e');
      OKToastUtil.showError('搜索失败，请稍后重试');
    } finally {
      if (showLoading) {
        isSearching.value = false;
      }
    }
  }

  /// 加载更多
  Future<void> loadMore() async {
    // 如果正在加载或没有更多数据，直接返回
    if (isLoadingMore.value || !hasMore.value) {
      debugPrint('⚠️ 跳过加载更多: isLoadingMore=${isLoadingMore.value}, hasMore=${hasMore.value}');
      return;
    }
    
    final keyword = searchController.text.trim();
    if (keyword.isEmpty || selectedCity.value == null) return;

    try {
      isLoadingMore.value = true;
      currentPage++;
      debugPrint('📄 加载第 $currentPage 页数据');

      // 获取当前位置（用于计算距离）
      final currentLocation = _getCurrentLocationString();

      final results = await _poiService.searchPoi(
        keyword: keyword,
        city: selectedCity.value!.adcode,
        page: currentPage,
        pageSize: pageSize,
        location: currentLocation, // 传递当前位置
      );

      debugPrint('✅ 加载更多完成，新增 ${results.length} 条结果');
      searchResults.addAll(results);
      
      // 判断是否还有更多数据
      hasMore.value = results.length >= pageSize;
    } catch (e) {
      debugPrint('❌ 加载更多失败: $e');
      currentPage--;
      OKToastUtil.showError('加载失败，请稍后重试');
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// 选择城市
  Future<void> selectCity() async {
    final result = await Get.to(
      () => const CityListPage(),
      transition: Transition.rightToLeft,
    );
    if (result != null && result is CityModel) {
      selectedCity.value = result;
      cityChanged.value = true; // 标记城市已变化
      debugPrint('🏙️ POI搜索页切换城市: ${result.cityName}');
    }
  }

  /// 选择POI
  void selectPoi(PoiModel poi) {
    // 返回POI和城市信息
    Get.back(result: {
      'poi': poi,
      'city': selectedCity.value,
      'cityChanged': cityChanged.value,
    });
  }
  
  /// 返回按钮（需要同步城市变化）
  void goBack() {
    if (cityChanged.value && selectedCity.value != null) {
      // 如果城市发生变化，返回城市信息
      Get.back(result: {
        'city': selectedCity.value,
        'cityChanged': true,
      });
    } else {
      // 否则直接返回
      Get.back();
    }
  }
}

