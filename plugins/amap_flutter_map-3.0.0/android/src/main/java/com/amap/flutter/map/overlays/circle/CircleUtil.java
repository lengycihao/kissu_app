package com.amap.flutter.map.overlays.circle;

import com.amap.api.maps.model.LatLng;
import com.amap.flutter.map.utils.ConvertUtil;

import java.util.Map;

/**
 * Circle工具类
 */
class CircleUtil {

    static String interpretOptions(Object o, CircleOptionsSink sink) {
        final Map<?, ?> data = ConvertUtil.toMap(o);
        
        final Object center = data.get("center");
        if (center != null) {
            LatLng latLng = ConvertUtil.toLatLng(center);
            if (latLng != null) {
                sink.setCenter(latLng);
            }
        }

        final Object radius = data.get("radius");
        if (radius != null) {
            sink.setRadius(ConvertUtil.toDouble(radius));
        }

        final Object width = data.get("strokeWidth");
        if (width != null) {
            sink.setStrokeWidth(ConvertUtil.toFloatPixels(width));
        }

        final Object strokeColor = data.get("strokeColor");
        if (strokeColor != null) {
            sink.setStrokeColor(ConvertUtil.toInt(strokeColor));
        }

        final Object fillColor = data.get("fillColor");
        if (fillColor != null) {
            sink.setFillColor(ConvertUtil.toInt(fillColor));
        }

        final Object visible = data.get("visible");
        if (visible != null) {
            sink.setVisible(ConvertUtil.toBoolean(visible));
        }

        final String circleId = (String) data.get("id");
        if (circleId == null) {
            throw new IllegalArgumentException("circleId was null");
        } else {
            return circleId;
        }
    }
}

