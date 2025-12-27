package com.amap.flutter.map.overlays.marker;

import android.animation.ObjectAnimator;
import android.animation.ValueAnimator;
import android.view.animation.AccelerateDecelerateInterpolator;

import com.amap.api.maps.model.BitmapDescriptor;
import com.amap.api.maps.model.LatLng;
import com.amap.api.maps.model.Marker;
import com.amap.api.maps.model.animation.ScaleAnimation;
import com.amap.api.maps.model.animation.AlphaAnimation;
import com.amap.api.maps.model.animation.AnimationSet;
import com.amap.api.maps.model.animation.RotateAnimation;

/**
 * @author whm
 * @date 2020/11/6 6:18 PM
 * @mail hongming.whm@alibaba-inc.com
 * @since
 */
class MarkerController implements MarkerOptionsSink {
    private final Marker marker;
    private final String markerId;
    private ScaleAnimation breathAnimation;
    private AnimationSet rippleAnimation;
    private RotateAnimation swingAnimation;
    private boolean isAnimating = false;
    private boolean isRippleAnimating = false;
    private boolean isSwingAnimating = false;

    MarkerController(Marker marker) {
        this.marker = marker;
        markerId = marker.getId();
    }

    public String getMarkerId() {
        return markerId;
    }

    public void remove() {
        if (null != marker) {
            marker.remove();
        }
    }

    public LatLng getPosition() {
        if(null != marker) {
            return marker.getPosition();
        }
        return null;
    }

    @Override
    public void setAlpha(float alpha) {
        marker.setAlpha(alpha);
    }

    @Override
    public void setAnchor(float u, float v) {
        marker.setAnchor(u, v);
    }

    @Override
    public void setDraggable(boolean draggable) {
        marker.setDraggable(draggable);
    }

    @Override
    public void setFlat(boolean flat) {
        marker.setFlat(flat);
    }

    @Override
    public void setIcon(BitmapDescriptor bitmapDescriptor) {
        marker.setIcon(bitmapDescriptor);
    }

    @Override
    public void setTitle(String title) {
        marker.setTitle(title);
    }

    @Override
    public void setSnippet(String snippet) {
        marker.setSnippet(snippet);
    }

    @Override
    public void setPosition(LatLng position) {
        marker.setPosition(position);
    }

    @Override
    public void setRotation(float rotation) {
        marker.setRotateAngle(rotation);
    }

    @Override
    public void setVisible(boolean visible) {
        marker.setVisible(visible);
    }

    @Override
    public void setZIndex(float zIndex) {
        marker.setZIndex(zIndex);
    }

    @Override
    public void setInfoWindowEnable(boolean enable) {
        marker.setInfoWindowEnable(enable);
    }

    @Override
    public void setClickable(boolean clickable) {
        marker.setClickable(clickable);
    }

    public void showInfoWindow() {
        marker.showInfoWindow();
    }

    public void hideInfoWindow() {
        marker.hideInfoWindow();
    }

    /**
     * 启动呼吸动画（横纵交替拉伸效果）
     * 
     * 🎯 iOS原版实现：
     * - 横向拉伸：X=1.03, Y=0.98（横向拉伸，纵向压缩）
     * - 纵向拉伸：X=0.98, Y=1..03（横向压缩，纵向拉伸）
     * - 两种状态交替变换，产生"呼吸"效果
     * 
     * 🚀 性能优势：
     * - 使用高德地图原生ScaleAnimation（硬件加速）
     * - 60fps流畅运行
     * - 在原生层执行，零跨平台开销
     * 
     * @param duration 动画时长（毫秒）
     */
    public void startBreathAnimation(long duration) {
        if (marker == null || isAnimating) {
            return;
        }

        // 🎯 iOS原版参数：横向和纵向交替拉伸
        // 第一阶段：横向拉伸(1.03, 0.98) -> 第二阶段：纵向拉伸(0.98, 1.03)
        breathAnimation = new ScaleAnimation(1.03f, 0.98f, 0.98f, 1.03f);
        breathAnimation.setDuration(duration);
        
        // 设置为无限重复、往返播放
        breathAnimation.setRepeatCount(ValueAnimator.INFINITE);
        breathAnimation.setRepeatMode(ValueAnimator.REVERSE);
        
        // 使用缓动插值器，让动画更自然
        breathAnimation.setInterpolator(new AccelerateDecelerateInterpolator());
        
        // 启动动画
        marker.setAnimation(breathAnimation);
        marker.startAnimation();
        
        isAnimating = true;
    }

    /**
     * 停止呼吸动画
     */
    public void stopBreathAnimation() {
        if (marker == null || !isAnimating) {
            return;
        }

        // 停止并清除动画
        if (breathAnimation != null) {
            marker.setAnimation(null);
            breathAnimation = null;
        }
        
        isAnimating = false;
    }

