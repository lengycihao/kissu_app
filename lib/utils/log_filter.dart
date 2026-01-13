import 'dart:io';
import 'package:kissu_app/network/tools/logging/logging.dart';

class LogFilter {
  static bool _isInitialized = false;
  
  /// 初始化日志过滤
  static void initialize() {
    if (_isInitialized) return;
    
    if (Platform.isAndroid) {
      _setupAndroidLogFilter();
    }
    
    _isInitialized = true;
  }
  
  /// 设置Android日志过滤
  static void _setupAndroidLogFilter() {
    try {
      // 设置系统属性来减少媒体编解码器的调试日志
      // 这些设置会在MainActivity中应用
      logDebug('🔧 日志过滤配置已初始化');
    } catch (e) {
      logWarning('⚠️ 日志过滤配置失败: $e');
    }
  }
  
  /// 过滤日志输出
  static void filterLog(String message) {
    // 过滤掉不需要的日志
    if (message.contains('TraceLog') ||
        message.contains('MediaCodec') ||
        message.contains('BufferPoolAccessor') ||
        message.contains('MetadataUtil') ||
        message.contains('Codec2Client') ||
        message.contains('CCodecConfig') ||
        message.contains('IHnMediaCodecService') ||
        message.contains('onQueueInputBuffer') ||
        message.contains('onReleaseOutputBuffer') ||
        message.contains('onMessageReceived') ||
        message.contains('c2.qti.avc.decoder') ||
        message.contains('c2.android.aac.decoder') ||
        message.contains('c2.android.avc.decoder') ||
        message.contains('Queued:') ||
        message.contains('Done:') ||
        message.contains('Rendered:') ||
        message.contains('Discarded:') ||
        message.contains('Skipped unknown metadata entry') ||
        message.contains('NoSupport') ||
        message.contains('query failed') ||
        message.contains('param skipped') ||
        message.contains('getSdrPlusStateFromSystem') ||
        message.contains('isSdrPlusWhiteList') ||
        message.contains('bufferpool2') ||
        message.contains('MediaCodec::') ||
        message.contains('keep callback message') ||
        message.contains('enter') ||
        message.contains('exit') ||
        message.contains('BAD_INDEX') ||
        message.contains('frameIndex not found') ||
        message.contains('flush()') ||
        message.contains('start(') ||
        message.contains('reclaim') ||
        message.contains('PipelineWatcher')) {
      return; // 不输出这些日志
    }
    
    // 输出其他日志
    logDebug(message);
  }
  
  /// 检查是否应该过滤日志
  static bool shouldFilter(String message) {
    return message.contains('TraceLog') ||
           message.contains('MediaCodec') ||
           message.contains('BufferPoolAccessor') ||
           message.contains('MetadataUtil') ||
           message.contains('Codec2Client') ||
           message.contains('CCodecConfig') ||
           message.contains('IHnMediaCodecService') ||
           message.contains('onQueueInputBuffer') ||
           message.contains('onReleaseOutputBuffer') ||
           message.contains('onMessageReceived') ||
           message.contains('c2.qti.avc.decoder') ||
           message.contains('c2.android.aac.decoder') ||
           message.contains('c2.android.avc.decoder') ||
           message.contains('Queued:') ||
           message.contains('Done:') ||
           message.contains('Rendered:') ||
           message.contains('Discarded:') ||
           message.contains('Skipped unknown metadata entry') ||
           message.contains('NoSupport') ||
           message.contains('query failed') ||
           message.contains('param skipped') ||
           message.contains('getSdrPlusStateFromSystem') ||
           message.contains('isSdrPlusWhiteList') ||
           message.contains('bufferpool2') ||
           message.contains('MediaCodec::') ||
           message.contains('keep callback message') ||
           message.contains('enter') ||
           message.contains('exit') ||
           message.contains('BAD_INDEX') ||
           message.contains('frameIndex not found') ||
           message.contains('flush()') ||
           message.contains('start(') ||
           message.contains('reclaim') ||
           message.contains('PipelineWatcher');
  }
}
