package com.example.flutter_pag_plugin;

import android.content.Context;
import android.graphics.SurfaceTexture;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.Surface;

import androidx.annotation.NonNull;

import org.libpag.PAGFile;
import org.libpag.PAGLayer;
import org.libpag.PAGSurface;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
// 移除v1 embedding依赖
// import io.flutter.plugin.common.PluginRegistry;
// import io.flutter.view.FlutterNativeView;
import io.flutter.view.TextureRegistry;
import kotlin.Unit;
import kotlin.jvm.functions.Function1;

/**
 * FlutterPagPlugin
 */
public class FlutterPagPlugin implements FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private MethodChannel channel;
    TextureRegistry textureRegistry;
    Context context;
    // 移除v1 embedding变量
    // io.flutter.plugin.common.PluginRegistry.Registrar registrar;
    FlutterPlugin.FlutterAssets flutterAssets;
    private Handler handler = new Handler(Looper.getMainLooper());

    // 多引擎使用是plugin的集合，请留意该场景下需手动释放，否则存在内存泄漏的问题
    public static List<FlutterPagPlugin> pluginList = new ArrayList<FlutterPagPlugin>();

    public HashMap<String, FlutterPagPlayer> layerMap = new HashMap<String, FlutterPagPlayer>();
    public HashMap<String, TextureRegistry.SurfaceTextureEntry> entryMap = new HashMap<String, TextureRegistry.SurfaceTextureEntry>();
    public LinkedList<String>  freeEntryPool = new LinkedList<>();

    // 原生接口
    final static String _nativeInit = "initPag";
    final static String _nativeRelease = "release";
    final static String _nativeStart = "start";
    final static String _nativeStop = "stop";
    final static String _nativePause = "pause";
    final static String _nativeSetProgress = "setProgress";
    final static String _nativeGetPointLayer = "getLayersUnderPoint";
    final static String _nativeEnableCache = "enableCache";
    final static String _nativeSetCacheSize = "setCacheSize";
    final static String _nativeEnableMultiThread = "enableMultiThread";


    // 参数
    final static String _argumentTextureId = "textureId";
    final static String _argumentAssetName = "assetName";
    final static String _argumentPackage = "package";
    final static String _argumentUrl = "url";
    final static String _argumentBytes = "bytesData";
    final static String _argumentRepeatCount = "repeatCount";
    final static String _argumentInitProgress = "initProgress";
    final static String _argumentAutoPlay = "autoPlay";
    final static String _argumentWidth = "width";
    final static String _argumentHeight = "height";
    final static String _argumentPointX = "x";
    final static String _argumentPointY = "y";
    final static String _argumentProgress = "progress";
    final static String _argumentEvent = "PAGEvent";
    final static String _argumentCacheEnabled = "cacheEnabled";
    final static String _argumentCacheSize = "cacheSize";
    final static String _argumentMultiThreadEnabled = "multiThreadEnabled";

    // 回调
    final static String _playCallback = "PAGCallback";
    final static String _eventStart = "onAnimationStart";
    final static String _eventEnd = "onAnimationEnd";
    final static String _eventCancel = "onAnimationCancel";
    final static String _eventRepeat = "onAnimationRepeat";
    final static String _eventUpdate = "onAnimationUpdate";

    private boolean useCache = true;
    private int maxFreePoolSize = 10;

    public FlutterPagPlugin() {
    }

    // 移除v1 embedding构造函数
    // public FlutterPagPlugin(io.flutter.plugin.common.PluginRegistry.Registrar registrar) {
    //     pluginList.add(this);
    //     this.registrar = registrar;
    //     textureRegistry = registrar.textures();
    //     context = registrar.context();
    //     DataLoadHelper.INSTANCE.initDiskCache(context, DataLoadHelper.INSTANCE.DEFAULT_DIS_SIZE);
    // }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        if (!pluginList.contains(this)) {
            pluginList.add(this);
        }
        flutterAssets = binding.getFlutterAssets();
        channel = new MethodChannel(binding.getBinaryMessenger(), "flutter_pag_plugin");
        channel.setMethodCallHandler(this);
        context = binding.getApplicationContext();
        textureRegistry = binding.getTextureRegistry();
        DataLoadHelper.INSTANCE.initDiskCache(context, DataLoadHelper.INSTANCE.DEFAULT_DIS_SIZE);
    }

    // 移除v1 embedding注册方法
    // public static void registerWith(io.flutter.plugin.common.PluginRegistry.Registrar registrar) {
    //     final FlutterPagPlugin plugin = new FlutterPagPlugin(registrar);
    //     registrar.addViewDestroyListener(new PluginRegistry.ViewDestroyListener() {
    //         @Override
    //         public boolean onViewDestroy(FlutterNativeView flutterNativeView) {
    //             plugin.onDestroy();
    //             pluginList.remove(this);
    //             return false; // We are not interested in assuming ownership of the NativeView.
    //         }
    //     });
    // }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        switch (call.method) {
            case _nativeInit:
                initPag(call, result);
                break;
            case _nativeStart:
                start(call);
                result.success("");
                break;
            case _nativeStop:
                stop(call);
                result.success("");
                break;
            case _nativePause:
                pause(call);
                result.success("");
                break;
            case _nativeSetProgress:
                setProgress(call);
                result.success("");
                break;
            case _nativeRelease:
                release(call);
                result.success("");
                break;
            case _nativeGetPointLayer:
                result.success(getLayersUnderPoint(call));
                break;
            case _nativeEnableCache:
                enableCache(call);
                result.success("");
                break;
            case _nativeSetCacheSize:
                setCacheSize(call);
                result.success("");
                break;
            case _nativeEnableMultiThread:
                enableMultiThread(call);
                result.success("");
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    private void enableCache(final MethodCall call) {
        useCache = call.argument(_argumentCacheEnabled);
    }

    private void setCacheSize(final MethodCall call) {
        maxFreePoolSize = call.argument(_argumentCacheSize);
    }

    private void enableMultiThread(final MethodCall call) {
        WorkThreadExecutor.getInstance().enableMultiThread(call.argument(_argumentMultiThreadEnabled));
    }


    private void initPag(final MethodCall call, final Result result) {
        String assetName = call.argument(_argumentAssetName);
        byte[] bytes = call.argument(_argumentBytes);
        String url = call.argument(_argumentUrl);
        String flutterPackage = call.argument(_argumentPackage);

        if (bytes != null) {
            initPagPlayerAndCallback(PAGFile.Load(bytes), call, result);
        } else if (assetName != null) {
            String assetKey;
            // 只使用v2 embedding的flutterAssets
            if (flutterAssets != null) {
                if (flutterPackage == null || flutterPackage.isEmpty()) {
                    assetKey = flutterAssets.getAssetFilePathByName(assetName);
                } else {
                    assetKey = flutterAssets.getAssetFilePathByName(assetName, flutterPackage);
                }
            } else {
                assetKey = "";
            }

            if (assetKey == null) {
                result.error("-1100", "asset资源加载错误", null);
                return;
            }
            WorkThreadExecutor.getInstance().post(() -> {
                PAGFile composition = PAGFile.Load(context.getAssets(), assetKey);
                handler.post(() -> initPagPlayerAndCallback(composition, call, result));
            });
        } else if (url != null) {
            DataLoadHelper.INSTANCE.loadPag(url, new Function1<byte[], Unit>() {
                @Override
                public Unit invoke(final byte[] bytes) {
                    handler.post(new Runnable() {
                        @Override
                        public void run() {
                            if (bytes == null) {
                                result.error("-1100", "url资源加载错误", null);
                                return;
                            }

                            initPagPlayerAndCallback(PAGFile.Load(bytes), call, result);
                        }
                    });

                    return null;
                }
            }, DataLoadHelper.FROM_PLUGIN);
        } else {
            result.error("-1100", "未添加资源", null);
        }
    }

    private void initPagPlayerAndCallback(PAGFile composition, MethodCall call, final Result result) {
        if (composition == null) {
            result.error("-1100", "load composition is null! ", null);
            return;
        }

        final int repeatCount = call.argument(_argumentRepeatCount);
        final double initProgress = call.argument(_argumentInitProgress);
        final boolean autoPlay = call.argument(_argumentAutoPlay);
        final FlutterPagPlayer pagPlayer;
        final String currentId;
        if (freeEntryPool.isEmpty() || !useCache) {
            pagPlayer = new FlutterPagPlayer();
            final TextureRegistry.SurfaceTextureEntry entry = textureRegistry.createSurfaceTexture();
            currentId = String.valueOf(entry.id());
            entryMap.put(String.valueOf(entry.id()), entry);
            SurfaceTexture surfaceTexture = entry.surfaceTexture();

            final Surface surface = new Surface(surfaceTexture);
            final PAGSurface pagSurface = PAGSurface.FromSurface(surface);
            pagPlayer.setSurface(pagSurface);
            pagPlayer.setSurfaceTexture(surfaceTexture);
            layerMap.put(String.valueOf(entry.id()), pagPlayer);
        } else {
            currentId = freeEntryPool.removeFirst();
            pagPlayer = layerMap.get(currentId);
            if (pagPlayer == null) {
                result.error("-1101", "id异常，未命中缓存！", null);
                return;
            }
            if (pagPlayer.isRelease()) {
                result.error("-1102", "PagPlayer异常！", null);
                return;
            }
        }

        WorkThreadExecutor.getInstance().post(() -> {
            pagPlayer.updateBufferSize(composition.width(), composition.height());
            pagPlayer.init(composition, repeatCount, initProgress, channel, Long.parseLong(currentId));
            final HashMap<String, Object> callback = new HashMap<String, Object>();
            callback.put(_argumentTextureId, Long.parseLong(currentId));
            callback.put(_argumentWidth, (double) composition.width());
            callback.put(_argumentHeight, (double) composition.height());
            pagPlayer.flush();

            handler.post(new Runnable() {
                @Override
                public void run() {
                    if (autoPlay) {
                        pagPlayer.start();
                    }
                    result.success(callback);
                }
            });
        });
    }

    void start(MethodCall call) {
        FlutterPagPlayer flutterPagPlayer = getFlutterPagPlayer(call);
        if (flutterPagPlayer != null) {
            flutterPagPlayer.start();
        }
    }

    void stop(MethodCall call) {
        FlutterPagPlayer flutterPagPlayer = getFlutterPagPlayer(call);
        if (flutterPagPlayer != null) {
            flutterPagPlayer.stop();
        }
    }

    void pause(MethodCall call) {
        FlutterPagPlayer flutterPagPlayer = getFlutterPagPlayer(call);
        if (flutterPagPlayer != null) {
            flutterPagPlayer.pause();
        }
    }

    void setProgress(MethodCall call) {
        double progress = call.argument(_argumentProgress);
        FlutterPagPlayer flutterPagPlayer = getFlutterPagPlayer(call);
        if (flutterPagPlayer != null) {
            flutterPagPlayer.setProgressValue(progress);
        }
    }

    void release(MethodCall call) {
        if (useCache && freeEntryPool.size() < maxFreePoolSize) {
            FlutterPagPlayer flutterPagPlayer = layerMap.get(getTextureId(call));
            int id = call.argument(_argumentTextureId);
            if (flutterPagPlayer != null) {
                flutterPagPlayer.cancel();
                WorkThreadExecutor.getInstance().post(() -> {
                    flutterPagPlayer.clear();
                    if (id >= 0) {
                        handler.post(() -> {
                            freeEntryPool.add(id + "");
                        });
                    }
                });
            }
        } else {
            FlutterPagPlayer flutterPagPlayer = layerMap.remove(getTextureId(call));
            if (flutterPagPlayer != null) {
                flutterPagPlayer.stop();
                flutterPagPlayer.release();
            }

            TextureRegistry.SurfaceTextureEntry entry = entryMap.remove(getTextureId(call));
            if (entry != null) {
                entry.release();
            }
        }
    }

    List<String> getLayersUnderPoint(MethodCall call) {
        FlutterPagPlayer flutterPagPlayer = getFlutterPagPlayer(call);

        List<String> layerNames = new ArrayList<>();
        PAGLayer[] layers = null;
        if (flutterPagPlayer != null) {
            layers = flutterPagPlayer.getLayersUnderPoint(
                    ((Double) call.argument(_argumentPointX)).floatValue(), ((Double) call.argument(_argumentPointY)).floatValue());
        }

        if (layers != null) {
            for (PAGLayer layer : layers) {
                layerNames.add(layer.layerName());
            }
        }

        return layerNames;
    }

    FlutterPagPlayer getFlutterPagPlayer(MethodCall call) {
        return layerMap.get(getTextureId(call));
    }

    String getTextureId(MethodCall call) {
        return "" + call.argument(_argumentTextureId);
    }

    //插件销毁
    public void onDestroy() {
        releaseAll();
        channel.setMethodCallHandler(null);
    }

    // 释放全部资源
    public void releaseAll() {
        for (FlutterPagPlayer pagPlayer : layerMap.values()) {
            pagPlayer.release();
        }
        for (TextureRegistry.SurfaceTextureEntry entry : entryMap.values()) {
            entry.release();
        }
        freeEntryPool.clear();
        layerMap.clear();
        entryMap.clear();
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        onDestroy();
    }
}
