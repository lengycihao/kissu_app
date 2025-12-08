package com.amap.flutter.map.overlays.marker;

import android.text.TextUtils;

import androidx.annotation.NonNull;

import com.amap.api.maps.AMap;
import com.amap.api.maps.TextureMapView;
import com.amap.api.maps.model.LatLng;
import com.amap.api.maps.model.Marker;
import com.amap.api.maps.model.MarkerOptions;
import com.amap.api.maps.model.Poi;
import com.amap.api.maps.model.Polyline;
import com.amap.flutter.map.MyMethodCallHandler;
import com.amap.flutter.map.overlays.AbstractOverlayController;
import com.amap.flutter.map.utils.Const;
import com.amap.flutter.map.utils.ConvertUtil;
import com.amap.flutter.map.utils.LogUtil;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * @author whm
 * @date 2020/11/6 5:38 PM
 * @mail hongming.whm@alibaba-inc.com
 * @since
 */
public class MarkersController
        extends AbstractOverlayController<MarkerController>
        implements MyMethodCallHandler,
        AMap.OnMapClickListener,
        AMap.OnMarkerClickListener,
        AMap.OnMarkerDragListener,
        AMap.OnPOIClickListener {
    private static final String CLASS_NAME = "MarkersController";
    private String selectedMarkerDartId;
    private CustomInfoWindowAdapter customInfoWindowAdapter;

    public MarkersController(MethodChannel methodChannel, AMap amap, android.content.Context context) {
        super(methodChannel, amap);
        amap.addOnMarkerClickListener(this);
        amap.addOnMarkerDragListener(this);
        amap.addOnMapClickListener(this);
        amap.addOnPOIClickListener(this);
        
        // 初始化自定义 InfoWindow 适配器
        customInfoWindowAdapter = new CustomInfoWindowAdapter(context, methodChannel);
        amap.setInfoWindowAdapter(customInfoWindowAdapter);
    }

    @Override
    public String[] getRegisterMethodIdArray() {
        return Const.METHOD_ID_LIST_FOR_MARKER;
    }


    @Override
    public void doMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        // LogUtil.i(CLASS_NAME, "doMethodCall===>" + call.method); // 已注释：减少日志输出
        switch (call.method) {
            case Const.METHOD_MARKER_UPDATE:
                invokeMarkerOptions(call, result);
                break;
            case Const.METHOD_SINGLE_MARKER_UPDATE:
                invokeSingleMarkerUpdate(call, result);
                break;
            case Const.METHOD_MARKER_START_BREATH_ANIMATION:
                startBreathAnimation(call, result);
                break;
            case Const.METHOD_MARKER_STOP_BREATH_ANIMATION:
                stopBreathAnimation(call, result);
                break;
            case Const.METHOD_MARKER_START_RIPPLE_ANIMATION:
                startRippleAnimation(call, result);
                break;
            case Const.METHOD_MARKER_STOP_RIPPLE_ANIMATION:
                stopRippleAnimation(call, result);
                break;
            case Const.METHOD_MARKER_MOVE_SMOOTHLY:
                moveMarkerSmoothly(call, result);
                break;
        }
    }


    /**
     * 执行主动方法更新marker
     *
     * @param methodCall
     * @param result
     */
    public void invokeMarkerOptions(MethodCall methodCall, MethodChannel.Result result) {
        if (null == methodCall) {
            return;
        }
        Object markersToAdd = methodCall.argument("markersToAdd");
        addByList((List<Object>) markersToAdd);
        Object markersToChange = methodCall.argument("markersToChange");
        updateByList((List<Object>) markersToChange);
        Object markerIdsToRemove = methodCall.argument("markerIdsToRemove");
        removeByIdList((List<Object>) markerIdsToRemove);
        result.success(null);
    }

    /**
     * 更新单个标记
     *
     * @param methodCall
     * @param result
     */
    public void invokeSingleMarkerUpdate(MethodCall methodCall, MethodChannel.Result result) {
        if (null == methodCall) {
            result.error("INVALID_ARGUMENT", "MethodCall is null", null);
            return;
        }
        
        try {
            // 直接从methodCall.arguments获取标记数据
            Object markerData = methodCall.arguments;
            if (markerData != null) {
                update(markerData);
                result.success(null);
            } else {
                result.error("INVALID_ARGUMENT", "Marker data is null", null);
            }
        } catch (Exception e) {
            LogUtil.e(CLASS_NAME, "invokeSingleMarkerUpdate", e);
            result.error("UPDATE_ERROR", "Failed to update marker: " + e.getMessage(), null);
        }
    }

    public void addByList(List<Object> markersToAdd) {
        if (markersToAdd != null) {
            for (Object markerToAdd : markersToAdd) {
                add(markerToAdd);
            }
        }
    }

    private void add(Object markerObj) {
        if (null != amap) {
            MarkerOptionsBuilder builder = new MarkerOptionsBuilder();
            String dartMarkerId = MarkerUtil.interpretMarkerOptions(markerObj, builder);
            if (!TextUtils.isEmpty(dartMarkerId)) {
                MarkerOptions markerOptions = builder.build();
                final Marker marker = amap.addMarker(markerOptions);
                Object clickable = ConvertUtil.getKeyValueFromMapObject(markerObj, "clickable");
                if (null != clickable) {
                    marker.setClickable(ConvertUtil.toBoolean(clickable));
                }
                
                // 🚀 优化：只在有自定义 InfoWindow 或轨迹样式时才更新，减少不必要的调用
                Object hasCustomInfoWindow = ConvertUtil.getKeyValueFromMapObject(markerObj, "hasCustomInfoWindow");
                Object isTrackStyle = ConvertUtil.getKeyValueFromMapObject(markerObj, "isTrackStyle");
                boolean needUpdateInfoWindow = (hasCustomInfoWindow != null && ConvertUtil.toBoolean(hasCustomInfoWindow))
                    || (isTrackStyle != null && ConvertUtil.toBoolean(isTrackStyle));
                if (needUpdateInfoWindow) {
                    updateCustomInfoWindowData(marker.getId(), markerObj);
                }
                
                MarkerController markerController = new MarkerController(marker);
                controllerMapByDartId.put(dartMarkerId, markerController);
                idMapByOverlyId.put(marker.getId(), dartMarkerId);
                
                // 如果有自定义 InfoWindow 且明确设置了自动显示，则在创建时就显示
                // 🚀 复用上面已定义的 hasCustomInfoWindow 变量，避免重复定义
                Object autoShowCustomInfoWindow = ConvertUtil.getKeyValueFromMapObject(markerObj, "autoShowCustomInfoWindow");
                if (hasCustomInfoWindow != null && ConvertUtil.toBoolean(hasCustomInfoWindow) 
                    && autoShowCustomInfoWindow != null && ConvertUtil.toBoolean(autoShowCustomInfoWindow)) {
                    marker.showInfoWindow();
                }
                // 注意：即使不自动显示，点击 Marker 时 InfoWindow 仍然会显示（这是高德地图的默认行为）
            }
        }

    }

    private void updateByList(List<Object> markersToChange) {
        if (markersToChange != null) {
            for (Object markerToChange : markersToChange) {
                update(markerToChange);
            }
        }
    }

    private void update(Object markerToChange) {
        Object dartMarkerId = ConvertUtil.getKeyValueFromMapObject(markerToChange, "id");
        if (null != dartMarkerId) {
            MarkerController markerController = controllerMapByDartId.get(dartMarkerId);
            if (null != markerController) {
                MarkerUtil.interpretMarkerOptions(markerToChange, markerController);
                
                // 🚀 优化：只在有自定义 InfoWindow 或轨迹样式时才更新，减少不必要的调用
                Object hasCustomInfoWindow = ConvertUtil.getKeyValueFromMapObject(markerToChange, "hasCustomInfoWindow");
                Object isTrackStyle = ConvertUtil.getKeyValueFromMapObject(markerToChange, "isTrackStyle");
                boolean needUpdateInfoWindow = (hasCustomInfoWindow != null && ConvertUtil.toBoolean(hasCustomInfoWindow))
                    || (isTrackStyle != null && ConvertUtil.toBoolean(isTrackStyle));
                if (needUpdateInfoWindow) {
                    updateCustomInfoWindowData(markerController.getMarkerId(), markerToChange);
                }
            }
        }
    }


    private void removeByIdList(List<Object> markerIdsToRemove) {
        if (markerIdsToRemove == null) {
            return;
        }
        for (Object rawMarkerId : markerIdsToRemove) {
            if (rawMarkerId == null) {
                continue;
            }
            String markerId = (String) rawMarkerId;
            final MarkerController markerController = controllerMapByDartId.remove(markerId);
            if (markerController != null) {
                // 移除自定义 InfoWindow 数据
                customInfoWindowAdapter.removeMarkerInfo(markerController.getMarkerId());
                
                idMapByOverlyId.remove(markerController.getMarkerId());
                markerController.remove();
            }
        }
    }

    private void showMarkerInfoWindow(String dartMarkId) {
        MarkerController markerController = controllerMapByDartId.get(dartMarkId);
        if (null != markerController) {
            markerController.showInfoWindow();
        }
    }

    private void hideMarkerInfoWindow(String dartMarkId, LatLng newPosition) {
        if (TextUtils.isEmpty(dartMarkId)) {
            return;
        }
        if (!controllerMapByDartId.containsKey(dartMarkId)) {
            return;
        }
        MarkerController markerController = controllerMapByDartId.get(dartMarkId);
        if (null != markerController) {
            if (null != newPosition && null != markerController.getPosition()) {
                if (markerController.getPosition().equals(newPosition)) {
                    return;
                }
            }
            markerController.hideInfoWindow();
        }
    }

    @Override
    public void onMapClick(LatLng latLng) {
        hideMarkerInfoWindow(selectedMarkerDartId, null);
    }

    @Override
    public boolean onMarkerClick(Marker marker) {
        String dartId = idMapByOverlyId.get(marker.getId());
        if (null == dartId) {
            return false;
        }
        final Map<String, Object> data = new HashMap<>(1);
        data.put("markerId", dartId);
        selectedMarkerDartId = dartId;
        showMarkerInfoWindow(dartId);
        methodChannel.invokeMethod("marker#onTap", data);
        LogUtil.i(CLASS_NAME, "onMarkerClick==>" + data);
        return true;
    }

    @Override
    public void onMarkerDragStart(Marker marker) {

    }

    @Override
    public void onMarkerDrag(Marker marker) {

    }

    @Override
    public void onMarkerDragEnd(Marker marker) {
        String markerId = marker.getId();
        String dartId = idMapByOverlyId.get(markerId);
        LatLng latLng = marker.getPosition();
        if (null == dartId) {
            return;
        }
        final Map<String, Object> data = new HashMap<>(2);
        data.put("markerId", dartId);
        data.put("position", ConvertUtil.latLngToList(latLng));
        methodChannel.invokeMethod("marker#onDragEnd", data);

        LogUtil.i(CLASS_NAME, "onMarkerDragEnd==>" + data);
    }

    @Override
    public void onPOIClick(Poi poi) {
        hideMarkerInfoWindow(selectedMarkerDartId, null != poi ? poi.getCoordinate() : null);
    }

    /**
     * 隐藏所有 InfoWindow
     */
    public void hideAllInfoWindows() {
        if (customInfoWindowAdapter != null) {
            customInfoWindowAdapter.hideCurrentInfoWindow();
        }
        selectedMarkerDartId = null;
        LogUtil.i(CLASS_NAME, "hideAllInfoWindows: 已隐藏所有 InfoWindow");
    }
    
    /**
     * 根据 Marker ID 隐藏特定的 InfoWindow
     */
    public void hideInfoWindowByMarkerId(String dartMarkerId) {
        if (TextUtils.isEmpty(dartMarkerId)) {
            LogUtil.w(CLASS_NAME, "hideInfoWindowByMarkerId: markerId is empty");
            return;
        }
        
        MarkerController markerController = controllerMapByDartId.get(dartMarkerId);
        if (markerController != null) {
            markerController.hideInfoWindow();
            if (dartMarkerId.equals(selectedMarkerDartId)) {
                selectedMarkerDartId = null;
            }
            LogUtil.i(CLASS_NAME, "hideInfoWindowByMarkerId: 已隐藏 marker " + dartMarkerId + " 的 InfoWindow");
        } else {
            LogUtil.w(CLASS_NAME, "hideInfoWindowByMarkerId: marker not found: " + dartMarkerId);
        }
    }
    
    /**
     * 根据 Marker ID 显示特定的 InfoWindow
     */
    public void showInfoWindowByMarkerId(String dartMarkerId) {
        if (TextUtils.isEmpty(dartMarkerId)) {
            LogUtil.w(CLASS_NAME, "showInfoWindowByMarkerId: markerId is empty");
            return;
        }
        
        MarkerController markerController = controllerMapByDartId.get(dartMarkerId);
        if (markerController != null) {
            markerController.showInfoWindow();
            selectedMarkerDartId = dartMarkerId;
            LogUtil.i(CLASS_NAME, "showInfoWindowByMarkerId: 已显示 marker " + dartMarkerId + " 的 InfoWindow");
        } else {
            LogUtil.w(CLASS_NAME, "showInfoWindowByMarkerId: marker not found: " + dartMarkerId);
        }
    }

    /**
     * 更新自定义 InfoWindow 数据
     */
    private void updateCustomInfoWindowData(String markerId, Object markerObj) {
        if (customInfoWindowAdapter == null) {
            return;
        }
        
        // 检查是否有自定义 InfoWindow
        Object hasCustom = ConvertUtil.getKeyValueFromMapObject(markerObj, "hasCustomInfoWindow");
        boolean hasCustomInfoWindow = hasCustom != null && ConvertUtil.toBoolean(hasCustom);
        
        // 检查是否是轨迹样式
        Object isTrackStyleObj = ConvertUtil.getKeyValueFromMapObject(markerObj, "isTrackStyle");
        boolean isTrackStyle = isTrackStyleObj != null && ConvertUtil.toBoolean(isTrackStyleObj);
        
        // 获取 InfoWindow 数据
        String locationName = null;
        String address = null;
        String stayDuration = null;
        String stayTime = null;
        
        Object infoWindow = ConvertUtil.getKeyValueFromMapObject(markerObj, "infoWindow");
        if (infoWindow != null && infoWindow instanceof Map) {
            Map<String, Object> infoMap = (Map<String, Object>) infoWindow;
            Object titleObj = infoMap.get("title");
            Object snippetObj = infoMap.get("snippet");
            
            if (titleObj != null) {
                locationName = titleObj.toString();
            }
            if (snippetObj != null) {
                address = snippetObj.toString();
            }
        }
        
        // 获取轨迹专用数据
        if (isTrackStyle) {
            Object stayDurationObj = ConvertUtil.getKeyValueFromMapObject(markerObj, "stayDuration");
            Object stayTimeObj = ConvertUtil.getKeyValueFromMapObject(markerObj, "stayTime");
            
            if (stayDurationObj != null) {
                stayDuration = stayDurationObj.toString();
            }
            if (stayTimeObj != null) {
                stayTime = stayTimeObj.toString();
            }
        }
        
        // 更新适配器数据
        CustomInfoWindowAdapter.MarkerInfoData infoData;
        if (isTrackStyle) {
            // 使用轨迹样式构造函数
            infoData = new CustomInfoWindowAdapter.MarkerInfoData(hasCustomInfoWindow, locationName, stayDuration, stayTime);
        } else {
            // 使用普通样式构造函数
            infoData = new CustomInfoWindowAdapter.MarkerInfoData(hasCustomInfoWindow, locationName, address);
        }
        
        // 🚀 优化：减少日志输出，只在真正需要时输出（调试模式）
        // LogUtil.i(CLASS_NAME, "updateCustomInfoWindowData: markerId=" + markerId + ", hasCustomInfoWindow=" + hasCustomInfoWindow + ", isTrackStyle=" + isTrackStyle + ", locationName=" + locationName);
        
        customInfoWindowAdapter.updateMarkerInfo(markerId, infoData);
    }

    /**
     * 启动Marker呼吸动画（横纵交替拉伸）
     * 
     * 🎯 iOS原版实现：
     * - 横向拉伸：X=1.03, Y=0.98
     * - 纵向拉伸：X=0.98, Y=1.15
     * - 两种状态交替变换，产生"呼吸"效果
     * 
     * 🚀 性能优势：
     * 1. 使用高德地图SDK的ScaleAnimation（GPU加速）
     * 2. 60fps流畅运行
     * 3. 零跨平台通信开销（只调用一次）
     * 4. 在原生层持续执行，不占用Flutter线程
     * 
     * @param call 包含markerId、duration的参数
     * @param result 回调结果
     */
    private void startBreathAnimation(MethodCall call, MethodChannel.Result result) {
        try {
            // 获取参数
            String markerId = call.argument("markerId");
            Integer duration = call.argument("duration");

            // 参数校验
            if (markerId == null || markerId.isEmpty()) {
                result.error("INVALID_ARGUMENT", "markerId不能为空", null);
                return;
            }

            // 设置默认值（iOS原版使用0.4秒=400ms）
            long durationMs = duration != null ? duration.longValue() : 400L;

            // 获取MarkerController
            MarkerController controller = controllerMapByDartId.get(markerId);
            if (controller == null) {
                result.error("MARKER_NOT_FOUND", "未找到markerId对应的Marker: " + markerId, null);
                return;
            }

            // 启动动画（iOS原版参数：横纵交替拉伸）
            controller.startBreathAnimation(durationMs);
            
            LogUtil.i(CLASS_NAME, String.format(
                "✅ 启动Marker呼吸动画(iOS原版): markerId=%s, duration=%dms (横向1.03→0.98, 纵向0.98→1.15)",
                markerId, durationMs));
            
            result.success(true);

        } catch (Exception e) {
            LogUtil.e(CLASS_NAME, "启动呼吸动画失败", e);
            result.error("ANIMATION_ERROR", "启动动画失败: " + e.getMessage(), null);
        }
    }

    /**
     * 停止Marker呼吸动画
     * 
     * @param call 包含markerId的参数
     * @param result 回调结果
     */
    private void stopBreathAnimation(MethodCall call, MethodChannel.Result result) {
        try {
            // 获取参数
            String markerId = call.argument("markerId");

            // 参数校验
            if (markerId == null || markerId.isEmpty()) {
                result.error("INVALID_ARGUMENT", "markerId不能为空", null);
                return;
            }

            // 获取MarkerController
            MarkerController controller = controllerMapByDartId.get(markerId);
            if (controller == null) {
                result.error("MARKER_NOT_FOUND", "未找到markerId对应的Marker: " + markerId, null);
                return;
            }

            // 停止动画
            controller.stopBreathAnimation();
            
            LogUtil.i(CLASS_NAME, "✅ 停止Marker呼吸动画: markerId=" + markerId);
            
            result.success(true);

        } catch (Exception e) {
            LogUtil.e(CLASS_NAME, "停止呼吸动画失败", e);
            result.error("ANIMATION_ERROR", "停止动画失败: " + e.getMessage(), null);
        }
    }

    /**
     * 启动Marker波纹动画（扩散+透明度渐变）
     * 
     * 🌊 波纹效果：
     * 1. 从1.0扩大到1.5倍
     * 2. 透明度从0.6渐变到0.0
     * 3. 循环播放，产生持续扩散效果
     * 4. 在原生层执行，60fps流畅运行
     * 
     * @param call 包含markerId、duration的参数
     * @param result 回调结果
     */
    private void startRippleAnimation(MethodCall call, MethodChannel.Result result) {
        try {
            // 获取参数
            String markerId = call.argument("markerId");
            Integer duration = call.argument("duration");

            // 参数校验
            if (markerId == null || markerId.isEmpty()) {
                result.error("INVALID_ARGUMENT", "markerId不能为空", null);
                return;
            }

            // 设置默认值（2秒=2000ms）
            long durationMs = duration != null ? duration.longValue() : 2000L;

            // 获取MarkerController
            MarkerController controller = controllerMapByDartId.get(markerId);
            if (controller == null) {
                result.error("MARKER_NOT_FOUND", "未找到markerId对应的Marker: " + markerId, null);
                return;
            }

            // 启动波纹动画
            controller.startRippleAnimation(durationMs);
            
            LogUtil.i(CLASS_NAME, String.format(
                "✅ 启动Marker波纹动画: markerId=%s, duration=%dms (扩散1.0→1.5, 透明度0.6→0.0)",
                markerId, durationMs));
            
            result.success(true);

        } catch (Exception e) {
            LogUtil.e(CLASS_NAME, "启动波纹动画失败", e);
            result.error("ANIMATION_ERROR", "启动动画失败: " + e.getMessage(), null);
        }
    }

    /**
     * 停止Marker波纹动画
     * 
     * @param call 包含markerId的参数
     * @param result 回调结果
     */
    private void stopRippleAnimation(MethodCall call, MethodChannel.Result result) {
        try {
            // 获取参数
            String markerId = call.argument("markerId");

            // 参数校验
            if (markerId == null || markerId.isEmpty()) {
                result.error("INVALID_ARGUMENT", "markerId不能为空", null);
                return;
            }

            // 获取MarkerController
            MarkerController controller = controllerMapByDartId.get(markerId);
            if (controller == null) {
                result.error("MARKER_NOT_FOUND", "未找到markerId对应的Marker: " + markerId, null);
                return;
            }

            // 停止动画
            controller.stopRippleAnimation();
            
            LogUtil.i(CLASS_NAME, "✅ 停止Marker波纹动画: markerId=" + markerId);
            
            result.success(true);

        } catch (Exception e) {
            LogUtil.e(CLASS_NAME, "停止波纹动画失败", e);
            result.error("ANIMATION_ERROR", "停止动画失败: " + e.getMessage(), null);
        }
    }

    /**
     * 🎯 平滑移动Marker到目标位置（原生动画）
     * 
     * 使用高德地图原生平滑移动API，实现60fps流畅移动
     * 
     * @param call 包含markerId、latitude、longitude、duration、rotation的参数
     * @param result 回调结果
     */
    private void moveMarkerSmoothly(MethodCall call, MethodChannel.Result result) {
        try {
            // 获取参数
            String markerId = call.argument("markerId");
            Double latitude = call.argument("latitude");
            Double longitude = call.argument("longitude");
            Integer duration = call.argument("duration");
            Double rotation = call.argument("rotation");

            // 参数校验
            if (markerId == null || markerId.isEmpty()) {
                result.error("INVALID_ARGUMENT", "markerId不能为空", null);
                return;
            }
            if (latitude == null || longitude == null) {
                result.error("INVALID_ARGUMENT", "latitude和longitude不能为空", null);
                return;
            }

            // 设置默认值
            long durationMs = duration != null ? duration.longValue() : 100L;
            Float rotationFloat = rotation != null ? rotation.floatValue() : null;

            // 获取MarkerController
            MarkerController controller = controllerMapByDartId.get(markerId);
            if (controller == null) {
                result.error("MARKER_NOT_FOUND", "未找到markerId对应的Marker: " + markerId, null);
                return;
            }

            // 创建目标位置
            com.amap.api.maps.model.LatLng targetPosition = 
                new com.amap.api.maps.model.LatLng(latitude, longitude);

            // 平滑移动Marker
            controller.moveMarkerSmoothly(targetPosition, durationMs, rotationFloat);
            
            // 降低日志频率（每10次记录一次）
            // LogUtil.i(CLASS_NAME, String.format(
            //     "✅ 平滑移动Marker: markerId=%s, target=(%.6f,%.6f), duration=%dms, rotation=%s",
            //     markerId, latitude, longitude, durationMs, rotationFloat));
            
            result.success(true);

        } catch (Exception e) {
            LogUtil.e(CLASS_NAME, "平滑移动Marker失败", e);
            result.error("MOVE_ERROR", "平滑移动失败: " + e.getMessage(), null);
        }
    }

}
