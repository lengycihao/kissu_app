package com.amap.flutter.map.overlays.marker;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Handler;
import android.os.Looper;

import com.amap.api.maps.model.BitmapDescriptor;
import com.amap.api.maps.model.BitmapDescriptorFactory;
import com.amap.api.maps.model.Marker;
import com.amap.flutter.map.utils.LogUtil;

import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.flutter.FlutterInjector;

/**
 * GIF动画Marker控制器
 * 
 * 负责解析GIF文件并在Marker上播放帧动画
 * 
 * @author cascade
 * @date 2024/12/27
 */
public class GifMarkerController {
    private static final String TAG = "GifMarkerController";
    
    private final Context context;
    private final Marker marker;
    private final Handler handler;
    
    private List<Bitmap> frames;
    private List<Integer> delays;
    private int currentFrame = 0;
    private boolean isPlaying = false;
    private Runnable frameRunnable;
    private int targetWidth = 0;  // 目标宽度，0表示使用原始尺寸
    private int targetHeight = 0; // 目标高度，0表示使用原始尺寸
    private boolean isLoading = false;
    private OnLoadCompleteListener loadCompleteListener;
    private boolean isUsingCachedFrames = false; // 标记是否使用缓存的帧（缓存帧不能回收）
    
    // 静态线程池，用于异步加载GIF
    private static final ExecutorService executor = Executors.newSingleThreadExecutor();
    
    public interface OnLoadCompleteListener {
        void onLoadComplete(boolean success);
    }
    
    public GifMarkerController(Context context, Marker marker) {
        this.context = context;
        this.marker = marker;
        this.handler = new Handler(Looper.getMainLooper());
        this.frames = new ArrayList<>();
        this.delays = new ArrayList<>();
    }
    
    /**
     * 设置加载完成监听器
     */
    public void setOnLoadCompleteListener(OnLoadCompleteListener listener) {
        this.loadCompleteListener = listener;
    }
    
    /**
     * 设置GIF显示尺寸
     * 
     * @param width 目标宽度（像素），0表示使用原始尺寸
     * @param height 目标高度（像素），0表示使用原始尺寸
     */
    public void setSize(int width, int height) {
        this.targetWidth = width;
        this.targetHeight = height;
    }
    
    /**
     * 从Flutter assets异步加载GIF文件
     * 
     * @param assetPath Flutter asset路径 (如: assets/gif/ceshi.gif)
     */
    public void loadGifFromAssetAsync(String assetPath) {
        if (isLoading) {
            LogUtil.i(TAG, "GIF正在加载中，跳过重复请求");
            return;
        }
        
        // 先检查缓存
        GifFrameCache cache = GifFrameCache.getInstance();
        if (cache.isCached(assetPath, targetWidth, targetHeight)) {
            LogUtil.i(TAG, "✅ 使用缓存的GIF帧数据");
            GifFrameCache.CachedGif cached = cache.getCached(assetPath, targetWidth, targetHeight);
            if (cached != null) {
                synchronized (this) {
                    frames.clear();
                    delays.clear();
                    // 直接引用缓存的帧（不复制，节省内存）
                    frames.addAll(cached.frames);
                    delays.addAll(cached.delays);
                    // 标记使用缓存帧，release时不回收这些帧
                    isUsingCachedFrames = true;
                }
                
                handler.post(() -> {
                    if (loadCompleteListener != null) {
                        loadCompleteListener.onLoadComplete(true);
                    }
                    startAnimation();
                });
                return;
            }
        }
        
        // 非缓存模式
        isUsingCachedFrames = false;
        
        isLoading = true;
        final long startTime = System.currentTimeMillis();
        
        executor.execute(() -> {
            boolean success = loadGifFromAssetInternal(assetPath);
            long elapsed = System.currentTimeMillis() - startTime;
            LogUtil.i(TAG, "GIF异步加载完成，耗时: " + elapsed + "ms, 成功: " + success);
            
            isLoading = false;
            
            // 在主线程回调
            handler.post(() -> {
                if (loadCompleteListener != null) {
                    loadCompleteListener.onLoadComplete(success);
                }
                // 加载成功后自动开始播放
                if (success) {
                    startAnimation();
                }
            });
        });
    }
    
