import 'package:get/get.dart';
import 'widget_center_controller.dart';

class WidgetCenterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WidgetCenterController>(() => WidgetCenterController());
  }
}
