import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 惩罚记录数据模型
class PenaltyRecord {
  final String title;       // 惩罚名称
  final String source;      // 来源描述
  final String type;        // photo | audio | text | promise
  final String status;      // done | undone | verified
  final String? proofUrl;   // 照片凭证 URL（photo 类型）
  final String? audioUrl;   // 语音凭证 URL（audio 类型）
  final String time;        // 时间戳字符串

  const PenaltyRecord({
    required this.title,
    required this.source,
    required this.type,
    required this.status,
    this.proofUrl,
    this.audioUrl,
    required this.time,
  });
}

/// 惩罚记录页（我的惩罚 / Ta的惩罚 两个 tab）
class GamePenaltyRecordPage extends StatefulWidget {
  const GamePenaltyRecordPage({super.key});

  @override
  State<GamePenaltyRecordPage> createState() => _GamePenaltyRecordPageState();
}

class _GamePenaltyRecordPageState extends State<GamePenaltyRecordPage> {
  int _tabIndex = 0; // 0=我的惩罚 1=Ta的惩罚

  // ——— Mock 数据 ———
  final List<PenaltyRecord> _myRecords = const [
    PenaltyRecord(
      title: '发一张搞怪自拍',
      source: '情侣10星挑战结算惩罚',
      type: 'photo',
      status: 'done',
      proofUrl: null,
      time: '2025-08-14 15:44:37',
    ),
    PenaltyRecord(
      title: '承包下次晚餐',
      source: '情侣10星挑战结算惩罚',
      type: 'text',
      status: 'undone',
      time: '2025-08-14 15:44:37',
    ),
    PenaltyRecord(
      title: '说十遍我爱你',
      source: '情侣10星挑战结算惩罚',
      type: 'audio',
      status: 'done',
      time: '2025-08-14 15:44:37',
    ),
    PenaltyRecord(
      title: '见面答应一件事',
      source: '情侣10星挑战结算惩罚',
      type: 'promise',
      status: 'verified',
      time: '2025-08-14 15:44:37',
    ),
  ];

  final List<PenaltyRecord> _taRecords = const [
    PenaltyRecord(
      title: '发一张搞怪自拍',
      source: '情侣10星挑战结算惩罚',
      type: 'photo',
      status: 'done',
      proofUrl: null,
      time: '2025-08-14 15:44:37',
    ),
    PenaltyRecord(
      title: '说十遍我爱你',
      source: '情侣10星挑战结算惩罚',
      type: 'audio',
      status: 'undone',
      time: '2025-08-14 15:44:37',
    ),
  ];

  List<PenaltyRecord> get _currentList =>
      _tabIndex == 0 ? _myRecords : _taRecords;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/say_guess/kissu_say_guess_bg.webp'),
            alignment: Alignment.topCenter,
          ),
          color: Color(0xFFF7F7F7),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              fontSize: 17,
              fontWeight: FontWeight.w600,
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
          onTap: () => setState(() => _tabIndex = i),
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
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? Colors.white : const Color(0xFF999999),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildList() {
    final records = _currentList;
    if (records.isEmpty) {
      return const Center(
        child: Text('暂无记录', style: TextStyle(fontSize: 14, color: Color(0xFFAAAAAA))),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: records.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _buildCard(records[i]),
    );
  }

  Widget _buildCard(PenaltyRecord r) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                      r.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF222222),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r.source,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildRightWidget(r),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusBadge(r.status),
              Text(
                '${r.status == 'done' || r.status == 'verified' ? '完成时间' : '惩罚时间'}: ${r.time}',
                style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRightWidget(PenaltyRecord r) {
    switch (r.type) {
      case 'photo':
        if (r.status == 'done' && r.proofUrl != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              r.proofUrl!,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _photoPlaceholder(),
            ),
          );
        }
        return r.status == 'done' ? _photoPlaceholder() : _pinkButton('扫码接受');

      case 'audio':
        if (r.status == 'done' || r.status == 'verified') {
          return _AudioPlayWidget();
        }
        return _pinkButton('扫码接受');

      case 'promise':
        return _pinkButton('惩罚凭证');

      case 'text':
      default:
        return r.status == 'undone'
            ? _pinkButton('扫码接受')
            : const SizedBox.shrink();
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

  Widget _buildStatusBadge(String status) {
    late String label;
    late Color color;
    switch (status) {
      case 'done':
        label = '已完成';
        color = const Color(0xFF4CAF50);
        break;
      case 'undone':
        label = '未完成';
        color = const Color(0xFFFF6B9D);
        break;
      case 'verified':
        label = '已核验完成';
        color = const Color(0xFF4CAF50);
        break;
      default:
        label = status;
        color = const Color(0xFF999999);
    }
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
  }
}

/// 语音播放小组件（带播放/暂停切换）
class _AudioPlayWidget extends StatefulWidget {
  @override
  State<_AudioPlayWidget> createState() => _AudioPlayWidgetState();
}

class _AudioPlayWidgetState extends State<_AudioPlayWidget> {
  bool _playing = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => setState(() => _playing = !_playing),
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
          _playing ? '5s' : '',
          style: const TextStyle(fontSize: 11, color: Color(0xFFFF9AD9)),
        ),
      ],
    );
  }
}
