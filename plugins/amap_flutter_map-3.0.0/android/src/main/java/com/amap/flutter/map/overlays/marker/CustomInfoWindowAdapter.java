package com.amap.flutter.map.overlays.marker;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Outline;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.PorterDuff;
import android.graphics.PorterDuffXfermode;
import android.graphics.RectF;
import android.graphics.drawable.GradientDrawable;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewOutlineProvider;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.TextView;

import com.amap.api.maps.AMap;
import com.amap.api.maps.model.Marker;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodChannel;

/**
 * 自定义 InfoWindow 适配器
 * 支持通过 Flutter 传递的数据动态构建 InfoWindow
 */
public class CustomInfoWindowAdapter implements AMap.InfoWindowAdapter {
    private final Context context;
    private final MethodChannel methodChannel;
    private final Map<String, MarkerInfoData> markerInfoDataMap = new HashMap<>();

    public CustomInfoWindowAdapter(Context context, MethodChannel methodChannel) {
        this.context = context;
        this.methodChannel = methodChannel;
    }

    /**
     * 更新 Marker 的 InfoWindow 数据
     */
    public void updateMarkerInfo(String markerId, MarkerInfoData infoData) {
        markerInfoDataMap.put(markerId, infoData);
    }

    /**
     * 移除 Marker 的 InfoWindow 数据
     */
    public void removeMarkerInfo(String markerId) {
        markerInfoDataMap.remove(markerId);
    }

    @Override
    public View getInfoWindow(Marker marker) {
        String markerId = marker.getId();
        MarkerInfoData infoData = markerInfoDataMap.get(markerId);
        
        if (infoData == null || !infoData.hasCustomView) {
            // 没有自定义 InfoWindow，返回 null 使用默认样式
            return null;
        }

        // 返回完全自定义的 InfoWindow，这样高德地图不会添加默认边框
        return createCustomInfoWindow(infoData);
    }

    @Override
    public View getInfoContents(Marker marker) {
        // 返回 null，因为我们在 getInfoWindow 中已经返回了完整的自定义窗口
        // 注意：只有 getInfoWindow 返回 null 时，getInfoContents 才会被调用
        return null;
    }

    /**
     * 创建自定义 InfoWindow View
     */
    private View createCustomInfoWindow(MarkerInfoData infoData) {
        int paddingHorizontal = dpToPx(16); // 左右边距 16dp
        int paddingVertical = dpToPx(10);   // 上下边距 10dp
        int width = dpToPx(220); // 固定宽度 220dp
        final float cornerRadius = dpToPx(62); // 62dp 圆角
        
        // 创建内容容器
        LinearLayout contentContainer = new LinearLayout(context);
        contentContainer.setOrientation(LinearLayout.VERTICAL);
        contentContainer.setPadding(paddingHorizontal, paddingVertical, paddingHorizontal, paddingVertical);
        
        // 添加标题
        if (infoData.locationName != null && !infoData.locationName.isEmpty()) {
            TextView titleView = new TextView(context);
            titleView.setText(infoData.locationName);
            titleView.setTextSize(TypedValue.COMPLEX_UNIT_SP, 14);
            titleView.setTextColor(0xFF333333);
            titleView.setGravity(Gravity.START);
            titleView.setMaxWidth(width - paddingHorizontal * 2);
            contentContainer.addView(titleView);
        }
        
        // 添加地址
        if (infoData.address != null && !infoData.address.isEmpty()) {
            TextView addressView = new TextView(context);
            addressView.setText(infoData.address);
            addressView.setTextSize(TypedValue.COMPLEX_UNIT_SP, 12);
            addressView.setTextColor(0xFF666666);
            addressView.setGravity(Gravity.START);
            addressView.setMaxWidth(width - paddingHorizontal * 2);
            
            LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            );
            params.topMargin = dpToPx(4);
            addressView.setLayoutParams(params);
            
            contentContainer.addView(addressView);
        }
        
        // 创建带圆角裁剪的外层容器
        RoundedFrameLayout wrapper = new RoundedFrameLayout(context, cornerRadius);
        wrapper.addView(contentContainer);
        
        // 添加外层透明容器，留出空间避免边框显示
        FrameLayout outerContainer = new FrameLayout(context);
        outerContainer.setBackgroundColor(Color.TRANSPARENT);
        int margin = dpToPx(2); // 2dp 的透明边距
        FrameLayout.LayoutParams wrapperParams = new FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.WRAP_CONTENT,
            FrameLayout.LayoutParams.WRAP_CONTENT
        );
        wrapperParams.setMargins(margin, margin, margin, margin);
        wrapper.setLayoutParams(wrapperParams);
        outerContainer.addView(wrapper);
        
        // 测量和布局
        outerContainer.measure(
            View.MeasureSpec.makeMeasureSpec(width + margin * 2, View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED)
        );
        outerContainer.layout(0, 0, outerContainer.getMeasuredWidth(), outerContainer.getMeasuredHeight());
        
        return outerContainer;
    }
    
    /**
     * 自定义圆角 FrameLayout
     */
    private static class RoundedFrameLayout extends FrameLayout {
        private final float cornerRadius;
        private final Path clipPath = new Path();
        private final RectF rectF = new RectF();
        private final Paint bgPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final Paint shadowPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
        
        public RoundedFrameLayout(Context context, float cornerRadius) {
            super(context);
            this.cornerRadius = cornerRadius;
            setWillNotDraw(false);
            
            // 设置背景画笔
            bgPaint.setColor(Color.WHITE);
            bgPaint.setStyle(Paint.Style.FILL);
            bgPaint.setAntiAlias(true);
        }
        
        @Override
        protected void onSizeChanged(int w, int h, int oldw, int oldh) {
            super.onSizeChanged(w, h, oldw, oldh);
            rectF.set(0, 0, w, h);
            clipPath.reset();
            clipPath.addRoundRect(rectF, cornerRadius, cornerRadius, Path.Direction.CW);
        }
        
        @Override
        protected void onDraw(Canvas canvas) {
            // 绘制圆角背景
            canvas.drawRoundRect(rectF, cornerRadius, cornerRadius, bgPaint);
            super.onDraw(canvas);
        }
        
        @Override
        protected void dispatchDraw(Canvas canvas) {
            canvas.save();
            canvas.clipPath(clipPath);
            super.dispatchDraw(canvas);
            canvas.restore();
        }
    }

    /**
     * dp 转 px
     */
    private int dpToPx(float dp) {
        return (int) TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            dp,
            context.getResources().getDisplayMetrics()
        );
    }

    /**
     * Marker InfoWindow 数据类
     */
    public static class MarkerInfoData {
        public boolean hasCustomView;
        public String locationName;
        public String address;

        public MarkerInfoData(boolean hasCustomView, String locationName, String address) {
            this.hasCustomView = hasCustomView;
            this.locationName = locationName;
            this.address = address;
        }
    }
}

