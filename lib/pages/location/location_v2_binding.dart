import 'package:get/get.dart';
import 'location_v2_controller.dart';

class LocationV2Binding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LocationV2Controller>(() => LocationV2Controller());
  }
}
