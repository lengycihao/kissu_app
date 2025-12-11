# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# 支付宝SDK
-keep class com.alipay.android.app.IAlixPay{*;}
-keep class com.alipay.android.app.IAlixPay$Stub{*;}
-keep class com.alipay.android.app.IRemoteServiceCallback{*;}
-keep class com.alipay.android.app.IRemoteServiceCallback$Stub{*;}
-keep class com.alipay.sdk.app.PayTask{ public *;}
-keep class com.alipay.sdk.app.AuthTask{ public *;}
-keep class com.alipay.sdk.app.H5PayCallback {
    <fields>;
    <methods>;
}
-keep class com.alipay.android.phone.mrpc.core.** { *; }
-keep class com.alipay.apmobilesecuritysdk.** { *; }
-keep class com.alipay.mobile.framework.service.annotation.** { *; }
-keep class com.alipay.mobilesecuritysdk.face.** { *; }
-keep class com.alipay.tscenter.biz.rpc.** { *; }
-keep class org.json.alipay.** { *; }
-keep class com.alipay.tscenter.** { *; }
-keep class com.ta.utdid2.** { *;}
-keep class com.ut.device.** { *;}

# ============ 微信SDK完整混淆规则 ============
# 微信开放平台SDK
-keep class com.tencent.mm.opensdk.** {
    *;
}
-keep class com.tencent.wxop.** {
    *;
}
-keep class com.tencent.mm.sdk.** {
    *;
}

# 微信企业客服
-keep class com.tencent.wework.** {
    *;
}

# Flutter微信插件
-keep class io.flutter.plugins.wechat.** {
    *;
}
-keep class com.jarvanmo.fluwx.** {
    *;
}

# 微信回调和接口
-keep class * implements com.tencent.mm.opensdk.openapi.IWXAPIEventHandler {
    *;
}
-keep class * implements com.tencent.mm.opensdk.api.IWXAPIEventHandler {
    *;
}

# 保留微信相关注解
-keepattributes *Annotation*
-keepattributes Signature
-keep public class * extends java.lang.Exception{*;}

# 日志过滤规则 - 减少媒体编解码器日志输出
# 在发布版本中移除调试和详细日志，但保留警告日志用于问题排查
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# 保留警告和错误日志用于调试
-keep class android.util.Log {
    public static *** w(...);
    public static *** e(...);
}

# ============ 高德地图SDK完整混淆规则 ============
# 高德定位SDK
-keep class com.amap.api.location.**{*;}
-keep class com.amap.api.fence.**{*;}
-keep class com.loc.**{*;}
-dontwarn com.amap.api.location.**
-dontwarn com.loc.**

# 高德地图SDK - 核心类
-keep class com.amap.api.maps.**{*;}
-keep class com.amap.api.mapcore.**{*;}
-keep class com.amap.api.maps2d.**{*;}
-keep class com.amap.api.navi.**{*;}
-keep class com.amap.api.services.**{*;}
-keep class com.autonavi.**{*;}
-keep class com.autonavi.amap.mapcore.**{*;}

# 高德地图 - 3D地图
-keep class com.amap.api.maps.model.**{*;}
-keep class com.amap.api.mapcore.util.**{*;}

# 高德地图 - OpenGL相关
-keep class com.amap.api.maps.AMapException { *; }
-keep class com.amap.api.maps.AMap { *; }
-keep class com.amap.api.maps.AMapOptions { *; }

# 高德地图 - 忽略警告
-dontwarn com.amap.api.**
-dontwarn com.autonavi.**
-dontwarn com.loc.es.**
-dontwarn com.loc.ei.**
-dontwarn com.loc.e.**

# 高德地图 - 保留Native方法
-keepclasseswithmembernames class * {
    native <methods>;
}

# 高德地图 - 保留自定义View
-keep public class * extends android.view.View {
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
    public <init>(android.content.Context, android.util.AttributeSet, int);
    public void set*(...);
}

# JPush推送SDK保护规则
-dontoptimize
-dontpreverify
-keep class cn.jpush.** { *; }
-keep class * extends cn.jpush.android.helpers.JPushMessageReceiver { *; }
-dontwarn cn.jpush.**

# 友盟分享SDK保护规则
-keep class com.umeng.** {*;}
-keep class com.uc.** {*;}
-keepclassmembers class * {
   public <init> (org.json.JSONObject);
}
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# 腾讯QQ SDK
-keep class com.tencent.open.TDialog$*
-keep class com.tencent.open.TDialog$* {*;}
-keep class com.tencent.open.PKDialog
-keep class com.tencent.open.PKDialog {*;}
-keep class com.tencent.open.PKDialog$*
-keep class com.tencent.open.PKDialog$* {*;}

# Gson规则（如果使用）
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# 保留所有数据模型类
-keep class * implements java.io.Serializable {*;}
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ============ 腾讯云IM SDK混淆规则 ============
-keep class com.tencent.imsdk.** { *; }
-keep class com.tencent.qcloud.** { *; }
-keep class com.tencent.tuicore.** { *; }
-keep class com.tencent.tuikit.** { *; }
-dontwarn com.tencent.imsdk.**
-dontwarn com.tencent.qcloud.**

# ============ OpenInstall SDK混淆规则 ============
-keep class com.openinstall.** { *; }
-dontwarn com.openinstall.**
-keepclassmembers class * {
    public <init>(org.json.JSONObject);
}

# ============ OAID SDK混淆规则 ============
-keep class com.bun.miitmdid.** { *; }
-keep class XI.CA.XI.**{*;}
-keep class XI.K0.XI.**{*;}
-keep class XI.XI.K0.**{*;}
-keep class XI.vs.K0.**{*;}
-keep class XI.xo.XI.XI.**{*;}
-keep class com.asus.msa.SupplementaryDID.**{*;}
-keep class com.asus.msa.sdid.**{*;}
-keep class com.huawei.hms.ads.identifier.**{*;}
-keep class com.samsung.android.deviceidservice.**{*;}
-keep class com.zui.opendeviceidlibrary.**{*;}
-keep public class com.netease.nis.sdkwrapper.Utils {public <methods>;}

# ============ Lottie动画混淆规则 ============
# Lottie核心类
-keep class com.airbnb.lottie.** { *; }
-dontwarn com.airbnb.lottie.**

# 保留Lottie动画相关的模型类
-keep class com.airbnb.lottie.model.** { *; }
-keep class com.airbnb.lottie.animation.** { *; }
-keep class com.airbnb.lottie.value.** { *; }

# 保留Lottie的解析器
-keep class com.airbnb.lottie.parser.** { *; }

# 保留Lottie的网络相关类
-keep class com.airbnb.lottie.network.** { *; }

# ============ Flutter插件增强保护 ============
# 保护所有Flutter插件的反射调用
-keep class io.flutter.embedding.** { *; }

# 保护原生方法调用（已在高德地图规则中定义，这里补充确保覆盖）
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}

# 保护序列化类的详细规则
-keepnames class * implements java.io.Serializable
-keepclassmembers class * implements java.io.Serializable {
    !static !transient <fields>;
}