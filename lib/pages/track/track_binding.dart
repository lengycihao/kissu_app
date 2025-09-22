import 'package:get/get.dart';
import 'package:kissu_app/pages/track/track_controller.dart';

class TrackBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => TrackController());
  }
}
