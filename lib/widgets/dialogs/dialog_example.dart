import 'package:flutter/material.dart';
import 'dialog_manager.dart';

/// 弹窗使用示例
class DialogExamplePage extends StatelessWidget {
  const DialogExamplePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('弹窗组件示例'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('通用确认弹窗', [
            _buildButton(
              '退出登录确认',
              () => DialogManager.showLogoutConfirm(context),
            ),
            _buildButton(
              '手机号更改确认',
              () => DialogManager.showPhoneChangeConfirm(context, '+86 192****2378'),
            ),
            _buildButton(
              '解除关系确认',
              () => DialogManager.showUnbindConfirm(context),
            ),
            _buildButton(
              '自定义确认弹窗',
              () => DialogManager.showConfirm(
                context: context,
                title: '自定义标题',
                content: '这是自定义内容',
                subContent: '这是副标题',
                confirmText: '好的',
                cancelText: '算了',
              ),
            ),
          ]),
          _buildSection('性别选择弹窗', [
            _buildButton(
              '选择性别',
              () async {
                final gender = await DialogManager.showGenderSelect(
                  context: context,
                  selectedGender: '男生',
                );
                if (gender != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('选择了: $gender')),
                  );
                }
              },
            ),
          ]),
          _buildSection('输入框弹窗', [
            _buildButton(
              '输入昵称',
              () async {
                final nickname = await DialogManager.showNicknameInput(
                  context,
                  currentNickname: '当前昵称',
                );
                if (nickname != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('输入的昵称: $nickname')),
                  );
                }
              },
            ),
            _buildButton(
              '自定义输入框',
              () async {
                final input = await DialogManager.showInput(
                  context: context,
                  title: '请输入内容',
                  hintText: '在这里输入...',
                  maxLength: 20,
                );
                if (input != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('输入的内容: $input')),
                  );
                }
              },
            ),
          ]),
          _buildSection('绑定确认弹窗', [
            _buildButton(
              '情侣绑定确认',
              () => DialogManager.showCoupleBindConfirm(context),
            ),
            _buildButton(
              '自定义绑定确认',
              () => DialogManager.showBindConfirm(
                context: context,
                title: '绑定确认',
                content: '确定要绑定吗？',
                confirmText: '确认',
              ),
            ),
          ]),
          _buildSection('VIP会员弹窗', [
            _buildButton(
              '再看30秒得会员',
              () => DialogManager.showVipWatchMore(context),
            ),
            _buildButton(
              '再看2个视频得会员',
              () => DialogManager.showVipWatchVideos(context),
            ),
            _buildButton(
              '任务完成',
              () => DialogManager.showVipTaskComplete(context),
            ),
            _buildButton(
              '开通会员成功',
              () => DialogManager.showVipSuccess(context),
            ),
            _buildButton(
              '自定义VIP弹窗',
              () => DialogManager.showVip(
                context: context,
                title: '自定义VIP标题',
                subtitle: '副标题',
                content: '内容描述',
                buttonText: '立即开通',
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
        ),
        child: Text(text),
      ),
    );
  }
}