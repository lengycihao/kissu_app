package com.amap.flutter.map.overlays.circle;

import com.amap.api.maps.model.Circle;
import com.amap.api.maps.model.LatLng;

/**
 * Circle控制器
 */
class CircleController implements CircleOptionsSink {

    private final Circle circle;
    private final String id;
    
    CircleController(Circle circle){
        this.circle = circle;
        this.id = circle.getId();
    }

    public String getId() {
        return id;
    }

    public void remove() {
        circle.remove();
    }

    @Override
    public void setCenter(LatLng center) {
        circle.setCenter(center);
    }

    @Override
    public void setRadius(double radius) {
        circle.setRadius(radius);
    }

    @Override
    public void setStrokeWidth(float strokeWidth) {
        circle.setStrokeWidth(strokeWidth);
    }

    @Override
    public void setStrokeColor(int color) {
        circle.setStrokeColor(color);
    }

    @Override
    public void setFillColor(int color) {
        circle.setFillColor(color);
    }

    @Override
    public void setVisible(boolean visible) {
        circle.setVisible(visible);
    }
}

