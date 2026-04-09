package com.amap.flutter.map.overlays.marker;

import android.content.Context;

import androidx.annotation.NonNull;

import com.amap.flutter.map.utils.LogUtil;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * GIF预加载插件
 * 
 * 提供独立的MethodChannel用于在任何页面预加载GIF
 * 不依赖地图实例
 * 
 * @author cascade
 * @date 2024/12/27
 */
public class GifPreloadPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler {
    private static final String TAG = "GifPreloadPlugin";
    private static final String CHANNEL_NAME = "com.amap.flutter.map.gif_preload";
    
    private MethodChannel channel;
    private Context context;
    
    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        context = binding.getApplicationContext();
        channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL_NAME);
        channel.setMethodCallHandler(this);
        LogUtil.i(TAG, "GIF预加载插件已初始化");
    }
    
    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        if (channel != null) {
            channel.setMethodCallHandler(null);
            channel = null;
        }
        context = null;
    }
    
    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        if ("preloadGif".equals(call.method)) {
            preloadGif(call, result);
        } else {
            result.notImplemented();
        }
    }
    
    private void preloadGif(MethodCall call, MethodChannel.Result result) {
        try {
            String assetPath = call.argument("assetPath");
            Integer width = call.argument("width");
            Integer height = call.argument("height");
            
            if (assetPath == null || assetPath.isEmpty()) {
                result.error("INVALID_ARGUMENT", "assetPath不能为空", null);
                return;
            }
            
            int w = (width != null && width > 0) ? width : 0;
            int h = (height != null && height > 0) ? height : 0;
            
            // 检查是否已缓存
            GifFrameCache cache = GifFrameCache.getInstance();
            if (cache.isCached(assetPath, w, h)) {
                LogUtil.i(TAG, "GIF已缓存，跳过预加载: " + assetPath);
                result.success(true);
                return;
            }
            
            // 异步预加载
            cache.preload(context, assetPath, w, h, success -> {
                LogUtil.i(TAG, "GIF预加载完成: " + assetPath + ", 成功: " + success);
            });
            
            LogUtil.i(TAG, "✅ 启动GIF预加载: " + assetPath + ", 尺寸: " + w + "x" + h);
            result.success(true);
            
        } catch (Exception e) {
            LogUtil.e(TAG, "预加载GIF失败", e);
            result.error("PRELOAD_ERROR", "预加载GIF失败: " + e.getMessage(), null);
        }
    }
}
