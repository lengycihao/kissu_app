import 'package:get/get.dart';
import 'location_state_controller.dart';

class LocationStateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LocationStateController>(() => LocationStateController());
  }
}

