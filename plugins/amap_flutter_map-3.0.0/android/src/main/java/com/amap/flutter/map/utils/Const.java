package com.amap.flutter.map.utils;

/**
 * @author whm
 * @date 2020/11/10 9:44 PM
 * @mail hongming.whm@alibaba-inc.com
 * @since
 */
public class Const {
    /**
     * map
     */
    public static final String METHOD_MAP_WAIT_FOR_MAP = "map#waitForMap";
    public static final String METHOD_MAP_CONTENT_APPROVAL_NUMBER = "map#contentApprovalNumber";
    public static final String METHOD_MAP_SATELLITE_IMAGE_APPROVAL_NUMBER = "map#satelliteImageApprovalNumber";
    public static final String METHOD_MAP_UPDATE = "map#update";
    public static final String METHOD_MAP_MOVE_CAMERA = "camera#move";
    public static final String METHOD_MAP_SET_RENDER_FPS = "map#setRenderFps";
    public static final String METHOD_MAP_TAKE_SNAPSHOT = "map#takeSnapshot";
    public static final String METHOD_MAP_CLEAR_DISK = "map#clearDisk";
    public static final String METHOD_MAP_HIDE_ALL_INFO_WINDOWS = "map#hideAllInfoWindows";
    public static final String METHOD_MAP_HIDE_INFO_WINDOW = "map#hideInfoWindow";
    public static final String METHOD_MAP_SHOW_INFO_WINDOW = "map#showInfoWindow";
    public static final String METHOD_MAP_SHOW_GEOFENCE_CIRCLE = "map#showGeofenceCircle";
    public static final String METHOD_MAP_HIDE_GEOFENCE_CIRCLE = "map#hideGeofenceCircle";
    public static final String METHOD_MAP_CLEAR_GEOFENCE_CIRCLE = "map#clearGeofenceCircle";
    public static final String METHOD_MAP_GET_CAMERA_POSITION = "map#getCameraPosition";

    public static final String[] METHOD_ID_LIST_FOR_MAP = {
            METHOD_MAP_CONTENT_APPROVAL_NUMBER,
            METHOD_MAP_SATELLITE_IMAGE_APPROVAL_NUMBER,
            METHOD_MAP_WAIT_FOR_MAP,
            METHOD_MAP_UPDATE,
            METHOD_MAP_MOVE_CAMERA,
            METHOD_MAP_SET_RENDER_FPS,
            METHOD_MAP_TAKE_SNAPSHOT,
            METHOD_MAP_CLEAR_DISK,
            METHOD_MAP_HIDE_ALL_INFO_WINDOWS,
            METHOD_MAP_HIDE_INFO_WINDOW,
            METHOD_MAP_SHOW_INFO_WINDOW,
            METHOD_MAP_SHOW_GEOFENCE_CIRCLE,
            METHOD_MAP_HIDE_GEOFENCE_CIRCLE,
            METHOD_MAP_CLEAR_GEOFENCE_CIRCLE,
            METHOD_MAP_GET_CAMERA_POSITION};


    /**
     * markers
     */
    public static final String METHOD_MARKER_UPDATE = "markers#update";
    public static final String METHOD_SINGLE_MARKER_UPDATE = "marker#update";
    public static final String METHOD_MARKER_START_BREATH_ANIMATION = "marker#startBreathAnimation";
    public static final String METHOD_MARKER_STOP_BREATH_ANIMATION = "marker#stopBreathAnimation";
    public static final String METHOD_MARKER_START_RIPPLE_ANIMATION = "marker#startRippleAnimation";
    public static final String METHOD_MARKER_STOP_RIPPLE_ANIMATION = "marker#stopRippleAnimation";
    public static final String METHOD_MARKER_MOVE_SMOOTHLY = "marker#moveMarkerSmoothly";
    public static final String METHOD_MARKER_START_GIF_ANIMATION = "marker#startGifAnimation";
    public static final String METHOD_MARKER_STOP_GIF_ANIMATION = "marker#stopGifAnimation";
    public static final String METHOD_MARKER_PRELOAD_GIF = "marker#preloadGif";
    public static final String METHOD_MARKER_START_SWING_ANIMATION = "marker#startSwingAnimation";
    public static final String METHOD_MARKER_STOP_SWING_ANIMATION = "marker#stopSwingAnimation";
    public static final String[] METHOD_ID_LIST_FOR_MARKER = {
            METHOD_MARKER_UPDATE, 
            METHOD_SINGLE_MARKER_UPDATE,
            METHOD_MARKER_START_BREATH_ANIMATION,
            METHOD_MARKER_STOP_BREATH_ANIMATION,
            METHOD_MARKER_START_RIPPLE_ANIMATION,
            METHOD_MARKER_STOP_RIPPLE_ANIMATION,
            METHOD_MARKER_MOVE_SMOOTHLY,
            METHOD_MARKER_START_GIF_ANIMATION,
            METHOD_MARKER_STOP_GIF_ANIMATION,
            METHOD_MARKER_PRELOAD_GIF,
            METHOD_MARKER_START_SWING_ANIMATION,
            METHOD_MARKER_STOP_SWING_ANIMATION
    };

    /**
     * polygons
     */
    public static final String METHOD_POLYGON_UPDATE = "polygons#update";
    public static final String[] METHOD_ID_LIST_FOR_POLYGON = {METHOD_POLYGON_UPDATE};

    /**
     * polylines
     */
    public static final String METHOD_POLYLINE_UPDATE = "polylines#update";
    public static final String[] METHOD_ID_LIST_FOR_POLYLINE = {METHOD_POLYLINE_UPDATE};

    /**
     * circles
     */
    public static final String METHOD_CIRCLE_UPDATE = "circles#update";
    public static final String[] METHOD_ID_LIST_FOR_CIRCLE = {METHOD_CIRCLE_UPDATE};
}
