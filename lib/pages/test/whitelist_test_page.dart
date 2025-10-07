import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/whitelist_helper.dart';

/// 白名单引导功能测试页面
/// 
/// 访问路径: /whitelist_test
class WhitelistTestPage extends StatefulWidget {
  const WhitelistTestPage({Key? key}) : super(key: key);

  @override
  State<WhitelistTestPage> createState() => _WhitelistTestPageState();
}

class _WhitelistTestPageState extends State<WhitelistTestPage> {
  String _manufacturer = '未知';
  bool _needsGuidance = false;
  String _guidanceText = '';
  String _shortGuidance = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    setState(() => _loading = true);
    
    try {
      final manufacturer = await WhitelistHelper.getManufacturer();
      final needsGuidance = await WhitelistHelper.needsWhitelistGuidance();
      final guidanceText = await WhitelistHelper.getGuidanceText();
      final shortGuidance = await WhitelistHelper.getShortGuidance();
      
      setState(() {
        _manufacturer = manufacturer;
        _needsGuidance = needsGuidance;
        _guidanceText = guidanceText;
        _shortGuidance = shortGuidance;
        _loading = false;
      });
      
      print('📱 设备信息加载完成:');
      print('   厂商: $_manufacturer');
      print('   需要引导: $_needsGuidance');
    } catch (e) {
      print('❌ 加载设备信息失败: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('白名单引导测试'),
        backgroundColor: Colors.blue,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(16),
              children: [
                // 设备信息卡片
                _buildInfoCard(),
                SizedBox(height: 16),
                
                // 引导文本卡片
                if (_needsGuidance) ...[
                  _buildGuidanceCard(),
                  SizedBox(height: 16),
                ],
                
                // 测试按钮
                _buildTestButtons(),
              ],
            ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.phone_android, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  '设备信息',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Divider(height: 24),
            _buildInfoRow('厂商名称', _manufacturer),
            SizedBox(height: 8),
            _buildInfoRow(
              '需要白名单引导',
              _needsGuidance ? '是 ✅' : '否 ❌',
              valueColor: _needsGuidance ? Colors.orange : Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuidanceCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  '引导文本预览',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Divider(height: 24),
            
            // 简短引导
            if (_shortGuidance.isNotEmpty) ...[
              Text(
                '简短引导:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _shortGuidance,
                  style: TextStyle(fontSize: 13),
                ),
              ),
              SizedBox(height: 16),
            ],
            
            // 详细引导
            if (_guidanceText.isNotEmpty) ...[
              Text(
                '详细引导:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  _guidanceText,
                  style: TextStyle(fontSize: 13, height: 1.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestButtons() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.science, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  '测试功能',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Divider(height: 24),
            
            // 显示完整对话框
            ElevatedButton.icon(
              onPressed: () {
                WhitelistHelper.showGuidanceDialog();
              },
              icon: Icon(Icons.open_in_new),
              label: Text('显示完整引导对话框'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            SizedBox(height: 12),
            
            // 显示简短提示
            ElevatedButton.icon(
              onPressed: () {
                WhitelistHelper.showShortTip();
              },
              icon: Icon(Icons.message),
              label: Text('显示简短提示 (Snackbar)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            SizedBox(height: 12),
            
            // 直接打开设置
            ElevatedButton.icon(
              onPressed: () async {
                final success = await WhitelistHelper.openWhitelistSettings();
                
                Get.snackbar(
                  success ? '成功' : '失败',
                  success ? '已打开设置页面' : '无法打开设置页面',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: success ? Colors.green : Colors.red,
                  colorText: Colors.white,
                );
              },
              icon: Icon(Icons.settings),
              label: Text('直接打开白名单设置'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            SizedBox(height: 12),
            
            // 刷新信息
            OutlinedButton.icon(
              onPressed: _loadInfo,
              icon: Icon(Icons.refresh),
              label: Text('刷新设备信息'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



