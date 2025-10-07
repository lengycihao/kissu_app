package com.amap.flutter.map.overlays.circle;

import com.amap.api.maps.model.LatLng;

/**
 * Circle选项接口
 */
interface CircleOptionsSink {
    //圆形中心点
    void setCenter(LatLng center);
    
    //圆形半径（米）
    void setRadius(double radius);

    //边框宽度
    void setStrokeWidth(float strokeWidth);

    //边框颜色
    void setStrokeColor(int color);

    //填充颜色
    void setFillColor(int color);

    //是否显示
    void setVisible(boolean visible);
}

