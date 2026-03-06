import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:kissu_app/utils/oktoast_util.dart';

/// 常见相册名中文映射
const Map<String, String> _albumNameZhMap = {
  'All Photos': '所有照片',
  'Recent': '最近项目',
  'Recents': '最近项目',
  'Camera Roll': '相机胶卷',
  'Camera': '相机',
  'DCIM': '相机',
  'Screenshots': '截屏',
  'Screen recordings': '屏幕录制',
  'Download': '下载',
  'Downloads': '下载',
  'Pictures': '图片',
  'Favorites': '收藏',
  'Edited': '已编辑',
  'Videos': '视频',
  'Panoramas': '全景照片',
  'Portrait': '人像',
  'Selfies': '自拍',
  'Live Photos': '实况照片',
  'Animated': '动图',
  'Bursts': '连拍快照',
  'Hidden': '隐藏',
  'Recently Deleted': '最近删除',
  'Recently Added': '最近添加',
  'WhatsApp Images': 'WhatsApp 图片',
  'WeChat': '微信',
  'WeiXin': '微信',
  'WeixinWork': '微信工作空间',
  'QQ Images': 'QQ 图片',
  'Telegram': 'Telegram',
};

/// 将相册名转为中文显示名
String _localizedAlbumName(AssetPathEntity album) {
  if (album.isAll) return '所有照片';
  final name = album.name;
  return _albumNameZhMap[name] ?? name;
}

/// 仿微信图片选择器
/// 支持多选、勾选、预览、底部发送栏
class ChatImagePickerPage extends StatefulWidget {
  final int maxCount;

  const ChatImagePickerPage({
    super.key,
    this.maxCount = 9,
  });

  /// 打开图片选择器，返回选中的图片文件列表
  static Future<List<File>?> open(BuildContext context, {int maxCount = 9}) {
    return Navigator.of(context).push<List<File>>(
      MaterialPageRoute(
        builder: (_) => ChatImagePickerPage(maxCount: maxCount),
      ),
    );
  }

  @override
  State<ChatImagePickerPage> createState() => _ChatImagePickerPageState();
}

class _ChatImagePickerPageState extends State<ChatImagePickerPage> {
  List<AssetPathEntity> _albums = [];
  AssetPathEntity? _currentAlbum;
  List<AssetEntity> _assets = [];
  final List<AssetEntity> _selectedAssets = [];
  bool _isLoading = true;
  int _currentPage = 0;
  static const int _pageSize = 80;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  // 缩略图缓存
  final Map<String, Uint8List> _thumbnailCache = {};

