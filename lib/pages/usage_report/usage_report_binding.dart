import 'package:get/get.dart';
import 'usage_report_controller.dart';

class UsageReportBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UsageReportController>(() => UsageReportController());
  }
}

