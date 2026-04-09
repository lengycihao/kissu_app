import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 事件筛选底部弹窗
class FilterBottomSheet extends StatelessWidget {
  final List<String> filterOptions;
  final RxList<String> tempSelectedFilters;
  final VoidCallback onConfirm;

  const FilterBottomSheet({
    super.key,
    required this.filterOptions,
    required this.tempSelectedFilters,
    required this.onConfirm,
  });

  /// 显示筛选弹窗
  static void show({
    required List<String> filterOptions,
    required List<String> currentFilters,
    required void Function(List<String> selectedFilters) onConfirm,
  }) {
    final tempFilters = List<String>.from(currentFilters).obs;

    Get.bottomSheet(
      FilterBottomSheet(
        filterOptions: filterOptions,
        tempSelectedFilters: tempFilters,
        onConfirm: () {
          Get.back();
          onConfirm(List.from(tempFilters));
        },
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '事件筛选',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),
          ...filterOptions.map((option) {
            return Obx(() {
              final isSelected = tempSelectedFilters.contains(option);
              return InkWell(
                onTap: () {
                  if (isSelected) {
                    tempSelectedFilters.remove(option);
                  } else {
                    tempSelectedFilters.add(option);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  margin: const EdgeInsets.symmetric(horizontal: 36),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(width: 1, color: Color(0xffF6F6F6)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                      Image(
                        image: AssetImage(
                          isSelected
                              ? 'assets/phone_history/kissu3_history_seting_sel.webp'
                              : 'assets/phone_history/kissu3_history_seting_unsel.webp',
                        ),
                        width: 16,
                      ),
                    ],
                  ),
                ),
              );
            });
          }),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onConfirm,
            child: Container(
              height: 42,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 36),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(21),
              ),
              alignment: Alignment.center,
              child: const Text(
                "确定",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
