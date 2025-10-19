package com.amap.flutter.map.overlays.marker;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Outline;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.PorterDuff;
import android.graphics.PorterDuffXfermode;
import android.graphics.RectF;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.GradientDrawable;
import android.text.TextUtils;
import android.util.TypedValue;
import android.graphics.Typeface;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewOutlineProvider;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
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
    private Marker currentInfoWindowMarker; // 当前显示InfoWindow的marker

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
        // 记录当前显示InfoWindow的marker
        currentInfoWindowMarker = marker;
        
        String markerId = marker.getId();
        MarkerInfoData infoData = markerInfoDataMap.get(markerId);
        
        if (infoData == null || !infoData.hasCustomView) {
            // 没有自定义 InfoWindow，返回 null 使用默认样式
            return null;
        }

        // 根据样式类型返回不同的 InfoWindow
        if (infoData.isTrackStyle) {
            return createTrackInfoWindow(infoData);
        } else {
            return createCustomInfoWindow(infoData);
        }
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
        int topOffset = dpToPx(15); // 向下偏移 15dp，补偿原marker占用的空间
        FrameLayout.LayoutParams wrapperParams = new FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.WRAP_CONTENT,
            FrameLayout.LayoutParams.WRAP_CONTENT
        );
        wrapperParams.setMargins(margin, margin + topOffset, margin, margin);
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
     * 创建轨迹页面专用的 InfoWindow View
     */
    private View createTrackInfoWindow(MarkerInfoData infoData) {
        android.util.Log.d("CustomInfoWindow", "Creating track info window for: " + infoData.locationName);
        int width = dpToPx(215); // 宽度 215dp
        int height = dpToPx(106); // 高度 106dp
        int paddingHorizontal = dpToPx(12); // 左右边距 12dp
        int paddingTop = dpToPx(9);   // 上边距 9dp
        int paddingBottom = dpToPx(14);   // 下边距 14dp
        
        // 创建主容器 - 使用 RelativeLayout 来支持复杂布局
        RelativeLayout mainContainer = new RelativeLayout(context);
        mainContainer.setLayoutParams(new RelativeLayout.LayoutParams(width, height));
        
        // 设置背景图片
        try {
            // 从 assets 加载背景图片
            Bitmap backgroundBitmap = getBitmapFromAssets("kissu_marker_bg.png");
            if (backgroundBitmap != null) {
                android.util.Log.d("CustomInfoWindow", "Successfully loaded background image");
                BitmapDrawable backgroundDrawable = new BitmapDrawable(context.getResources(), backgroundBitmap);
                mainContainer.setBackground(backgroundDrawable);
            } else {
                android.util.Log.w("CustomInfoWindow", "Background image is null, using fallback");
                // 如果背景图片加载失败，使用白色圆角背景
                GradientDrawable fallbackBg = new GradientDrawable();
                fallbackBg.setColor(Color.WHITE);
                fallbackBg.setCornerRadius(dpToPx(8));
                mainContainer.setBackground(fallbackBg);
            }
        } catch (Exception e) {
            android.util.Log.e("CustomInfoWindow", "Exception loading background image", e);
            // 背景图片加载失败，使用白色圆角背景
            GradientDrawable fallbackBg = new GradientDrawable();
            fallbackBg.setColor(Color.WHITE);
            fallbackBg.setCornerRadius(dpToPx(8));
            mainContainer.setBackground(fallbackBg);
        }
        
        mainContainer.setPadding(paddingHorizontal, paddingTop, paddingHorizontal, paddingBottom);
        
        // 创建垂直布局的内容容器
        LinearLayout contentContainer = new LinearLayout(context);
        contentContainer.setOrientation(LinearLayout.VERTICAL);
        RelativeLayout.LayoutParams contentParams = new RelativeLayout.LayoutParams(
            RelativeLayout.LayoutParams.MATCH_PARENT, 
            RelativeLayout.LayoutParams.WRAP_CONTENT
        );
        contentContainer.setLayoutParams(contentParams);
        
        // 第一行：位置名称 + 关闭按钮（水平布局）
        LinearLayout titleRow = new LinearLayout(context);
        titleRow.setOrientation(LinearLayout.HORIZONTAL);
        titleRow.setGravity(Gravity.TOP); // 顶部对齐
        
        LinearLayout.LayoutParams titleRowParams = new LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        );
        titleRowParams.bottomMargin = dpToPx(6);
        titleRow.setLayoutParams(titleRowParams);
        
        // 位置名称（占据剩余空间）
        if (infoData.locationName != null && !infoData.locationName.isEmpty()) {
            TextView locationNameView = new TextView(context);
            locationNameView.setText(infoData.locationName);
            
            locationNameView.setTextSize(TypedValue.COMPLEX_UNIT_SP, 14);
            locationNameView.setTextColor(0xFF333333); // 深灰色
            locationNameView.setMaxLines(2); // 最多显示两行
            locationNameView.setSingleLine(false); // 允许多行
            locationNameView.setEllipsize(TextUtils.TruncateAt.END);
            locationNameView.setGravity(Gravity.LEFT);
            
            // 设置权重为1，占据剩余空间，并限制最大宽度
            LinearLayout.LayoutParams nameParams = new LinearLayout.LayoutParams(
                0,
                LinearLayout.LayoutParams.WRAP_CONTENT,
                1.0f
            );
            nameParams.rightMargin = dpToPx(8); // 与关闭按钮的间距
            locationNameView.setLayoutParams(nameParams);
            locationNameView.setMaxWidth(dpToPx(180)); //   限制最大宽度为180dp
            
            titleRow.addView(locationNameView);
        }
        
        // 关闭按钮（固定宽度）
        ImageView closeButton = new ImageView(context);
        int closeButtonSize = dpToPx(20); // 关闭按钮大小 20dp
        LinearLayout.LayoutParams closeParams = new LinearLayout.LayoutParams(closeButtonSize, closeButtonSize);
        closeParams.gravity = Gravity.TOP; // 关闭按钮顶部对齐
        closeButton.setLayoutParams(closeParams);
        
        // 设置关闭按钮图标
        try {
            Bitmap closeBitmap = getBitmapFromAssets("kissu3_close.webp");
            if (closeBitmap != null) {
                android.util.Log.d("CustomInfoWindow", "Successfully loaded close button icon");
                closeButton.setImageBitmap(closeBitmap);
            } else {
                android.util.Log.w("CustomInfoWindow", "Close button icon is null, using fallback");
                // 如果图标加载失败，使用系统默认图标
                closeButton.setImageResource(android.R.drawable.ic_menu_close_clear_cancel);
                closeButton.setColorFilter(0xFF999999); // 浅灰色
            }
        } catch (Exception e) {
            android.util.Log.e("CustomInfoWindow", "Exception loading close button icon", e);
            // 图标加载失败，使用系统默认图标
            closeButton.setImageResource(android.R.drawable.ic_menu_close_clear_cancel);
            closeButton.setColorFilter(0xFF999999); // 浅灰色
        }
        closeButton.setScaleType(ImageView.ScaleType.CENTER_INSIDE);
        
        // 添加点击事件
        closeButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                // 通过 MethodChannel 通知 Flutter 关闭 InfoWindow
                if (methodChannel != null) {
                    methodChannel.invokeMethod("onInfoWindowClose", null);
                }
                // 直接隐藏 InfoWindow
                hideCurrentInfoWindow();
            }
        });
        
        titleRow.addView(closeButton);
        contentContainer.addView(titleRow);
        
        // 第二行：图标 + 停留时长
        if (infoData.stayDuration != null && !infoData.stayDuration.isEmpty()) {
            LinearLayout iconDurationLayout = new LinearLayout(context);
            iconDurationLayout.setOrientation(LinearLayout.HORIZONTAL);
            iconDurationLayout.setGravity(Gravity.LEFT | Gravity.CENTER_VERTICAL);
            
            LinearLayout.LayoutParams iconDurationParams = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            );
            iconDurationParams.bottomMargin = dpToPx(4);
            iconDurationLayout.setLayoutParams(iconDurationParams);
            
            // 创建位置图标
            ImageView locationIcon = new ImageView(context);
            int iconSize = dpToPx(16); // 图标大小 16dp
            LinearLayout.LayoutParams iconParams = new LinearLayout.LayoutParams(iconSize, iconSize);
            iconParams.rightMargin = dpToPx(6); // 与文字的间距
            locationIcon.setLayoutParams(iconParams);
            
            // 加载位置图标
            try {
                Bitmap iconBitmap = getBitmapFromAssets("kissu_track_location.webp");
                if (iconBitmap != null) {
                    android.util.Log.d("CustomInfoWindow", "Successfully loaded location icon");
                    locationIcon.setImageBitmap(iconBitmap);
                } else {
                    android.util.Log.w("CustomInfoWindow", "Location icon is null, using fallback");
                    // 如果图标加载失败，设置一个默认的颜色圆圈
                    GradientDrawable defaultIcon = new GradientDrawable();
                    defaultIcon.setShape(GradientDrawable.OVAL);
                    defaultIcon.setColor(0xFFFF69B4); // 粉色
                    locationIcon.setBackground(defaultIcon);
                }
            } catch (Exception e) {
                android.util.Log.e("CustomInfoWindow", "Exception loading location icon", e);
                // 图标加载失败，设置默认颜色圆圈
                GradientDrawable defaultIcon = new GradientDrawable();
                defaultIcon.setShape(GradientDrawable.OVAL);
                defaultIcon.setColor(0xFFFF69B4); // 粉色
                locationIcon.setBackground(defaultIcon);
            }
            
            // 停留时长文本
            TextView stayDurationView = new TextView(context);
            stayDurationView.setText(infoData.stayDuration);
            stayDurationView.setTextSize(TypedValue.COMPLEX_UNIT_SP, 14);
            stayDurationView.setTypeface(null, Typeface.BOLD);
            stayDurationView.setTextColor(0xFF333333); // 中灰色
            stayDurationView.setMaxLines(1);
            stayDurationView.setSingleLine(true);
            
            iconDurationLayout.addView(locationIcon);
            iconDurationLayout.addView(stayDurationView);
            contentContainer.addView(iconDurationLayout);
        }
        
        // 第三行：停留时间
        if (infoData.stayTime != null && !infoData.stayTime.isEmpty()) {
            TextView stayTimeView = new TextView(context);
            stayTimeView.setText(infoData.stayTime);
            
            stayTimeView.setTextSize(TypedValue.COMPLEX_UNIT_SP, 12);
            stayTimeView.setTextColor(0xFF333333); // 浅灰色
            stayTimeView.setMaxLines(2); // 最多显示两行
            stayTimeView.setSingleLine(false); // 允许多行
            stayTimeView.setEllipsize(TextUtils.TruncateAt.END);
            stayTimeView.setGravity(Gravity.LEFT);
            
            LinearLayout.LayoutParams stayTimeParams = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            );
            stayTimeView.setLayoutParams(stayTimeParams);
            stayTimeView.setMaxWidth(dpToPx(250)); // 限制最大宽度
            
            contentContainer.addView(stayTimeView);
        }
        
        mainContainer.addView(contentContainer);
        
        // 创建外层透明容器，避免边框显示
        FrameLayout outerContainer = new FrameLayout(context);
        outerContainer.setBackgroundColor(Color.TRANSPARENT);
        int margin = dpToPx(2); // 2dp 的透明边距
        int topOffset = dpToPx(15); // 向下偏移 15dp，补偿原marker占用的空间
        FrameLayout.LayoutParams wrapperParams = new FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.WRAP_CONTENT,
            FrameLayout.LayoutParams.WRAP_CONTENT
        );
        wrapperParams.setMargins(margin, margin + topOffset, margin, margin);
        mainContainer.setLayoutParams(wrapperParams);
        outerContainer.addView(mainContainer);
        
        // 测量和布局
        outerContainer.measure(
            View.MeasureSpec.makeMeasureSpec(width + margin * 2, View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED)
        );
        outerContainer.layout(0, 0, outerContainer.getMeasuredWidth(), outerContainer.getMeasuredHeight());
        
        return outerContainer;
    }
    
    /**
     * 从 assets 加载图片
     */
    private Bitmap getBitmapFromAssets(String fileName) {
        try {
            return BitmapFactory.decodeStream(context.getAssets().open(fileName));
        } catch (Exception e) {
            android.util.Log.e("CustomInfoWindow", "Failed to load asset: " + fileName, e);
            return null;
        }
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
        
        // 轨迹页面专用字段
        public boolean isTrackStyle;      // 是否使用轨迹样式
        public String stayDuration;       // 停留时长，如 "停留了1小时21分钟"
        public String stayTime;           // 停留时间，如 "21:52~23:12"

        public MarkerInfoData(boolean hasCustomView, String locationName, String address) {
            this.hasCustomView = hasCustomView;
            this.locationName = locationName;
            this.address = address;
            this.isTrackStyle = false;
            this.stayDuration = null;
            this.stayTime = null;
        }
        
        // 轨迹样式的构造函数
        public MarkerInfoData(boolean hasCustomView, String locationName, String stayDuration, String stayTime) {
            this.hasCustomView = hasCustomView;
            this.locationName = locationName;
            this.address = null;
            this.isTrackStyle = true;
            this.stayDuration = stayDuration;
            this.stayTime = stayTime;
        }
    }
    
    /**
     * 隐藏当前显示的 InfoWindow
     */
    public void hideCurrentInfoWindow() {
        if (currentInfoWindowMarker != null) {
            currentInfoWindowMarker.hideInfoWindow();
            currentInfoWindowMarker = null;
        }
    }
}