    /**
     * 启动波纹动画（扩散+透明度渐变）
     * 
     * 🌊 波纹效果：
     * - 从 1.0 扩大到 1.5倍
     * - 透明度从 0.6 渐变到 0.0
     * - 循环播放，产生持续扩散效果
     * 
     * @param duration 动画周期（毫秒）
     */
    public void startRippleAnimation(long duration) {
        if (marker == null || isRippleAnimating) {
            return;
        }

        // 创建扩散动画：从 1.0 到 1.5个
        ScaleAnimation scaleAnim = new ScaleAnimation(1.0f, 1.5f, 1.0f, 1.5f);
        scaleAnim.setDuration(duration);
        scaleAnim.setRepeatCount(ValueAnimator.INFINITE); // 在子动画上设置重复
        scaleAnim.setRepeatMode(ValueAnimator.RESTART);
        
        // 创建透明度动画：从 0.6 渐变到 0.0
        AlphaAnimation alphaAnim = new AlphaAnimation(0.6f, 0.0f);
        alphaAnim.setDuration(duration);
        alphaAnim.setRepeatCount(ValueAnimator.INFINITE); // 在子动画上设置重复
        alphaAnim.setRepeatMode(ValueAnimator.RESTART);
        
        // 组合动画
        rippleAnimation = new AnimationSet(false); // false表示不共享插值器
        rippleAnimation.addAnimation(scaleAnim);
        rippleAnimation.addAnimation(alphaAnim);
        
        // 使用线性插值器，让扩散更均匀
        rippleAnimation.setInterpolator(new android.view.animation.LinearInterpolator());
        
        // 启动动画
        marker.setAnimation(rippleAnimation);
        marker.startAnimation();
        
        isRippleAnimating = true;
    }

    /**
     * 停止波纹动画
     */
    public void stopRippleAnimation() {
        if (marker == null || !isRippleAnimating) {
            return;
        }

        // 停止并清除动画
        if (rippleAnimation != null) {
            marker.setAnimation(null);
            rippleAnimation = null;
        }
        
        // 恢复透明度
        marker.setAlpha(1.0f);
        
        isRippleAnimating = false;
    }

    /**
     * 🔄 启动摆动动画（雨刷器效果）
     * 
     * 以Marker的锚点（尖尖）为圆心，左右摆动
     * 效果类似雨刷器，两个头像先靠拢再分开
     * 
     * @param fromAngle 起始角度（当前旋转角度）
     * @param toAngle 目标角度（摆动到的角度）
     * @param duration 单次摆动时长（毫秒）
     */
    public void startSwingAnimation(float fromAngle, float toAngle, long duration) {
        if (marker == null || isSwingAnimating) {
            return;
        }

        // 创建旋转动画：从fromAngle摆动到toAngle
        // 参数：fromDegree, toDegree, pivotX, pivotY, pivotZ
        // pivotX=0, pivotY=0 表示以锚点为旋转中心
        swingAnimation = new RotateAnimation(fromAngle, toAngle, 0, 0, 0);
        swingAnimation.setDuration(duration);
        
        // 设置为无限重复、往返播放（形成摆动效果）
        swingAnimation.setRepeatCount(ValueAnimator.INFINITE);
        swingAnimation.setRepeatMode(ValueAnimator.REVERSE);
        
        // 使用缓动插值器，让摆动更自然
        swingAnimation.setInterpolator(new AccelerateDecelerateInterpolator());
        
        // 启动动画
        marker.setAnimation(swingAnimation);
        marker.startAnimation();
        
        isSwingAnimating = true;
    }

    /**
     * 停止摆动动画
     */
    public void stopSwingAnimation() {
        if (marker == null || !isSwingAnimating) {
            return;
        }

        // 停止并清除动画
        if (swingAnimation != null) {
            marker.setAnimation(null);
            swingAnimation = null;
        }
        
        isSwingAnimating = false;
    }

    /**
     * 🎯 平滑移动Marker到目标位置（原生动画）
     * 
     * 使用高德地图原生平滑移动API，实现60fps流畅移动
     * 
     * 🚀 性能优势：
     * - 使用高德地图原生TranslateAnimation（GPU加速）
     * - 60fps流畅运行，无卡顿
     * - 在原生层执行，零跨平台通信开销
     * - 支持同时更新位置和旋转角度
     * 
     * @param targetPosition 目标位置
     * @param duration 动画时长（毫秒）
     * @param rotation 可选的旋转角度（度数，null表示不改变旋转）
     */
    public void moveMarkerSmoothly(LatLng targetPosition, long duration, Float rotation) {
        if (marker == null) {
            return;
        }

        try {
            // 🎯 使用高德地图原生平滑移动API
            // 创建位置动画
            com.amap.api.maps.model.animation.TranslateAnimation translateAnimation = 
                new com.amap.api.maps.model.animation.TranslateAnimation(targetPosition);
            translateAnimation.setDuration(duration);
            translateAnimation.setInterpolator(new android.view.animation.LinearInterpolator());
            
            // 如果需要同时更新旋转角度
            if (rotation != null) {
                // 创建旋转动画
                com.amap.api.maps.model.animation.RotateAnimation rotateAnimation = 
                    new com.amap.api.maps.model.animation.RotateAnimation(
                        marker.getRotateAngle(), 
                        rotation, 
                        0, 0, 0
                    );
                rotateAnimation.setDuration(duration);
                rotateAnimation.setInterpolator(new android.view.animation.LinearInterpolator());
                
                // 组合动画
                AnimationSet animationSet = new AnimationSet(true);
                animationSet.addAnimation(translateAnimation);
                animationSet.addAnimation(rotateAnimation);
                
                marker.setAnimation(animationSet);
            } else {
                // 只有位置动画
                marker.setAnimation(translateAnimation);
            }
            
            // 启动动画
            marker.startAnimation();
            
        } catch (Exception e) {
            // 如果动画失败，直接设置位置（降级方案）
            marker.setPosition(targetPosition);
            if (rotation != null) {
                marker.setRotateAngle(rotation);
            }
        }
    }

    /**
     * 获取Marker实例（供MarkersController使用）
     */
    public Marker getMarker() {
        return marker;
    }
}
