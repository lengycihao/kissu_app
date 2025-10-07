package com.amap.flutter.map.overlays.circle;

import com.amap.api.maps.model.CircleOptions;
import com.amap.api.maps.model.LatLng;

/**
 * Circle选项构建器
 */
class CircleOptionsBuilder implements CircleOptionsSink {
    final CircleOptions circleOptions;
    
    CircleOptionsBuilder() {
        circleOptions = new CircleOptions();
    }

    public CircleOptions build(){
        return circleOptions;
    }

    @Override
    public void setCenter(LatLng center) {
        circleOptions.center(center);
    }

    @Override
    public void setRadius(double radius) {
        circleOptions.radius(radius);
    }

    @Override
    public void setStrokeWidth(float strokeWidth) {
        circleOptions.strokeWidth(strokeWidth);
    }

    @Override
    public void setStrokeColor(int color) {
        circleOptions.strokeColor(color);
    }

    @Override
    public void setFillColor(int color) {
        circleOptions.fillColor(color);
    }

    @Override
    public void setVisible(boolean visible) {
        circleOptions.visible(visible);
    }
}

