import 'package:get/get.dart';
import 'package:kissu_app/pages/home/home_controller.dart';
 
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => HomeController());
  }
}
