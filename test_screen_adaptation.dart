import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'lib/utils/screen_adaptation.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Screen Adaptation Test',
      home: TestScreen(),
    );
  }
}

class TestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('屏幕适配测试'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '屏幕适配测试结果',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            _buildInfoRow('屏幕宽度', '${ScreenAdaptation.screenWidth}px'),
            _buildInfoRow('屏幕高度', '${ScreenAdaptation.screenHeight}px'),
            _buildInfoRow('设计稿宽度', '${ScreenAdaptation.designWidth}px'),
            _buildInfoRow('设计稿高度', '${ScreenAdaptation.designHeight}px'),
            _buildInfoRow('宽度缩放比例', '${ScreenAdaptation.widthScale.toStringAsFixed(3)}'),
            _buildInfoRow('高度缩放比例', '${ScreenAdaptation.heightScale.toStringAsFixed(3)}'),
            SizedBox(height: 20),
            Text(
              'PAG文件适配结果',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            _buildPagInfo('home_bg_person.pag', 395, 293, 350, 380),
            _buildPagInfo('home_bg_fridge.pag', 22, 139, 174, 364),
            _buildPagInfo('home_bg_clothes.pag', 1228, 68, 272, 174),
            _buildPagInfo('home_bg_flowers.pag', 675, 268, 232, 119),
            _buildPagInfo('home_bg_music.pag', 352, 260, 130, 108),
            SizedBox(height: 20),
            Text(
              '背景图适配结果',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            _buildInfoRow('适配后背景宽度', '${ScreenAdaptation.getAdaptedBackgroundSize().width.toStringAsFixed(1)}px'),
            _buildInfoRow('适配后背景高度', '${ScreenAdaptation.getAdaptedBackgroundSize().height.toStringAsFixed(1)}px'),
            _buildInfoRow('容器宽度', '${ScreenAdaptation.getAdaptedContainerSize().width.toStringAsFixed(1)}px'),
            _buildInfoRow('容器高度', '${ScreenAdaptation.getAdaptedContainerSize().height.toStringAsFixed(1)}px'),
            _buildInfoRow('预设滚动偏移', '${ScreenAdaptation.getPresetScrollOffset().toStringAsFixed(1)}px'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPagInfo(String name, double originalX, double originalY, double originalWidth, double originalHeight) {
    final adaptedX = ScreenAdaptation.scaleX(originalX);
    final adaptedY = ScreenAdaptation.scaleY(originalY);
    final adaptedWidth = ScreenAdaptation.scaleWidth(originalWidth);
    final adaptedHeight = ScreenAdaptation.scaleWidth(originalHeight);
    
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            _buildInfoRow('位置', '(${adaptedX.toStringAsFixed(1)}, ${adaptedY.toStringAsFixed(1)})'),
            _buildInfoRow('尺寸', '${adaptedWidth.toStringAsFixed(1)} × ${adaptedHeight.toStringAsFixed(1)}'),
          ],
        ),
      ),
    );
  }
}