  @override
  void initState() {
    super.initState();
    _loadAlbums();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        _hasMore &&
        !_isLoading) {
      _loadMoreAssets();
    }
  }

  Future<void> _loadAlbums() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.hasAccess) {
      if (mounted) {
        OKToastUtil.showError('请授予相册访问权限');
        Navigator.of(context).pop();
      }
      return;
    }

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: FilterOptionGroup(
        imageOption: const FilterOption(
          sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
        orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
      ),
    );

    if (albums.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    // 查找"所有照片"相册（通常是 isAll == true 的那个）
    AssetPathEntity defaultAlbum = albums.first;
    for (final album in albums) {
      if (album.isAll) {
        defaultAlbum = album;
        break;
      }
    }

    setState(() {
      _albums = albums;
      _currentAlbum = defaultAlbum;
    });

    await _loadAssets();
  }

  Future<void> _loadAssets() async {
    if (_currentAlbum == null) return;
    setState(() => _isLoading = true);

    _currentPage = 0;
    final assets = await _currentAlbum!.getAssetListPaged(
      page: _currentPage,
      size: _pageSize,
    );

    final totalCount = await _currentAlbum!.assetCountAsync;

    setState(() {
      _assets = assets;
      _hasMore = assets.length < totalCount;
      _isLoading = false;
    });
  }

  Future<void> _loadMoreAssets() async {
    if (_currentAlbum == null || !_hasMore) return;
    setState(() => _isLoading = true);

    _currentPage++;
    final assets = await _currentAlbum!.getAssetListPaged(
      page: _currentPage,
      size: _pageSize,
    );

    final totalCount = await _currentAlbum!.assetCountAsync;

    setState(() {
      _assets.addAll(assets);
      _hasMore = _assets.length < totalCount;
      _isLoading = false;
    });
  }

  void _toggleSelect(AssetEntity asset) {
    setState(() {
      if (_selectedAssets.contains(asset)) {
        _selectedAssets.remove(asset);
      } else {
        if (_selectedAssets.length >= widget.maxCount) {
          OKToastUtil.show('最多选择${widget.maxCount}张');
          return;
        }
        _selectedAssets.add(asset);
      }
    });
  }

  int _getSelectIndex(AssetEntity asset) {
    final idx = _selectedAssets.indexOf(asset);
    return idx >= 0 ? idx + 1 : -1;
  }

  Future<void> _onSend() async {
    if (_selectedAssets.isEmpty) return;

    // 显示加载
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF7ECE)),
      ),
    );

    try {
      final List<File> files = [];
      for (final asset in _selectedAssets) {
        final file = await asset.file;
        if (file != null) {
          // 压缩图片
          final compressed = await _compressImage(file);
          files.add(compressed);
        }
      }

      if (mounted) {
        Navigator.of(context).pop(); // 关闭loading
        Navigator.of(context).pop(files); // 返回结果
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // 关闭loading
        OKToastUtil.showError('处理图片失败');
      }
    }
  }

  Future<File> _compressImage(File file) async {
    try {
      final filePath = file.absolute.path;
      final lastIndex = filePath.lastIndexOf(RegExp(r'\.'));
      final splitted = filePath.substring(0, lastIndex);
      final outPath = '${splitted}_compressed.jpg';

      final XFile? compressedFile =
          await FlutterImageCompress.compressAndGetFile(
        filePath,
        outPath,
        quality: 92,
        minWidth: 1920,
        minHeight: 1920,
      );

      if (compressedFile != null) {
        return File(compressedFile.path);
      }
      return file;
    } catch (_) {
      return file;
    }
  }

  void _onPreview() {
    if (_selectedAssets.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ImagePreviewPage(
          assets: _selectedAssets,
          initialIndex: 0,
          selectedAssets: _selectedAssets,
          maxCount: widget.maxCount,
          onToggleSelect: (asset) {
            _toggleSelect(asset);
            // 强制刷新预览页
          },
        ),
      ),
    ).then((_) {
      // 从预览返回时刷新状态
      if (mounted) setState(() {});
    });
  }

  void _onTapPreviewSingle(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ImagePreviewPage(
          assets: _assets,
          initialIndex: index,
          selectedAssets: _selectedAssets,
          maxCount: widget.maxCount,
          onToggleSelect: (asset) {
            _toggleSelect(asset);
          },
        ),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _switchAlbum() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _AlbumListSheet(
        albums: _albums,
        currentAlbum: _currentAlbum,
        onSelect: (album) {
          Navigator.of(context).pop();
          setState(() {
            _currentAlbum = album;
            _assets = [];
          });
          _loadAssets();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: Colors.black87, size: 24),
        ),
        title: GestureDetector(
          onTap: _albums.length > 1 ? _switchAlbum : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _currentAlbum != null ? _localizedAlbumName(_currentAlbum!) : '所有照片',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              if (_albums.length > 1)
                const Icon(Icons.arrow_drop_down, color: Colors.black54),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 图片网格
          Expanded(
            child: _assets.isEmpty && _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: Color(0xFFFF7ECE)))
                : GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(2),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 2,
                      crossAxisSpacing: 2,
                    ),
                    itemCount: _assets.length,
                    itemBuilder: (context, index) {
                      final asset = _assets[index];
                      final selectIndex = _getSelectIndex(asset);
                      final isSelected = selectIndex > 0;

                      return _ImageGridItem(
                        asset: asset,
                        isSelected: isSelected,
                        selectIndex: selectIndex,
                        thumbnailCache: _thumbnailCache,
                        onTap: () => _onTapPreviewSingle(index),
                        onSelect: () => _toggleSelect(asset),
                      );
                    },
                  ),
          ),
          // 底部操作栏
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final count = _selectedAssets.length;
    final hasSelection = count > 0;

    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 预览按钮
          GestureDetector(
            onTap: hasSelection ? _onPreview : null,
            child: Text(
              '预览',
              style: TextStyle(
                fontSize: 16,
                color: hasSelection ? Colors.black87 : Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Spacer(),
          // 发送按钮
          GestureDetector(
            onTap: hasSelection ? _onSend : null,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: hasSelection
                    ? const Color(0xFFFF7ECE)
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                hasSelection ? '发送($count)' : '发送',
                style: TextStyle(
                  fontSize: 15,
                  color: hasSelection ? Colors.white : Colors.grey[500],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 图片网格项
class _ImageGridItem extends StatelessWidget {
  final AssetEntity asset;
  final bool isSelected;
  final int selectIndex;
  final Map<String, Uint8List> thumbnailCache;
  final VoidCallback onTap;
  final VoidCallback onSelect;

  const _ImageGridItem({
    required this.asset,
    required this.isSelected,
    required this.selectIndex,
    required this.thumbnailCache,
    required this.onTap,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 缩略图
          _ThumbnailWidget(asset: asset, cache: thumbnailCache),
          // 选中遮罩
          if (isSelected)
            Container(
              color: Colors.white.withValues(alpha: 0.3),
            ),
          // 勾选框
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onSelect,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? const Color(0xFFFF7ECE)
                      : Colors.black.withValues(alpha: 0.3),
                  border: Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Text(
                          '$selectIndex',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 缩略图组件（带缓存）
class _ThumbnailWidget extends StatefulWidget {
  final AssetEntity asset;
  final Map<String, Uint8List> cache;

  const _ThumbnailWidget({required this.asset, required this.cache});

  @override
  State<_ThumbnailWidget> createState() => _ThumbnailWidgetState();
}

class _ThumbnailWidgetState extends State<_ThumbnailWidget> {
  Uint8List? _thumbData;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    final cached = widget.cache[widget.asset.id];
    if (cached != null) {
      if (mounted) setState(() => _thumbData = cached);
      return;
    }

    final data = await widget.asset.thumbnailDataWithSize(
      const ThumbnailSize(200, 200),
      quality: 80,
    );
    if (data != null) {
      widget.cache[widget.asset.id] = data;
      if (mounted) setState(() => _thumbData = data);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_thumbData != null) {
      return Image.memory(
        _thumbData!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    }
    return Container(color: Colors.grey[200]);
  }
}

/// 相册列表底部弹窗
class _AlbumListSheet extends StatelessWidget {
  final List<AssetPathEntity> albums;
  final AssetPathEntity? currentAlbum;
  final Function(AssetPathEntity) onSelect;

  const _AlbumListSheet({
    required this.albums,
    required this.currentAlbum,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '选择相册',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: albums.length,
              itemBuilder: (context, index) {
                final album = albums[index];
                final isCurrent = album.id == currentAlbum?.id;
                return _AlbumListItem(
                  album: album,
                  isCurrent: isCurrent,
                  onTap: () => onSelect(album),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 相册列表项
class _AlbumListItem extends StatefulWidget {
  final AssetPathEntity album;
  final bool isCurrent;
  final VoidCallback onTap;

  const _AlbumListItem({
    required this.album,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  State<_AlbumListItem> createState() => _AlbumListItemState();
}

class _AlbumListItemState extends State<_AlbumListItem> {
  Uint8List? _coverData;
  int _assetCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCover();
  }

  Future<void> _loadCover() async {
    final count = await widget.album.assetCountAsync;
    if (count > 0) {
      final assets =
          await widget.album.getAssetListPaged(page: 0, size: 1);
      if (assets.isNotEmpty) {
        final data = await assets.first.thumbnailDataWithSize(
          const ThumbnailSize(100, 100),
          quality: 60,
        );
        if (mounted) {
          setState(() {
            _coverData = data;
            _assetCount = count;
          });
        }
        return;
      }
    }
    if (mounted) setState(() => _assetCount = count);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: widget.onTap,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 50,
          height: 50,
          child: _coverData != null
              ? Image.memory(_coverData!, fit: BoxFit.cover)
              : Container(color: Colors.grey[200]),
        ),
      ),
      title: Text(
        _localizedAlbumName(widget.album),
        style: TextStyle(
          fontSize: 15,
          fontWeight: widget.isCurrent ? FontWeight.w600 : FontWeight.normal,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        '$_assetCount张',
        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
      ),
      trailing: widget.isCurrent
          ? const Icon(Icons.check, color: Color(0xFFFF7ECE), size: 22)
          : null,
    );
  }
}

/// 图片预览页面
class _ImagePreviewPage extends StatefulWidget {
  final List<AssetEntity> assets;
  final int initialIndex;
  final List<AssetEntity> selectedAssets;
  final int maxCount;
  final Function(AssetEntity) onToggleSelect;

  const _ImagePreviewPage({
    required this.assets,
    required this.initialIndex,
    required this.selectedAssets,
    required this.maxCount,
    required this.onToggleSelect,
  });

  @override
  State<_ImagePreviewPage> createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends State<_ImagePreviewPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 图片翻页
          PageView.builder(
            controller: _pageController,
            itemCount: widget.assets.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              return _FullImageView(asset: widget.assets[index]);
            },
          ),
          // 顶部栏
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  8, MediaQuery.of(context).padding.top, 8, 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios,
                        color: Colors.white, size: 20),
                  ),
                  const Spacer(),
                  Text(
                    '${_currentIndex + 1}/${widget.assets.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const Spacer(),
                  // 勾选按钮
                  GestureDetector(
                    onTap: () {
                      final asset = widget.assets[_currentIndex];
                      widget.onToggleSelect(asset);
                      setState(() {});
                    },
                    child: _buildCheckBox(widget.assets[_currentIndex]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckBox(AssetEntity asset) {
    final idx = widget.selectedAssets.indexOf(asset);
    final isSelected = idx >= 0;

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected
            ? const Color(0xFFFF7ECE)
            : Colors.black.withValues(alpha: 0.3),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: isSelected
          ? Center(
              child: Text(
                '${idx + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }
}

/// 大图查看组件
class _FullImageView extends StatefulWidget {
  final AssetEntity asset;

  const _FullImageView({required this.asset});

  @override
  State<_FullImageView> createState() => _FullImageViewState();
}

class _FullImageViewState extends State<_FullImageView> {
  File? _file;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  Future<void> _loadFile() async {
    final file = await widget.asset.file;
    if (mounted && file != null) {
      setState(() => _file = file);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_file == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF7ECE)),
      );
    }
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: Image.file(
          _file!,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
