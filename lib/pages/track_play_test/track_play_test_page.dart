import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:kissu_app/widgets/safe_amap_widget.dart';
import 'track_play_test_controller.dart';

/// 轨迹播放测试页面
class TrackPlayTestPage extends StatelessWidget {
  const TrackPlayTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TrackPlayTestController());
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('轨迹播放测试'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 地图区域
          Positioned.fill(
            child: _buildMap(controller),
          ),
          
          // 可折叠的侧边控制面板
          _buildCollapsibleControlPanel(controller),
        ],
      ),
    );
  }

  /// 构建地图
  Widget _buildMap(TrackPlayTestController controller) {
    return Obx(() {
      return SafeAMapWidget(
        initialCameraPosition: controller.initialCameraPosition,
        onMapCreated: controller.onMapCreated,
        markers: controller.markers.toSet(),
        mapType: MapType.normal,
        buildingsEnabled: false, // 隐藏3D建筑物
        compassEnabled: true,
        scaleEnabled: true,
        zoomGesturesEnabled: true,
        scrollGesturesEnabled: true,
        rotateGesturesEnabled: true,
        tiltGesturesEnabled: true,
      );
    });
  }


  /// 构建可折叠的侧边控制面板
  Widget _buildCollapsibleControlPanel(TrackPlayTestController controller) {
    return Obx(() {
      return AnimatedPositioned(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        right: controller.isPanelExpanded.value ? 0 : -280,
        top: 0,
        bottom: 0,
        child: Container(
          width: 320,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(-2, 0),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 控制面板内容
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 标题
                        const Text(
                          '轨迹播放控制',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // 进度条
                        Obx(() {
                          return Column(
                            children: [
                              SliderTheme(
                                data: SliderThemeData(
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 8,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 16,
                                  ),
                                  activeTrackColor: const Color(0xFF4285F4),
                                  inactiveTrackColor: const Color(0xFFE0E0E0),
                                  thumbColor: const Color(0xFF4285F4),
                                  overlayColor: const Color(0xFF4285F4).withValues(alpha: 0.2),
                                ),
                                child: Slider(
                                  value: controller.playProgress.value,
                                  onChanged: (value) {
                                    // 手动拖拽进度条时暂停播放并跳转到指定位置
                                    if (controller.isPlaying.value) {
                                      controller.pausePlay();
                                    }
                                    controller.playProgress.value = value;
                                    
                                    // 计算对应的位置并更新标记点
                                    final trackPoints = controller.trackPoints;
                                    final totalPoints = trackPoints.length;
                                    final exactIndex = value * (totalPoints - 1);
                                    final currentIndex = exactIndex.floor().clamp(0, totalPoints - 2);
                                    final nextIndex = (currentIndex + 1).clamp(0, totalPoints - 1);
                                    final interpolationProgress = exactIndex - currentIndex;
                                    
                                    // 插值计算位置
                                    final startPoint = trackPoints[currentIndex];
                                    final endPoint = trackPoints[nextIndex];
                                    final lat = startPoint.latitude + (endPoint.latitude - startPoint.latitude) * interpolationProgress;
                                    final lng = startPoint.longitude + (endPoint.longitude - startPoint.longitude) * interpolationProgress;
                                    final newPosition = LatLng(lat, lng);
                                    
                                    controller.currentMarkerPosition.value = newPosition;
                                    controller.updateMovingMarker();
                                    controller.moveMapToPosition(newPosition);
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${(controller.playProgress.value * 100).toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF666666),
                                    ),
                                  ),
                                  Text(
                                    '${controller.trackPoints.length} 个轨迹点',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF666666),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }),
                        
                        const SizedBox(height: 20),
                        
                        // 标记图片选择器
                        _buildMarkerSelector(controller),
                        
                        const SizedBox(height: 20),
                        
                        // 🎛️ Marker大小控制器
                        _buildMarkerSizeController(controller),
                        
                        const SizedBox(height: 20),
                        
                        // 动画效果选择器
                        _buildAnimationSelector(controller),
                        
                        const SizedBox(height: 20),
                        
                        // 控制按钮
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // 重置按钮
                            _buildControlButton(
                              icon: Icons.replay,
                              label: '重置',
                              color: const Color(0xFF666666),
                              onTap: controller.resetPlay,
                            ),
                            
                            // 播放/暂停按钮
                            Obx(() {
                              return _buildControlButton(
                                icon: controller.isPlaying.value ? Icons.pause : Icons.play_arrow,
                                label: controller.isPlaying.value ? '暂停' : '播放',
                                color: const Color(0xFF4285F4),
                                onTap: () {
                                  if (controller.isPlaying.value) {
                                    controller.pausePlay();
                                  } else {
                                    controller.startPlay();
                                  }
                                },
                              );
                            }),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // 说明文字
                        const Text(
                          '选择标记图片和动画效果，点击播放按钮开始轨迹动画\n标记点将沿着轨迹线从起点移动到终点',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF999999),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // 折叠/展开按钮
              Positioned(
                left: -20,
                top: 20,
                child: GestureDetector(
                  onTap: () {
                    controller.togglePanel();
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4285F4),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      controller.isPanelExpanded.value ? Icons.chevron_right : Icons.chevron_left,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }


  /// 构建控制按钮
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建标记图片选择器
  Widget _buildMarkerSelector(TrackPlayTestController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '移动标记样式',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 12),
        Obx(() {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: controller.markerOptions.entries.map((entry) {
              final markerType = entry.key;
              final option = entry.value;
              final isSelected = controller.selectedMarkerType.value == markerType;
              
              return GestureDetector(
                onTap: () => controller.changeMarkerType(markerType),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? const Color(0xFF4285F4).withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected 
                          ? const Color(0xFF4285F4)
                          : Colors.grey.withValues(alpha: 0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    option.name,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected 
                          ? const Color(0xFF4285F4)
                          : const Color(0xFF666666),
                      fontWeight: isSelected 
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }


  /// 构建动画效果选择器
  Widget _buildAnimationSelector(TrackPlayTestController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '动画效果',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 12),
        Obx(() {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MarkerAnimationType.values.map((animationType) {
              final isSelected = controller.selectedAnimationType.value == animationType;
              
              return GestureDetector(
                onTap: () => controller.changeAnimationType(animationType),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? const Color(0xFF4285F4).withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected 
                          ? const Color(0xFF4285F4)
                          : Colors.grey.withValues(alpha: 0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        animationType.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected 
                              ? const Color(0xFF4285F4)
                              : const Color(0xFF666666),
                          fontWeight: isSelected 
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        animationType.description,
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected 
                              ? const Color(0xFF4285F4).withValues(alpha: 0.7)
                              : const Color(0xFF999999),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  /// 🎛️ 构建Marker大小控制器
  Widget _buildMarkerSizeController(TrackPlayTestController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Marker大小',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 12),
        
        // 大小滑块
        Obx(() {
          return Column(
            children: [
              // 滑块
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: const Color(0xFF4285F4),
                  inactiveTrackColor: const Color(0xFF4285F4).withValues(alpha: 0.2),
                  thumbColor: const Color(0xFF4285F4),
                  overlayColor: const Color(0xFF4285F4).withValues(alpha: 0.1),
                  trackHeight: 4.0,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
                ),
                child: Slider(
                  value: controller.markerSize.value,
                  min: 20.0,
                  max: 120.0,
                  divisions: 20,
                  onChanged: (value) {
                    controller.changeMarkerSize(value);
                  },
                ),
              ),
              
              // 大小显示和预设按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 当前大小显示
                  Text(
                    '当前: ${controller.markerSize.value.toInt()}px',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),
                  
                  // 预设大小按钮
                  Row(
                    children: [
                      _buildSizePresetButton('小', 30.0, controller),
                      const SizedBox(width: 8),
                      _buildSizePresetButton('中', 60.0, controller),
                      const SizedBox(width: 8),
                      _buildSizePresetButton('大', 90.0, controller),
                    ],
                  ),
                ],
              ),
            ],
          );
        }),
      ],
    );
  }

  /// 构建预设大小按钮
  Widget _buildSizePresetButton(String label, double size, TrackPlayTestController controller) {
    return Obx(() {
      final isSelected = (controller.markerSize.value - size).abs() < 1.0;
      return GestureDetector(
        onTap: () => controller.changeMarkerSize(size),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4285F4) : Colors.transparent,
            border: Border.all(
              color: isSelected ? const Color(0xFF4285F4) : const Color(0xFFE0E0E0),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.white : const Color(0xFF666666),
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
      );
    });
  }
}
