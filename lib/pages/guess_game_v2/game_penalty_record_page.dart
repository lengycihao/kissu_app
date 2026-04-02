import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:kissu_app/utils/network_image_helper.dart';
import 'models/game_models.dart';
import 'services/game_api_service.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';

/// 惩罚记录页（我的惩罚 / Ta的惩罚 两个 tab）
class GamePenaltyRecordPage extends StatefulWidget {
  const GamePenaltyRecordPage({super.key});

  @override
  State<GamePenaltyRecordPage> createState() => _GamePenaltyRecordPageState();
}

class _GamePenaltyRecordPageState extends State<GamePenaltyRecordPage> {
  final _api = GameApiService();
  final _scrollController = ScrollController();

  int _tabIndex = 0; // 0=我的惩罚 1=Ta的惩罚

  final List<GamePenaltyRecordItem> _myRecords = [];
  final List<GamePenaltyRecordItem> _taRecords = [];

  bool _myLoading = false;
  bool _taLoading = false;
  bool _myHasMore = true;
  bool _taHasMore = true;
  int _myPage = 1;
  int _taPage = 1;
  int _myTotal = 0;
  int _taTotal = 0;

  List<GamePenaltyRecordItem> get _currentList =>
      _tabIndex == 0 ? _myRecords : _taRecords;
  bool get _currentLoading => _tabIndex == 0 ? _myLoading : _taLoading;
  bool get _currentHasMore => _tabIndex == 0 ? _myHasMore : _taHasMore;
  int get _currentTotal => _tabIndex == 0 ? _myTotal : _taTotal;

