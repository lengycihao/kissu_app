import 'package:get/get.dart';
 import 'package:kissu_app/pages/location/location_controller.dart';
  
class LocationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LocationController());
  }
}