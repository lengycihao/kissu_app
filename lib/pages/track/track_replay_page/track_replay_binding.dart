import 'package:get/get.dart';
import 'track_replay_controller.dart';

/// 轨迹播放页面的绑定
/// 注意：由于播放页面需要从轨迹页面传递数据，
/// 控制器的创建和注册在跳转时手动完成，这个 binding 主要用于备用
class TrackReplayBinding extends Bindings {
  @override
  void dependencies() {
    // 控制器已经在跳转前手动创建和注册
    // 这里不需要再次创建
  }
}