    /**
     * 从Flutter assets同步加载GIF文件（内部方法）
     * 
     * @param assetPath Flutter asset路径 (如: assets/gif/ceshi.gif)
     * @return 是否加载成功
     */
    private boolean loadGifFromAssetInternal(String assetPath) {
        try {
            // 获取Flutter asset的实际路径
            String lookupKey = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(assetPath);
            InputStream inputStream = context.getAssets().open(lookupKey);
            
            // 解析GIF
            GifDecoder decoder = new GifDecoder();
            int status = decoder.read(inputStream);
            
            if (status != GifDecoder.STATUS_OK) {
                LogUtil.e(TAG, "GIF解析失败，状态码: " + status, null);
                return false;
            }
            
            // 提取所有帧
            List<Bitmap> newFrames = new ArrayList<>();
            List<Integer> newDelays = new ArrayList<>();
            
            int frameCount = decoder.getFrameCount();
            LogUtil.i(TAG, "GIF帧数: " + frameCount);
            
            for (int i = 0; i < frameCount; i++) {
                Bitmap frame = decoder.getFrame(i);
                if (frame != null) {
                    // 复制Bitmap，因为decoder会复用内存
                    Bitmap copiedFrame = frame.copy(Bitmap.Config.ARGB_8888, false);
                    
                    // 如果设置了目标尺寸，进行缩放
                    if (targetWidth > 0 && targetHeight > 0) {
                        Bitmap scaledFrame = Bitmap.createScaledBitmap(copiedFrame, targetWidth, targetHeight, true);
                        copiedFrame.recycle();
                        newFrames.add(scaledFrame);
                    } else {
                        newFrames.add(copiedFrame);
                    }
                    newDelays.add(decoder.getDelay(i));
                }
            }
            
            inputStream.close();
            
            // 替换帧数据（线程安全）
            synchronized (this) {
                // 释放旧帧
                for (Bitmap bitmap : frames) {
                    if (bitmap != null && !bitmap.isRecycled()) {
                        bitmap.recycle();
                    }
                }
                frames.clear();
                delays.clear();
                
                frames.addAll(newFrames);
                delays.addAll(newDelays);
            }
            
            LogUtil.i(TAG, "GIF加载成功，共 " + frames.size() + " 帧");
            return frames.size() > 0;
            
        } catch (Exception e) {
            LogUtil.e(TAG, "加载GIF失败: " + assetPath, e);
            return false;
        }
    }
    
    /**
     * 从Flutter assets同步加载GIF文件（保留兼容性）
     * 
     * @param assetPath Flutter asset路径 (如: assets/gif/ceshi.gif)
     * @return 是否加载成功
     */
    public boolean loadGifFromAsset(String assetPath) {
        return loadGifFromAssetInternal(assetPath);
    }
    
    /**
     * 开始播放GIF动画
     */
    public void startAnimation() {
        if (frames.isEmpty() || isPlaying) {
            return;
        }
        
        isPlaying = true;
        currentFrame = 0;
        
        frameRunnable = new Runnable() {
            @Override
            public void run() {
                if (!isPlaying || frames.isEmpty()) {
                    return;
                }
                
                try {
                    // 更新Marker图标
                    Bitmap currentBitmap = frames.get(currentFrame);
                    BitmapDescriptor descriptor = BitmapDescriptorFactory.fromBitmap(currentBitmap);
                    marker.setIcon(descriptor);
                    
                    // 获取当前帧延迟
                    int delay = delays.get(currentFrame);
                    if (delay < 20) {
                        delay = 100; // 最小延迟100ms
                    }
                    
                    // 调试日志（每10帧输出一次）
                    if (currentFrame % 10 == 0) {
                        // LogUtil.i(TAG, "GIF播放中: 帧=" + currentFrame + "/" + frames.size() + ", 延迟=" + delay + "ms");
                    }
                    
                    // 移动到下一帧
                    currentFrame = (currentFrame + 1) % frames.size();
                    
                    // 继续播放
                    handler.postDelayed(this, delay);
                    
                } catch (Exception e) {
                    LogUtil.e(TAG, "播放GIF帧失败", e);
                }
            }
        };
        
        handler.post(frameRunnable);
        LogUtil.i(TAG, "GIF动画开始播放");
    }
    
    /**
     * 停止播放GIF动画
     */
    public void stopAnimation() {
        isPlaying = false;
        if (frameRunnable != null) {
            handler.removeCallbacks(frameRunnable);
        }
        LogUtil.i(TAG, "GIF动画已停止");
    }
    
    /**
     * 释放资源
     */
    public void release() {
        stopAnimation();
        
        // 只有非缓存的帧才能回收，缓存的帧由GifFrameCache管理
        if (!isUsingCachedFrames) {
            for (Bitmap bitmap : frames) {
                if (bitmap != null && !bitmap.isRecycled()) {
                    bitmap.recycle();
                }
            }
            LogUtil.i(TAG, "已回收非缓存GIF帧资源");
        } else {
            LogUtil.i(TAG, "使用缓存帧，跳过回收（由GifFrameCache管理）");
        }
        
        frames.clear();
        delays.clear();
        isUsingCachedFrames = false;
    }
    
    /**
     * 是否正在播放
     */
    public boolean isPlaying() {
        return isPlaying;
    }
}
