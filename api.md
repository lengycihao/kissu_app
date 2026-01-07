D/ForegroundLocationService(21400): ⚡ 前台服务已立即启动（避免5秒超时）
D/ForegroundLocationService(21400): 服务期望状态已更新: true
D/ForegroundLocationService(21400): 服务组件已完整初始化，跳过
W/Bundle  (21400): Key priority expected String but value was a java.lang.Integer.  The default value <null> was returned.
W/Bundle  (21400): Attempt to cast generated internal exception:
W/Bundle  (21400): java.lang.ClassCastException: java.lang.Integer cannot be cast to java.lang.String
W/Bundle  (21400): 	at android.os.BaseBundle.getString(BaseBundle.java:1422)
W/Bundle  (21400): 	at android.content.Intent.getStringExtra(Intent.java:9758)
W/Bundle  (21400): 	at com.yuluo.kissu.ForegroundLocationService.getStringExtraCompat(ForegroundLocationService.kt:897)
W/Bundle  (21400): 	at com.yuluo.kissu.ForegroundLocationService.startLocationForegroundService(ForegroundLocationService.kt:576)
W/Bundle  (21400): 	at com.yuluo.kissu.ForegroundLocationService.onStartCommand(ForegroundLocationService.kt:190)
W/Bundle  (21400): 	at android.app.ActivityThread.handleServiceArgs(ActivityThread.java:6164)
W/Bundle  (21400): 	at android.app.ActivityThread.-$$Nest$mhandleServiceArgs(Unknown Source:0)
W/Bundle  (21400): 	at android.app.ActivityThread$H.handleMessage(ActivityThread.java:3173)
W/Bundle  (21400): 	at android.os.Handler.dispatchMessage(Handler.java:118)
W/Bundle  (21400): 	at android.os.Looper.loopOnce(Looper.java:237)
W/Bundle  (21400): 	at android.os.Looper.loop(Looper.java:325)
W/Bundle  (21400): 	at android.app.ActivityThread.main(ActivityThread.java:10404)
W/Bundle  (21400): 	at java.lang.reflect.Method.invoke(Native Method)
W/Bundle  (21400): 	at com.android.internal.os.RuntimeInit$MethodAndArgsCaller.run(RuntimeInit.java:635)
W/Bundle  (21400): 	at com.android.internal.os.ZygoteInit.main(ZygoteInit.java:970)
D/ForegroundLocationService(21400): 通知渠道创建成功: kissu_location_service
D/ForegroundLocationService(21400): 原生定位监听已在运行中
D/LocationReportService(21400): ✅ 保活检查：定时器运行正常
D/ForegroundLocationService(21400): 🚀 App使用记录上报已启动（每2分钟采集一次，前台/后台统一原生）
D/ForegroundLocationService(21400): 前台定位服务启动成功
W/AppUsageReportService(21400): ! 没有使用情况访问权限，无法采集数据
I/HiTouch_PressGestureDetector(21400): checkDoublePointerLimit: false
I/flutter (21400): 💡 定位页面：切换头像，恢复下半屏到底部吸顶位置
I/flutter (21400): 🎯 定位页面：收起底部面板到底部吸顶位置
I/flutter (21400): [LogManager] Not initialized. Message: DeviceUtil not initialized, using fallback deviceId
I/flutter (21400): INFO: OAID 已添加到请求头
I/flutter (21400): INFO: ========== Request Headers ==========
I/flutter (21400): INFO: URL: https://service-api.ikissu.cn/get/location
I/flutter (21400): INFO: Method: GET
I/flutter (21400): INFO: --- Business Headers ---
I/flutter (21400): INFO: token: eyJ0eXAiOiJKV1QiLCJh... (205 chars)
I/flutter (21400): INFO: sign: EDF3EC124B2C4A49CCC4... (32 chars)
I/flutter (21400): INFO: version: 1.1.3
I/flutter (21400): INFO: channel: kissu_huawei
I/flutter (21400): INFO: pkg: com.yuluo.kissu
I/flutter (21400): INFO: os: 1
I/flutter (21400): INFO: network-name: wifi_YuluoKeji_5G
I/flutter (21400): INFO: deviceid: android-1767775477118
I/flutter (21400): INFO: mobile-model: HONOR ALI-AN00
I/flutter (21400): INFO: power: 50
I/flutter (21400): INFO: is-open-location: 1
I/flutter (21400): INFO: brand: HONOR
I/flutter (21400): INFO: oaid: 18887152-1202-4a74-9d32-2b825f7d3d73
I/flutter (21400): INFO: --- Other Headers ---
I/flutter (21400): INFO: cache_control: noCache
I/flutter (21400): INFO: timestamp: 1767775477118
I/flutter (21400): INFO: =====================================
I/flutter (21400): [LogManager] Not initialized. Message: GET https://service-api.ikissu.cn/get/location
I/flutter (21400): [LogManager] Not initialized. Message: Headers: {cache_control: noCache, token: ***HIDDEN***, version: 1.1.3, pkg: com.yuluo.kissu, os: 1, deviceid: android-1767775477118, oaid: 18887152-1202-4a74-9d32-2b825f7d3d73, mobile-model: HONOR ALI-AN00, brand: HONOR, is-open-location: 1, channel: kissu_huawei, network-name: wifi_YuluoKeji_5G, power: 50, timestamp: 1767775477118, sign: EDF3EC124B2C4A49CCC4D93B67611FCA}
I/flutter (21400): [LogManager] Not initialized. Message: 5秒后检查：定位是否有数据回调...
I/HwViewRootImpl(21400): removeInvalidNode all the node in jank list is out of time
D/ForegroundLocationService(21400): 📍 原生定位成功: 30.275025, 120.220817, 精度: 44.0m
D/ForegroundLocationService(21400): 定位成功，静默模式（不更新通知）
D/LocationReportService(21400): 📍 距离不足且时间未到，跳过收集: 移动4米 < 50米，距上次收集35秒
I/flutter (21400): [LogManager] Not initialized. Message: 200 GET https://service-api.ikissu.cn/get/location (734ms)
I/flutter (21400): [LogManager] Not initialized. Message: Response: {
I/flutter (21400):   "isSuccess": true,
I/flutter (21400):   "code": 0,
I/flutter (21400):   "msg": "",
I/flutter (21400):   "data": null,
I/flutter (21400):   "dataList": null,
I/flutter (21400):   "dataJson": {
I/flutter (21400):     "user_location_mobile_device": {
I/flutter (21400):       "power": "50%",
I/flutter (21400):       "network_name": "wifi_YuluoKeji_5G",
I/flutter (21400):       "mobile_model": "HONOR",
I/flutter (21400):       "is_wifi": "0",
I/flutter (21400):       "real_speed": "0",
I/flutter (21400):       "longitude": "120.220854",
I/flutter (21400):       "latitude": "30.275097",
I/flutter (21400):       "location": "浙江省杭州市上城区运河东路301号靠近中豪·湘和国际 附近",
I/flutter (21400):       "speed": "0m/s",
I/flutter (21400):       "location_time": "1767775379",
I/flutter (21400):       "calculate_location_time": "1分钟37秒",
I/flutter (21400):  ... (truncated)
I/flutter (21400): ✅ Request GET /get/location - 776ms - Status: 200
I/flutter (21400): CHECK: API原始JSON数据:
I/flutter (21400): CHECK:   JSON keys: [user_location_mobile_device, half_location_mobile_device, user]
I/flutter (21400): CHECK:   user_location_mobile_device keys: [power, network_name, mobile_model, is_wifi, real_speed, longitude, latitude, location, speed, location_time, calculate_location_time, is_open_location, is_oneself, distance, stops, stay_collect, head_portrait, face]
I/flutter (21400): CHECK:   user_location_mobile_device stops: [{latitude: 30.275073, longitude: 120.220825, location_name: 浙江省杭州市上城区四季青街道杭州市上城区仁本职业培训学校中豪·湘和国际 附近, start_time: 当前, end_time: , duration: 4分钟1秒, duration_int: 241, status: staying, point_type: stop, serial_number: 1}]
I/flutter (21400): CHECK:   half_location_mobile_device keys: [power, network_name, mobile_model, is_wifi, longitude, latitude, location, location_time, speed, calculate_location_time, is_open_location, is_oneself, distance, stops, stay_collect, head_portrait, face, online, lives]
I/flutter (21400): CHECK:   half_location_mobile_device stops: []
I/flutter (21400): 📍 另一半定位开关提示状态: false
I/flutter (21400): ✅ [已绑定] 更新头像和对方位置数据
I/flutter (21400): 📍 [已绑定] 使用接口数据更新我的位置
I/flutter (21400): 📍 [Marker创建] myPos: LatLng(30.275097, 120.22085400000003), partnerPos: null
I/flutter (21400): 📍 距离数据未到达，等待接口数据...
I/flutter (21400): 📍 移动到我的位置: LatLng(30.275097, 120.22085400000003)
I/flutter (21400): 📍 移动地图到位置: LatLng(30.275097, 120.22085400000003)，缩放级别17
I/flutter (21400): 📍 已绑定状态，计算双人中心位置
I/flutter (21400): 📍 只有我的位置: LatLng(30.275097, 120.22085400000003)，缩放级别17
I/AMapFlutter_MapController(21400): onCameraChange===>{position={bearing=0.0, zoom=17.0, tilt=0.0, target=[30.275097000000002, 120.22085400000002]}}
I/AMapFlutter_MapController(21400): onCameraChangeFinish===>{position={bearing=0.0, zoom=17.0, tilt=0.0, target=[30.275097000000002, 120.22085400000002]}}
I/flutter (21400): [LogManager] Not initialized. Message: 全局监听器收到定位数据: {callbackTime: 2026-01-07 16:44:40, locationTime: 2026-01-07 16:44:32, locationType: 2, latitude: 30.275025, longitude: 120.220817, accuracy: 44.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 上城区, street: 运河东路, streetNumber: 301号, cityCode: 0571, adCode: 330102, address: 浙江省杭州市上城区运河东路301号靠近中豪·湘和国际, description: 在中豪·湘和国际附近}
I/flutter (21400): [LogManager] Not initialized. Message: 完整定位数据: {callbackTime: 2026-01-07 16:44:40, locationTime: 2026-01-07 16:44:32, locationType: 2, latitude: 30.275025, longitude: 120.220817, accuracy: 44.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 上城区, street: 运河东路, streetNumber: 301号, cityCode: 0571, adCode: 330102, address: 浙江省杭州市上城区运河东路301号靠近中豪·湘和国际, description: 在中豪·湘和国际附近}
[GETX] CLOSE TO ROUTE /LocationV2Page
W/WindowOnBackDispatcher(21400): sendCancelIfRunning: isInProgress=false callback=io.flutter.embedding.android.FlutterActivity$1@7953275
I/HwViewRootImpl(21400): removeInvalidNode all the node in jank list is out of time
I/flutter (21400): deactivate AMapWidget}
I/flutter (21400): [LogManager] Not initialized. Message: 🗺️ SafeAMapWidget 销毁
[GETX] Worker [ever] disposed
I/flutter (21400): dispose AMapWidget with mapId: 14
[GETX] "LocationV2Controller" onDelete() called
[GETX] "LocationV2Controller" deleted from memory
I/flutter (21400): ✅ 定位服务监听器已清理
I/flutter (21400): ✅ 方向监听器已清理
I/flutter (21400): ✅ 底座更新定时器已清理
I/flutter (21400): ✅ Marker重建定时器已清理
I/flutter (21400): ✅ 位置刷新定时器已清理
2
I/flutter (21400): 停止Marker呼吸动画失败: Bad state: 地图Channel未初始化，mapId: 14
I/flutter (21400): ✅ Marker呼吸动画已停止
2
I/AMapFlutter_AMapPlatformView(21400): getView==>
D/libEGL  (21400): [eglDestroySurface] start surface is 0xb4000071b1aa7f80
I/BufferQueueProducer(21400): [SurfaceTexture-0-21400-14](id:539800000031,api:1,p:21400,c:21400) disconnect: api 1
I/BufferQueueConsumer(21400): [SurfaceTexture-0-21400-14](id:539800000031,api:0,p:-1,c:21400) disconnect
I/AMapFlutter_AMapPlatformView(21400): dispose==>
E/libEGL  (21400): call to OpenGL ES API with no current context (logged once per thread)
D/libEGL  (21400): [eglDestroySurface] start surface is 0xb4000071b1a16e10
I/BufferQueueProducer(21400): [ImageReader-1200x2652f22m7-21400-29](id:539800000030,api:1,p:21400,c:21400) disconnect: api 1
I/BufferQueueConsumer(21400): [ImageReader-1200x2652f22m7-21400-29](id:539800000030,api:0,p:-1,c:21400) disconnect
I/flutter (21400): [LogManager] Not initialized. Message: 权限状态更新:
I/flutter (21400): [LogManager] Not initialized. Message: 前台定位: granted
I/flutter (21400): [LogManager] Not initialized. Message: 后台定位: denied
I/flutter (21400): INFO: 定位权限状态缓存已更新: 1
D/ForegroundLocationService(21400): 📍 原生定位成功: 30.275025, 120.220817, 精度: 44.0m
D/ForegroundLocationService(21400): 定位成功，静默模式（不更新通知）
D/LocationReportService(21400): 📍 距离不足且时间未到，跳过收集: 移动4米 < 50米，距上次收集40秒
I/HiTouch_PressGestureDetector(21400): checkDoublePointerLimit: false
I/imsdk   (21400): TIM: |-login.cpp:533                           RequestHeartbeat                        |send heartbeat request
I/imsdk   (21400): TIM: |-login.cpp:574                           HandleHeartbeatResponse                 |receive heartbeat response|client_address:122.234.105.191:45734|heartbeat_interval:120|sync_timestamp:1767775482
I/flutter (21400): 🔍 底部导航按钮 0 被点击
I/flutter (21400): 📍 准备跳转到定位V2页面（检查会员状态）
I/flutter (21400): INFO: 🔍 检查会员状态后导航到定位页面
I/flutter (21400): INFO: 📊 会员信息 - isVip: 0, isForEverVip: 0, vipEndTime: 0
[GETX] GOING TO ROUTE /LocationV2Page
D/Choreographer(21400): still have 2 traversal callbacks
[GETX] Instance "LocationV2Controller" has been created
I/flutter (21400): 🔄 定位页面：静默刷新用户信息
I/flutter (21400): 🚀 地图页面异步初始化流程开始（后台静默执行）
I/flutter (21400): ⏰ 定位页面：定时刷新已启动（每30秒）
I/flutter (21400): 📍 已绑定状态，计算双人中心位置
I/flutter (21400): 📍 已绑定但无位置数据，使用默认位置（天安门）
I/flutter (21400): [LogManager] Not initialized. Message: 🗺️ SafeAMapWidget 初始化开始
[GETX] Instance "LocationV2Controller" has been initialized
I/flutter (21400): 🔍 LocationTipsManager: 开始检查所有提示
I/flutter (21400): 🔍 LocationTipsManager: 开始检查始终允许定位权限
I/flutter (21400): 👤 非会员，不显示到期提示
I/flutter (21400): 🔍 LocationTipsManager: 所有提示检查完成
I/flutter (21400): [LogManager] Not initialized. Message: 🗺️ SafeAMapWidget 自定义样式加载成功
I/flutter (21400): [LogManager] Not initialized. Message: DeviceUtil not initialized, using fallback deviceId
I/flutter (21400): INFO: OAID 已添加到请求头
I/flutter (21400): INFO: ========== Request Headers ==========
I/flutter (21400): INFO: URL: https://service-api.ikissu.cn/get/user
I/flutter (21400): INFO: Method: GET
I/flutter (21400): INFO: --- Business Headers ---
I/flutter (21400): INFO: token: eyJ0eXAiOiJKV1QiLCJh... (205 chars)
I/flutter (21400): INFO: sign: 24706EB60C3A0BE85698... (32 chars)
I/flutter (21400): INFO: version: 1.1.3
I/flutter (21400): INFO: channel: kissu_huawei
I/flutter (21400): INFO: pkg: com.yuluo.kissu
I/flutter (21400): INFO: os: 1
I/flutter (21400): INFO: network-name: wifi_YuluoKeji_5G
I/flutter (21400): INFO: deviceid: android-1767775482733
I/flutter (21400): INFO: mobile-model: HONOR ALI-AN00
I/flutter (21400): INFO: power: 50
I/flutter (21400): INFO: is-open-location: 1
I/flutter (21400): INFO: brand: HONOR
I/flutter (21400): INFO: oaid: 18887152-1202-4a74-9d32-2b825f7d3d73
I/flutter (21400): INFO: --- Other Headers ---
I/flutter (21400): INFO: network_debounce: true
I/flutter (21400): INFO: timestamp: 1767775482734
I/flutter (21400): INFO: =====================================
I/flutter (21400): [LogManager] Not initialized. Message: DeviceUtil not initialized, using fallback deviceId
I/flutter (21400): INFO: OAID 已添加到请求头
I/flutter (21400): INFO: ========== Request Headers ==========
I/flutter (21400): INFO: URL: https://service-api.ikissu.cn/get/location
I/flutter (21400): INFO: Method: GET
I/flutter (21400): INFO: --- Business Headers ---
I/flutter (21400): INFO: token: eyJ0eXAiOiJKV1QiLCJh... (205 chars)
I/flutter (21400): INFO: sign: 9B900F44F986D39EB1AA... (32 chars)
I/flutter (21400): INFO: version: 1.1.3
I/flutter (21400): INFO: channel: kissu_huawei
I/flutter (21400): INFO: pkg: com.yuluo.kissu
I/flutter (21400): INFO: os: 1
I/flutter (21400): INFO: network-name: wifi_YuluoKeji_5G
I/flutter (21400): INFO: deviceid: android-1767775482737
I/flutter (21400): INFO: mobile-model: HONOR ALI-AN00
I/flutter (21400): INFO: power: 50
I/flutter (21400): INFO: is-open-location: 1
I/flutter (21400): INFO: brand: HONOR
I/flutter (21400): INFO: oaid: 18887152-1202-4a74-9d32-2b825f7d3d73
I/flutter (21400): INFO: --- Other Headers ---
I/flutter (21400): INFO: cache_control: noCache
I/flutter (21400): INFO: timestamp: 1767775482737
I/flutter (21400): INFO: =====================================
I/flutter (21400): 🔐 始终允许定位权限状态: PermissionStatus.granted
I/flutter (21400): 🔐 是否应该显示权限提示: false
I/flutter (21400): 🔐 当前提示状态: false
I/flutter (21400): 🔐 权限提示状态无变化，保持: false
I/flutter (21400): [LogManager] Not initialized. Message: 🗺️ SafeAMapWidget 渲染已启用
I/flutter (21400): [LogManager] Not initialized. Message: GET https://service-api.ikissu.cn/get/user
I/flutter (21400): [LogManager] Not initialized. Message: Headers: {network_debounce: true, token: ***HIDDEN***, version: 1.1.3, pkg: com.yuluo.kissu, os: 1, deviceid: android-1767775482733, oaid: 18887152-1202-4a74-9d32-2b825f7d3d73, mobile-model: HONOR ALI-AN00, brand: HONOR, is-open-location: 1, channel: kissu_huawei, network-name: wifi_YuluoKeji_5G, power: 50, timestamp: 1767775482734, sign: 24706EB60C3A0BE8569878BEE971CD1E}
I/flutter (21400): [LogManager] Not initialized. Message: GET https://service-api.ikissu.cn/get/location
I/flutter (21400): [LogManager] Not initialized. Message: Headers: {cache_control: noCache, token: ***HIDDEN***, version: 1.1.3, pkg: com.yuluo.kissu, os: 1, deviceid: android-1767775482737, oaid: 18887152-1202-4a74-9d32-2b825f7d3d73, mobile-model: HONOR ALI-AN00, brand: HONOR, is-open-location: 1, channel: kissu_huawei, network-name: wifi_YuluoKeji_5G, power: 50, timestamp: 1767775482737, sign: 9B900F44F986D39EB1AAB71988D99E50}
I/flutter (21400): initState AMapWidget
I/AMapFlutter_AMapPlatformViewFactory(21400): create params==>{initialCameraPosition={bearing=0.0, zoom=3.0, tilt=0.0, target=[39.9042, 116.4074]}, circlesToAdd=[], privacyStatement={hasAgree=true, hasContains=true, hasShow=true}, apiKey=null, polylinesToAdd=[], options={touchPoiEnabled=true, customStyleOptions={styleExtraData=[B@a9c3cef, styleData=[B@ef0f3fc, enabled=true}, compassEnabled=true, labelsEnabled=true, mapType=0, tiltGesturesEnabled=true, zoomGesturesEnabled=true, logoPosition=0, rotateGesturesEnabled=true, scrollGesturesEnabled=true, buildingsEnabled=true, scaleEnabled=true, trafficEnabled=false}, polygonsToAdd=[], markersToAdd=[], debugMode=true}
I/AMapFlutter_AMapPlatformView(21400): onCreate==>
I/AMapFlutter_AMapPlatformView(21400): onStart==>
I/AMapFlutter_AMapPlatformView(21400): onResume==>
2
I/AMapFlutter_AMapPlatformView(21400): getView==>
I/PlatformViewsController(21400): Hosting view in view hierarchy for platform view: 15
I/PlatformViewsController(21400): PlatformView is using SurfaceProducer backend
I/BufferQueueConsumer(21400): [](id:539800000032,api:0,p:-1,c:21400) connect: controlledByApp=true
D/libEGL  (21400): [eglCreateWindowSurface] start window is 12970367409232131424
I/BufferQueueProducer(21400): [ImageReader-1x1f22m7-21400-30](id:539800000032,api:0,p:-1,c:21400) connect: api=1 producerControlledByApp=true
I/AMapFlutter_AMapPlatformView(21400): getView==>
I/BufferQueueConsumer(21400): [](id:539800000033,api:0,p:-1,c:21400) connect: controlledByApp=true
D/libEGL  (21400): [eglCreateWindowSurface] start window is 12970367409231346624
I/BufferQueueProducer(21400): [ImageReader-1200x2652f22m7-21400-31](id:539800000033,api:0,p:-1,c:21400) connect: api=1 producerControlledByApp=true
I/BufferQueueConsumer(21400): [](id:539800000034,api:0,p:-1,c:21400) connect: controlledByApp=true
D/libEGL  (21400): [eglCreateWindowSurface] start window is 12970367409231006544
I/BufferQueueProducer(21400): [SurfaceTexture-0-21400-15](id:539800000034,api:0,p:-1,c:21400) connect: api=1 producerControlledByApp=true
I/flutter (21400): [LogManager] Not initialized. Message: 隐私合规设置完成
I/flutter (21400): [LogManager] Not initialized. Message: 定位服务已启动，先停止旧服务
I/flutter (21400): 🛑 停止前台定位服务...
I/flutter (21400): [LogManager] Not initialized. Message: 高德定位服务已停止（全局监听器保持激活）
I/flutter (21400): [LogManager] Not initialized. Message: 收集缓冲区和智能状态已清理
D/TrafficStats(21400): tagSocket(204) with statsTag=0xffffffff, statsUid=-1
D/libEGL  (21400): [eglDestroySurface] start surface is 0xb4000071b19a6f10
I/BufferQueueProducer(21400): [ImageReader-1x1f22m7-21400-30](id:539800000032,api:1,p:21400,c:21400) disconnect: api 1
I/BufferQueueConsumer(21400): [ImageReader-1x1f22m7-21400-30](id:539800000032,api:0,p:-1,c:21400) disconnect
D/BootCompletedReceiver(21400): 定位服务状态已保存: enabled=false
D/ForegroundServiceHandler(21400): 定位服务已停止，开机将不会自动启动
I/flutter (21400): ✅ 前台定位服务停止成功
I/flutter (21400): [LogManager] Not initialized. Message: 前台服务停止成功
I/AMapFlutter_MapController(21400): onCameraChange===>{position={bearing=0.0, zoom=3.0, tilt=0.0, target=[39.90420000000002, 116.40740000000004]}}
I/AMapFlutter_MapController(21400): onCameraChangeFinish===>{position={bearing=0.0, zoom=3.0, tilt=0.0, target=[39.90420000000002, 116.40740000000004]}}
W/ForegroundLocationService(21400): ! 前台定位服务被销毁，尝试自恢复
D/ForegroundLocationService(21400): 原生定位监听已停止
D/ForegroundLocationService(21400): 已释放所有上报服务
D/ForegroundLocationService(21400): ❤️ 心跳闹钟已停止
D/ForegroundLocationService(21400): 🌙 息屏心跳闹钟已停止
D/ForegroundLocationService(21400): 🌙 息屏保活机制已停止
D/ForegroundLocationService(21400): App使用记录上报已停止
D/ForegroundLocationService(21400): 锁屏/解锁广播接收器已注销
D/ForegroundLocationService(21400): 网络状态广播接收器已注销
D/ForegroundLocationService(21400): 充电状态广播接收器已注销
D/ForegroundLocationService(21400): WakeLock 已释放
D/ForegroundLocationService(21400): 🔄 已安排重启（onDestroy），delay=1200ms
E/ForegroundLocationService(21400): 安排 WorkManager 重启失败（onDestroy）
E/ForegroundLocationService(21400): java.lang.IllegalArgumentException: Expedited jobs cannot be delayed
E/ForegroundLocationService(21400): 	at androidx.work.WorkRequest$Builder.build(WorkRequest.kt:271)
E/ForegroundLocationService(21400): 	at com.yuluo.kissu.ForegroundLocationService.scheduleWorkRestart(ForegroundLocationService.kt:865)
E/ForegroundLocationService(21400): 	at com.yuluo.kissu.ForegroundLocationService.onDestroy(ForegroundLocationService.kt:411)
E/ForegroundLocationService(21400): 	at android.app.ActivityThread.handleStopService(ActivityThread.java:6196)
E/ForegroundLocationService(21400): 	at android.app.ActivityThread.-$$Nest$mhandleStopService(Unknown Source:0)
E/ForegroundLocationService(21400): 	at android.app.ActivityThread$H.handleMessage(ActivityThread.java:3181)
E/ForegroundLocationService(21400): 	at android.os.Handler.dispatchMessage(Handler.java:118)
E/ForegroundLocationService(21400): 	at android.os.Looper.loopOnce(Looper.java:237)
E/ForegroundLocationService(21400): 	at android.os.Looper.loop(Looper.java:325)
E/ForegroundLocationService(21400): 	at android.app.ActivityThread.main(ActivityThread.java:10404)
E/ForegroundLocationService(21400): 	at java.lang.reflect.Method.invoke(Native Method)
E/ForegroundLocationService(21400): 	at com.android.internal.os.RuntimeInit$MethodAndArgsCaller.run(RuntimeInit.java:635)
E/ForegroundLocationService(21400): 	at com.android.internal.os.ZygoteInit.main(ZygoteInit.java:970)
D/ForegroundLocationService(21400): 前台定位服务销毁
I/AMapFlutter_MapController(21400): onMapLoaded==>
I/flutter (21400): [LogManager] Not initialized. Message: 🗺️ SafeAMapWidget 地图创建成功
I/flutter (21400): [LogManager] Not initialized. Message: 🗺️ SafeAMapWidget 地图就绪完成
I/flutter (21400): [LogManager] Not initialized. Message: 200 GET https://service-api.ikissu.cn/get/user (176ms)
I/flutter (21400): [LogManager] Not initialized. Message: Response: {
I/flutter (21400):   "isSuccess": true,
I/flutter (21400):   "code": 0,
I/flutter (21400):   "msg": "获取用户信息",
I/flutter (21400):   "data": null,
I/flutter (21400):   "dataList": null,
I/flutter (21400):   "dataJson": {
I/flutter (21400):     "register_version": "1.1.3",
I/flutter (21400):     "unique_id": "d10e9af3c4b3480b93b00b138d35a510",
I/flutter (21400):     "is_order_vip": "0",
I/flutter (21400):     "current_mobile_sys": "android",
I/flutter (21400):     "id": 8365,
I/flutter (21400):     "channel_cate_id": "28",
I/flutter (21400):     "province_name": "浙江",
I/flutter (21400):     "login_nums": "1",
I/flutter (21400):     "friend_code": "1008371",
I/flutter (21400):     "device_id": "android-1767774982330",
I/flutter (21400):     "is_give_vip": "0",
I/flutter (21400):     "status": 1,
I/flutter (21400):     "lately_unbind_time": "0",
I/flutter (21400):     "o... (truncated)
I/flutter (21400): ✅ Request GET /get/user - 283ms - Status: 200
I/flutter (21400): [LogManager] Not initialized. Message: 调用getUserInfo API
I/flutter (21400): INFO:  开始保存用户数据，用户ID: 8365, 数据长度: 2737
I/flutter (21400): [LogManager] Not initialized. Message: 🗺️ SafeAMapWidget 已设置渲染帧率: 30fps
I/flutter (21400): SUCCESS:  用户数据保存成功
I/flutter (21400): SUCCESS:  验证保存成功，数据长度: 2737
I/flutter (21400): [LogManager] Not initialized. Message: 用户信息已更新
I/flutter (21400): [LogManager] Not initialized. Message: 用户信息已从服务器刷新
I/flutter (21400): 📍 已绑定状态，计算双人地图位置
I/flutter (21400): 📍 已绑定但无位置数据，地图保持默认位置
I/flutter (21400): [LogManager] Not initialized. Message: 高德定位插件状态正常
I/flutter (21400): [LogManager] Not initialized. Message: 高德定位插件已停止
I/flutter (21400): [LogManager] Not initialized. Message: 所有流监听器清理完成
I/flutter (21400): [LogManager] Not initialized. Message: 200 GET https://service-api.ikissu.cn/get/location (725ms)
I/flutter (21400): [LogManager] Not initialized. Message: Response: {
I/flutter (21400):   "isSuccess": true,
I/flutter (21400):   "code": 0,
I/flutter (21400):   "msg": "",
I/flutter (21400):   "data": null,
I/flutter (21400):   "dataList": null,
I/flutter (21400):   "dataJson": {
I/flutter (21400):     "user_location_mobile_device": {
I/flutter (21400):       "power": "50%",
I/flutter (21400):       "network_name": "wifi_YuluoKeji_5G",
I/flutter (21400):       "mobile_model": "HONOR",
I/flutter (21400):       "is_wifi": "0",
I/flutter (21400):       "real_speed": "0",
I/flutter (21400):       "longitude": "120.220854",
I/flutter (21400):       "latitude": "30.275097",
I/flutter (21400):       "location": "浙江省杭州市上城区运河东路301号靠近中豪·湘和国际 附近",
I/flutter (21400):       "speed": "0m/s",
I/flutter (21400):       "location_time": "1767775379",
I/flutter (21400):       "calculate_location_time": "1分钟43秒",
I/flutter (21400):  ... (truncated)
I/flutter (21400): ✅ Request GET /get/location - 834ms - Status: 200
I/flutter (21400): CHECK: API原始JSON数据:
I/flutter (21400): CHECK:   JSON keys: [user_location_mobile_device, half_location_mobile_device, user]
I/flutter (21400): CHECK:   user_location_mobile_device keys: [power, network_name, mobile_model, is_wifi, real_speed, longitude, latitude, location, speed, location_time, calculate_location_time, is_open_location, is_oneself, distance, stops, stay_collect, head_portrait, face]
I/flutter (21400): CHECK:   user_location_mobile_device stops: [{latitude: 30.275073, longitude: 120.220825, location_name: 浙江省杭州市上城区四季青街道杭州市上城区仁本职业培训学校中豪·湘和国际 附近, start_time: 当前, end_time: , duration: 4分钟1秒, duration_int: 241, status: staying, point_type: stop, serial_number: 1}]
I/flutter (21400): CHECK:   half_location_mobile_device keys: [power, network_name, mobile_model, is_wifi, longitude, latitude, location, location_time, speed, calculate_location_time, is_open_location, is_oneself, distance, stops, stay_collect, head_portrait, face, online, lives]
I/flutter (21400): CHECK:   half_location_mobile_device stops: []
I/flutter (21400): 📍 另一半定位开关提示状态: false
I/flutter (21400): ✅ [已绑定] 更新头像和对方位置数据
I/flutter (21400): 📍 [已绑定] 使用接口数据更新我的位置
I/flutter (21400): 🎯 命中Marker缓存: marker_529130873_null
I/flutter (21400): 📱 ============ Marker创建调试信息 ============
I/flutter (21400): 📱 设备像素比(DPI): 3.25
I/flutter (21400): 📱 屏幕宽度: 369逻辑像素 (1200物理像素)
I/flutter (21400): 📱 设计稿比例: 0.985x (369 / 375.0)
I/flutter (21400): 📱 头像尺寸: 160.0px (设计稿50.0px × 0.98 × 3.25)
I/flutter (21400): 📱 底座尺寸: 640.0px (设计稿200.0px × 0.98 × 3.25)
I/flutter (21400): 📱 Canvas尺寸: 657.8 x 196.5px
I/flutter (21400): 📱 边框宽度: 9.79px
I/flutter (21400): 📍 已绑定状态，计算双人中心位置
I/flutter (21400): 📍 只有我的位置: LatLng(30.275097, 120.22085400000003)，缩放级别17
I/flutter (21400): 📱 图片尺寸: 657 x 196px
I/flutter (21400): 📱 头像底部Y: 178.7px
I/flutter (21400): 📱 锚点位置: (0.5, 0.909)
I/flutter (21400): 📱 创建耗时: 151ms
I/flutter (21400): 📱 ============================================
I/flutter (21400): 💾 缓存Marker: marker_529130873_null (总缓存数: 1)
I/flutter (21400): 📱 ============ 底座Marker创建 ============
I/flutter (21400): 📱 设备像素比(DPI): 3.25
I/flutter (21400): 📱 屏幕宽度: 369px
I/flutter (21400): 📱 设计稿比例: 0.985x (369 / 375.0)
I/flutter (21400): 📱 请求底座尺寸: 800.0px
I/flutter (21400): 📱 设计稿尺寸: 200.0px
I/flutter (21400): 📱 实际底座尺寸: 640.0px (200.0px × 0.98 × 3.25)
I/flutter (21400): 📱 ==========================================
I/flutter (21400): [LogManager] Not initialized. Message: 清理完成，等待结束
I/flutter (21400): [LogManager] Not initialized. Message: - 定位模式: 高精度模式（GPS+网络+WIFI）
I/flutter (21400): [LogManager] Not initialized. Message: - !  息屏后限制：Android系统会限制GPS访问，自动降级为基站+WIFI定位
I/flutter (21400): [LogManager] Not initialized. Message: - 定位间隔: 5000ms（平衡响应性与耗电）
I/flutter (21400): [LogManager] Not initialized. Message: 高德定位参数设置完成
I/flutter (21400): [LogManager] Not initialized. Message: 高德定位启动请求已发送
I/flutter (21400): [LogManager] Not initialized. Message: 立即启动前台服务以支持息屏后定位...
I/flutter (21400): 🚀 启动前台定位服务...
D/BootCompletedReceiver(21400): 定位服务状态已保存: enabled=true
D/ForegroundServiceHandler(21400): 定位服务已启动，状态已保存用于开机自启动
I/flutter (21400): ✅ 前台定位服务启动成功
I/flutter (21400): [LogManager] Not initialized. Message: 前台服务启动成功（静默模式）
I/flutter (21400): [LogManager] Not initialized. Message: 智能启动策略检查：应用在前台
I/flutter (21400): [LogManager] Not initialized. Message: 应用在前台，仅启动基础定位（不启动后台定时器）
I/flutter (21400): [LogManager] Not initialized. Message: 恢复前台位置采集模式
I/flutter (21400): [LogManager] Not initialized. Message: 前台模式参数已应用：Hight_Accuracy / 5000ms / distanceFilter=-1.0
I/flutter (21400): [LogManager] Not initialized. Message: 后台通知未显示，跳过隐藏
I/flutter (21400): [LogManager] Not initialized. Message: 定位服务启动完成，立即尝试获取一次定位放入收集池
I/flutter (21400): [LogManager] Not initialized. Message: 主动获取初始定位，准备放入收集池...
I/flutter (21400): [LogManager] Not initialized. Message: 高德定位服务已启动完成
I/flutter (21400): 📊 定位权限检查完成
D/ForegroundLocationService(21400): 前台定位服务创建
D/ForegroundLocationService(21400): ⚡ 前台服务已立即启动（避免5秒超时）
D/ForegroundLocationService(21400): 服务期望状态已更新: true
D/ForegroundLocationService(21400): WakeLock 创建成功
D/ForegroundLocationService(21400): WakeLock 已立即获取（服务启动时）
D/ForegroundLocationService(21400): 定位上报服务初始化成功
D/ForegroundLocationService(21400): App使用记录上报服务初始化成功
D/ForegroundLocationService(21400): 锁屏/解锁广播接收器已注册（服务级）
D/ForegroundLocationService(21400): 网络状态广播接收器已注册
D/ForegroundLocationService(21400): 充电状态广播接收器已注册
D/ForegroundLocationService(21400): 敏感事件上报服务初始化成功
D/ForegroundLocationService(21400): 原生定位客户端初始化成功
D/ForegroundLocationService(21400): 🚑 原生保活健康检查已启动（60秒）
D/ForegroundLocationService(21400): 通知渠道创建成功: kissu_location_service
D/ForegroundLocationService(21400): 🚀 原生定位监听已启动（APP被杀后仍可工作）
D/LocationReportService(21400): ✅ 保活检查：定时器运行正常
D/ForegroundLocationService(21400): 🚀 App使用记录上报已启动（每2分钟采集一次，前台/后台统一原生）
D/ForegroundLocationService(21400): 前台定位服务启动成功
W/AppUsageReportService(21400): ! 没有使用情况访问权限，无法采集数据
I/flutter (21400): 🎯 命中Marker缓存: marker_529130873_null
I/flutter (21400): 📱 ============ Marker创建调试信息 ============
I/flutter (21400): 📱 设备像素比(DPI): 3.25
I/flutter (21400): 📱 屏幕宽度: 369逻辑像素 (1200物理像素)
I/flutter (21400): 📱 设计稿比例: 0.985x (369 / 375.0)
I/flutter (21400): 📱 头像尺寸: 160.0px (设计稿50.0px × 0.98 × 3.25)
I/flutter (21400): 📱 底座尺寸: 44.8px (设计稿14.0px × 0.98 × 3.25)
I/flutter (21400): 📱 Canvas尺寸: 177.8 x 196.5px
I/flutter (21400): 📱 边框宽度: 9.79px
W/System.err(21400): java.lang.SecurityException: listen
W/System.err(21400): 	at android.os.Parcel.createExceptionOrNull(Parcel.java:3262)
W/System.err(21400): 	at android.os.Parcel.createException(Parcel.java:3246)
W/System.err(21400): 	at android.os.Parcel.readException(Parcel.java:3229)
W/System.err(21400): 	at android.os.Parcel.readException(Parcel.java:3171)
W/System.err(21400): 	at com.android.internal.telephony.ITelephonyRegistry$Stub$Proxy.listenWithEventList(ITelephonyRegistry.java:1218)
W/System.err(21400): 	at android.telephony.TelephonyRegistryManager.listenFromListener(TelephonyRegistryManager.java:297)
W/System.err(21400): 	at android.telephony.TelephonyManager.listen(TelephonyManager.java:6912)
W/System.err(21400): 	at com.loc.es.o(Unknown Source:17)
W/System.err(21400): 	at com.loc.es.n(Unknown Source:5)
W/System.err(21400): 	at com.loc.es.<init>(Unknown Source:70)
W/System.err(21400): 	at com.loc.ei.a(Unknown Source:58)
W/System.err(21400): 	at com.loc.d.a(Unknown Source:2)
W/System.err(21400): 	at com.loc.d.b(Unknown Source:59)
W/System.err(21400): 	at com.loc.d.o(Unknown Source:6)
W/System.err(21400): 	at com.loc.d.p(Unknown Source:94)
W/System.err(21400): 	at com.loc.d.e(Unknown Source:0)
W/System.err(21400): 	at com.loc.d$a.handleMessage(Unknown Source:132)
W/System.err(21400): 	at android.os.Handler.dispatchMessage(Handler.java:118)
W/System.err(21400): 	at android.os.Looper.loopOnce(Looper.java:237)
W/System.err(21400): 	at android.os.Looper.loop(Looper.java:325)
W/System.err(21400): 	at android.os.HandlerThread.run(HandlerThread.java:85)
W/System.err(21400): 	at com.loc.d$b.run(Unknown Source:0)
W/System.err(21400): Caused by: android.os.RemoteException: Remote stack trace:
W/System.err(21400): 	at com.android.internal.telephony.TelephonyPermissions.enforceCarrierPrivilege(TelephonyPermissions.java:720)
W/System.err(21400): 	at com.android.internal.telephony.TelephonyPermissions.checkReadPhoneState(TelephonyPermissions.java:211)
W/System.err(21400): 	at com.android.internal.telephony.TelephonyPermissions.checkCallingOrSelfReadPhoneState(TelephonyPermissions.java:118)
W/System.err(21400): 	at com.android.server.TelephonyRegistry.checkListenerPermission(TelephonyRegistry.java:4095)
W/System.err(21400): 	at com.android.server.TelephonyRegistry.listen(TelephonyRegistry.java:1167)
W/System.err(21400): callee: null 2636/3176
W/System.err(21400): java.lang.SecurityException: listen
W/System.err(21400): 	at android.os.Parcel.createExceptionOrNull(Parcel.java:3262)
W/System.err(21400): 	at android.os.Parcel.createException(Parcel.java:3246)
W/System.err(21400): 	at android.os.Parcel.readException(Parcel.java:3229)
W/System.err(21400): 	at android.os.Parcel.readException(Parcel.java:3171)
W/System.err(21400): 	at com.android.internal.telephony.ITelephonyRegistry$Stub$Proxy.listenWithEventList(ITelephonyRegistry.java:1218)
W/System.err(21400): 	at android.telephony.TelephonyRegistryManager.listenFromListener(TelephonyRegistryManager.java:297)
W/System.err(21400): 	at android.telephony.TelephonyManager.listen(TelephonyManager.java:6912)
W/System.err(21400): 	at com.loc.es.o(Unknown Source:17)
W/System.err(21400): 	at com.loc.es.n(Unknown Source:5)
W/System.err(21400): 	at com.loc.es.<init>(Unknown Source:70)
W/System.err(21400): 	at com.loc.ei.a(Unknown Source:58)
W/System.err(21400): 	at com.loc.d.a(Unknown Source:2)
W/System.err(21400): 	at com.loc.d.b(Unknown Source:59)
W/System.err(21400): 	at com.loc.d.o(Unknown Source:6)
W/System.err(21400): 	at com.loc.d.p(Unknown Source:94)
W/System.err(21400): 	at com.loc.d.e(Unknown Source:0)
W/System.err(21400): 	at com.loc.d$a.handleMessage(Unknown Source:132)
W/System.err(21400): 	at android.os.Handler.dispatchMessage(Handler.java:118)
W/System.err(21400): 	at android.os.Looper.loopOnce(Looper.java:237)
W/System.err(21400): 	at android.os.Looper.loop(Looper.java:325)
W/System.err(21400): 	at android.os.HandlerThread.run(HandlerThread.java:85)
W/System.err(21400): 	at com.loc.d$b.run(Unknown Source:0)
I/flutter (21400): 📱 图片尺寸: 177 x 196px
I/flutter (21400): 📱 头像底部Y: 178.7px
I/flutter (21400): 📱 锚点位置: (0.5, 0.909)
I/flutter (21400): 📱 创建耗时: 41ms
I/flutter (21400): 📱 ============================================
I/flutter (21400): 💾 缓存Marker: marker_529130873_null (总缓存数: 1)
I/flutter (21400): 📱 ============ 底座Marker创建 ============
I/flutter (21400): 📱 设备像素比(DPI): 3.25
I/flutter (21400): 📱 屏幕宽度: 369px
I/flutter (21400): 📱 设计稿比例: 0.985x (369 / 375.0)
I/flutter (21400): 📱 请求底座尺寸: 40.0px
I/flutter (21400): 📱 设计稿尺寸: 21.0px
I/flutter (21400): 📱 实际底座尺寸: 67.2px (21.0px × 0.98 × 3.25)
I/flutter (21400): 📱 ==========================================
I/flutter (21400): [LogManager] Not initialized. Message: 全局监听器收到定位数据: {callbackTime: 2026-01-07 16:44:43, locationTime: 2026-01-07 16:44:32, locationType: 4, latitude: 30.275025, longitude: 120.220817, accuracy: 44.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 上城区, street: 运河东路, streetNumber: 301号, cityCode: 0571, adCode: 330102, address: 浙江省杭州市上城区运河东路301号靠近中豪·湘和国际, description: 在中豪·湘和国际附近}
I/flutter (21400): [LogManager] Not initialized. Message: 完整定位数据: {callbackTime: 2026-01-07 16:44:43, locationTime: 2026-01-07 16:44:32, locationType: 4, latitude: 30.275025, longitude: 120.220817, accuracy: 44.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 上城区, street: 运河东路, streetNumber: 301号, cityCode: 0571, adCode: 330102, address: 浙江省杭州市上城区运河东路301号靠近中豪·湘和国际, description: 在中豪·湘和国际附近}
D/ForegroundLocationService(21400): 📍 原生定位成功: 30.275025, 120.220817, 精度: 44.0m
D/ForegroundLocationService(21400): 定位成功，静默模式（不更新通知）
D/LocationReportService(21400): 📍 距离不足且时间未到，跳过收集: 移动4米 < 50米，距上次收集42秒
W/System.err(21400): java.lang.SecurityException: listen
W/System.err(21400): 	at android.os.Parcel.createExceptionOrNull(Parcel.java:3262)
W/System.err(21400): 	at android.os.Parcel.createException(Parcel.java:3246)
W/System.err(21400): 	at android.os.Parcel.readException(Parcel.java:3229)
W/System.err(21400): 	at android.os.Parcel.readException(Parcel.java:3171)
W/System.err(21400): 	at com.android.internal.telephony.ITelephonyRegistry$Stub$Proxy.listenWithEventList(ITelephonyRegistry.java:1218)
W/System.err(21400): 	at android.telephony.TelephonyRegistryManager.listenFromListener(TelephonyRegistryManager.java:297)
W/System.err(21400): 	at android.telephony.TelephonyManager.listen(TelephonyManager.java:6912)
W/System.err(21400): 	at com.loc.es.o(Unknown Source:17)
W/System.err(21400): 	at com.loc.es.n(Unknown Source:5)
W/System.err(21400): 	at com.loc.es.<init>(Unknown Source:70)
W/System.err(21400): 	at com.loc.ei.a(Unknown Source:58)
W/System.err(21400): 	at com.loc.e.a(Unknown Source:28)
W/System.err(21400): 	at com.loc.e.a(Unknown Source:0)
W/System.err(21400): 	at com.loc.e$a.handleMessage(Unknown Source:294)
W/System.err(21400): 	at android.os.Handler.dispatchMessage(Handler.java:118)
W/System.err(21400): 	at android.os.Looper.loopOnce(Looper.java:237)
W/System.err(21400): 	at android.os.Looper.loop(Looper.java:325)
W/System.err(21400): 	at android.os.HandlerThread.run(HandlerThread.java:85)
W/System.err(21400): 	at com.loc.e$b.run(Unknown Source:0)
I/flutter (21400): 📊 Marker创建/缓存耗时: 554ms
I/flutter (21400): 📍 [Marker创建] myPos: LatLng(30.275097, 120.22085400000003), partnerPos: null
I/flutter (21400): 📍 距离数据未到达，等待接口数据...
I/flutter (21400): 📊 位置数据加载完成
I/flutter (21400): 📍 已绑定状态，计算双人中心位置
I/flutter (21400): 📍 只有我的位置: LatLng(30.275097, 120.22085400000003)，缩放级别17
I/HiTouch_PressGestureDetector(21400): checkDoublePointerLimit: false
I/flutter (21400): 💡 定位页面：切换头像，恢复下半屏到底部吸顶位置
I/flutter (21400): 🎯 定位页面：收起底部面板到底部吸顶位置
I/flutter (21400): [LogManager] Not initialized. Message: DeviceUtil not initialized, using fallback deviceId
I/flutter (21400): INFO: OAID 已添加到请求头
I/flutter (21400): INFO: ========== Request Headers ==========
I/flutter (21400): INFO: URL: https://service-api.ikissu.cn/get/location
I/flutter (21400): INFO: Method: GET
I/flutter (21400): INFO: --- Business Headers ---
I/flutter (21400): INFO: token: eyJ0eXAiOiJKV1QiLCJh... (205 chars)
I/flutter (21400): INFO: sign: 2E5CD3B86E90D474A480... (32 chars)
I/flutter (21400): INFO: version: 1.1.3
I/flutter (21400): INFO: channel: kissu_huawei
I/flutter (21400): INFO: pkg: com.yuluo.kissu
I/flutter (21400): INFO: os: 1
I/flutter (21400): INFO: network-name: wifi_YuluoKeji_5G
I/flutter (21400): INFO: deviceid: android-1767775484982
I/flutter (21400): INFO: mobile-model: HONOR ALI-AN00
I/flutter (21400): INFO: power: 50
I/flutter (21400): INFO: is-open-location: 1
I/flutter (21400): INFO: brand: HONOR
I/flutter (21400): INFO: oaid: 18887152-1202-4a74-9d32-2b825f7d3d73
I/flutter (21400): INFO: --- Other Headers ---
I/flutter (21400): INFO: cache_control: noCache
I/flutter (21400): INFO: timestamp: 1767775484982
I/flutter (21400): INFO: =====================================
I/flutter (21400): [LogManager] Not initialized. Message: GET https://service-api.ikissu.cn/get/location
I/flutter (21400): [LogManager] Not initialized. Message: Headers: {cache_control: noCache, token: ***HIDDEN***, version: 1.1.3, pkg: com.yuluo.kissu, os: 1, deviceid: android-1767775484982, oaid: 18887152-1202-4a74-9d32-2b825f7d3d73, mobile-model: HONOR ALI-AN00, brand: HONOR, is-open-location: 1, channel: kissu_huawei, network-name: wifi_YuluoKeji_5G, power: 50, timestamp: 1767775484982, sign: 2E5CD3B86E90D474A480EE67BF190063}
I/flutter (21400): [LogManager] Not initialized. Message: 200 GET https://service-api.ikissu.cn/get/location (764ms)
I/flutter (21400): [LogManager] Not initialized. Message: Response: {
I/flutter (21400):   "isSuccess": true,
I/flutter (21400):   "code": 0,
I/flutter (21400):   "msg": "",
I/flutter (21400):   "data": null,
I/flutter (21400):   "dataList": null,
I/flutter (21400):   "dataJson": {
I/flutter (21400):     "user_location_mobile_device": {
I/flutter (21400):       "power": "50%",
I/flutter (21400):       "network_name": "wifi_YuluoKeji_5G",
I/flutter (21400):       "mobile_model": "HONOR",
I/flutter (21400):       "is_wifi": "0",
I/flutter (21400):       "real_speed": "0",
I/flutter (21400):       "longitude": "120.220854",
I/flutter (21400):       "latitude": "30.275097",
I/flutter (21400):       "location": "浙江省杭州市上城区运河东路301号靠近中豪·湘和国际 附近",
I/flutter (21400):       "speed": "0m/s",
I/flutter (21400):       "location_time": "1767775379",
I/flutter (21400):       "calculate_location_time": "1分钟45秒",
I/flutter (21400):  ... (truncated)
I/flutter (21400): ✅ Request GET /get/location - 814ms - Status: 200
I/flutter (21400): CHECK: API原始JSON数据:
I/flutter (21400): CHECK:   JSON keys: [user_location_mobile_device, half_location_mobile_device, user]
I/flutter (21400): CHECK:   user_location_mobile_device keys: [power, network_name, mobile_model, is_wifi, real_speed, longitude, latitude, location, speed, location_time, calculate_location_time, is_open_location, is_oneself, distance, stops, stay_collect, head_portrait, face]
I/flutter (21400): CHECK:   user_location_mobile_device stops: [{latitude: 30.275073, longitude: 120.220825, location_name: 浙江省杭州市上城区四季青街道杭州市上城区仁本职业培训学校中豪·湘和国际 附近, start_time: 当前, end_time: , duration: 4分钟1秒, duration_int: 241, status: staying, point_type: stop, serial_number: 1}]
I/flutter (21400): CHECK:   half_location_mobile_device keys: [power, network_name, mobile_model, is_wifi, longitude, latitude, location, location_time, speed, calculate_location_time, is_open_location, is_oneself, distance, stops, stay_collect, head_portrait, face, online, lives]
I/flutter (21400): CHECK:   half_location_mobile_device stops: []
I/flutter (21400): 📍 另一半定位开关提示状态: false
I/flutter (21400): ✅ [已绑定] 更新头像和对方位置数据
I/flutter (21400): 📍 [已绑定] 使用接口数据更新我的位置
I/flutter (21400): 📍 [Marker创建] myPos: LatLng(30.275097, 120.22085400000003), partnerPos: null
I/flutter (21400): 📍 距离数据未到达，等待接口数据...
I/flutter (21400): 📍 移动到我的位置: LatLng(30.275097, 120.22085400000003)
I/flutter (21400): 📍 移动地图到位置: LatLng(30.275097, 120.22085400000003)，缩放级别17
I/flutter (21400): 📍 已绑定状态，计算双人中心位置
I/flutter (21400): 📍 只有我的位置: LatLng(30.275097, 120.22085400000003)，缩放级别17
I/AMapFlutter_MapController(21400): onCameraChange===>{position={bearing=0.0, zoom=17.0, tilt=0.0, target=[30.275097000000002, 120.22085400000002]}}
I/AMapFlutter_MapController(21400): onCameraChangeFinish===>{position={bearing=0.0, zoom=17.0, tilt=0.0, target=[30.275097000000002, 120.22085400000002]}}
I/flutter (21400): [LogManager] Not initialized. Message: 为收集池请求单次定位...
I/flutter (21400): [LogManager] Not initialized. Message: 为收集池的单次定位请求已发送
W/System.err(21400): java.lang.SecurityException: listen
W/System.err(21400): 	at android.os.Parcel.createExceptionOrNull(Parcel.java:3262)
W/System.err(21400): 	at android.os.Parcel.createException(Parcel.java:3246)
W/System.err(21400): 	at android.os.Parcel.readException(Parcel.java:3229)
W/System.err(21400): 	at android.os.Parcel.readException(Parcel.java:3171)
W/System.err(21400): 	at com.android.internal.telephony.ITelephonyRegistry$Stub$Proxy.listenWithEventList(ITelephonyRegistry.java:1218)
W/System.err(21400): 	at android.telephony.TelephonyRegistryManager.listenFromListener(TelephonyRegistryManager.java:297)
W/System.err(21400): 	at android.telephony.TelephonyManager.listen(TelephonyManager.java:6912)
W/System.err(21400): 	at com.loc.es.o(Unknown Source:17)
W/System.err(21400): 	at com.loc.es.n(Unknown Source:5)
W/System.err(21400): 	at com.loc.es.<init>(Unknown Source:70)
W/System.err(21400): 	at com.loc.ei.a(Unknown Source:58)
W/System.err(21400): 	at com.loc.d.a(Unknown Source:2)
W/System.err(21400): 	at com.loc.d.b(Unknown Source:59)
W/System.err(21400): 	at com.loc.d.o(Unknown Source:6)
W/System.err(21400): 	at com.loc.d.p(Unknown Source:94)
W/System.err(21400): 	at com.loc.d.e(Unknown Source:0)
W/System.err(21400): 	at com.loc.d$a.handleMessage(Unknown Source:132)
W/System.err(21400): 	at android.os.Handler.dispatchMessage(Handler.java:118)
W/System.err(21400): 	at android.os.Looper.loopOnce(Looper.java:237)
W/System.err(21400): 	at android.os.Looper.loop(Looper.java:325)
W/System.err(21400): 	at android.os.HandlerThread.run(HandlerThread.java:85)
W/System.err(21400): 	at com.loc.d$b.run(Unknown Source:0)
W/System.err(21400): Caused by: android.os.RemoteException: Remote stack trace:
W/System.err(21400): 	at com.android.internal.telephony.TelephonyPermissions.enforceCarrierPrivilege(TelephonyPermissions.java:720)
W/System.err(21400): 	at com.android.internal.telephony.TelephonyPermissions.checkReadPhoneState(TelephonyPermissions.java:211)
W/System.err(21400): 	at com.android.internal.telephony.TelephonyPermissions.checkCallingOrSelfReadPhoneState(TelephonyPermissions.java:118)
W/System.err(21400): 	at com.android.server.TelephonyRegistry.checkListenerPermission(TelephonyRegistry.java:4095)
W/System.err(21400): 	at com.android.server.TelephonyRegistry.listen(TelephonyRegistry.java:1167)
W/System.err(21400): callee: null 2636/3176
I/flutter (21400): [LogManager] Not initialized. Message: 全局监听器收到定位数据: {callbackTime: 2026-01-07 16:44:46, locationTime: 2026-01-07 16:44:32, locationType: 4, latitude: 30.275025, longitude: 120.220817, accuracy: 44.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 上城区, street: 运河东路, streetNumber: 301号, cityCode: 0571, adCode: 330102, address: 浙江省杭州市上城区运河东路301号靠近中豪·湘和国际, description: 在中豪·湘和国际附近}
I/flutter (21400): [LogManager] Not initialized. Message: 完整定位数据: {callbackTime: 2026-01-07 16:44:46, locationTime: 2026-01-07 16:44:32, locationType: 4, latitude: 30.275025, longitude: 120.220817, accuracy: 44.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 上城区, street: 运河东路, streetNumber: 301号, cityCode: 0571, adCode: 330102, address: 浙江省杭州市上城区运河东路301号靠近中豪·湘和国际, description: 在中豪·湘和国际附近}
I/flutter (21400): [LogManager] Not initialized. Message: 单次定位成功，准备重启持续定位
I/flutter (21400): [LogManager] Not initialized. Message: 重启持续定位...
I/flutter (21400): [LogManager] Not initialized. Message: 缓冲区为空，重置首次定位标志
I/flutter (21400): [LogManager] Not initialized. Message: 重新设置持续定位参数...
I/flutter (21400): [LogManager] Not initialized. Message: 持续定位参数重新设置完成
I/flutter (21400): [LogManager] Not initialized. Message: 持续定位已重启
W/System.err(21400): java.lang.SecurityException: listen
W/System.err(21400): 	at android.os.Parcel.createExceptionOrNull(Parcel.java:3262)
W/System.err(21400): 	at android.os.Parcel.createException(Parcel.java:3246)
W/System.err(21400): 	at android.os.Parcel.readException(Parcel.java:3229)
W/System.err(21400): 	at android.os.Parcel.readException(Parcel.java:3171)
W/System.err(21400): 	at com.android.internal.telephony.ITelephonyRegistry$Stub$Proxy.listenWithEventList(ITelephonyRegistry.java:1218)
W/System.err(21400): 	at android.telephony.TelephonyRegistryManager.listenFromListener(TelephonyRegistryManager.java:297)
W/System.err(21400): 	at android.telephony.TelephonyManager.listen(TelephonyManager.java:6912)
W/System.err(21400): 	at com.loc.es.o(Unknown Source:17)
W/System.err(21400): 	at com.loc.es.n(Unknown Source:5)
W/System.err(21400): 	at com.loc.es.<init>(Unknown Source:70)
W/System.err(21400): 	at com.loc.ei.a(Unknown Source:58)
W/System.err(21400): 	at com.loc.d.a(Unknown Source:2)
W/System.err(21400): 	at com.loc.d.b(Unknown Source:59)
W/System.err(21400): 	at com.loc.d.o(Unknown Source:6)
W/System.err(21400): 	at com.loc.d.p(Unknown Source:94)
W/System.err(21400): 	at com.loc.d.e(Unknown Source:0)
W/System.err(21400): 	at com.loc.d$a.handleMessage(Unknown Source:132)
W/System.err(21400): 	at android.os.Handler.dispatchMessage(Handler.java:118)
W/System.err(21400): 	at android.os.Looper.loopOnce(Looper.java:237)
W/System.err(21400): 	at android.os.Looper.loop(Looper.java:325)
W/System.err(21400): 	at android.os.HandlerThread.run(HandlerThread.java:85)
W/System.err(21400): 	at com.loc.d$b.run(Unknown Source:0)
I/flutter (21400): [LogManager] Not initialized. Message: 全局监听器收到定位数据: {callbackTime: 2026-01-07 16:44:47, locationTime: 2026-01-07 16:44:32, locationType: 4, latitude: 30.275025, longitude: 120.220817, accuracy: 44.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 上城区, street: 运河东路, streetNumber: 301号, cityCode: 0571, adCode: 330102, address: 浙江省杭州市上城区运河东路301号靠近中豪·湘和国际, description: 在中豪·湘和国际附近}
I/flutter (21400): [LogManager] Not initialized. Message: 完整定位数据: {callbackTime: 2026-01-07 16:44:47, locationTime: 2026-01-07 16:44:32, locationType: 4, latitude: 30.275025, longitude: 120.220817, accuracy: 44.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 上城区, street: 运河东路, streetNumber: 301号, cityCode: 0571, adCode: 330102, address: 浙江省杭州市上城区运河东路301号靠近中豪·湘和国际, description: 在中豪·湘和国际附近}
D/ForegroundLocationService(21400): ⚡ 前台服务已立即启动（避免5秒超时）
D/ForegroundLocationService(21400): 服务期望状态已更新: true
D/ForegroundLocationService(21400): 服务组件已完整初始化，跳过
W/Bundle  (21400): Key priority expected String but value was a java.lang.Integer.  The default value <null> was returned.
W/Bundle  (21400): Attempt to cast generated internal exception:
W/Bundle  (21400): java.lang.ClassCastException: java.lang.Integer cannot be cast to java.lang.String
W/Bundle  (21400): 	at android.os.BaseBundle.getString(BaseBundle.java:1422)
W/Bundle  (21400): 	at android.content.Intent.getStringExtra(Intent.java:9758)
W/Bundle  (21400): 	at com.yuluo.kissu.ForegroundLocationService.getStringExtraCompat(ForegroundLocationService.kt:897)
W/Bundle  (21400): 	at com.yuluo.kissu.ForegroundLocationService.startLocationForegroundService(ForegroundLocationService.kt:576)
W/Bundle  (21400): 	at com.yuluo.kissu.ForegroundLocationService.onStartCommand(ForegroundLocationService.kt:190)
W/Bundle  (21400): 	at android.app.ActivityThread.handleServiceArgs(ActivityThread.java:6164)
W/Bundle  (21400): 	at android.app.ActivityThread.-$$Nest$mhandleServiceArgs(Unknown Source:0)
W/Bundle  (21400): 	at android.app.ActivityThread$H.handleMessage(ActivityThread.java:3173)
W/Bundle  (21400): 	at android.os.Handler.dispatchMessage(Handler.java:118)
W/Bundle  (21400): 	at android.os.Looper.loopOnce(Looper.java:237)
W/Bundle  (21400): 	at android.os.Looper.loop(Looper.java:325)
W/Bundle  (21400): 	at android.app.ActivityThread.main(ActivityThread.java:10404)
W/Bundle  (21400): 	at java.lang.reflect.Method.invoke(Native Method)
W/Bundle  (21400): 	at com.android.internal.os.RuntimeInit$MethodAndArgsCaller.run(RuntimeInit.java:635)
W/Bundle  (21400): 	at com.android.internal.os.ZygoteInit.main(ZygoteInit.java:970)
D/ForegroundLocationService(21400): 通知渠道创建成功: kissu_location_service
D/ForegroundLocationService(21400): 原生定位监听已在运行中
D/LocationReportService(21400): ✅ 保活检查：定时器运行正常
D/ForegroundLocationService(21400): 🚀 App使用记录上报已启动（每2分钟采集一次，前台/后台统一原生）
D/ForegroundLocationService(21400): 前台定位服务启动成功
