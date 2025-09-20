import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ViewModeService extends GetxService {
  static ViewModeService get to => Get.find();
  
  // 视图模式：0 = pst (屏视图), 1 = dst (岛视图)
  var selectedViewMode = 0.obs;
  
  @override
  Future<void> onInit() async {
    super.onInit();
    await loadViewMode();
  }
  
  // 保存视图模式到本地存储
  Future<void> saveViewMode(int mode) async {
    selectedViewMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('home_view_mode', mode);
  }
  
  // 从本地存储读取视图模式
  Future<void> loadViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    selectedViewMode.value = prefs.getInt('home_view_mode') ?? 0;
  }
  
  // 切换视图模式
  void toggleViewMode() {
    final newMode = selectedViewMode.value == 0 ? 1 : 0;
    saveViewMode(newMode);
  }
  
  // 设置视图模式
  void setViewMode(int mode) {
    saveViewMode(mode);
  }
  
  // 获取当前视图模式
  int get currentViewMode => selectedViewMode.value;
  
  // 是否为屏视图 (pst)
  bool get isScreenView => selectedViewMode.value == 0;
  
  // 是否为岛视图 (dst)
  bool get isIslandView => selectedViewMode.value == 1;
}
