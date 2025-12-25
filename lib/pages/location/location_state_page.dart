import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/utils/network_image_helper.dart';
import 'package:kissu_app/utils/emoji_cache_manager.dart';
import 'location_state_controller.dart';
import 'package:kissu_app/widgets/dialogs/location_state_delete_dialog.dart';

/// 状态设置页面
class LocationStatePage extends StatelessWidget {
  LocationStatePage({super.key});

  final controller = Get.put(LocationStateController());

  @override
  Widget build(BuildContext context) {
    // 设置替换确认弹窗的回调
    controller.onShowReplaceDialog = () => _showReplaceConfirmDialog(context);
    // 设置返回确认弹窗的回调
    controller.onShowBackDialog = () => _showBackConfirmDialog(context);

    return Scaffold(
      backgroundColor: const Color(0xFFf6f6f6),
      body: Stack(
        children: [
          Column(
            children: [
              // 自定义导航栏
              _buildCustomAppBar(context),
              if (controller.hasStatus.value ||
                  controller.currentStatusEmoji.value.isEmpty ||
                  controller.currentStatusText.value.isEmpty)
                const SizedBox(height: 10),
              // 表情列表内容 - 添加RepaintBoundary优化
              Expanded(child: RepaintBoundary(child: _buildEmojiContent())),
            ],
          ),

          // 底部有效期选择弹窗
          Obx(() {
            if (controller.selectedEmoji.value == null) {
              return const SizedBox.shrink();
            }
            return _buildExpireTimeBottomSheet(context);
          }),
        ],
      ),
    );
  }

