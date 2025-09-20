package com.amap.flutter.location;

import android.content.Context;
import android.util.Log;

import com.amap.api.location.AMapLocation;
import com.amap.api.location.AMapLocationClient;
import com.amap.api.location.AMapLocationClientOption;
import com.amap.api.location.AMapLocationListener;

import java.util.Map;

import io.flutter.plugin.common.EventChannel;

/**
 * @author whm
 * @date 2020-04-16 15:49
 * @mail hongming.whm@alibaba-inc.com
 */
public class AMapLocationClientImpl implements AMapLocationListener {

    private Context mContext;
    private AMapLocationClientOption locationOption = new AMapLocationClientOption();
    private AMapLocationClient locationClient = null;
    private EventChannel.EventSink mEventSink;

    private String mPluginKey;

    public AMapLocationClientImpl(Context context, String pluginKey, EventChannel.EventSink eventSink) {
        mContext = context;
        mPluginKey = pluginKey;
        mEventSink = eventSink;
        try {
            if (null == locationClient) {
                locationClient = new AMapLocationClient(context);
            }
        } catch (SecurityException e) {
            // 捕获SecurityException（如电话状态权限问题），但继续执行
            Log.w("AMapLocation", "SecurityException caught during initialization: " + e.getMessage());
            Log.w("AMapLocation", "Location service will continue without phone state monitoring");
            // 仍然尝试创建locationClient，忽略权限错误
            try {
                locationClient = new AMapLocationClient(context);
            } catch (Exception ex) {
                Log.e("AMapLocation", "Failed to create AMapLocationClient after SecurityException: " + ex.getMessage());
            }
        } catch (Exception e) {
            Log.e("AMapLocation", "Exception during AMapLocationClient initialization: " + e.getMessage());
            e.printStackTrace();
        }
    }

    /**
     * 开始定位
     */
    public void startLocation() {
        try {
            if (null == locationClient) {
                locationClient = new AMapLocationClient(mContext);
            }
        } catch (SecurityException e) {
            // 捕获SecurityException（如电话状态权限问题），但继续执行
            Log.w("AMapLocation", "SecurityException caught during startLocation: " + e.getMessage());
            Log.w("AMapLocation", "Location service will continue without phone state monitoring");
            // 仍然尝试创建locationClient，忽略权限错误
            try {
                locationClient = new AMapLocationClient(mContext);
            } catch (Exception ex) {
                Log.e("AMapLocation", "Failed to create AMapLocationClient in startLocation after SecurityException: " + ex.getMessage());
                return; // 如果彻底失败则返回
            }
        } catch (Exception e) {
            Log.e("AMapLocation", "Exception during startLocation: " + e.getMessage());
            e.printStackTrace();
            return; // 如果有其他异常则返回
        }
        
        if (null != locationOption && null != locationClient) {
            try {
                locationClient.setLocationOption(locationOption);
                locationClient.setLocationListener(this);
                locationClient.startLocation();
            } catch (SecurityException e) {
                Log.w("AMapLocation", "SecurityException during location start: " + e.getMessage());
                // 继续执行，不中断定位服务
            } catch (Exception e) {
                Log.e("AMapLocation", "Exception during location configuration: " + e.getMessage());
                e.printStackTrace();
            }
        }
    }


    /**
     * 停止定位
     */
    public void stopLocation() {
        if (null != locationClient) {
            locationClient.stopLocation();
            locationClient.onDestroy();
            locationClient = null;
        }
    }

    public void destroy() {
        if(null != locationClient) {
            locationClient.onDestroy();
            locationClient = null;
        }
    }
    /**
     * 定位回调
     *
     * @param location
     */
    @Override
    public void onLocationChanged(AMapLocation location) {
        if (null == mEventSink) {
            return;
        }
        Map<String, Object> result = Utils.buildLocationResultMap(location);
        result.put("pluginKey", mPluginKey);
        mEventSink.success(result);
    }


    /**
     * 设置定位参数
     *
     * @param optionMap
     */
    public void setLocationOption(Map optionMap) {
        if (null == locationOption) {
            locationOption = new AMapLocationClientOption();
        }

        if (optionMap.containsKey("locationInterval")) {
            locationOption.setInterval(((Integer) optionMap.get("locationInterval")).longValue());
        }

        if (optionMap.containsKey("needAddress")) {
            locationOption.setNeedAddress((boolean) optionMap.get("needAddress"));
        }

        if (optionMap.containsKey("locationMode")) {
            try {
                locationOption.setLocationMode(AMapLocationClientOption.AMapLocationMode.values()[(int) optionMap.get("locationMode")]);
            } catch (Throwable e) {
            }
        }

        if (optionMap.containsKey("geoLanguage")) {
            locationOption.setGeoLanguage(AMapLocationClientOption.GeoLanguage.values()[(int) optionMap.get("geoLanguage")]);
        }

        if (optionMap.containsKey("onceLocation")) {
            locationOption.setOnceLocation((boolean) optionMap.get("onceLocation"));
        }

        if (null != locationClient) {
            locationClient.setLocationOption(locationOption);
        }
    }
}
