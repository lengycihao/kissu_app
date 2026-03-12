import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kissu_app/services/lock_screen_overlay_service.dart';
import 'package:kissu_app/network/public/lock_permission_api.dart';

/// 答题解锁页面
/// 从SharedPreferences读取锁机时设置的问题和答案
/// 答对后调用LockScreenOverlayService.unlockScreen()解锁
class LockScreenQuestionPage extends StatefulWidget {
  const LockScreenQuestionPage({super.key});

  @override
  State<LockScreenQuestionPage> createState() => _LockScreenQuestionPageState();
}

class _LockScreenQuestionPageState extends State<LockScreenQuestionPage> {
  String _question = '';
  List<String> _answers = [];
  int _selectedIndex = -1;
  bool _isWrong = false;
  bool _isLoading = true;
  bool _hasUnlocked = false; // 是否已成功解锁
  final _lockApi = LockPermissionApi();

  @override
  void initState() {
    super.initState();
    _loadQuestionData();
  }

  @override
  void dispose() {
    // 如果没有成功解锁，恢复悬浮窗显示
    if (!_hasUnlocked) {
      LockScreenOverlayService.showOverlayAgain();
    }
    super.dispose();
  }

  Future<void> _loadQuestionData() async {
    final prefs = await SharedPreferences.getInstance();
    final question = prefs.getString('lock_question') ?? '什么马不能骑？';
    final answersJson = prefs.getString('lock_answers') ?? '["海马","河马","斑马","木马"]';
    List<String> answers;
    try {
      answers = (jsonDecode(answersJson) as List).cast<String>();
    } catch (_) {
      answers = ['海马', '河马', '斑马', '木马'];
    }

    setState(() {
      _question = question;
      _answers = answers;
      _isLoading = false;
    });
  }

  void _onAnswerTap(int index) async {
    setState(() {
      _selectedIndex = index;
      _isWrong = false;
    });

    // 每次选择答案都调用解锁接口，unlock_answer_index 从0开始
    try {
      final result = await _lockApi.unlockUserPhone(
        unlockType: 2,
        unlockAnswerIndex: index,
      );
      debugPrint('🔓 答题解锁API调用: index=$index, success=${result.isSuccess}');

      if (result.isSuccess) {
        // 答对了，解锁成功
        _hasUnlocked = true;
        await LockScreenOverlayService.unlockScreen();
        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      }
    } catch (e) {
      debugPrint('🔓 答题解锁API异常: $e');
    }

    // 答错了，提示可以重新选择
    if (mounted) {
      setState(() {
        _isWrong = true;
      });
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        setState(() {
          _selectedIndex = -1;
          _isWrong = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5E6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF5E6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF333333), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '答对问题，立即解锁手机',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // 黑板区域
            _buildBlackboard(),
            const SizedBox(height: 32),
            // 答案选项
            ..._buildAnswerOptions(),
          ],
        ),
      ),
    );
  }

  /// 黑板UI - 显示问题
  Widget _buildBlackboard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFD4903C),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0x40000000),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        decoration: BoxDecoration(
          color: const Color(0xFF2D7D4F),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // 装饰元素 - 左上角小物件
            Positioned(
              top: -10,
              left: -5,
              child: Text(
                '）',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
            ),
            // 装饰元素 - 右上角
            Positioned(
              top: -10,
              right: 10,
              child: Icon(
                Icons.favorite,
                size: 18,
                color: const Color(0xFFFF7ECE).withOpacity(0.6),
              ),
            ),
            // 问题文字
            Center(
              child: Text(
                _question,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建答案选项列表
  List<Widget> _buildAnswerOptions() {
    return List.generate(_answers.length, (index) {
      final isSelected = _selectedIndex == index;
      final isWrongSelection = isSelected && _isWrong;

      Color borderColor = const Color(0xFFEEEEEE);
      Color bgColor = Colors.white;

      if (isSelected && !_isWrong) {
        // 选中且正确（或还没判断）
        borderColor = const Color(0xFFFF7ECE);
        bgColor = Colors.white;
      } else if (isWrongSelection) {
        // 选中但答错了
        borderColor = Colors.red.withOpacity(0.6);
        bgColor = Colors.red.withOpacity(0.05);
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: _selectedIndex == -1 || _isWrong == false
              ? () => _onAnswerTap(index)
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x08000000),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _answers[index],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isWrongSelection ? Colors.red : const Color(0xFF333333),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
