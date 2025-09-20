import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 网络诊断工具
class NetworkDiagnostic {
  /// 测试域名解析
  static Future<bool> testDnsResolution(String hostname) async {
    try {
      final result = await InternetAddress.lookup(hostname);
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      print('DNS解析失败: $e');
      return false;
    }
  }

  /// 测试HTTP连接
  static Future<bool> testHttpConnection(String url) async {
    try {
      final uri = Uri.parse(url);
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      
      final request = await client.getUrl(uri);
      final response = await request.close();
      
      client.close();
      return response.statusCode == 200;
    } catch (e) {
      print('HTTP连接测试失败: $e');
      return false;
    }
  }

  /// 完整的网络诊断
  static Future<Map<String, dynamic>> runFullDiagnostic() async {
    final results = <String, dynamic>{};
    
    // 测试基本网络连接
    try {
      final result = await InternetAddress.lookup('www.baidu.com');
      results['basic_connectivity'] = result.isNotEmpty;
    } catch (e) {
      results['basic_connectivity'] = false;
      results['basic_connectivity_error'] = e.toString();
    }
    
    // 测试目标域名解析
    final targetHosts = [
      'devweb.ikissu.cn',
      'ikissu.cn',
      'www.baidu.com',
      'www.google.com',
    ];
    
    for (final host in targetHosts) {
      results['dns_$host'] = await testDnsResolution(host);
    }
    
    // 测试HTTP连接
    final testUrls = [
      'https://www.ikissu.cn/agreement/privacy.html',
      'https://www.baidu.com',
      'https://httpbin.org/get',
    ];
    
    for (final url in testUrls) {
      results['http_${url.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}'] = 
          await testHttpConnection(url);
    }
    
    return results;
  }

  /// 显示诊断结果
  static void showDiagnosticResults(BuildContext context, Map<String, dynamic> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('网络诊断结果'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildResultItem('基本网络连接', results['basic_connectivity']),
              const SizedBox(height: 8),
              const Text('DNS解析测试:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...results.entries
                  .where((e) => e.key.startsWith('dns_'))
                  .map((e) => _buildResultItem(e.key.replaceFirst('dns_', ''), e.value)),
              const SizedBox(height: 8),
              const Text('HTTP连接测试:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...results.entries
                  .where((e) => e.key.startsWith('http_'))
                  .map((e) => _buildResultItem(
                      e.key.replaceFirst('http_', '').replaceAll('_', '/'), e.value)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final newResults = await runFullDiagnostic();
              showDiagnosticResults(context, newResults);
            },
            child: const Text('重新测试'),
          ),
        ],
      ),
    );
  }

  static Widget _buildResultItem(String label, dynamic result) {
    final isSuccess = result == true;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            color: isSuccess ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Text(
            isSuccess ? '正常' : '失败',
            style: TextStyle(
              fontSize: 12,
              color: isSuccess ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 快速网络测试
  static Future<void> quickNetworkTest() async {
    try {
      final result = await InternetAddress.lookup('devweb.ikissu.cn');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        Get.snackbar(
          '网络测试',
          'devweb.ikissu.cn 连接正常',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      } else {
        Get.snackbar(
          '网络测试',
          'devweb.ikissu.cn 连接失败',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      Get.snackbar(
        '网络测试',
        '网络连接异常: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }
}

