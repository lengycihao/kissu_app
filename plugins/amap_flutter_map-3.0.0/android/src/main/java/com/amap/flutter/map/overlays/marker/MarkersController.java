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
        LogUtil.i(CLASS_NAME, "doMethodCall===>" + call.method);
        switch (call.method) {
            case Const.METHOD_MARKER_UPDATE:
                invokeMarkerOptions(call, result);
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
                
                // 处理自定义 InfoWindow
                updateCustomInfoWindowData(marker.getId(), markerObj);
                
                MarkerController markerController = new MarkerController(marker);
                controllerMapByDartId.put(dartMarkerId, markerController);
                idMapByOverlyId.put(marker.getId(), dartMarkerId);
                
                // 如果有自定义 InfoWindow 且明确设置了自动显示，则在创建时就显示
                Object hasCustomInfoWindow = ConvertUtil.getKeyValueFromMapObject(markerObj, "hasCustomInfoWindow");
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
                
                // 更新自定义 InfoWindow
                updateCustomInfoWindowData(markerController.getMarkerId(), markerToChange);
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
        
        customInfoWindowAdapter.updateMarkerInfo(markerId, infoData);
    }

}
