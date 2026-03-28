import 'package:get/get.dart';
import '../controllers/topic_selection_controller.dart';

class TopicSelectionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TopicSelectionController>(() => TopicSelectionController());
  }
}
