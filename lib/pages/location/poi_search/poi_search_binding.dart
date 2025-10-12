import 'package:get/get.dart';
import 'package:kissu_app/pages/location/poi_search/poi_search_controller.dart';
import 'package:kissu_app/models/city_model.dart';

/// POI搜索页面的依赖注入绑定
class PoiSearchBinding extends Bindings {
  @override
  void dependencies() {
    // 从路由参数获取城市信息
    final CityModel? initialCity = Get.arguments as CityModel?;
    
    Get.lazyPut<PoiSearchController>(
      () => PoiSearchController(initialCity: initialCity),
      fenix: false,
    );
  }
}

