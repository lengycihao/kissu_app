import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'models/game_models.dart';
import 'state/game_state.dart';
import 'views/lobby_view.dart';
import 'views/role_selection_view.dart';
import 'views/game_play_view.dart';
import 'views/game_result_view.dart';

/// 你说我猜 主页面（根据GamePhase切换不同视图）
/// 路由参数：
///   groupId: String? - 被邀请方传入的群ID
///   isInvited: bool? - 是否为被邀请方
class GuessGamePage extends StatefulWidget {
  const GuessGamePage({super.key});

  @override
  State<GuessGamePage> createState() => _GuessGamePageState();
}

class _GuessGamePageState extends State<GuessGamePage> {
  late GameState _gameState;

  @override
  void initState() {
    super.initState();
    _gameState = GameState();
    _gameState.addListener(_onStateChanged);

    // 对方退出时自动返回
    _gameState.onPartnerExited = _onPartnerExited;

    // 加入房间失败时提示并返回
    _gameState.onJoinFailed = _onJoinFailed;

    // 解析路由参数
    final args = Get.arguments as Map<String, dynamic>?;
    final isInvited = args?['isInvited'] == true;
    final groupId = args?['groupId'] as String?;

    if (isInvited && groupId != null && groupId.isNotEmpty) {
      // 被邀请方：加入已有群聊
      _gameState.joinRoom(groupId);
    } else {
      // 房主：创建大厅（不立即创建群）
      _gameState.createRoom();
    }
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  void _onPartnerExited() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _onJoinFailed(String reason) {
    if (!mounted) return;
    OKToastUtil.show(reason);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _gameState.onJoinFailed = null;
    _gameState.onPartnerExited = null;
    _gameState.removeListener(_onStateChanged);
    // 异步退出（解散群聊），不阻塞dispose
    _gameState.exitGame();
    _gameState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _gameState.phase == GamePhase.lobby ||
          _gameState.phase == GamePhase.gameResult,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _showExitConfirmDialog();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFE4EC),
                Color(0xFFFFF5F7),
                Colors.white,
              ],
              stops: [0.0, 0.3, 1.0],
            ),
          ),
          child: SafeArea(
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_gameState.phase) {
      case GamePhase.lobby:
        return LobbyView(gameState: _gameState);
      case GamePhase.roleSelection:
        return RoleSelectionView(gameState: _gameState);
      case GamePhase.countdown:
      case GamePhase.playing:
        return GamePlayView(gameState: _gameState);
      case GamePhase.roundResult:
        // 暂时和playing用同一个view
        return GamePlayView(gameState: _gameState);
      case GamePhase.gameResult:
        return GameResultView(gameState: _gameState);
    }
  }

  void _showExitConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出游戏'),
        content: const Text('游戏正在进行中，确定要退出吗？退出后本局游戏将结束。'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('继续游戏',
                style: TextStyle(color: Color(0xFFFF90CA))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _gameState.exitGame();
              if (context.mounted) Navigator.of(context).pop();
            },
            child:
                const Text('退出', style: TextStyle(color: Color(0xFF999999))),
          ),
        ],
      ),
    );
  }
}
