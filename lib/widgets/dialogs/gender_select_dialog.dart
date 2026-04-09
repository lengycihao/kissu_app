import 'package:flutter/material.dart';
import 'base_dialog.dart'; 

/// 性别选择弹窗
class GenderSelectDialog extends BaseDialog {
  final String? selectedGender;
  final Function(String gender)? onGenderSelected;

  const GenderSelectDialog({
    Key? key,
    this.selectedGender,
    this.onGenderSelected,
  }) : super(key: key);

  @override
  Widget buildContent(BuildContext context) {
    return _GenderSelectContent(
      selectedGender: selectedGender,
      onGenderSelected: onGenderSelected,
    );
  }

  /// 显示性别选择弹窗
  static Future<String?> show({
    required BuildContext context,
    String? selectedGender,
    Function(String gender)? onGenderSelected,
  }) {
    return BaseDialog.show<String>(
      context: context,
      dialog: GenderSelectDialog(
        selectedGender: selectedGender,
        onGenderSelected: onGenderSelected,
      ),
    );
  }
}

class _GenderSelectContent extends StatefulWidget {
  final String? selectedGender;
  final Function(String gender)? onGenderSelected;

  const _GenderSelectContent({
    Key? key,
    this.selectedGender,
    this.onGenderSelected,
  }) : super(key: key);

  @override
  State<_GenderSelectContent> createState() => _GenderSelectContentState();
}

class _GenderSelectContentState extends State<_GenderSelectContent> {
  late String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _selectedGender = widget.selectedGender;
  }

 
  @override
  Widget build(BuildContext context) {
    return DialogContainer(
      backgroundImage: 'assets/dialog/kissu_toast_bg.webp',
      width: 270,
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题
          const Text(
            '请选择您的性别',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 15),
          // 性别选项
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _GenderOption(
                gender: '男生',
                isSelected: _selectedGender == '男生',
                selectedImage: 'assets/images/kissu_info_setting_boysel.webp',
                unselectedImage: 'assets/images/kissu_info_setting_boyunsel.webp',
                onTap: () {
                  setState(() {
                    _selectedGender = '男生';
                  });
              
                },
              ),
              const SizedBox(width: 18),
              _GenderOption(
                gender: '女生',
                isSelected: _selectedGender == '女生',
                selectedImage: 'assets/images/kissu_info_setting_girlsel.webp',
                unselectedImage: 'assets/images/kissu_info_setting_girlunsel.webp',
                onTap: () {
                  setState(() {
                    _selectedGender = '女生';
                  });
                 
                },
              ),
            ],
          ),
          const SizedBox(height: 28),
          // 确定按钮
          GestureDetector( onTap: () {
              if (_selectedGender != null) {
                Navigator.of(context).pop(_selectedGender);
                widget.onGenderSelected?.call(_selectedGender!);
              }
            },
            child: Image(image: AssetImage('assets/images/kissu_dialop_common_sure_bg.webp'),width: 106,height: 36,),
          ),
          
        ],
      ),
    );
  }
}

/// 性别选项组件
class _GenderOption extends StatelessWidget {
  final String gender;
  final bool isSelected;
  final String selectedImage;
  final String unselectedImage;
  final VoidCallback onTap;

  const _GenderOption({
    Key? key,
    required this.gender,
    required this.isSelected,
    required this.selectedImage,
    required this.unselectedImage,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 100,
            height: 45,
            decoration: BoxDecoration(
              // borderRadius: BorderRadius.circular(40),
              image: DecorationImage(
                image: AssetImage(isSelected ? selectedImage : unselectedImage),
                fit: BoxFit.contain,
              ),
            ),
          ),
          // const SizedBox(height: 10),
          // Text(
          //   gender,
          //   style: TextStyle(
          //     fontSize: 16,
          //     color: isSelected ? const Color(0xFFFF6B9D) : const Color(0xFF999999),
          //     fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          //   ),
          // ),
        ],
      ),
    );
  }
}
