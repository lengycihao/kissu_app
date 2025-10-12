import 'package:flutter/material.dart';
import 'package:kissu_app/models/usage_record_api_model.dart';

/// 通用记录列表项组件（用于敏感记录、定位异常等）
/// 根据event_type和ext动态渲染不同的UI
class GenericRecordItemWidget extends StatelessWidget {
  final RecordItem record;
  final VoidCallback? onTap;
  final bool showTimeLabel; // 是否显示时间标签（用于全部记录页面）
  final bool showSensitiveLevel; // 是否显示敏感等级标签

  const GenericRecordItemWidget({
    super.key,
    required this.record,
    this.onTap,
    this.showTimeLabel = false,
    this.showSensitiveLevel = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 时间标签（仅在全部记录页面显示）
        // if (showTimeLabel) ...[
        //   const SizedBox(height: 8),
        //   _buildTimeLabel(),
        //   const SizedBox(height: 8),
        // ],
        _buildTimeLabel(),
          const SizedBox(height: 8),
        _buildRecordContent(),
      ],
    );
  }

  /// 构建时间标签
  Widget _buildTimeLabel() {
    return Center(
      child: Text(
        record.createTime,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF999999),
        ),
      ),
    );
  }

  /// 构建记录内容
  Widget _buildRecordContent() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 12, right: 12, bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                // 图标
                if (record.icon.isNotEmpty)
                  Image.network(
                    record.icon,
                    width: 16,
                    height: 16,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.image_not_supported,
                      size: 16,
                      // color: Colors.grey[400],
                    ),
                  )
                else
                  Icon(Icons.info_outline, size: 20, color: Colors.grey[400]),
                const SizedBox(width: 4),
                // 文本内容（支持高亮）
                Expanded(
                  child: _buildContentText(),
                ),
              ],
            ),
            // 扩展信息（如果有特殊显示需求）
            if (_hasExtendedInfo()) ...[
              const SizedBox(height: 12),
              _buildExtendedInfo(),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建内容文本（支持 var_data 高亮）
  Widget _buildContentText() {
    // 如果没有 var_data，直接显示 content
    if (record.varData.isEmpty) {
      return Text(
        record.content,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF333333),
        ),
      );
    }

    // 有 var_data，需要对文本进行分段高亮
    List<TextSpan> spans = [];
    String remainingText = record.content;

    for (var varItem in record.varData) {
      // 找到需要高亮的文本位置
      int index = remainingText.indexOf(varItem.changeText);
      if (index == -1) continue;

      // 添加前面的普通文本
      if (index > 0) {
        spans.add(TextSpan(
          text: remainingText.substring(0, index),
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF333333),
          ),
        ));
      }

      // 添加高亮文本
      spans.add(TextSpan(
        text: varItem.changeText,
        style: TextStyle(
          fontSize: 13,
          color: _parseColor(varItem.color),
        ),
      ));

      // 更新剩余文本
      remainingText = remainingText.substring(index + varItem.changeText.length);
    }

    // 添加剩余的普通文本
    if (remainingText.isNotEmpty) {
      spans.add(TextSpan(
        text: remainingText,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF333333),
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  /// 解析颜色字符串（支持 #RRGGBB 格式）
  Color _parseColor(String colorStr) {
    try {
      // 去掉 # 号
      String hexColor = colorStr.replaceAll('#', '');
      // 如果是6位，添加FF作为完全不透明
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      // 解析失败返回默认颜色
      return const Color(0xFF333333);
    }
  }

  /// 是否有扩展信息需要显示
  bool _hasExtendedInfo() {
    // event_type 19: 解锁->锁定时段记录（在解锁记录页面已经有专门组件处理）
    // 这里只处理一些特殊的扩展信息展示
    return false;
  }

  /// 构建扩展信息
  Widget _buildExtendedInfo() {
    return const SizedBox.shrink();
  }
}

