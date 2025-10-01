import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crop_your_image/crop_your_image.dart';

class ImageCropPage extends StatefulWidget {
  final String imagePath;
  final Function(String) onCropComplete;

  /// 自定义裁剪框图片路径（可选）
  /// 如果提供，将在裁剪框上方显示这个装饰图片
  final String? customCropFrameAsset;

  const ImageCropPage({
    Key? key,
    required this.imagePath,
    required this.onCropComplete,
    this.customCropFrameAsset,
  }) : super(key: key);

  @override
  State<ImageCropPage> createState() => _ImageCropPageState();
}

class _ImageCropPageState extends State<ImageCropPage> {
  final _cropController = CropController();
  Uint8List? _imageData;
  bool _isLoading = true;
  bool _isCropping = false;
  
  // 裁剪区域的水平边距（确保裁剪框和装饰图片对齐）
  static const double _horizontalPadding = 20.0;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final file = File(widget.imagePath);
      final bytes = await file.readAsBytes();
      setState(() {
        _imageData = bytes;
        _isLoading = false;
      });
    } catch (e) {
      print('加载图片失败: $e');
      if (mounted) {
        Get.back();
      }
    }
  }

  void _onCrop() {
    setState(() {
      _isCropping = true;
    });
    _cropController.crop();
  }

  Future<void> _onCropped(Uint8List croppedData) async {
    try {
      // 保存裁剪后的图片
      final file = File(widget.imagePath);
      final directory = file.parent;
      final croppedFile = File(
        '${directory.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await croppedFile.writeAsBytes(croppedData);

      // 回调
      widget.onCropComplete(croppedFile.path);
    } catch (e) {
      print('保存裁剪图片失败: $e');
    } finally {
      if (mounted) {
        Get.back();
      }
    }
  }

  void _handleCropResult(CropResult result) {
    if (result is CropSuccess) {
      _onCropped(result.croppedImage);
    } else if (result is CropFailure) {
      print('裁剪失败');
      Get.back();
    }
  }

  void _onCancel() {
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Stack(
            children: [
              Container(
            margin: EdgeInsets.only(left: 22, right: 22,top: 50,bottom: 50),
            color: Colors.black,
            child: Stack(
              children: [
                // 裁剪区域
                if (_imageData != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 0,
                      // vertical: 100,
                    ),
                    child: Crop(
                      image: _imageData!,
                      controller: _cropController,
                      onCropped: _handleCropResult,
                      aspectRatio: 1.0, // 正方形
                      withCircleUi: false, // 使用方形裁剪框
                      baseColor: Colors.black,
                      maskColor: Colors.black.withOpacity(0.6),
                      radius: 0, // 裁剪框圆角
                      cornerDotBuilder: (size, edgeAlignment) {
                        // 如果有自定义裁剪框图片，隐藏默认角点
                        if (widget.customCropFrameAsset != null) {
                          return Container(); // 隐藏角点
                        }
                        // 自定义裁剪框角点
                        return const DotControl(color: Colors.blue);
                      },
                      interactive: true,
                    ),
                  ),

                // 自定义裁剪框装饰图片（覆盖在上方，仅作为视觉引导）
                if (widget.customCropFrameAsset != null)
                  Center(
                    child: IgnorePointer(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // 计算裁剪框大小（与 Crop 组件的 padding 保持一致）
                          final size = constraints.maxWidth ;
                          return SizedBox(
                            width: size,
                            height: size,
                            child: Image.asset(
                              widget.customCropFrameAsset!,
                              fit: BoxFit.contain,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                
                 
               ],
            ),
   
          ),
          
            Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Container(
                     
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.5),
                            Colors.black.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          // 取消按钮
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isCropping ? null : _onCancel,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                side: const BorderSide(
                                  color: Colors.transparent,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                '取消',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // 确认裁剪按钮
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isCropping ? null : _onCrop,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                backgroundColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: _isCropping
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      '完成',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          )
             
           );
  }
}