  @override
  void initState() {
    super.initState();
    _loadPage(isRefresh: true, tabIndex: 0);
    _loadPage(isRefresh: true, tabIndex: 1);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 80) {
      _loadMore();
    }
  }

  Future<void> _loadPage({required bool isRefresh, required int tabIndex}) async {
    final isMy = tabIndex == 0;
    if (isMy) {
      if (_myLoading) return;
      if (!isRefresh && !_myHasMore) return;
    } else {
      if (_taLoading) return;
      if (!isRefresh && !_taHasMore) return;
    }

    setState(() {
      if (isMy) {
        _myLoading = true;
        if (isRefresh) _myPage = 1;
      } else {
        _taLoading = true;
        if (isRefresh) _taPage = 1;
      }
    });

    final page = isMy ? _myPage : _taPage;
    final result = await _api.getPenaltyList(
      isOneself: tabIndex == 0 ? 1 : 0,
      page: page,
    );

    if (!mounted) return;
    setState(() {
      if (isMy) {
        _myLoading = false;
        if (result != null) {
          if (isRefresh) _myRecords.clear();
          _myRecords.addAll(result.records);
          _myHasMore = result.hasMore;
          _myPage = result.currentPage + 1;
          _myTotal = result.total;
        }
      } else {
        _taLoading = false;
        if (result != null) {
          if (isRefresh) _taRecords.clear();
          _taRecords.addAll(result.records);
          _taHasMore = result.hasMore;
          _taPage = result.currentPage + 1;
          _taTotal = result.total;
        }
      }
    });
  }

  Future<void> _onRefresh() async {
    await _loadPage(isRefresh: true, tabIndex: _tabIndex);
  }

  void _loadMore() {
    _loadPage(isRefresh: false, tabIndex: _tabIndex);
  }

  void _onTabTap(int i) {
    if (_tabIndex == i) return;
    setState(() => _tabIndex = i);
    _scrollController.jumpTo(0);
  }

  void _onItemTap(GamePenaltyRecordItem item) {
    final isDone = item.isPenalty == 1;
    final isMine = _tabIndex == 0;

    if (isMine) {
      // ===== 我的惩罚 =====
      switch (item.penaltyType) {
        case 0:
          showToast('对方还未选择惩罚方式');
          break;
        case 1: // 自拍
          if (isDone && item.penaltyFile.isNotEmpty) {
            _showImagePreview(item.penaltyFile);
          } else if (!isDone) {
            Get.toNamed(
              KissuRoutePath.guessGameV2PenaltyPhoto,
              arguments: {'groupId': item.id},
            )?.then((_) => _refreshBoth());
          }
          break;
        case 2: // 语音 — 已完成的语音由 _AudioPlayWidget 自行处理，不在 onTap 处理
          if (!isDone) {
            Get.toNamed(
              KissuRoutePath.guessGameV2PenaltyAudio,
              arguments: {'groupId': item.id},
            )?.then((_) => _refreshBoth());
          }
          break;
        case 3:
        case 4: // 晚餐/许诺 — 我的惩罚：展示二维码让对方扫
          if (item.verifyQrCode.isNotEmpty) {
            _showQrCodeDialog(item.verifyQrCode);
          }
          break;
      }
    } else {
      // ===== Ta的惩罚 =====
      switch (item.penaltyType) {
        case 0: // 未选择惩罚方式 → 去选择
          Get.toNamed(
            KissuRoutePath.guessGameV2PenaltySelect,
            arguments: {'groupId': item.id},
          )?.then((_) => _refreshBoth());
          break;
        case 1: // 自拍 — 已完成时预览图片
          if (isDone && item.penaltyFile.isNotEmpty) {
            _showImagePreview(item.penaltyFile);
          }
          break;
        case 3:
        case 4: // 晚餐/许诺
          if (isDone) {
            // 已完成 → 展示惩罚凭证二维码
            if (item.verifyQrCode.isNotEmpty) {
              _showQrCodeDialog(item.verifyQrCode);
            }
          } else {
            // 未完成 → 扫码核验
            _scanAndVerify();
          }
          break;
      }
    }
  }

  /// 刷新两个 tab 的数据
  Future<void> _refreshBoth() async {
    await Future.wait([
      _loadPage(isRefresh: true, tabIndex: 0),
      _loadPage(isRefresh: true, tabIndex: 1),
    ]);
  }

  /// 全屏预览图片
  void _showImagePreview(String imageUrl) {
    Get.dialog(
      GestureDetector(
        onTap: () => Get.back(),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image,
                  size: 64,
                  color: Colors.white54,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 展示二维码弹窗（参考绑定弹窗 viewQRCode 样式）
  void _showQrCodeDialog(String qrCodeUrl) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '请让对方使用Kissu扫描此二维码',
                    style: TextStyle(fontSize: 16, color: Color(0xffFF0A6C)),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 262,
                    height: 262,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: NetworkImageHelper.loadImage(
                        imageUrl: qrCodeUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Image(
                  image: AssetImage('assets/3.0/kissu3_dialog_close.webp'),
                  width: 24,
                  height: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 扫码核验惩罚
  Future<void> _scanAndVerify() async {
    final result = await Get.toNamed(KissuRoutePath.qrScanPage);
    if (result is String && result.isNotEmpty) {
      final groupId = result.trim();
      final ok = await _api.verifyPenalty(groupId: groupId);
      if (ok) {
        showToast('核验成功');
        _refreshBoth();
      } else {
        showToast('核验失败，请重试');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/say_guess/kissu_say_guess_bg.webp'),
            alignment: Alignment.topCenter,
          ),
          color: Color(0xFFffffff),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              const SizedBox(height: 12),
              _buildTabs(),
              const SizedBox(height: 12),
              Expanded(child: _buildList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Get.back(),
              child: const Icon(Icons.chevron_left, size: 28, color: Color(0xFF333333)),
            ),
          ),
          const Text(
            '惩罚记录',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    const labels = ['我的惩罚', 'Ta的惩罚'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(labels.length, (i) {
        final active = _tabIndex == i;
        return GestureDetector(
          onTap: () => _onTabTap(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: active ? Colors.black : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              labels[i],
              style: TextStyle(
                fontSize: 14,
                fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                color: active ? Colors.white : const Color(0xFF666666),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildList() {
    final records = _currentList;
    if (_currentLoading && records.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (records.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image(image: AssetImage('assets/say_guess/kissu_say_guess_empty.webp'),width: 56,),
            Text('暂无记录', style: TextStyle(fontSize: 14, color: Color(0xFFAAAAAA))),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: records.length + (_currentHasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          if (i == records.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          return _buildCard(records[i], i);
        },
      ),
    );
  }

  Widget _buildCard(GamePenaltyRecordItem item, int index) {
    final isDone = item.isPenalty == 1;
    final typeLabel = _penaltyTypeLabel(item.penaltyType);
    final isMine = _tabIndex == 0;
    final canTap = isMine
        ? (
            // 我的惩罚：type==0 toast / type==1未完成跳执行页或已完成预览 / type==2未完成跳执行页
            item.penaltyType == 0 ||
            (item.penaltyType == 1 && (!isDone || item.penaltyFile.isNotEmpty)) ||
            (item.penaltyType == 2 && !isDone) ||
            ((item.penaltyType == 3 || item.penaltyType == 4) && item.verifyQrCode.isNotEmpty)
          )
        : (
            // Ta的惩罚：type==0跳选择页 / type==1已完成预览 / type==3,4有按钮
            (item.penaltyType == 0 && !isDone) ||
            (item.penaltyType == 1 && isDone && item.penaltyFile.isNotEmpty) ||
            (item.penaltyType == 3 || item.penaltyType == 4)
          );

    return GestureDetector(
      onTap: canTap ? () => _onItemTap(item) : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        typeLabel,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF222222),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '第${_currentTotal - index}轮挑战',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _buildRightWidget(item),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusBadge(isDone),
                Text(
                  '${isDone ? '完成时间' : '惩罚时间'}: ${item.createTimeRaw}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightWidget(GamePenaltyRecordItem item) {
    final isDone = item.isPenalty == 1;
    final isMine = _tabIndex == 0; // 我的惩罚

    switch (item.penaltyType) {
      case 0: // 未选择惩罚方式
        if (isMine) return _pinkButton('等待中');
        return _pinkButton('去选择');

      case 1: // 自拍
        if (isDone && item.penaltyFile.isNotEmpty) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.penaltyFile,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _photoPlaceholder(),
            ),
          );
        }
        if (isDone) return _photoPlaceholder();
        // 未完成：只有被惩罚方(我的惩罚)才显示去完成，接收方不显示
        return isMine ? _pinkButton('去完成') : const SizedBox.shrink();

      case 2: // 语音
        if (isDone) {
          return _AudioPlayWidget(audioUrl: item.penaltyFile);
        }
        // 未完成：只有被惩罚方(我的惩罚)才显示去完成
        return isMine ? _pinkButton('去完成') : const SizedBox.shrink();

      case 3: // 吃饭
      case 4: // 承诺
        if (isDone) {
          return _pinkButton('惩罚凭证');
        }
        // 未完成：接收方(Ta的惩罚)显示扫码核验
        return isMine ? const SizedBox.shrink() : _pinkButton('扫码核验');

      default:
        return const SizedBox.shrink();
    }
  }

  String _penaltyTypeLabel(int type) {
    switch (type) {
      case 0: return '待选择惩罚方式';
      case 1: return '发一张搞怪自拍';
      case 2: return '录制一段语音';
      case 3: return '承包下次晚餐';
      case 4: return '见面答应一件事';
      default: return '未知惩罚';
    }
  }

  Widget _photoPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image_outlined, size: 28, color: Color(0xFFCCBBEE)),
    );
  }

  Widget _pinkButton(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9AD9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isDone) {
    return Text(
      isDone ? '已完成' : '未完成',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: isDone ? const Color(0xFF2E9541) : const Color(0xFFDD4C64),
      ),
    );
  }
}

/// 语音播放小组件（使用 audioplayers 真实播放）
class _AudioPlayWidget extends StatefulWidget {
  final String audioUrl;
  const _AudioPlayWidget({required this.audioUrl});

  @override
  State<_AudioPlayWidget> createState() => _AudioPlayWidgetState();
}

class _AudioPlayWidgetState extends State<_AudioPlayWidget> {
  final _player = AudioPlayer();
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      if (state == PlayerState.completed || state == PlayerState.stopped) {
        setState(() => _playing = false);
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.stop();
      setState(() => _playing = false);
    } else {
      final url = widget.audioUrl;
      if (url.isEmpty) return;
      await _player.play(UrlSource(url));
      setState(() => _playing = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _toggle,
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFFF9AD9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _playing ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _playing ? '播放中' : '听语音',
          style: const TextStyle(fontSize: 11, color: Color(0xFFFF9AD9)),
        ),
      ],
    );
  }
}
