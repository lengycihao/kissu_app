12467): Won't deliver top position change in state=1
I/RmeSchedManager(12467): init Rme, version is: v1.0
I/RtgSchedEvent(12467): current pid:12467 AppType:-1
D/ActivityThread(12467): Won't deliver top position change in state=1
D/ActivityThread(12467): Won't deliver top position change in state=5
I/ActivityThread(12467): Performing restart of ActivityRecord{d50a333 token=android.os.BinderProxy@20c9e6d {com.yuluo.kissu/com.yuluo.kissu.MainActivity}} start=false callers:android.app.servertransaction.TransactionExecutor.performLifecycleSequence:310 android.app.servertransaction.TransactionExecutor.cycleToPath:265 android.app.servertransaction.TransactionExecutor.cycleToPath:247 android.app.servertransaction.TransactionExecutor.executeNonLifecycleItem:185 android.app.servertransaction.TransactionExecutor.executeTransactionItems:124 android.app.servertransaction.TransactionExecutor.execute:90 android.app.ActivityThread$H.handleMessage:3342 android.os.Handler.dispatchMessage:118 android.os.Looper.loopOnce:237 android.os.Looper.loop:325 
D/JIGUANG-JCore(12467): [JCoreHelper] runActionWithService action:sync_target
D/JIGUANG-JCore(12467): [JCoreHelper] runActionWithService action:handle_cache_message
D/JIGUANG-JCore(12467): [JCoreHelper] runActionWithService action:change_foreground
D/JIGUANG-JOperate(12467): [JOperateEventDispatch] onEvent:start_app,bundle:Bundle[{type=3}]
D/JIGUANG-JCore(12467): [JCoreGobal]  sendRtcToTcp  bundle=Bundle[{delay_time=0, force=true}]
D/JIGUANG-JOperate(12467): [JOperateEventDispatch] onEvent:activity_lifecycle,bundle:Bundle[{lifecycle_name=onActivityStarted, activity_hash=98053669, activity_name=com.yuluo.kissu.MainActivity, activity_intent=Intent { act=android.intent.action.MAIN cat=[android.intent.category.LAUNCHER] flg=0x30000000 cmp=com.yuluo.kissu/.MainActivity (has extras) }}]
I/DecorView[](12467): set decor visibility 0
D/OpenInstallPlugin(12467): onNewIntent
D/OpenInstallPlugin(12467): getWakeUp : alwaysCallback=false
D/JIGUANG-JOperate(12467): [JOperateEventDispatch] onEvent:activity_lifecycle,bundle:Bundle[{lifecycle_name=onActivityResumed, activity_hash=98053669, activity_name=com.yuluo.kissu.MainActivity, activity_intent=Intent { act=android.intent.action.MAIN cat=[android.intent.category.LAUNCHER] flg=0x30000000 cmp=com.yuluo.kissu/.MainActivity (has extras) }}]
I/flutter (12467): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (12467): │ #0   _AppLifecycleObserver.didChangeAppLifecycleState (package:kissu_app/services/payment_service.dart:603:29)
payment_service.dart:603
I/flutter (12467): │ #1   WidgetsBinding.handleAppLifecycleStateChanged (package:flutter/src/widgets/binding.dart:1060:16)
binding.dart:1060
I/flutter (12467): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (12467): │ 💡 应用生命周期变化: AppLifecycleState.hidden
I/flutter (12467): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (12467): 📱 应用已在后台，不重复记录时间（当前记录: 2025-10-22 01:54:18.400206）
I/flutter (12467): 📱 首页：应用进入后台，停止红点轮询
I/flutter (12467): 应用状态变化: AppLifecycleState.hidden
I/flutter (12467): 👁️ 应用被隐藏
I/flutter (12467): ℹ️ 隐藏状态定位服务已在运行，继续定位
I/flutter (12467): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (12467): │ #0   _AppLifecycleObserver.didChangeAppLifecycleState (package:kissu_app/services/payment_service.dart:603:29)
payment_service.dart:603
I/flutter (12467): │ #1   WidgetsBinding.handleAppLifecycleStateChanged (package:flutter/src/widgets/binding.dart:1060:16)
binding.dart:1060
I/flutter (12467): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (12467): │ 💡 应用生命周期变化: AppLifecycleState.inactive
I/flutter (12467): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (12467): 应用状态变化: AppLifecycleState.inactive
I/flutter (12467): ⏸️ 应用变为非活跃状态
I/DecorView[](12467): set decor visibility 0
I/SurfaceView(12467): 19753717 win vis 0
D/VRI[MainActivity](12467): relayoutWindow: mRelayoutRequested = true
I/BufferQueueConsumer(12467): [](id:30b300000004,api:0,p:-1,c:12467) connect: controlledByApp=false
D/FullScreenUtils(12467): isNeedToHideStatusBar: splitscreenstate=-1
D/libEGL  (12467): [eglCreateWindowSurface] start window is 12970367432059141248
I/BufferQueueProducer(12467): [VRI[MainActivity]#4(BLAST Consumer)4](id:30b300000004,api:0,p:-1,c:12467) connect: api=1 producerControlledByApp=true
I/SurfaceView(12467): 19753717 setWindowStopped false
I/BufferQueueConsumer(12467): [](id:30b300000005,api:0,p:-1,c:12467) connect: controlledByApp=false
I/SurfaceView(12467): 19753717 create Surface(name=SurfaceView[com.yuluo.kissu/com.yuluo.kissu.MainActivity])/@0x987f5ae Surface(name=Background for SurfaceView[com.yuluo.kissu/com.yuluo.kissu.MainActivity])/@0xe52cf4f Surface(name=SurfaceView[com.yuluo.kissu/com.yuluo.kissu.MainActivity](BLAST))/@0xa8686dc android.graphics.BLASTBufferQueue@286a3e5
I/BufferQueueProducer(12467): [SurfaceView[com.yuluo.kissu/com.yuluo.kissu.MainActivity]#5(BLAST Consumer)5](id:30b300000005,api:0,p:-1,c:12467) connect: api=1 producerControlledByApp=true
E/qdgralloc(12467): GetSize: Unrecognized pixel format: 0x38
E/Gralloc4(12467): isSupported(1, 1, 56, 1, ...) failed with 5
E/GraphicBufferAllocator(12467): Failed to allocate (4 x 4) layerCount 1 format 56 usage b00: 5
D/GraphicBufferAllocator(12467): Allocated buffers:
D/GraphicBufferAllocator(12467): Total allocated (estimate): 0.00 KB
E/AHardwareBuffer(12467): GraphicBuffer(w=4, h=4, lc=1) failed (Unknown error -5), handle=0x0
E/qdgralloc(12467): GetSize: Unrecognized pixel format: 0x3b
E/Gralloc4(12467): isSupported(1, 1, 59, 1, ...) failed with 5
E/GraphicBufferAllocator(12467): Failed to allocate (4 x 4) layerCount 1 format 59 usage b00: 5
D/GraphicBufferAllocator(12467): Allocated buffers:
D/GraphicBufferAllocator(12467): Total allocated (estimate): 0.00 KB
E/AHardwareBuffer(12467): GraphicBuffer(w=4, h=4, lc=1) failed (Unknown error -5), handle=0x0
E/qdgralloc(12467): GetSize: Unrecognized pixel format: 0x38
E/Gralloc4(12467): isSupported(1, 1, 56, 1, ...) failed with 5
E/GraphicBufferAllocator(12467): Failed to allocate (4 x 4) layerCount 1 format 56 usage b00: 5
D/GraphicBufferAllocator(12467): Allocated buffers:
D/GraphicBufferAllocator(12467): Total allocated (estimate): 0.00 KB
E/AHardwareBuffer(12467): GraphicBuffer(w=4, h=4, lc=1) failed (Unknown error -5), handle=0x0
E/qdgralloc(12467): GetSize: Unrecognized pixel format: 0x3b
E/Gralloc4(12467): isSupported(1, 1, 59, 1, ...) failed with 5
E/GraphicBufferAllocator(12467): Failed to allocate (4 x 4) layerCount 1 format 59 usage b00: 5
D/GraphicBufferAllocator(12467): Allocated buffers:
D/GraphicBufferAllocator(12467): Total allocated (estimate): 0.00 KB
E/AHardwareBuffer(12467): GraphicBuffer(w=4, h=4, lc=1) failed (Unknown error -5), handle=0x0
D/MobclickAgent(12467): 延续上一个会话: 39346076AF6E201B12A3A3925CB8C35F
5
W/qdgralloc(12467): getInterlacedFlag: getMetaData returned -22, defaulting to interlaced_flag = 0
W/SQLiteLog(12467): (28) double-quoted string literal: "39346076AF6E201B12A3A3925CB8C35F"
W/SQLiteLog(12467): (28) double-quoted string literal: ""
W/SQLiteLog(12467): (28) double-quoted string literal: "39346076AF6E201B12A3A3925CB8C35F"
W/SQLiteLog(12467): (28) double-quoted string literal: "-1"
D/UMLog   (12467): 当前发送策略为: 间隔发送。间隔时间为：90秒。详见链接 https://developer.umeng.com/docs/66632/detail/66976?um_channel=sdk
W/SQLiteLog(12467): (28) double-quoted string literal: "39346076AF6E201B12A3A3925CB8C35F"
W/SQLiteLog(12467): (28) double-quoted string literal: ""
W/SQLiteLog(12467): (28) double-quoted string literal: "39346076AF6E201B12A3A3925CB8C35F"
W/SQLiteLog(12467): (28) double-quoted string literal: "-1"
D/MobclickAgent(12467): 数据发送策略 : ReportByInterval
D/UMLog   (12467): 当前发送策略为: 间隔发送。间隔时间为：90秒。详见链接 https://developer.umeng.com/docs/66632/detail/66976?um_channel=sdk
D/TrafficStats(12467): tagSocket(111) with statsTag=0xffffffff, statsUid=-1
I/SurfaceView(12467): updateSurface: handleSyncNoBuffer
I/SurfaceCallbackHelper(12467): Run surfaceRedrawNeededAsync of app because callback is Callback2
I/VRI[MainActivity](12467): addToSync: syncable:android.window.SurfaceSyncGroup@33265e
I/HwViewRootImpl(12467): removeInvalidNode all the node in jank list is out of time
I/SurfaceControl(12467): nativeRelease 0xb4000075f63026f0 count: 1 name: Surface(name=c9f755a StatusBar)/@0xe1e8fc - animation-leash of insets_animation#87127
I/SurfaceControl(12467): nativeRelease 0xb4000075f62d4df0 count: 1 name: Surface(name=79cf4ee NavigationBar0)/@0x4152b85 - animation-leash of insets_animation#87128
I/VRI[MainActivity](12467): send MSG_WINDOW_FOCUS_CHANGED msg
I/InputEventReceiver(12467): consumeEvents focus, 1
I/flutter (12467): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (12467): │ #0   _AppLifecycleObserver.didChangeAppLifecycleState (package:kissu_app/services/payment_service.dart:603:29)
payment_service.dart:603
I/flutter (12467): │ #1   WidgetsBinding.handleAppLifecycleStateChanged (package:flutter/src/widgets/binding.dart:1060:16)
binding.dart:1060
I/flutter (12467): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (12467): │ 💡 应用生命周期变化: AppLifecycleState.resumed
I/flutter (12467): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (12467): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (12467): │ #0   _AppLifecycleObserver.didChangeAppLifecycleState (package:kissu_app/services/payment_service.dart:607:31)
payment_service.dart:607
I/flutter (12467): │ #1   WidgetsBinding.handleAppLifecycleStateChanged (package:flutter/src/widgets/binding.dart:1060:16)
binding.dart:1060
I/flutter (12467): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (12467): │ 💡 应用回到前台，检查支付状态: true
I/flutter (12467): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (12467): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (12467): │ #0   _AppLifecycleObserver.didChangeAppLifecycleState (package:kissu_app/services/payment_service.dart:611:33)
payment_service.dart:611
I/flutter (12467): │ #1   WidgetsBinding.handleAppLifecycleStateChanged (package:flutter/src/widgets/binding.dart:1060:16)
binding.dart:1060
I/flutter (12467): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (12467): │ 💡 💰 用户从微信返回，立即启动VIP状态轮询检测
I/flutter (12467): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (12467): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (12467): │ #0   PaymentService._startVipStatusPolling (package:kissu_app/services/payment_service.dart:491:13)
payment_service.dart:491
I/flutter (12467): │ #1   _AppLifecycleObserver.didChangeAppLifecycleState (package:kissu_app/services/payment_service.dart:612:25)
payment_service.dart:612
I/flutter (12467): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (12467): │ 💡 🔍 启动VIP状态轮询，最多轮询 30 次
I/flutter (12467): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (12467): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (12467): │ #0   PaymentService._checkVipStatus (package:kissu_app/services/payment_service.dart:520:15)
payment_service.dart:520
I/flutter (12467): │ #1   PaymentService._startVipStatusPolling (package:kissu_app/services/payment_service.dart:494:5)
payment_service.dart:494
I/flutter (12467): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (12467): │ 💡 🔍 检测VIP状态...
I/flutter (12467): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (12467): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (12467): │ #0   _AppLifecycleObserver.didChangeAppLifecycleState (package:kissu_app/services/payment_service.dart:615:33)
payment_service.dart:615
I/flutter (12467): │ #1   WidgetsBinding.handleAppLifecycleStateChanged (package:flutter/src/widgets/binding.dart:1060:16)
binding.dart:1060
I/flutter (12467): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (12467): │ ! 检测到支付进行中，等待5秒后检查是否需要重置
I/flutter (12467): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (12467): 📱 应用返回前台，检查是否需要提醒后台定位权限
I/flutter (12467): 📱 首页：应用返回前台，先获取红点数据再启动轮询
I/flutter (12467): 🏠 开始加载首页数据...
I/flutter (12467): INFO: 🏠 开始请求首页数据...
I/flutter (12467): 应用状态变化: AppLifecycleState.resumed
I/flutter (12467): 🔄 应用恢复前台，优化前台策略
I/flutter (12467): INFO: 网络信息缓存已清除
I/flutter (12467): 📡 已清除过期的网络信息缓存
I/flutter (12467): 🔧 外部调用：优化前台策略
I/flutter (12467): 🛑 停止前台定位服务...
I/flutter (12467): 🔧 停止后台保活任务 ID: 1761069258403
I/flutter (12467): 🔧 恢复前台位置采集模式
I/flutter (12467): ✅ 前台模式参数已应用：Hight_Accuracy / 5000ms / distanceFilter=-1.0
I/flutter (12467): 🔔 后台通知未显示，跳过隐藏
2
I/flutter (12467): ✅ 前台策略已优化
I/flutter (12467): 🏠 应用回到前台但首页不可见
V/ImeFocusController(12467): onWindowFocus: com.android.internal.policy.DecorView{cd1a9ee V.E...... R....... 0,0-1122,2442 aid=0}[MainActivity] softInputMode=STATE_UNSPECIFIED|ADJUST_RESIZE|IS_FORWARD_NAVIGATION
V/InputMethodManager(12467): Restarting due to mRestartOnNextWindowFocus as true
W/InputMethodManager(12467): startInputReason = 1
V/InputMethodManager(12467): Starting input: editorInfo=android.view.inputmethod.EditorInfo@406a33c ic=null
V/InputMethodManager(12467): START INPUT: view=com.android.internal.policy.DecorView{cd1a9ee V.E...... R....... 0,0-1122,2442 aid=0}[MainActivity],focus=false,windowFocus=true,window=android.view.ViewRootImpl$W@aaff51c,displayId=0,temporaryDetach=false,hasImeFocus=true ic=null editorInfo=android.view.inputmethod.EditorInfo@406a33c startInputFlags=VIEW_HAS_FOCUS|INITIAL_CONNECTION
D/JIGUANG-JOperate(12467): [JOperateEventDispatch] onEvent:activity_lifecycle,bundle:Bundle[{lifecycle_name=onActivityDestroyed, activity_hash=263264940, activity_name=com.jarvan.fluwx.wxapi.FluwxWXEntryActivity, activity_intent=Intent { flg=0x10000000 hwFlg=0x2000000 cmp=com.yuluo.kissu/.wxapi.WXPayEntryActivity (has extras) }}]
I/ActivityThread(12467): Remove activity client record, r= ActivityRecord{e6750fe token=android.os.BinderProxy@e21c4b9 {com.yuluo.kissu/com.yuluo.kissu.wxapi.WXPayEntryActivity}} token= android.os.BinderProxy@e21c4b9
2
I/flutter (12467): [LogManager] Not initialized. Message: DeviceUtil not initialized, using fallback deviceId
I/flutter (12467): 📱 通知权限无变化: true
D/BootCompletedReceiver(12467): 定位服务状态已保存: enabled=false
D/MainActivity(12467): 定位服务已停止，开机将不会自动启动
I/flutter (12467): ✅ 前台定位服务停止成功
I/flutter (12467): ✅ 前台服务停止成功
D/ForegroundLocationService(12467): 原生定位监听已停止
D/ForegroundLocationService(12467): 前台定位服务销毁
I/InputMethodManager(12467): handleMessage: MSG_SET_ACTIVE true, was false
V/InputMethodManager(12467): Starting input: Bind result=InputBindResult{result=SUCCESS_WAITING_IME_SESSION method=null id=com.baidu.input_hihonor/com.baidu.input_honor.ImeService sequence=6590 result=1 isInputMethodSuppressingSpellChecker=false}
I/InputMethodManager(12467): handleMessage: MSG_BIND 6590,com.baidu.input_hihonor/com.baidu.input_honor.ImeService
W/InputMethodManager(12467): startInputReason = 6
V/InputMethodManager(12467): Starting input: editorInfo=android.view.inputmethod.EditorInfo@7075279 ic=null
V/InputMethodManager(12467): Starting input: finished by someone else. view=com.android.internal.policy.DecorView{cd1a9ee V.E...... R....... 0,0-1122,2442 aid=0}[MainActivity],focus=false,windowFocus=true,window=android.view.ViewRootImpl$W@aaff51c,displayId=0,temporaryDetach=false,hasImeFocus=true servedView=com.android.internal.policy.DecorView{cd1a9ee V.E...... R....... 0,0-1122,2442 aid=0}[MainActivity],focus=false,windowFocus=true,window=android.view.ViewRootImpl$W@aaff51c,displayId=0,temporaryDetach=false,hasImeFocus=true mServedConnecting=false
I/flutter (12467): [LogManager] Not initialized. Message: GET http://dev-love-api.ikissu.cn/get/user
I/flutter (12467): [LogManager] Not initialized. Message: Headers: {network_debounce: true, token: ***HIDDEN***, version: 1.0.2, pkg: com.yuluo.kissu, deviceid: android-1761069263532, mobile-model: HONOR LGE-AN00, brand: HONOR, channel: kissu_oppo, network-name: wifi_OuHuaZhiChuang, power: 60, timestamp: 1761069263607, sign: 5951D9465F96CAD17825973328503976}
I/flutter (12467): [LogManager] Not initialized. Message: GET http://dev-love-api.ikissu.cn/index
I/flutter (12467): [LogManager] Not initialized. Message: Headers: {cache_control: noCache, token: ***HIDDEN***, version: 1.0.2, pkg: com.yuluo.kissu, deviceid: android-1761069263533, mobile-model: HONOR LGE-AN00, brand: HONOR, channel: kissu_oppo, network-name: wifi_OuHuaZhiChuang, power: 60, timestamp: 1761069263612, sign: 1AF78B93F3D0FBD8E1ADDFC054C0BA0B}
I/SurfaceControl(12467): nativeRelease 0xb4000075f62cff30 count: 1 name: Surface(name=c9f755a StatusBar)/@0xe1e8fc - animation-leash of insets_animation#87127
I/SurfaceControl(12467): nativeRelease 0xb4000075f6437630 count: 1 name: Surface(name=79cf4ee NavigationBar0)/@0x4152b85 - animation-leash of insets_animation#87128
W/System.err(12467): java.lang.SecurityException: listen
W/System.err(12467): 	at android.os.Parcel.createExceptionOrNull(Parcel.java:3262)
W/System.err(12467): 	at android.os.Parcel.createException(Parcel.java:3246)
W/System.err(12467): 	at android.os.Parcel.readException(Parcel.java:3229)
W/System.err(12467): 	at android.os.Parcel.readException(Parcel.java:3171)
W/System.err(12467): 	at com.android.internal.telephony.ITelephonyRegistry$Stub$Proxy.listenWithEventList(ITelephonyRegistry.java:1218)
W/System.err(12467): 	at android.telephony.TelephonyRegistryManager.listenFromListener(TelephonyRegistryManager.java:297)
W/System.err(12467): 	at android.telephony.TelephonyManager.listen(TelephonyManager.java:6912)
W/System.err(12467): 	at com.loc.es.o(Unknown Source:17)
W/System.err(12467): 	at com.loc.es.n(Unknown Source:5)
W/System.err(12467): 	at com.loc.es.<init>(Unknown Source:70)
W/System.err(12467): 	at com.loc.ei.a(Unknown Source:58)
W/System.err(12467): 	at com.loc.d.a(Unknown Source:2)
W/System.err(12467): 	at com.loc.d.b(Unknown Source:59)
W/System.err(12467): 	at com.loc.d.o(Unknown Source:6)
W/System.err(12467): 	at com.loc.d.p(Unknown Source:94)
W/System.err(12467): 	at com.loc.d.e(Unknown Source:0)
W/System.err(12467): 	at com.loc.d$a.handleMessage(Unknown Source:132)
W/System.err(12467): 	at android.os.Handler.dispatchMessage(Handler.java:118)
W/System.err(12467): 	at android.os.Looper.loopOnce(Looper.java:237)
W/System.err(12467): 	at android.os.Looper.loop(Looper.java:325)
W/System.err(12467): 	at android.os.HandlerThread.run(HandlerThread.java:85)
W/System.err(12467): 	at com.loc.d$b.run(Unknown Source:0)
W/System.err(12467): Caused by: android.os.RemoteException: Remote stack trace:
W/System.err(12467): 	at com.android.internal.telephony.TelephonyPermissions.enforceCarrierPrivilege(TelephonyPermissions.java:720)
W/System.err(12467): 	at com.android.internal.telephony.TelephonyPermissions.checkReadPhoneState(TelephonyPermissions.java:211)
W/System.err(12467): 	at com.android.internal.telephony.TelephonyPermissions.checkCallingOrSelfReadPhoneState(TelephonyPermissions.java:118)
W/System.err(12467): 	at com.android.server.TelephonyRegistry.checkListenerPermission(TelephonyRegistry.java:4095)
W/System.err(12467): 	at com.android.server.TelephonyRegistry.listen(TelephonyRegistry.java:1167)
W/System.err(12467): callee: null 2694/4032
I/flutter (12467): 🔍 原始响应URL: http://dev-love-api.ikissu.cn/get/user
I/flutter (12467): 🔍 原始响应状态码: 200
I/flutter (12467): 🔍 原始响应Headers: connection: keep-alive
I/flutter (12467): date: Tue, 21 Oct 2025 17:54:24 GMT
I/flutter (12467): transfer-encoding: chunked
I/flutter (12467): vary: Accept-Encoding
I/flutter (12467): content-encoding: gzip
I/flutter (12467): content-type: application/json; charset=utf-8
I/flutter (12467): server: nginx
I/flutter (12467): 🔍 原始响应Body: {code: 0, msg: 获取用户信息, time: 1761069264, data: {is_order_vip: 0, lately_unbind_time: 0, half_uid: 0, gender: 2, status: 1, birthday: 2007-01-01, inviter_id: 0, channel: kissu_oppo, open_app_nums: 0, is_for_ever_vip: 0, bind_status: 0, id: 636, vip_end_time: 0, province_name: 浙江, friend_code: 2000465, lately_open_app_time: 0, nickname: kissu0092, friend_qr_code: https://kissustatic.yuluojishu.com/uploads/2025/10/22/0ef941746fbea3bbd1e12bd55fe759d2.png, city_name: 杭州, head_portrait: https://kissustatic.yuluojishu.com/uploads/2025/09/11/e00b3be4bb4801e07a62ff4080fb6d13.png, lately_login_time: 1761066963, login_nums: 1, lately_bind_time: 0, lover_id: 0, is_test: 2, lately_pay_time: 0, device_id: android-1761066962787, is_give_vip: 0, lately_location_switch_handle_time: 0, channel_cate_id: 0, channel_id: 0, phone: 13999990092, mobile_model: , register_version: 1.0.2, unique_id: ed37dcb4a018481ea67c2bcad2b9ac9b, vip_end_date: , is_vip: 0, vip_num: VIP0000636, share_config
I/flutter (12467): 🔍 原始响应Body类型: _Map<String, dynamic>
I/flutter (12467): [LogManager] Not initialized. Message: 200 GET http://dev-love-api.ikissu.cn/get/user (116ms)
I/flutter (12467): [LogManager] Not initialized. Message: Response: {
I/flutter (12467):   "isSuccess": true,
I/flutter (12467):   "code": 0,
I/flutter (12467):   "msg": "获取用户信息",
I/flutter (12467):   "data": null,
I/flutter (12467):   "dataList": null,
I/flutter (12467):   "dataJson": {
I/flutter (12467):     "is_order_vip": "0",
I/flutter (12467):     "lately_unbind_time": "0",
I/flutter (12467):     "half_uid": 0,
I/flutter (12467):     "gender": 2,
I/flutter (12467):     "status": 1,
I/flutter (12467):     "birthday": "2007-01-01",
I/flutter (12467):     "inviter_id": 0,
I/flutter (12467):     "channel": "kissu_oppo",
I/flutter (12467):     "open_app_nums": "0",
I/flutter (12467):     "is_for_ever_vip": 0,
I/flutter (12467):     "bind_status": "0",
I/flutter (12467):     "id": 636,
I/flutter (12467):     "vip_end_time": 0,
I/flutter (12467):     "province_name": "浙江",
I/flutter (12467):     "friend_code": "2000465",
I/flutter (12467):     "lately_open_app_time": "0",
I/flutter (12467): ... (truncated)
I/flutter (12467): ✅ Request GET /get/user - 229ms - Status: 200
I/flutter (12467): [LogManager] Not initialized. Message: 调用getUserInfo API
I/flutter (12467): INFO:  开始保存用户数据，用户ID: 636, 数据长度: 2457
I/flutter (12467): SUCCESS:  用户数据保存成功
I/flutter (12467): 📍 全局监听器收到定位数据: {callbackTime: 2025-10-22 01:54:23, locationTime: 2025-10-22 01:37:03, locationType: 4, latitude: 30.284149, longitude: 119.98445, accuracy: 37.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 余杭区, street: 余杭塘河滨水公园绿道, streetNumber: 19号, cityCode: 0571, adCode: 330110, address: 浙江省杭州市余杭区余杭塘河滨水公园绿道19号靠近浙江大学校友企业总部经济园二期, description: 在浙江大学校友企业总部经济园二期附近}
I/flutter (12467): 📍 完整定位数据: {callbackTime: 2025-10-22 01:54:23, locationTime: 2025-10-22 01:37:03, locationType: 4, latitude: 30.284149, longitude: 119.98445, accuracy: 37.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 余杭区, street: 余杭塘河滨水公园绿道, streetNumber: 19号, cityCode: 0571, adCode: 330110, address: 浙江省杭州市余杭区余杭塘河滨水公园绿道19号靠近浙江大学校友企业总部经济园二期, description: 在浙江大学校友企业总部经济园二期附近}
I/flutter (12467): 🔍 _handleLocationReporting: _isFirstLocationSuccess = false
I/flutter (12467): 🔍 收集缓冲区当前大小: 1
I/flutter (12467): 📦 位置收集: 距离58.3m≥50m (缓冲区: 2/12)
I/flutter (12467): 📍 收集位置: 30.284149, 119.98445, 精度: 37.00m
I/flutter (12467): SUCCESS:  验证保存成功，数据长度: 2457
I/flutter (12467): [LogManager] Not initialized. Message: 用户信息已更新
I/flutter (12467): [LogManager] Not initialized. Message: 用户信息已从服务器刷新
I/flutter (12467): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (12467): │ #0   PaymentService._checkVipStatus (package:kissu_app/services/payment_service.dart:556:17)
payment_service.dart:556
I/flutter (12467): │ #1   <asynchronous suspension>
I/flutter (12467): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (12467): │ 💡 用户尚未成为VIP，继续轮询
I/flutter (12467): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
W/System.err(12467): java.lang.SecurityException: listen
W/System.err(12467): 	at android.os.Parcel.createExceptionOrNull(Parcel.java:3262)
W/System.err(12467): 	at android.os.Parcel.createException(Parcel.java:3246)
W/System.err(12467): 	at android.os.Parcel.readException(Parcel.java:3229)
W/System.err(12467): 	at android.os.Parcel.readException(Parcel.java:3171)
W/System.err(12467): 	at com.android.internal.telephony.ITelephonyRegistry$Stub$Proxy.listenWithEventList(ITelephonyRegistry.java:1218)
W/System.err(12467): 	at android.telephony.TelephonyRegistryManager.listenFromListener(TelephonyRegistryManager.java:297)
W/System.err(12467): 	at android.telephony.TelephonyManager.listen(TelephonyManager.java:6912)
W/System.err(12467): 	at com.loc.es.o(Unknown Source:17)
W/System.err(12467): 	at com.loc.es.n(Unknown Source:5)
W/System.err(12467): 	at com.loc.es.<init>(Unknown Source:70)
W/System.err(12467): 	at com.loc.ei.a(Unknown Source:58)
W/System.err(12467): 	at com.loc.e.a(Unknown Source:28)
W/System.err(12467): 	at com.loc.e.a(Unknown Source:0)
W/System.err(12467): 	at com.loc.e$a.handleMessage(Unknown Source:294)
W/System.err(12467): 	at android.os.Handler.dispatchMessage(Handler.java:118)
W/System.err(12467): 	at android.os.Looper.loopOnce(Looper.java:237)
W/System.err(12467): 	at android.os.Looper.loop(Looper.java:325)
W/System.err(12467): 	at android.os.HandlerThread.run(HandlerThread.java:85)
W/System.err(12467): 	at com.loc.e$b.run(Unknown Source:0)
I/flutter (12467): 🔍 原始响应URL: http://dev-love-api.ikissu.cn/index
I/flutter (12467): 🔍 原始响应状态码: 200
I/flutter (12467): 🔍 原始响应Headers: connection: keep-alive
I/flutter (12467): date: Tue, 21 Oct 2025 17:54:24 GMT
I/flutter (12467): transfer-encoding: chunked
I/flutter (12467): vary: Accept-Encoding
I/flutter (12467): content-encoding: gzip
I/flutter (12467): content-type: application/json; charset=utf-8
I/flutter (12467): server: nginx
I/flutter (12467): 🔍 原始响应Body: {code: 0, msg: , time: 1761069264, data: {is_red_dot: 0, is_system_notice_red_dot: 0, is_interaction_notice_red_dot: 0, activity: {is_pop_ads: 0, watch_ads_nums: 0, is_ads_exempt: 0, is_ads_count_down: 0, ads_count_down: 0, is_activity: 1, is_activity_icon: https://kissustatic.yuluojishu.com/uploads/2025/09/05/3e4bcaa18cd0b27710bbce9d748a258e.png, activity_link: https://www.ikissu.cn/share/invitepro.html?bindCode=2000465, activity_title: 邀请好友得红包}, location: {stay_count: 2, distance: 5km, travel_tool: 1}, user: {lover_days: 0, head_portrait: https://kissustatic.yuluojishu.com/uploads/2025/09/11/e00b3be4bb4801e07a62ff4080fb6d13.png, half_head_portrait: , is_bind: 0}, photo: {photo_wall: https://kissustatic.yuluojishu.com/uploads/2025/10/21/87783e72474a60d2ed35d7cd3f769dea.png}, weather: {base: [{province: 浙江, city: 上城区, adcode: 330102, weather: 阴, temperature: 14, winddirection: 北, windpower: 4, humidity: 72, reporttime: 2025-10-22 01:32:06, temperature_float:
I/flutter (12467): 🔍 原始响应Body类型: _Map<String, dynamic>
I/flutter (12467): [LogManager] Not initialized. Message: 200 GET http://dev-love-api.ikissu.cn/index (166ms)
I/flutter (12467): [LogManager] Not initialized. Message: Response: {
I/flutter (12467):   "isSuccess": true,
I/flutter (12467):   "code": 0,
I/flutter (12467):   "msg": "",
I/flutter (12467):   "data": null,
I/flutter (12467):   "dataList": null,
I/flutter (12467):   "dataJson": {
I/flutter (12467):     "is_red_dot": 0,
I/flutter (12467):     "is_system_notice_red_dot": 0,
I/flutter (12467):     "is_interaction_notice_red_dot": 0,
I/flutter (12467):     "activity": {
I/flutter (12467):       "is_pop_ads": 0,
I/flutter (12467):       "watch_ads_nums": 0,
I/flutter (12467):       "is_ads_exempt": 0,
I/flutter (12467):       "is_ads_count_down": 0,
I/flutter (12467):       "ads_count_down": 0,
I/flutter (12467):       "is_activity": 1,
I/flutter (12467):       "is_activity_icon": "https://kissustatic.yuluojishu.com/uploads/2025/09/05/3e4bcaa18cd0b27710bbce9d748a258e.png",
I/flutter (12467):       "a... (truncated)
I/flutter (12467): ✅ Request GET /index - 283ms - Status: 200
I/flutter (12467): SUCCESS: 🏠 首页数据请求成功
I/flutter (12467): INFO: 首页数据结构: [is_red_dot, is_system_notice_red_dot, is_interaction_notice_red_dot, activity, location, user, photo, weather]
I/flutter (12467): 📊 红点信息更新: 系统消息=0, 互动消息=0, 总数=0, 显示红点=false
I/flutter (12467): 📸 照片墙URL: https://kissustatic.yuluojishu.com/uploads/2025/10/21/87783e72474a60d2ed35d7cd3f769dea.png
I/flutter (12467): 🌤️ 开始解析首页天气数据
I/flutter (12467): 🌤️ 解析 base 数据: icon=https://kissustatic.yuluojishu.com/uploads/2025/09/23/1d2226cd28e0db355a41759e37306371.png, weather=阴, temp=14
I/flutter (12467): 🌤️ 解析 all 数据: min=14, max=18
I/flutter (12467): ✅ 天气数据解析成功
I/flutter (12467): ✅ 首页数据加载成功: 绑定状态=false, 恋爱天数=0, 距离=5km
I/flutter (12467): ✅ 红点轮询已启动（每10秒刷新）
I/flutter (12467): 🔍 检查引导图1显示状态: true (已绑定: false)
I/flutter (12467): ℹ️ 引导图1已显示过，检查是否需要显示引导图2 (已绑定: false)
I/flutter (12467): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (12467): │ #0   PaymentService._startVipStatusPolling.<anonymous closure> (package:kissu_app/services/payment_service.dart:499:15)
payment_service.dart:499
I/flutter (12467): │ #1   _Timer._runTimers (dart:isolate-patch/timer_impl.dart:423:19)
timer_impl.dart:423
I/flutter (12467): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (12467): │ 💡 🔍 VIP状态轮询中... (1/30)
I/flutter (12467): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (12467): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (12467): │ #0   PaymentService._checkVipStatus (package:kissu_app/services/payment_service.dart:520:15)
payment_service.dart:520
I/flutter (12467): │ #1   PaymentService._startVipStatusPolling.<anonymous closure> (package:kissu_app/services/payment_service.dart:513:7)
payment_service.dart:513
I/flutter (12467): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (12467): │ 💡 🔍 检测VIP状态...
I/flutter (12467): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (12467): [LogManager] Not initialized. Message: DeviceUtil not initialized, using fallback deviceId
I/flutter (12467): [LogManager] Not initialized. Message: GET http://dev-love-api.ikissu.cn/get/user
I/flutter (12467): [LogManager] Not initialized. Message: Headers: {network_debounce: true, token: ***HIDDEN***, version: 1.0.2, pkg: com.yuluo.kissu, deviceid: android-1761069264548, mobile-model: HONOR LGE-AN00, brand: HONOR, channel: kissu_oppo, network-name: wifi_OuHuaZhiChuang, power: 60, timestamp: 1761069264548, sign: 1CF86BE8CC4E96A427C542C9893451B1}
I/flutter (12467): 🔍 原始响应URL: http://dev-love-api.ikissu.cn/get/user
I/flutter (12467): 🔍 原始响应状态码: 200
I/flutter (12467): 🔍 原始响应Headers: connection: keep-alive
I/flutter (12467): date: Tue, 21 Oct 2025 17:54:25 GMT
I/flutter (12467): transfer-encoding: chunked
I/flutter (12467): vary: Accept-Encoding
I/flutter (12467): content-encoding: gzip
I/flutter (12467): content-type: application/json; charset=utf-8
I/flutter (12467): server: nginx
I/flutter (12467): 🔍 原始响应Body: {code: 0, msg: 获取用户信息, time: 1761069265, data: {is_order_vip: 0, lately_unbind_time: 0, half_uid: 0, gender: 2, status: 1, birthday: 2007-01-01, inviter_id: 0, channel: kissu_oppo, open_app_nums: 0, is_for_ever_vip: 0, bind_status: 0, id: 636, vip_end_time: 0, province_name: 浙江, friend_code: 2000465, lately_open_app_time: 0, nickname: kissu0092, friend_qr_code: https://kissustatic.yuluojishu.com/uploads/2025/10/22/0ef941746fbea3bbd1e12bd55fe759d2.png, city_name: 杭州, head_portrait: https://kissustatic.yuluojishu.com/uploads/2025/09/11/e00b3be4bb4801e07a62ff4080fb6d13.png, lately_login_time: 1761066963, login_nums: 1, lately_bind_time: 0, lover_id: 0, is_test: 2, lately_pay_time: 0, device_id: android-1761066962787, is_give_vip: 0, lately_location_switch_handle_time: 0, channel_cate_id: 0, channel_id: 0, phone: 13999990092, mobile_model: , register_version: 1.0.2, unique_id: ed37dcb4a018481ea67c2bcad2b9ac9b, vip_end_date: , is_vip: 0, vip_num: VIP0000636, share_config
I/flutter (12467): 🔍 原始响应Body类型: _Map<String, dynamic>
I/flutter (12467): [LogManager] Not initialized. Message: 200 GET http://dev-love-api.ikissu.cn/get/user (171ms)
I/flutter (12467): [LogManager] Not initialized. Message: Response: {
I/flutter (12467):   "isSuccess": true,
I/flutter (12467):   "code": 0,
I/flutter (12467):   "msg": "获取用户信息",
I/flutter (12467):   "data": null,
I/flutter (12467):   "dataList": null,
I/flutter (12467):   "dataJson": {
I/flutter (12467):     "is_order_vip": "0",
I/flutter (12467):     "lately_unbind_time": "0",
I/flutter (12467):     "half_uid": 0,
I/flutter (12467):     "gender": 2,
I/flutter (12467):     "status": 1,
I/flutter (12467):     "birthday": "2007-01-01",
I/flutter (12467):     "inviter_id": 0,
I/flutter (12467):     "channel": "kissu_oppo",
I/flutter (12467):     "open_app_nums": "0",
I/flutter (12467):     "is_for_ever_vip": 0,
I/flutter (12467):     "bind_status": "0",
I/flutter (12467):     "id": 636,
I/flutter (12467):     "vip_end_time": 0,
I/flutter (12467):     "province_name": "浙江",
I/flutter (12467):     "friend_code": "2000465",
I/flutter (12467):     "lately_open_app_time": "0",
I/flutter (12467): ... (truncated)
I/flutter (12467): ✅ Request GET /get/user - 188ms - Status: 200
I/flutter (12467): [LogManager] Not initialized. Message: 调用getUserInfo API
I/flutter (12467): INFO:  开始保存用户数据，用户ID: 636, 数据长度: 2457
I/flutter (12467): SUCCESS:  用户数据保存成功
I/flutter (12467): SUCCESS:  验证保存成功，数据长度: 2457
I/flutter (12467): [LogManager] Not initialized. Message: 用户信息已更新
I/flutter (12467): [LogManager] Not initialized. Message: 用户信息已从服务器刷新
I/flutter (12467): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (12467): │ #0   PaymentService._checkVipStatus (package:kissu_app/services/payment_service.dart:556:17)
payment_service.dart:556
I/flutter (12467): │ #1   <asynchronous suspension>
I/flutter (12467): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (12467): │ 💡 用户尚未成为VIP，继续轮询
I/flutter (12467): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (12467): 🏠 首页开始请求定位权限...
I/flutter (12467): 🏠 已请求过定位权限，直接检查服务状态
I/flutter (12467): 🏠 首页定位服务已在运行
I/flutter (12467): 🔍 检查VIP推广标识: false
I/flutter (12467): ℹ️ 无需显示VIP推广弹窗
I/flutter (12467): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (12467): │ #0   PaymentService._startVipStatusPolling.<anonymous closure> (package:kissu_app/services/payment_service.dart:499:15)
payment_service.dart:499
I/flutter (12467): │ #1   _Timer._runTimers (dart:isolate-patch/timer_impl.dart:423:19)
timer_impl.dart:423
I/flutter (12467): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (12467): │ 💡 🔍 VIP状态轮询中... (2/30)
I/flutter (12467): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (12467): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (12467): │ #0   PaymentService._checkVipStatus (package:kissu_app/services/payment_service.dart:520:15)
payment_service.dart:520
I/flutter (12467): │ #1   PaymentService._startVipStatusPolling.<anonymous closure> (package:kissu_app/services/payment_service.dart:513:7)
payment_service.dart:513
I/flutter (12467): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (12467): │ 💡 🔍 检测VIP状态...
I/flutter (12467): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (12467): 📱 提醒冷却中，剩余时间: 5:35:53.364132
I/flutter (12467): 📱 不满足提醒条件，跳过
I/flutter (12467): 📱 已清空后台时间记录，为下次后台检测做准备
I/flutter (12467): [LogManager] Not initialized. Message: DeviceUtil not initialized, using fallback deviceId
I/flutter (12467): [LogManager] Not initialized. Message: GET http://dev-love-api.ikissu.cn/get/user
I/flutter (12467): [LogManager] Not initialized. Message: Headers: {network_debounce: true, token: ***HIDDEN***, version: 1.0.2, pkg: com.yuluo.kissu, deviceid: android-1761069265529, mobile-model: HONOR LGE-AN00, brand: HONOR, channel: kissu_oppo, network-name: wifi_OuHuaZhiChuang, power: 60, timestamp: 1761069265529, sign: 65CF6472C83731051FA590F2B389CD94}
I/flutter (12467): 🔍 原始响应URL: http://dev-love-api.ikissu.cn/get/user
I/flutter (12467): 🔍 原始响应状态码: 200
I/flutter (12467): 🔍 原始响应Headers: connection: keep-alive
I/flutter (12467): date: Tue, 21 Oct 2025 17:54:26 GMT
I/flutter (12467): transfer-encoding: chunked
I/flutter (12467): vary: Accept-Encoding
I/flutter (12467): content-encoding: gzip
I/flutter (12467): content-type: application/json; charset=utf-8
I/flutter (12467): server: nginx
I/flutter (12467): 🔍 原始响应Body: {code: 0, msg: 获取用户信息, time: 1761069266, data: {is_order_vip: 0, lately_unbind_time: 0, half_uid: 0, gender: 2, status: 1, birthday: 2007-01-01, inviter_id: 0, channel: kissu_oppo, open_app_nums: 0, is_for_ever_vip: 0, bind_status: 0, id: 636, vip_end_time: 0, province_name: 浙江, friend_code: 2000465, lately_open_app_time: 0, nickname: kissu0092, friend_qr_code: https://kissustatic.yuluojishu.com/uploads/2025/10/22/0ef941746fbea3bbd1e12bd55fe759d2.png, city_name: 杭州, head_portrait: https://kissustatic.yuluojishu.com/uploads/2025/09/11/e00b3be4bb4801e07a62ff4080fb6d13.png, lately_login_time: 1761066963, login_nums: 1, lately_bind_time: 0, lover_id: 0, is_test: 2, lately_pay_time: 0, device_id: android-1761066962787, is_give_vip: 0, lately_location_switch_handle_time: 0, channel_cate_id: 0, channel_id: 0, phone: 13999990092, mobile_model: , register_version: 1.0.2, unique_id: ed37dcb4a018481ea67c2bcad2b9ac9b, vip_end_date: , is_vip: 0, vip_num: VIP0000636, share_config
I/flutter (12467): 🔍 原始响应Body类型: _Map<String, dynamic>
I/flutter (12467): [LogManager] Not initialized. Message: 200 GET http://dev-love-api.ikissu.cn/get/user (182ms)
I/flutter (12467): [LogManager] Not initialized. Message: Response: {
I/flutter (12467):   "isSuccess": true,
I/flutter (12467):   "code": 0,
I/flutter (12467):   "msg": "获取用户信息",
I/flutter (12467):   "data": null,
I/flutter (12467):   "dataList": null,
I/flutter (12467):   "dataJson": {
I/flutter (12467):     "is_order_vip": "0",
I/flutter (12467):     "lately_unbind_time": "0",
I/flutter (12467):     "half_uid": 0,
I/flutter (12467):     "gender": 2,
I/flutter (12467):     "status": 1,
I/flutter (12467):     "birthday": "2007-01-01",
I/flutter (12467):     "inviter_id": 0,
I/flutter (12467):     "channel": "kissu_oppo",
I/flutter (12467):     "open_app_nums": "0",
I/flutter (12467):     "is_for_ever_vip": 0,
I/flutter (12467):     "bind_status": "0",
I/flutter (12467):     "id": 636,
I/flutter (12467):     "vip_end_time": 0,
I/flutter (12467):     "province_name": "浙江",
I/flutter (12467):     "friend_code": "2000465",
I/flutter (12467):     "lately_open_app_time": "0",
I/flutter (12467): ... (truncated)
I/flutter (12467): ✅ Request GET /get/user - 186ms - Status: 200
I/flutter (12467): [LogManager] Not initialized. Message: 调用getUserInfo API
I/flutter (12467): INFO:  开始保存用户数据，用户ID: 636, 数据长度: 2457
I/flutter (12467): SUCCESS:  用户数据保存成功
I/flutter (12467): SUCCESS:  验证保存成功，数据长度: 2457
I/flutter (12467): [LogManager] Not initialized. Message: 用户信息已更新
I/flutter (12467): [LogManager] Not initialized. Message: 用户信息已从服务器刷新
I/flutter (12467): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (12467): │ #0   PaymentService._checkVipStatus (package:kissu_app/services/payment_service.dart:556:17)
payment_service.dart:556
I/flutter (12467): │ #1   <asynchronous suspension>
I/flutter (12467): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (12467): │ 💡 用户尚未成为VIP，继续轮询
I/flutter (12467): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────