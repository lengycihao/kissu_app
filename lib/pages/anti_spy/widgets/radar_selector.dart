import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'radar_scanner.dart';
import 'modern_radar_scanner.dart';
import 'pulse_radar_scanner.dart';
import 'particle_radar_scanner.dart';
import 'glow_radar_scanner.dart';

enum RadarAnimationType {
  original,    // 原始雷达
  modern,      // 现代波纹雷达
  pulse,       // 脉冲扫描雷达
  particle,    // 粒子雷达
  glow,        // 发光环雷达
}

class RadarSelector extends StatelessWidget {
  final double size;
  final RadarAnimationType type;
  
  const RadarSelector({
    super.key,
    this.size = 280,
    this.type = RadarAnimationType.modern, // 默认使用现代波纹雷达
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case RadarAnimationType.original:
        return RadarScanner(size: size);
      case RadarAnimationType.modern:
        return ModernRadarScanner(size: size);
      case RadarAnimationType.pulse:
        return PulseRadarScanner(size: size);
      case RadarAnimationType.particle:
        return ParticleRadarScanner(size: size);
      case RadarAnimationType.glow:
        return GlowRadarScanner(size: size);
    }
  }
}

// 雷达动画预览卡片
class RadarAnimationCard extends StatelessWidget {
  final RadarAnimationType type;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;
  
  const RadarAnimationCard({
    super.key,
    required this.type,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5B9BD5).withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF5B9BD5) : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // 小型预览
            Container(
              width: 80,
              height: 80,
              child: RadarSelector(size: 80, type: type),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? const Color(0xFF5B9BD5) : const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// 雷达动画选择器页面
class RadarAnimationSelectorPage extends StatefulWidget {
  const RadarAnimationSelectorPage({super.key});

  @override
  State<RadarAnimationSelectorPage> createState() => _RadarAnimationSelectorPageState();
}

class _RadarAnimationSelectorPageState extends State<RadarAnimationSelectorPage> {
  RadarAnimationType selectedType = RadarAnimationType.modern;

  final List<Map<String, dynamic>> animationTypes = [
    {
      'type': RadarAnimationType.modern,
      'title': '现代波纹',
      'description': '多层波纹扩散\n现代科技感',
    },
    {
      'type': RadarAnimationType.pulse,
      'title': '脉冲扫描',
      'description': '脉冲式扫描\n动感十足',
    },
    {
      'type': RadarAnimationType.particle,
      'title': '粒子效果',
      'description': '粒子动画\n炫酷视觉',
    },
    {
      'type': RadarAnimationType.glow,
      'title': '发光环',
      'description': '发光环效果\n梦幻美观',
    },
    {
      'type': RadarAnimationType.original,
      'title': '经典雷达',
      'description': '原始扫描线\n简洁实用',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择雷达动画'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          // 大型预览区域
          Container(
            height: 300,
            padding: const EdgeInsets.all(20),
            child: Center(
              child: RadarSelector(size: 260, type: selectedType),
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '选择你喜欢的雷达动画效果',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 动画选择网格
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: animationTypes.length,
              itemBuilder: (context, index) {
                final item = animationTypes[index];
                return RadarAnimationCard(
                  type: item['type'],
                  title: item['title'],
                  description: item['description'],
                  isSelected: selectedType == item['type'],
                  onTap: () {
                    setState(() {
                      selectedType = item['type'];
                    });
                  },
                );
              },
            ),
          ),
          
          // 确认按钮
          Container(
            margin: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: () {
                Get.back(result: selectedType);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B9BD5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                '确认选择',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