  /// 自定义导航栏
  Widget _buildCustomAppBar(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题区域（带背景图）
          Container(
            padding: EdgeInsets.only(
              top: topPadding + 10,
              bottom: 10,
              left: 16,
              right: 16,
            ),
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/setting/kissu_navbar_bg.webp'),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => controller.handleBack(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        'assets/images/kissu_mine_back.webp',
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: const Text(
                      '我的心情',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 当前状态显示区域（白色固定背景）
          Obx(() {
            if (!controller.hasStatus.value ||
                controller.currentStatusEmoji.value.isEmpty ||
                controller.currentStatusText.value.isEmpty) {
              return const SizedBox.shrink();
            }

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: 12,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _showDeleteConfirmDialog(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                             vertical: 6,
                          ),
                          child: Row(
                            children: [
                              Image(
                                image: AssetImage(
                                  'assets/setting/kissu_navbar_delete.webp',
                                ),
                                width: 16,
                                height: 16,
                              ),
                              SizedBox(width: 4),
                              const Text(
                                '删除',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF666666),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                            
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Column(
                          children: [
                            NetworkImageHelper.loadImage(
                              imageUrl: controller.currentStatusEmoji.value,
                              width: 46,
                              height: 46,
                              errorWidget: const Icon(
                                Icons.image_not_supported,
                                size: 46,
                              ),
                            ),
                            Text(
                              controller.currentStatusText.value,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF333333),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Obx(() {
                        final hasChanges = controller.hasUnsavedChanges;
                        return GestureDetector(
                          onTap: hasChanges
                              ? () {
                                  controller.saveStatus();
                                }
                              : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: hasChanges
                                  ? const Color(0xFFFFA9E0)
                                  : const Color(0xccFFA9E0),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Text(
                              '保存',
                              style: TextStyle(
                                fontSize: 14,
                                color: hasChanges
                                    ? const Color(0xFFffffff)
                                    : const Color(0xFFffffff) ,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '状态有效期:',
                      style: TextStyle(fontSize: 12, color: Color(0xFF333333)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildExpireTimeOptions(isBottomSheet: false),
                  const SizedBox(height: 12),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 表情列表内容 - 所有分类垂直滚动展示
  Widget _buildEmojiContent() {
    return Obx(() {
      // 加载中状态
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      // 数据为空
      if (controller.emojiCategories.isEmpty) {
        return const Center(
          child: Text(
            '暂无表情',
            style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
          ),
        );
      }

      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: controller.emojiCategories.length,
            // 优化：增加缓存范围，提前渲染屏幕外的内容
            cacheExtent: 500,
            // 优化：使用iOS弹性滚动效果，提升滚动体验
            physics: const BouncingScrollPhysics(),
            // 优化：添加itemExtent提示，帮助ListView预估高度
            itemBuilder: (context, categoryIndex) {
              final category = controller.emojiCategories[categoryIndex];

              // 使用独立的Widget减少重建
              return _EmojiCategoryItem(
                category: category,
                onEmojiTap: controller.selectEmoji,
                index: categoryIndex,
              );
            },
          ),
       
      );
    });
  }

  /// 显示删除确认对话框
  void _showDeleteConfirmDialog(BuildContext context) {
    LocationStateDeleteDialog.show(
      context: context,
      title: '确定要删除吗？',
      onConfirm: () {
        controller.deleteStatus();
      },
    );
  }

  /// 显示替换状态确认弹窗
  void _showReplaceConfirmDialog(BuildContext context) {
    LocationStateDeleteDialog.show(
      context: context,
      title: '是否要替换之前的状态？',
      onConfirm: () {
        controller.confirmReplace();
      },
      onCancel: () {
        controller.cancelReplace();
      },
    );
  }

  /// 显示返回确认弹窗
  void _showBackConfirmDialog(BuildContext context) {
    LocationStateDeleteDialog.show(
      context: context,
      title: '确定要放弃当前更改吗？',
      onConfirm: () {
        controller.confirmBack();
      },
      onCancel: () {
        controller.cancelBack();
      },
    );
  }

  /// 底部有效期选择弹窗
  Widget _buildExpireTimeBottomSheet(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return GestureDetector(
      onTap: () {
        // 点击背景关闭弹窗
        controller.cancelSetStatus();
      },
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Column(
          children: [
            const Spacer(),
            GestureDetector(
              onTap: () {}, // 阻止点击事件冒泡
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 30,
                  bottom: bottomPadding + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 表情显示
                    Obx(() {
                      final emoji = controller.selectedEmoji.value;
                      if (emoji == null) return const SizedBox.shrink();

                      return Container(
                        decoration: BoxDecoration(
                          color: Color(0xffffffff),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Color(0xffFFF6F6),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Column(
                          children: [
                            // 使用网络图片显示表情
                            NetworkImageHelper.loadImage(
                              imageUrl: emoji.emoji,
                              width: 46,
                              height: 46,
                              errorWidget: const Icon(
                                Icons.image_not_supported,
                                size: 46,
                              ),
                            ),
                            Text(
                              emoji.name,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF333333),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 24),

                    // 状态有效期标题
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '状态有效期:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 有效期选项（底部弹窗使用 tempExpireHours）
                    _buildExpireTimeOptions(isBottomSheet: true),

                    const SizedBox(height: 24),

                    // 确定按钮
                    GestureDetector(
                      onTap: () {
                        controller.confirmSetStatus();
                      },
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF408D), Color(0xFFFF6699)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '确定',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 有效期选项
  /// [isBottomSheet] 是否是底部弹窗使用（true: 使用 tempExpireHours, false: 使用 topExpireHours）
  Widget _buildExpireTimeOptions({bool isBottomSheet = false}) {
    final options = [
      {'hours': 1, 'label': '1小时'},
      {'hours': 2, 'label': '2小时'},
      {'hours': 4, 'label': '4小时'},
      {'hours': 6, 'label': '6小时'},
      {'hours': 8, 'label': '8小时'},
      {'hours': 12, 'label': '12小时'},
    ];

    return Obx(() {
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: options.map((option) {
          final hours = option['hours'] as int;
          final label = option['label'] as String;

          // 根据是否是底部弹窗，使用不同的变量
          final isSelected = isBottomSheet
              ? controller.tempExpireHours.value == hours
              : controller.topExpireHours.value == hours;

          return GestureDetector(
            onTap: () {
              // 根据是否是底部弹窗，修改不同的变量
              if (isBottomSheet) {
                controller.tempExpireHours.value = hours;
              } else {
                // 顶部状态区域：只更新顶部有效期，不调用接口
                controller.setExpireTime(hours);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xffFFA9E0)
                    : const Color(0xFFf9f9f9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : const Color(0xFF333333),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}

/// 表情分类项 - 独立Widget减少重建，使用AutomaticKeepAlive保持状态
class _EmojiCategoryItem extends StatefulWidget {
  final EmojiCategory category;
  final Function(EmojiItem) onEmojiTap;
  final int index;

  const _EmojiCategoryItem({
    required this.category,
    required this.onEmojiTap,
    this.index = 0,
  });

  @override
  State<_EmojiCategoryItem> createState() => _EmojiCategoryItemState();
}

class _EmojiCategoryItemState extends State<_EmojiCategoryItem>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<double>(
      begin: 20.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // 延迟启动动画，每个分类延迟100ms
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用super.build

    return FadeTransition(
      opacity: _fadeAnimation,
      child: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: child,
          );
        },
        child: RepaintBoundary(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 分类标题
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 2,
                      child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE0E0),
                          borderRadius: BorderRadius.circular(2),
                          gradient: LinearGradient(
                            colors: [Color(0xFF97FED8), Color(0xFFF8F63B)],
                          ),
                        ),
                      ),
                    ),
                    Text(
                      widget.category.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'LiuHuanKaTongShouShu',
                        color: Color(0xFF593A37),
                      ),
                    ),
                  ],
                ),
              ),

              // 该分类的表情网格
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: widget.category.emojis.length,
                itemBuilder: (context, emojiIndex) {
                  final emoji = widget.category.emojis[emojiIndex];
                  return _EmojiGridItem(
                    emoji: emoji,
                    onTap: () => widget.onEmojiTap(emoji),
                    index: emojiIndex,
                  );
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// 表情网格项 - 独立Widget减少重建
class _EmojiGridItem extends StatefulWidget {
  final EmojiItem emoji;
  final VoidCallback onTap;
  final int index;

  const _EmojiGridItem({
    required this.emoji,
    required this.onTap,
    this.index = 0,
  });

  @override
  State<_EmojiGridItem> createState() => _EmojiGridItemState();
}

class _EmojiGridItemState extends State<_EmojiGridItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    // 延迟启动动画，每个表情延迟30ms
    Future.delayed(Duration(milliseconds: widget.index * 30), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: RepaintBoundary(
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xffffffff),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xffFFF6F6), width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 使用网络图片显示表情
                NetworkImageHelper.loadImage(
                  imageUrl: widget.emoji.emoji,
                  width: 24,
                  height: 24,
                  errorWidget: const Icon(Icons.image_not_supported, size: 24),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.emoji.name,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF333333),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
