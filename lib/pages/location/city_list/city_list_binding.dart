import 'package:get/get.dart';
import 'package:kissu_app/pages/location/city_list/city_list_controller.dart';

/// 城市列表页面的依赖注入绑定
class CityListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CityListController>(
      () => CityListController(),
      fenix: false,
    );
  }
}

