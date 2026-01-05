package com.amap.flutter.map.overlays.marker;

import android.content.Context;
import android.graphics.Bitmap;

import com.amap.flutter.map.utils.LogUtil;

import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.flutter.FlutterInjector;

/**
 * GIF帧缓存管理器（单例）
 * 
 * 用于预加载和缓存GIF帧数据，避免每次进入页面都重新解码
 * 
 * @author cascade
 * @date 2024/12/27
 */
public class GifFrameCache {
    private static final String TAG = "GifFrameCache";
    
    private static volatile GifFrameCache instance;
    
    // 缓存：assetPath -> CachedGif
    private final Map<String, CachedGif> cache = new ConcurrentHashMap<>();
    
    // 正在加载的资源
    private final Map<String, Boolean> loadingAssets = new ConcurrentHashMap<>();
    
    // 线程池
    private final ExecutorService executor = Executors.newSingleThreadExecutor();
    
    /**
     * 缓存的GIF数据
     */
    public static class CachedGif {
        public final List<Bitmap> frames;
        public final List<Integer> delays;
        public final int width;
        public final int height;
        
        public CachedGif(List<Bitmap> frames, List<Integer> delays, int width, int height) {
            this.frames = frames;
            this.delays = delays;
            this.width = width;
            this.height = height;
        }
    }
    
    private GifFrameCache() {}
    
    public static GifFrameCache getInstance() {
        if (instance == null) {
            synchronized (GifFrameCache.class) {
                if (instance == null) {
                    instance = new GifFrameCache();
                }
            }
        }
        return instance;
    }
    
    /**
     * 生成缓存key
     */
    private String getCacheKey(String assetPath, int width, int height) {
        return assetPath + "_" + width + "x" + height;
    }
    
    /**
     * 检查是否已缓存（同时验证帧有效性）
     */
    public boolean isCached(String assetPath, int width, int height) {
        String key = getCacheKey(assetPath, width, height);
        CachedGif cached = cache.get(key);
        if (cached == null) {
            return false;
        }
        // 🎯 检查帧是否有效，如果已被回收则清除缓存
        if (!isFramesValid(cached)) {
            LogUtil.e(TAG, "⚠️ isCached: 缓存的GIF帧已被回收，清除无效缓存: " + key, null);
            cache.remove(key);
            return false;
        }
        return true;
    }
    
    /**
     * 获取缓存的GIF
     * 🎯 增加帧有效性检查，如果帧已被回收则清除缓存并返回null
     */
    public CachedGif getCached(String assetPath, int width, int height) {
        String key = getCacheKey(assetPath, width, height);
        CachedGif cached = cache.get(key);
        
        // 检查缓存的帧是否有效（未被回收）
        if (cached != null && !isFramesValid(cached)) {
            LogUtil.e(TAG, "⚠️ 缓存的GIF帧已被回收，清除无效缓存: " + key, null);
            cache.remove(key);
            return null;
        }
        
        return cached;
    }
    
    /**
     * 检查缓存的帧是否有效（未被回收）
     */
    private boolean isFramesValid(CachedGif cached) {
        if (cached == null || cached.frames == null || cached.frames.isEmpty()) {
            return false;
        }
        for (Bitmap frame : cached.frames) {
            if (frame == null || frame.isRecycled()) {
                return false;
            }
        }
        return true;
    }
    
    /**
     * 预加载GIF（异步）
     * 
     * @param context Android上下文
     * @param assetPath Flutter asset路径
     * @param width 目标宽度
     * @param height 目标高度
     * @param callback 加载完成回调（可为null）
     */
    public void preload(Context context, String assetPath, int width, int height, PreloadCallback callback) {
        String key = getCacheKey(assetPath, width, height);
        
        // 已缓存，直接回调
        if (cache.containsKey(key)) {
            LogUtil.i(TAG, "GIF已缓存: " + key);
            if (callback != null) {
                callback.onComplete(true);
            }
            return;
        }
        
        // 正在加载中，跳过
        if (loadingAssets.containsKey(key)) {
            LogUtil.i(TAG, "GIF正在加载中: " + key);
            return;
        }
        
        loadingAssets.put(key, true);
        final long startTime = System.currentTimeMillis();
        
        executor.execute(() -> {
            try {
                // 获取Flutter asset的实际路径
                String lookupKey = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(assetPath);
                InputStream inputStream = context.getAssets().open(lookupKey);
                
                // 解析GIF
                GifDecoder decoder = new GifDecoder();
                int status = decoder.read(inputStream);
                
                if (status != GifDecoder.STATUS_OK) {
                    LogUtil.e(TAG, "GIF解析失败: " + assetPath, null);
                    loadingAssets.remove(key);
                    if (callback != null) {
                        callback.onComplete(false);
                    }
                    return;
                }
                
                // 提取所有帧
                List<Bitmap> frames = new ArrayList<>();
                List<Integer> delays = new ArrayList<>();
                
                int frameCount = decoder.getFrameCount();
                
                for (int i = 0; i < frameCount; i++) {
                    Bitmap frame = decoder.getFrame(i);
                    if (frame != null) {
                        Bitmap copiedFrame = frame.copy(Bitmap.Config.ARGB_8888, false);
                        
                        // 缩放
                        if (width > 0 && height > 0) {
                            Bitmap scaledFrame = Bitmap.createScaledBitmap(copiedFrame, width, height, true);
                            copiedFrame.recycle();
                            frames.add(scaledFrame);
                        } else {
                            frames.add(copiedFrame);
                        }
                        delays.add(decoder.getDelay(i));
                    }
                }
                
                inputStream.close();
                
                // 存入缓存
                CachedGif cachedGif = new CachedGif(frames, delays, width, height);
                cache.put(key, cachedGif);
                loadingAssets.remove(key);
                
                long elapsed = System.currentTimeMillis() - startTime;
                LogUtil.i(TAG, "✅ GIF预加载完成: " + key + ", 帧数: " + frames.size() + ", 耗时: " + elapsed + "ms");
                
                if (callback != null) {
                    callback.onComplete(true);
                }
                
            } catch (Exception e) {
                LogUtil.e(TAG, "GIF预加载失败: " + assetPath, e);
                loadingAssets.remove(key);
                if (callback != null) {
                    callback.onComplete(false);
                }
            }
        });
    }
    
    /**
     * 清除指定缓存
     */
    public void clearCache(String assetPath, int width, int height) {
        String key = getCacheKey(assetPath, width, height);
        CachedGif cached = cache.remove(key);
        if (cached != null) {
            for (Bitmap bitmap : cached.frames) {
                if (bitmap != null && !bitmap.isRecycled()) {
                    bitmap.recycle();
                }
            }
            LogUtil.i(TAG, "已清除缓存: " + key);
        }
    }
    
    /**
     * 清除所有缓存
     */
    public void clearAllCache() {
        for (CachedGif cached : cache.values()) {
            for (Bitmap bitmap : cached.frames) {
                if (bitmap != null && !bitmap.isRecycled()) {
                    bitmap.recycle();
                }
            }
        }
        cache.clear();
        LogUtil.i(TAG, "已清除所有GIF缓存");
    }
    
    public interface PreloadCallback {
        void onComplete(boolean success);
    }
}
