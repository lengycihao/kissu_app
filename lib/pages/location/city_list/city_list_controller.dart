import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/models/city_model.dart';
import 'package:kissu_app/network/public/api_request.dart';
import 'package:kissu_app/services/city_storage_service.dart';
import 'package:kissu_app/network/http_managerN.dart';

/// 城市列表Controller
class CityListController extends GetxController {
  final CityStorageService _cityStorageService = Get.find<CityStorageService>();
  
  // 搜索框控制器
  final TextEditingController searchController = TextEditingController();
  
  // 滚动控制器
  final ScrollController scrollController = ScrollController();
  
  // 所有城市数据（按首字母分组）
  final RxList<CityGroupModel> allCities = <CityGroupModel>[].obs;
  
  // 热门城市
  final RxList<CityModel> hotCities = <CityModel>[].obs;
  
  // 最近访问的城市
  final RxList<CityModel> recentCities = <CityModel>[].obs;
  
  // 当前定位的城市
  final Rx<CityModel?> currentCity = Rx<CityModel?>(null);
  
  // 搜索结果
  final RxList<CityModel> searchResults = <CityModel>[].obs;
  
  // 是否正在搜索
  final RxBool isSearching = false.obs;
  
  // 是否正在加载
  final RxBool isLoading = false.obs;
  
  // 字母索引列表
  final RxList<String> letterIndex = <String>[].obs;
  
  // 当前选中的字母（用于防抖）
  String? _lastScrolledLetter;
  DateTime? _lastScrollTime;

  @override
  void onInit() {
    super.onInit();
    _loadRecentCities();
    _loadCityList();
    _loadCurrentCity();
    
    // 监听搜索输入
    searchController.addListener(_onSearchChanged);
  }

  @override
  void onClose() {
    searchController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  /// 加载最近访问的城市
  Future<void> _loadRecentCities() async {
    recentCities.value = await _cityStorageService.getRecentCities();
  }

  /// 加载当前定位城市
  Future<void> _loadCurrentCity() async {
    // TODO: 从定位服务获取当前城市
    // 暂时使用默认城市
    currentCity.value = CityModel(
      cityName: '杭州市',
      adcode: '330100',
    );
  }

  /// 加载城市列表
  Future<void> _loadCityList() async {
    try {
      isLoading.value = true;
      
      // 从后端API获取城市列表
      final result = await HttpManagerN.instance.executeGet(ApiRequest.getRegion);
      
      if (result.isSuccess && result.dataJson != null) {
        final cityListResponse = CityListResponse.fromJson(result.dataJson);
        
        allCities.value = cityListResponse.region;
        hotCities.value = cityListResponse.hotCities;
        
        // 生成字母索引
        letterIndex.value = allCities.map((group) => group.firstLetter).toList();
        
        debugPrint('✅ 城市列表加载成功：${allCities.length}个分组，${hotCities.length}个热门城市');
      } else {
        debugPrint('❌ 加载城市列表失败: ${result.msg}');
        // 使用本地默认数据
        _loadDefaultCities();
      }
    } catch (e) {
      debugPrint('❌ 加载城市列表异常: $e');
      // 使用本地默认数据
      _loadDefaultCities();
    } finally {
      isLoading.value = false;
    }
  }

  /// 加载默认城市数据（离线数据）
  void _loadDefaultCities() {
    // 从 api.md 中提取的热门城市
    hotCities.value = [
      CityModel(cityName: '北京市', adcode: '110100'),
      CityModel(cityName: '广州市', adcode: '440100'),
      CityModel(cityName: '杭州市', adcode: '330100'),
      CityModel(cityName: '上海市', adcode: '310100'),
      CityModel(cityName: '深圳市', adcode: '440300'),
      CityModel(cityName: '天津市', adcode: '120100'),
      CityModel(cityName: '武汉市', adcode: '420100'),
    ];
    
    // 生成字母索引
    letterIndex.value = allCities.map((group) => group.firstLetter).toList();
    
    // TODO: 加载完整的城市列表
    // 这里需要将 api.md 的数据集成到应用中
  }

  /// 搜索输入变化
  void _onSearchChanged() {
    final keyword = searchController.text.trim();
    
    if (keyword.isEmpty) {
      isSearching.value = false;
      searchResults.clear();
      return;
    }
    
    isSearching.value = true;
    _searchCity(keyword);
  }

  /// 搜索城市
  void _searchCity(String keyword) {
    final results = <CityModel>[];
    
    for (final group in allCities) {
      for (final city in group.cityList) {
        if (city.cityName.contains(keyword) ||
            city.cityName.toLowerCase().contains(keyword.toLowerCase()) ||
            group.firstLetter.toLowerCase() == keyword.toLowerCase()) {
          results.add(city);
        }
      }
    }
    
    searchResults.value = results;
  }

  /// 选择城市
  Future<void> selectCity(CityModel city) async {
    // 保存到最近访问
    await _cityStorageService.addRecentCity(city);
    
    // 返回选中的城市
    Get.back(result: city);
  }

  /// 滚动到指定字母
  void scrollToLetter(String letter) {
    try {
      // 防抖：如果是同一个字母且在100ms内，则跳过
      final now = DateTime.now();
      if (_lastScrolledLetter == letter && 
          _lastScrollTime != null && 
          now.difference(_lastScrollTime!).inMilliseconds < 100) {
        return;
      }
      
      _lastScrolledLetter = letter;
      _lastScrollTime = now;
      
      // 找到目标字母在列表中的索引
      final targetIndex = allCities.indexWhere((group) => group.firstLetter == letter);
      if (targetIndex == -1) {
        debugPrint('⚠️ 未找到字母 $letter 的分组');
        return;
      }
      
      // 计算目标位置
      // 1. 顶部固定区域：当前定位城市(56) + 最近访问城市(约100) + 热门城市(约120) ≈ 276px
      double targetPosition = 276.0;
      
      // 2. 累加前面所有分组的高度
      for (int i = 0; i < targetIndex; i++) {
        final group = allCities[i];
        // 每个分组 = 标题(38) + 城市列表(每个42)
        targetPosition += 38 + (group.cityList.length * 42.0);
      }
      
      // 直接跳转，不要动画
      scrollController.jumpTo(
        targetPosition.clamp(0.0, scrollController.position.maxScrollExtent),
      );
      
      debugPrint('📍 滚动到字母: $letter (索引: $targetIndex, 位置: $targetPosition)');
    } catch (e) {
      debugPrint('❌ 滚动到字母失败: $e');
    }
  }
}

