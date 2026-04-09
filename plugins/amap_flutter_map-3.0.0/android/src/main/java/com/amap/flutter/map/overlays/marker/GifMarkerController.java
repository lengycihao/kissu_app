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
    private volatile boolean isReleased = false; // 🎯 标记控制器是否已被释放
    private volatile int loadVersion = 0; // 🎯 加载版本号，用于防止旧的异步加载覆盖新的加载
    
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
        // 🎯 每次加载都增加版本号，用于取消旧的加载
        final int currentLoadVersion = ++loadVersion;
         
        // 🎯 不再跳过重复请求，而是让新的加载取代旧的
        // if (isLoading) {
        //     LogUtil.i(TAG, "GIF正在加载中，跳过重复请求");
        //     return;
        // }
        
        // 先检查缓存
        GifFrameCache cache = GifFrameCache.getInstance();
        if (cache.isCached(assetPath, targetWidth, targetHeight)) {
             GifFrameCache.CachedGif cached = cache.getCached(assetPath, targetWidth, targetHeight);
            if (cached != null) {
                synchronized (this) {
                    // 🎯 检查版本号，如果已经有新的加载，跳过
                    if (currentLoadVersion != loadVersion) {
                         return;
                    }
                    frames.clear();
                    delays.clear();
                    // 直接引用缓存的帧（不复制，节省内存）
                    frames.addAll(cached.frames);
                    delays.addAll(cached.delays);
                    // 标记使用缓存帧，release时不回收这些帧
                    isUsingCachedFrames = true;
                }
                
                handler.post(() -> {
                    // 🎯 再次检查版本号
                    if (currentLoadVersion != loadVersion) {
                         return;
                    }
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
        isReleased = false; // 🎯 重置释放标志
        final long startTime = System.currentTimeMillis();
        
        executor.execute(() -> {
            // 🎯 在加载前检查版本号
            if (currentLoadVersion != loadVersion) {
                 isLoading = false;
                return;
            }
            
            boolean success = loadGifFromAssetInternal(assetPath, currentLoadVersion);
            long elapsed = System.currentTimeMillis() - startTime;
            
            isLoading = false;
            
            // 🎯 检查版本号，如果已经有新的加载，跳过
            if (currentLoadVersion != loadVersion) {
                return;
            }
            
            // 🎯 如果控制器已被释放，不要继续操作
            if (isReleased) {
                 return;
            }
            
            // 在主线程回调
            handler.post(() -> {
                // 🎯 再次检查版本号和释放状态
                if (currentLoadVersion != loadVersion) {

                    return;
                }
                if (isReleased) {

                    return;
                }
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
     * @param expectedVersion 期望的加载版本号，用于检测是否被新加载取代
     * @return 是否加载成功
     */
    private boolean loadGifFromAssetInternal(String assetPath, int expectedVersion) {
        try {
            // 获取Flutter asset的实际路径
            String lookupKey = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(assetPath);
            InputStream inputStream = context.getAssets().open(lookupKey);
            
            // 解析GIF
            GifDecoder decoder = new GifDecoder();
            int status = decoder.read(inputStream);
            
            if (status != GifDecoder.STATUS_OK) {
                return false;
            }
            
            // 🎯 解析完成后检查版本号
            if (expectedVersion != loadVersion) {
                inputStream.close();
                return false;
            }
            
            // 提取所有帧
            List<Bitmap> newFrames = new ArrayList<>();
            List<Integer> newDelays = new ArrayList<>();
            
            int frameCount = decoder.getFrameCount();
            
            for (int i = 0; i < frameCount; i++) {
                // 🎯 每隔一段时间检查版本号，避免浪费资源
                if (i % 50 == 0 && expectedVersion != loadVersion) {
                    // 回收已提取的帧
                    for (Bitmap bitmap : newFrames) {
                        if (bitmap != null && !bitmap.isRecycled()) {
                            bitmap.recycle();
                        }
                    }
                    inputStream.close();
                    return false;
                }
                
                Bitmap frame = decoder.getFrame(i);
                if (frame != null) {
                    // 复制Bitmap，因为decoder会复用内存
                    Bitmap copiedFrame = frame.copy(Bitmap.Config.ARGB_8888, false);
                    
                    // 如果设置了目标尺寸，进行缩放
                    if (targetWidth > 0 && targetHeight > 0) {
                        Bitmap scaledFrame = Bitmap.createScaledBitmap(copiedFrame, targetWidth, targetHeight, true);
                        // 🎯 关键修复：createScaledBitmap 如果尺寸相同会返回原始bitmap
                        // 只有当 scaledFrame 与 copiedFrame 不是同一个对象时才回收 copiedFrame
                        if (scaledFrame != copiedFrame) {
                            copiedFrame.recycle();
                        }
                        newFrames.add(scaledFrame);
                    } else {
                        newFrames.add(copiedFrame);
                    }
                    newDelays.add(decoder.getDelay(i));
                }
            }
            
            inputStream.close();
            
            // 🎯 最终检查版本号
            if (expectedVersion != loadVersion) {
                for (Bitmap bitmap : newFrames) {
                    if (bitmap != null && !bitmap.isRecycled()) {
                        bitmap.recycle();
                    }
                }
                return false;
            }
            
            // 替换帧数据（线程安全）
            // 🎯 先保存旧帧引用，替换后再回收，避免在加载过程中帧被意外回收
            List<Bitmap> oldFrames;
            synchronized (this) {
                // 🎯 在同步块内再次检查版本号
                if (expectedVersion != loadVersion) {

                    for (Bitmap bitmap : newFrames) {
                        if (bitmap != null && !bitmap.isRecycled()) {
                            bitmap.recycle();
                        }
                    }
                    return false;
                }
                
                oldFrames = new ArrayList<>(frames);
                frames.clear();
                delays.clear();
                
                frames.addAll(newFrames);
                delays.addAll(newDelays);
                // 🎯 标记为非缓存帧（新加载的帧）
                isUsingCachedFrames = false;
            }
            
            // 🎯 在替换完成后再回收旧帧（如果不是缓存帧）
            for (Bitmap bitmap : oldFrames) {
                if (bitmap != null && !bitmap.isRecycled()) {
                    bitmap.recycle();
                }
            }
            oldFrames.clear();
            

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
        // 🎯 同步加载时使用当前版本号
        return loadGifFromAssetInternal(assetPath, loadVersion);
    }
    
    /**
     * 开始播放GIF动画
     */
    public void startAnimation() {
        // 🎯 如果已被释放，不要开始播放
        if (isReleased || frames.isEmpty() || isPlaying) {
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
                    // 🎯 检查bitmap是否已被回收，避免在已回收的bitmap上操作
                    if (currentBitmap == null || currentBitmap.isRecycled()) {
                        LogUtil.e(TAG, "GIF帧已被回收，停止播放: frame=" + currentFrame, null);
                        isPlaying = false;
                        return;
                    }
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
        // 🎯 标记为已释放，阻止异步加载完成后的操作
        isReleased = true;
        // 🎯 增加版本号，取消正在进行的异步加载
        loadVersion++;
        
        stopAnimation();
        
        // 只有非缓存的帧才能回收，缓存的帧由GifFrameCache管理
        if (!isUsingCachedFrames) {
            synchronized (this) {
                for (Bitmap bitmap : frames) {
                    if (bitmap != null && !bitmap.isRecycled()) {
                        bitmap.recycle();
                    }
                }
                frames.clear();
                delays.clear();
            }

        } else {
            synchronized (this) {
                frames.clear();
                delays.clear();
            }

        }
        
        isUsingCachedFrames = false;
    }
    
    /**
     * 是否正在播放
     */
    public boolean isPlaying() {
        return isPlaying;
    }
}
