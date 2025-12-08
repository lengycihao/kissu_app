import 'package:flutter/material.dart';

import 'package:kissu_app/models/usage_record_api_model.dart';
import 'package:kissu_app/utils/network_image_helper.dart';
import '../usage_report_page.dart';

class UsageRecordItem extends StatelessWidget {
  final SensitiveRecordItem record;
  final VoidCallback onTap;
  final VoidCallback onJumpTap;

  const UsageRecordItem({
    super.key,
    required this.record,
    required this.onTap,
    required this.onJumpTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff000000).withOpacity(0.04),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Stack(
          children: [
            record.hasSubContent
                ? _buildDoubleRowItem()
                : _buildSingleRowItem(),
            if (record.needsVip)
              Positioned(
                right: 0,
                top: 0,
                child: Transform.translate(
                  offset: const Offset(16, -16),
                  child: Container(
                    height: 16,
                    width: 56,
                    decoration: const BoxDecoration(
                      color: Color(0xffFFBAE4),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'VIP查看',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF333333),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleRowItem() {
    return Row(
      children: [
        ClipRRect(
          child: NetworkImageHelper.loadImage(
            imageUrl: record.icon,
            width: 18,
            height: 18,
            fit: BoxFit.cover,
            errorWidget: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(color: Color(0xFFF5F5F5)),
              child: const Icon(
                Icons.image,
                size: 18,
                color: Color(0xFFCCCCCC),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(child: _buildContentWithHighlight()),
        const SizedBox(width: 8),
        Text(
          UsageReportPage.formatTime(record.createTime),
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF999999),
          ),
        ),
      ],
    );
  }

  Widget _buildDoubleRowItem() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          child: NetworkImageHelper.loadImage(
            imageUrl: record.icon,
            width: 18,
            height: 18,
            fit: BoxFit.cover,
            errorWidget: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.image,
                size: 16,
                color: Color(0xFFCCCCCC),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildContentWithHighlight(),
              if (record.hasSubContent) ...[
                const SizedBox(height: 2),
                Text(
                  record.subContent,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xcc333333),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          UsageReportPage.formatTime(record.createTime),
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF999999),
          ),
        ),
      ],
    );
  }

  Widget _buildContentWithHighlight() {
    return Row(
      children: [
        Text(
          record.content,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF333333),
          ),
        ),
        if (record.showJumpButton)
          GestureDetector(
            onTap: onJumpTap,
            child: Container(
              padding: const EdgeInsets.only(left: 8),
              child: Row(
                children: const [
                  Text(
                    '查看',
                    style: TextStyle(
                      color: Color(0xff009BFE),
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 2),
                  Image(
                    image: AssetImage(
                      'assets/phone_history/kissu3_vip_go.webp',
                    ),
                    color: Color(0xff009bfe),
                    width: 6,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}


