/InputMethodManager(15282): hideSoftInputFromWindow: reason is 4,mAsyncShowHideMethodEnabled=true
D/OpenInstall(15282): decodeInstall success : {}
[Login] 未获取到OpenInstall邀请码
[AuthService] 使用手动提供的邀请码登录
[DeviceUtil] DeviceUtil not initialized, using fallback deviceId
[OaidUtil] 开始获取设备ID...
[OaidUtil] 返回缓存的设备ID: 93ac3dd7...
I/flutter (15282): onInstallNotification
I/flutter (15282): INFO: 未在OpenInstall参数中找到邀请码，参数: {shouldRetry: false, channelCode: , bindData: }
I/flutter (15282): [16:50:53.648] [D] [Login] 未获取到OpenInstall邀请码
I/flutter (15282): [16:50:53.648] [I] [AuthService] 使用手动提供的邀请码登录 | Extra: {friendCode: , phone: 13245546464}
I/flutter (15282): [16:50:53.651] [W] [DeviceUtil] DeviceUtil not initialized, using fallback deviceId
I/flutter (15282): [16:50:53.652] [I] [OaidUtil] 开始获取设备ID...
I/flutter (15282): [16:50:53.652] [I] [OaidUtil] 返回缓存的设备ID: 93ac3dd7...
2
I/flutter (15282): [LogManager] Error in appender FileAppender: Bad state: StreamSink is bound to a stream
I/flutter (15282): INFO: OAID 已添加到请求头
I/flutter (15282): INFO: ========== Request Headers ==========
I/flutter (15282): INFO: URL: http://dev-love-api.ikissu.cn/user/login
I/flutter (15282): INFO: Method: POST
I/flutter (15282): INFO: --- Business Headers ---
I/flutter (15282): INFO: sign: 9E854785DD0C9B6644D5... (32 chars)
I/flutter (15282): INFO: version: 1.1.9
I/flutter (15282): INFO: channel: kissu_huawei
I/flutter (15282): INFO: pkg: com.yuluo.kissu
I/flutter (15282): INFO: os: 1
I/flutter (15282): INFO: network-name: wifi_YuluoKeji_5G
I/flutter (15282): INFO: deviceid: android-1773391853652
I/flutter (15282): INFO: mobile-model: HONOR ALI-AN00
I/flutter (15282): INFO: power: 73
I/flutter (15282): INFO: is-open-location: 1
I/flutter (15282): INFO: brand: HONOR
I/flutter (15282): INFO: oaid: 93ac3dd7-36c2-4b8d-94c1-1e4370103ba2
I/flutter (15282): INFO: --- Other Headers ---
I/flutter (15282): INFO: network_debounce: true
I/flutter (15282): INFO: content-type: application/json
I/flutter (15282): INFO: timestamp: 1773391853653
I/flutter (15282): INFO: =====================================
I/flutter (15282): [16:50:53.660] [D] [HTTP] POST http://dev-love-api.ikissu.cn/user/login
I/flutter (15282): [16:50:53.660] [D] [HTTP] Headers: {network_debounce: true, content-type: application/json, version: 1.1.9, pkg: com.yuluo.kissu, os: 1, deviceid: android-1773391853652, oaid: 93ac3dd7-36c2-4b8d-94c1-1e4370103ba2, mobile-model: HONOR ALI-AN00, brand: HONOR, is-open-location: 1, channel: kissu_huawei, network-name: wifi_YuluoKeji_5G, power: 73, timestamp: 1773391853653, sign: 9E854785DD0C9B6644D5A3B4680D45FD}
I/flutter (15282): [16:50:53.661] [D] [HTTP] Request: {
I/flutter (15282):   "phone": "13245546464",
I/flutter (15282):   "captcha": "79536",
I/flutter (15282):   "friend_code": ""
I/flutter (15282): }
[HTTP] POST http://dev-love-api.ikissu.cn/user/login
[HTTP] Request: {
         "phone": "13245546464",
         "captcha": "79536",
         "friend_code": ""
       }
D/InsetsController(15282): hide(ime(), fromIme=true)
D/FullScreenUtils(15282): isNeedToHideStatusBar: splitscreenstate=-1
I/ImeBackDispatcher(15282): onReceiveResult dispatcher:android.window.WindowOnBackInvokedDispatcher@eb2e4bb, resultCode:1
I/WindowOnBackDispatcher(15282): UnregisterOnBackInvokedCallback, remove ime callback.
W/WindowOnBackDispatcher(15282): sendCancelIfRunning: isInProgress=false callback=ImeCallback=ImeOnBackInvokedCallback@76097324 Callback=android.window.IOnBackInvokedCallback$Stub$Proxy@1bb326
I/SurfaceControl(15282): nativeRelease 0xb400007cb10f7110 count: 1 name: Surface(name=13f605f InputMethod)/@0xf1c375 - animation-leash of insets_animation#208854
I/SurfaceControl(15282): nativeRelease 0xb400007cb10ebbf0 count: 1 name: Surface(name=e70a967 StatusBar)/@0xb50aa20 - animation-leash of insets_animation#208853
[HTTP] Headers: {network_debounce: true, content-type: application/json, version: 1.1.9, pkg: com.yuluo.kissu, os: 1, deviceid: android-1773391853652, oaid: 93ac3dd7-36c2-4b8d-94c1-1e4370103ba2, mobile-model: HONOR ALI-AN00, brand: HONOR, is-open-location: 1, channel: kissu_huawei, network-name: wifi_YuluoKeji_5G, power: 73, timestamp: 1773391853653, sign: 9E854785DD0C9B6644D5A3B4680D45FD}
D/ForegroundLocationService(15282): 📍 原生定位成功: 30.27479802478409, 120.2207511437952, 精度: 50.0m
D/ForegroundLocationService(15282): 定位成功，静默模式（不更新通知）
D/LocationReportService(15282): 📍 距离不足且时间未到，跳过收集: 移动30米 < 50米，距上次收集55秒
I/ImeTracker(15282): com.yuluo.kissu:8bff7432: onRequestHide at ORIGIN_CLIENT reason HIDE_SOFT_INPUT_ON_ANIMATION_STATE_CHANGED fromUser false
I/InputMethodManager(15282): notifyImeHidden true
I/ImeTracker(15282): com.yuluo.kissu:743d8f02: onHidden
W/InputMethodManager(15282): startInputReason = 4
V/InputMethodManager(15282): Starting input: editorInfo=android.view.inputmethod.EditorInfo@3096d14 ic=null
V/InputMethodManager(15282): START INPUT: view=io.flutter.embedding.android.FlutterView{6536eec VFE...... .F...... 0,0-1200,2652 #1 aid=1073741824},focus=true,windowFocus=true,window=android.view.ViewRootImpl$W@96eb362,displayId=0,temporaryDetach=false,hasImeFocus=true ic=null editorInfo=android.view.inputmethod.EditorInfo@3096d14 startInputFlags=VIEW_HAS_FOCUS
I/SurfaceControl(15282): nativeRelease 0xb400007cb1090690 count: 4 name: Surface(name=13f605f InputMethod)/@0xf1c375 - animation-leash of insets_animation#208854
V/InputMethodManager(15282): Starting input: Bind result=InputBindResult{result=SUCCESS_WITH_IME_SESSION method=com.android.internal.inputmethod.IInputMethodSession$Stub$Proxy@bb7b9bd id=com.baidu.input_hihonor/com.baidu.input_honor.ImeService sequence=14626 result=0 isInputMethodSuppressingSpellChecker=false}
[HTTP] 200 POST http://dev-love-api.ikissu.cn/user/login (908ms)
I/flutter (15282): [16:50:54.569] [I] [HTTP] 200 POST http://dev-love-api.ikissu.cn/user/login (908ms)
I/flutter (15282): [16:50:54.582] [D] [HTTP] Response: {
I/flutter (15282):   "isSuccess": true,
I/flutter (15282):   "code": 0,
I/flutter (15282):   "msg": "登录成功",
I/flutter (15282):   "data": null,
I/flutter (15282):   "dataList": null,
I/flutter (15282):   "dataJson": {
I/flutter (15282):     "id": 218,
I/flutter (15282):     "phone": "13245546464",
I/flutter (15282):     "nickname": "kissu6464",
I/flutter (15282):     "head_portrait": "https://kissustatic.yuluojishu.com/uploads/2025/08/21/c995803f84b964e9b191b1f6a7422a2a.png",
I/flutter (15282):     "gender": 2,
I/flutter (15282):     "lover_id": 430,
I/flutter (15282):     "birthday": "1996-01-01",
I/flutter (15282):     "half_uid": 217,
I/flutter (15282):     "status": 1,
I/flutter (15282):     "inviter_id": 0,
I/flutter (15282):     "friend_code": "2000044",
I/flutter (15282):     "friend_qr_code": "https://kissustatic.yuluojis... (truncated)
I/flutter (15282): ✅ Request POST /user/login - 934ms - Status: 200
I/flutter (15282): INFO:  开始保存用户数据，用户ID: 218, 数据长度: 2783
I/flutter (15282): SUCCESS:  用户数据保存成功
I/flutter (15282): SUCCESS:  验证保存成功，数据长度: 2783
I/flutter (15282): [16:50:54.589] [I] [AuthService] 登录成功 | Extra: {userId: 218, nickname: kissu6464}
I/flutter (15282): [16:50:54.589] [I] [AuthService] 设备ID初始化完成
I/flutter (15282): [16:50:54.590] [I] [NativeLocationReportService] 🔐 保存用户 Token 到 Native：userId=218, baseUrl=http://dev-love-api.ikissu.cn
[AuthService] 登录成功
[AuthService] 设备ID初始化完成
2
I/flutter (15282): [LogManager] Error in appender FileAppender: Bad state: StreamSink is bound to a stream
D/ForegroundServiceHandler(15282): 📥 收到 saveUserToken 请求
D/ForegroundServiceHandler(15282): 📝 Token参数: token=eyJ0eXAiOiJKV1QiLCJh..., userId=218, baseUrl=http://dev-love-api.ikissu.cn
D/LocationReportService(15282): ✅ 用户Token已保存: 218
D/LocationReportService(15282): 🔄 Token已更新，重启定时器以使用新token
D/LocationReportService(15282): ⏰ 定时上报器已启动，间隔: 60秒
D/LocationReportService(15282): 🛠️ 已调度 WorkManager 单次兜底任务（2分钟后尝试重启服务/定时器）
D/LocationReportService(15282): ✅ API基础URL已保存: http://dev-love-api.ikissu.cn
2
D/AppUsageReportService(15282): 用户Token已保存: 218
[NativeLocationReportService] 🔐 保存用户 Token 到 Native：userId=218, baseUrl=http://dev-love-api.ikissu.cn
2
D/AppUsageReportService(15282): API基础URL已保存: http://dev-love-api.ikissu.cn
D/ForegroundServiceHandler(15282): ✅ 用户Token和API配置已保存: userId=218, baseUrl=http://dev-love-api.ikissu.cn
I/flutter (15282): [16:50:54.597] [I] [NativeLocationReportService] ✅ Native Token 保存成功
I/flutter (15282): [16:50:54.598] [I] [AuthService] 用户Token已同步到Native端
I/flutter (15282): [16:50:54.598] [I] [AuthService] 🔄 准备登录腾讯IM...
I/flutter (15282): [16:50:54.598] [I] [AuthService] IM登录参数检查 - uniqueId: 有值, hasImSign: true
I/flutter (15282): [16:50:54.599] [I] [AuthService] 开始登录腾讯IM (第1次尝试)
I/flutter (15282): [16:50:54.599] [I] [TencentIMService] IM登录请求 - uniqueId: d88b940a44154acc8ef2cf1d82632d4a, hasImSign: true, userId: 218
I/flutter (15282): [16:50:54.599] [W] [TencentIMService] IM SDK未初始化，尝试先初始化
I/flutter (15282): [16:50:54.599] [I] [TencentIMService] 开始初始化腾讯IM SDK...
I/flutter (15282): [LogManager] Error in appender FileAppender: Bad state: StreamSink is bound to a stream
I/imsdk   (15282): TIM: |-channel.cpp:98                          Close                                   |channel close|channel id:15
5
I/flutter (15282): [LogManager] Error in appender FileAppender: Bad state: StreamSink is bound to a stream
I/imsdk   (15282): TIM: |-longconnection.cpp:80                   Close                                   |Close
I/flutter (15282): [LogManager] Error in appender FileAppender: Bad state: StreamSink is bound to a stream
I/flutter (15282): [16:50:54.601] [D] [TencentIMService] 已重置Flutter插件SDK状态
I/imsdk   (15282): TIM: |-im_engine_impl.cpp:337                  InternalUninit                          |UnInitSDK|cost_time:3ms|api_type:8
[NativeLocationReportService] ✅ Native Token 保存成功
[AuthService] 用户Token已同步到Native端
[AuthService] 🔄 准备登录腾讯IM...
[AuthService] IM登录参数检查 - uniqueId: 有值, hasImSign: true
[AuthService] 开始登录腾讯IM (第1次尝试)
[TencentIMService] IM登录请求 - uniqueId: d88b940a44154acc8ef2cf1d82632d4a, hasImSign: true, userId: 218
[TencentIMService] IM SDK未初始化，尝试先初始化
[TencentIMService] 开始初始化腾讯IM SDK...
I/flutter (15282): deviceInfo: {deviceType: ALI-AN00, systemVersion: 15, deviceBrand: 2006}
I/flutter (15282): [16:50:54.609] [I] [TencentIMService] 腾讯IM SDK初始化成功
[TencentIMService] 已重置Flutter插件SDK状态
[HTTP] Response: {
         "isSuccess": true,
         "code": 0,
         "msg": "登录成功",
         "data": null,
         "dataList": null,
         "dataJson": {
           "id": 218,
           "phone": "13245546464",
           "nickname": "kissu6464",
           "head_portrait": "https://kissustatic.yuluojishu.com/uploads/2025/08/21/c995803f84b964e9b191b1f6a7422a2a.png",
           "gender": 2,
           "lover_id": 430,
           "birthday": "1996-01-01",
           "half_uid": 217,
           "status": 1,
           "inviter_id": 0,
           "friend_code": "2000044",
           "friend_qr_code": "https://kissustatic.yuluojis... (truncated)
[TencentIMService] 腾讯IM SDK初始化成功
I/imsdk   (15282): TIM: ==========================================================================
I/imsdk   (15282): TIM: ======  SDK APP ID:  1600095370
I/imsdk   (15282): TIM: ======  SDK Version: 8.8.7357
I/imsdk   (15282): TIM: ======  Platform:    Android
I/imsdk   (15282): TIM: ======  Device Type: ALI-AN00
I/imsdk   (15282): TIM: ======  Device ID:   57FB707C74-1BB5-75CA-BB6C-975B82A9A6
I/imsdk   (15282): TIM: ======  System Ver:  15
I/imsdk   (15282): TIM: ======  Process ID:  15282
I/imsdk   (15282): TIM: ======  Init Path:   /data/user/0/com.yuluo.kissu/files/
I/imsdk   (15282): TIM: ======  Log Path:    /storage/emulated/0/Android/data/com.yuluo.kissu/files/log/tencent/imsdk/
I/imsdk   (15282): TIM: ======  IM 智能客服:   https://cloud.tencent.com/act/event/smarty-service?from=im-doc
I/imsdk   (15282): TIM: ======  SDK 更新日志:  https://cloud.tencent.com/document/product/269/1606
I/imsdk   (15282): TIM: ======  SDK 接口文档:  https://cloud.tencent.com/document/product/269/44498
I/imsdk   (15282): TIM: ======  常见问题:      https://cloud.tencent.com/document/product/269/32483
I/imsdk   (15282): TIM: ======  反馈问题？戳我提 issue: https://github.com/tencentyun/TIMSDK/issues
I/imsdk   (15282): TIM: =========================================================================
I/imsdk   (15282): TIM: |-im_engine_impl.cpp:211                  Init                                    |InitSDK|sdk_app_id:1600095370|api_type:FlutterFFI|sdk_version:8.8.7357|sdk_instance_type:2006-Unkown|platform:Android|device_type:ALI-AN00|device_id:57FB707C74-1BB5-75CA-BB6C-975B82A9A6|system_version:15|app_memory_usage:0MB|app_cpu_usage:0%|system_cpu_usage:0%|ip_type:IPv4|network_type:WIFI|network_id:|network_status:network connected||initialize_cost_time:1ms|enable_test_environment:false|enable_ipv6_prior:false|sdk_init_path:/data/user/0/com.yuluo.kissu/files/|log_level:Debug|enable_console_log:true|log_file_path:/storage/emulated/0/Android/data/com.yuluo.kissu/files/log/tencent/imsdk/|ui_platform_string:|ui_platform_number:1|max_retry_count:0|packet_request_timeout:0|enable_quic:false|package_name:|app_name:|ignore_repeat_login:0
I/imsdk   (15282): TIM: |-longconnection.cpp:43                   Open                                    |Open and then first connect
I/imsdk   (15282): TIM: |-channel_switcher.cpp:127                ChooseBestChannel                       |is_initial_choose:true|server_type:Chinese|is_test_environment:false|net_type:WIFI|net_id:1__1|reason:first connect|ip_source:concurrent request|is_local_iplist_prior:true|is_force_use_push:false|is_first_ip_prior:true|is_support_quic:false|is_quic_enabled:false|dual_socket_control_bits:0x0
I/imsdk   (15282): TIM: |-channel_switcher.cpp:889                PrintIPList                             |iplist by anycast:<tcp:221.229.52.176:443,221.229.52.198:443,119.147.110.185:8080,183.60.225.225:14000,42.81.250.66:80,42.81.250.70:443>
I/imsdk   (15282): TIM: |-channel_switcher.cpp:889                PrintIPList                             |iplist by server push:<tcp:221.229.52.217:443,221.229.52.251:14000,14.152.91.153:80,119.147.110.185:443,42.81.250.39:8080,42.81.250.49:14000>
I/imsdk   (15282): TIM: |-channel_switcher.cpp:681                GetIPListFromLocalDNS                   |domain list:<tcp:1600095370l4c.my-imcloud.com:0,login.im.qcloud.com:0,18724l4c.my-cpaas.com:0,login.im.tencent.cn:0>
I/flutter (15282): [16:50:54.613] [I] [TencentIMService] IM正在连接...
I/xlog    (15282): [xlog] xlog version:2.0.1|output_dir:/storage/emulated/0/Android/data/com.yuluo.kissu/files/log/tencent/imsdk/|file_name_prefix:imsdk|is_compress_disabled:false|is_mmap_used:true
[TencentIMService] IM正在连接...
I/imsdk   (15282): TIM: |-im_engine_impl.cpp:373                  SetUserPreference                       |disable_storage:0|enable_signaling:1|api_type:8
I/imsdk   (15282): TIM: |-channel.cpp:59                          Connect                                 |channel connect|channel id:29|server address:221.229.52.176:443(tcp)
I/imsdk   (15282): TIM: |-channel.cpp:300                         OnReadPingCompleted                     |channel ping|channel id:29|client ip:115.227.131.159
I/imsdk   (15282): TIM: |-channel.cpp:338                         NotifyConnectResult                     |channel connect completed|channel id:29|server address:221.229.52.176:443(tcp)|connect cost time:12ms|ping cost time:15ms|error_code:0|error_message:
I/imsdk   (15282): TIM: |-channel_switcher.cpp:448                OnConnectComplete                       |Connect to im server successfully|is_initial_choose:true|server_type:Chinese|is_test_environment:false|net_type:WIFI|net_id:1__1|reason:first connect|ip_source:concurrent request|is_local_iplist_prior:true|is_force_use_push:false|is_first_ip_prior:true|is_support_quic:false|is_quic_enabled:false|dual_socket_control_bits:0x0|iplist by anycast:<tcp:221.229.52.176:443,221.229.52.198:443,119.147.110.185:8080,183.60.225.225:14000,42.81.250.66:80,42.81.250.70:443>|iplist by server push:<tcp:221.229.52.217:443,221.229.52.251:14000,14.152.91.153:80,119.147.110.185:443,42.81.250.39:8080,42.81.250.49:14000>|retry count:0|successful address:221.229.52.176:443(tcp)|choose channel cost time:0ms|connect cost time:12ms|ping cost time:15ms
D/imsdk   (15282): TIM: |-TIMPush-TIMPushProvider                                                         |onConnectSuccess
D/TIMPush-TIMPushProvider(15282): onConnectSuccess
I/flutter (15282): [16:50:54.649] [I] [TencentIMService] IM连接成功
[TencentIMService] IM连接成功
I/flutter (15282): 📊 开始上报事件，数量: 1
I/flutter (15282): 📊 上报数据: {"point_data":[{"event_id":"login_page_event","page_id":"login_page","device_id":"93ac3dd7-36c2-4b8d-94c1-1e4370103ba2","vip_status":0,"bind_status":0,"bind_num":0,"is_check_in":0,"page_enter_time":1773391823,"page_duration":30,"exit_type":4}]}
[DeviceUtil] DeviceUtil not initialized, using fallback deviceId
I/flutter (15282): [16:50:54.941] [W] [DeviceUtil] DeviceUtil not initialized, using fallback deviceId
I/flutter (15282): [16:50:54.942] [I] [OaidUtil] 开始获取设备ID...
I/flutter (15282): [16:50:54.942] [I] [OaidUtil] 返回缓存的设备ID: 93ac3dd7...
2
I/flutter (15282): [LogManager] Error in appender FileAppender: Bad state: StreamSink is bound to a stream
I/flutter (15282): INFO: OAID 已添加到请求头
I/flutter (15282): INFO: ========== Request Headers ==========
I/flutter (15282): INFO: URL: http://dev-love-api.ikissu.cn/upload/point
I/flutter (15282): INFO: Method: POST
I/flutter (15282): INFO: --- Business Headers ---
I/flutter (15282): INFO: token: eyJ0eXAiOiJKV1QiLCJh... (204 chars)
I/flutter (15282): INFO: sign: 52BE9AF416043C493601... (32 chars)
I/flutter (15282): INFO: version: 1.1.9
I/flutter (15282): INFO: channel: kissu_huawei
I/flutter (15282): INFO: pkg: com.yuluo.kissu
[OaidUtil] 开始获取设备ID...
I/flutter (15282): INFO: os: 1
[OaidUtil] 返回缓存的设备ID: 93ac3dd7...
I/flutter (15282): INFO: network-name: wifi_YuluoKeji_5G
I/flutter (15282): INFO: deviceid: android-1773391854942
I/flutter (15282): INFO: mobile-model: HONOR ALI-AN00
I/flutter (15282): INFO: power: 73
I/flutter (15282): INFO: is-open-location: 1
I/flutter (15282): INFO: brand: HONOR
I/flutter (15282): INFO: oaid: 93ac3dd7-36c2-4b8d-94c1-1e4370103ba2
I/flutter (15282): INFO: --- Other Headers ---
I/flutter (15282): INFO: network_debounce: true
I/flutter (15282): INFO: content-type: application/json
I/flutter (15282): INFO: timestamp: 1773391854944
I/flutter (15282): INFO: =====================================
I/flutter (15282): [16:50:54.947] [D] [HTTP] POST http://dev-love-api.ikissu.cn/upload/point
I/flutter (15282): [16:50:54.948] [D] [HTTP] Headers: {network_debounce: true, content-type: application/json, token: ***HIDDEN***, version: 1.1.9, pkg: com.yuluo.kissu, os: 1, deviceid: android-1773391854942, oaid: 93ac3dd7-36c2-4b8d-94c1-1e4370103ba2, mobile-model: HONOR ALI-AN00, brand: HONOR, is-open-location: 1, channel: kissu_huawei, network-name: wifi_YuluoKeji_5G, power: 73, timestamp: 1773391854944, sign: 52BE9AF416043C4936014AFE648137BD}
I/flutter (15282): [16:50:54.948] [D] [HTTP] Request: {
I/flutter (15282):   "point_data": [
I/flutter (15282):     {
I/flutter (15282):       "event_id": "login_page_event",
I/flutter (15282):       "page_id": "login_page",
I/flutter (15282):       "device_id": "93ac3dd7-36c2-4b8d-94c1-1e4370103ba2",
I/flutter (15282):       "vip_status": 0,
I/flutter (15282):       "bind_status": 0,
I/flutter (15282):       "bind_num": 0,
I/flutter (15282):       "is_check_in": 0,
I/flutter (15282):       "page_enter_time": 1773391823,
I/flutter (15282):       "page_duration": 30,
I/flutter (15282):       "exit_type": 4
I/flutter (15282):     }
I/flutter (15282):   ]
I/flutter (15282): }
[HTTP] POST http://dev-love-api.ikissu.cn/upload/point
[HTTP] Headers: {network_debounce: true, content-type: application/json, token: ***HIDDEN***, version: 1.1.9, pkg: com.yuluo.kissu, os: 1, deviceid: android-1773391854942, oaid: 93ac3dd7-36c2-4b8d-94c1-1e4370103ba2, mobile-model: HONOR ALI-AN00, brand: HONOR, is-open-location: 1, channel: kissu_huawei, network-name: wifi_YuluoKeji_5G, power: 73, timestamp: 1773391854944, sign: 52BE9AF416043C4936014AFE648137BD}
[HTTP] Request: {
         "point_data": [
           {
             "event_id": "login_page_event",
             "page_id": "login_page",
             "device_id": "93ac3dd7-36c2-4b8d-94c1-1e4370103ba2",
             "vip_status": 0,
             "bind_status": 0,
             "bind_num": 0,
             "is_check_in": 0,
             "page_enter_time": 1773391823,
             "page_duration": 30,
             "exit_type": 4
           }
         ]
       }
I/flutter (15282): [16:50:55.074] [I] [HTTP] 200 POST http://dev-love-api.ikissu.cn/upload/point (127ms)
I/flutter (15282): [16:50:55.075] [D] [HTTP] Response: {
I/flutter (15282):   "isSuccess": true,
I/flutter (15282):   "code": 0,
I/flutter (15282):   "msg": "",
I/flutter (15282):   "data": null,
I/flutter (15282):   "dataList": null,
[HTTP] 200 POST http://dev-love-api.ikissu.cn/upload/point (127ms)
I/flutter (15282):   "dataJson": {},
I/flutter (15282):   "listJson": null
I/flutter (15282): }
I/flutter (15282): ✅ Request POST /upload/point - 139ms - Status: 200
I/flutter (15282): ✅ 埋点上报成功
I/flutter (15282): 📊 事件上报成功，剩余: 0
[HTTP] Response: {
         "isSuccess": true,
         "code": 0,
         "msg": "",
         "data": null,
         "dataList": null,
         "dataJson": {},
         "listJson": null
       }
[TencentIMService] IM SDK初始化等待完成
[TencentIMService] 开始登录腾讯IM: userID=d88b940a44154acc8ef2cf1d82632d4a
I/flutter (15282): [16:50:55.110] [I] [TencentIMService] IM SDK初始化等待完成
I/flutter (15282): [16:50:55.111] [I] [TencentIMService] 开始登录腾讯IM: userID=d88b940a44154acc8ef2cf1d82632d4a
I/imsdk   (15282): TIM: |-login.cpp:768                           LogRequestBegin                         |Login begin|task_id:6|sdkappid:1600095370|userid:d88b940a44154acc8ef2cf1d82632d4a|account_type:IM|current status:UnLogined
I/flutter (15282): [LogManager] Error in appender FileAppender: Bad state: StreamSink is bound to a stream
I/imsdk   (15282): TIM: |-database.cpp:230                        InternalInit                            |database_path:/data/user/0/com.yuluo.kissu/files/|sdkappid:1600095370|userid:d88b940a44154acc8ef2cf1d82632d4a =>base16_format:6438386239343061343431353461636338656632636631643832363332643461
I/imsdk   (15282): TIM: |-login.cpp:325                           RequestA2D2Online                       |send ticket exchange and online request|task_id:6|userid:d88b940a44154acc8ef2cf1d82632d4a
I/imsdk   (15282): TIM: |-database.cpp:352                        InternalInit                            |init database success|im.db:98304(0.094MB)|msg_0.db:167936(0.160MB)|is_message_index_by_time_exist:true|is_message_index_by_client_time_exist:true
I/imsdk   (15282): TIM: |-login.cpp:414                           HandleA2D2OnlineResponse                |receive ticket exchange and online response|task_id:6|userid:d88b940a44154acc8ef2cf1d82632d4a|tinyid:144115248283192873|encrypt_type:TEA|cost time:63ms
I/imsdk   (15282): TIM: |-login.cpp:477                           HandleOnlineResponse                    |process online response|task_id:6|server_time:1773391853|client_address:115.227.131.159:48062|custom_status:|account_register_time:0|file_download_auth_key size:86|need_synchronize_push_message:false
I/imsdk   (15282): TIM: |-login.cpp:578                           StartHeartbeat                          |start heartbeat with interval 120s
I/imsdk   (15282): TIM: |-login.cpp:780                           LogRequestEnd                           |Login success|task_id:6|error_code:0 error_message:OK|sdkappid:1600095370|userid:d88b940a44154acc8ef2cf1d82632d4a tinyid: 144115248283192873|account_type:IM|commercial_ability_bits:0x0000020C00002000|current status:Logining|time cost:65ms(queue time cost:1ms)
I/imsdk   (15282): TIM: |-user_config.cpp:34                      Init                                    |start load user config data
D/imsdk   (15282): TIM: |-datareport.cpp:63                       StartQualityReport                      |first_report_delay: 60, report_interval: 360
I/imsdk   (15282): TIM: |-server_config.cpp:135                   RequestServerConfig                     |sdk_app_id:1600095370|common_version:1846|specified_version:0
I/flutter (15282): [16:50:55.179] [I] [TencentIMService] IM登录成功: userID=d88b940a44154acc8ef2cf1d82632d4a
I/flutter (15282): [16:50:55.180] [D] [TencentIMService] ✅ 消息监听器已成功设置
I/flutter (15282): [16:50:55.181] [D] [TencentIMService] ✅ 好友关系监听器已成功设置
I/flutter (15282): [16:50:55.182] [I] [AuthService] 腾讯IM登录成功（稳定性将由聊天页面ensureIMLoginStatus保证）
I/imsdk   (15282): TIM: |-sync_server_info_impl_chat.cpp:68       SynchronizeServerInfo                   |synchronize start|task_id:5|invoke_from_login_complete:1
I/flutter (15282): 📊 构建埋点参数，当前虚拟用户ID: 93ac3dd7-36c2-4b8d-94c1-1e4370103ba2
I/imsdk   (15282): TIM: |-user_config.cpp:58                      OnLoadDatabase                          |load user config data finished|error_code:0|error_message:succ|user_config_cache size:6
I/flutter (15282): 📊 记录事件: login_page_phone_input_event, 队列长度: 1
I/flutter (15282): 📊 构建埋点参数，当前虚拟用户ID: 93ac3dd7-36c2-4b8d-94c1-1e4370103ba2
I/flutter (15282): 📊 记录事件: login_page_code_input_event, 队列长度: 2
I/flutter (15282): 📊 构建埋点参数，当前虚拟用户ID: 93ac3dd7-36c2-4b8d-94c1-1e4370103ba2
I/flutter (15282): 📊 记录事件: login_page_button_event, 队列长度: 3
I/flutter (15282): [LogManager] Error in appender FileAppender: Bad state: StreamSink is bound to a stream
[TencentIMService] IM登录成功: userID=d88b940a44154acc8ef2cf1d82632d4a
[TencentIMService] ✅ 消息监听器已成功设置
I/imsdk   (15282): TIM: |-conversation_list_synchronizer.cpp:144  RequestSynchronize                      |normal_conversation_ts:1773391736ms|normal_conversation_index:0|pin_conversation_ts:0ms|pin_conversation_index:0
[TencentIMService] ✅ 好友关系监听器已成功设置
[AuthService] 腾讯IM登录成功（稳定性将由聊天页面ensureIMLoginStatus保证）
I/imsdk   (15282): TIM: |-im_relationship_impl.cpp:132            SetSelfInfo                             |info_list:<Tag_Profile_IM_Image:https://kissustatic.yuluojishu.com/uploads/2025/08/21/c995803f84b964e9b191b1f6a7422a2a.png><Tag_Profile_IM_Nick:kissu6464>
I/flutter (15282): [16:50:55.192] [D] [TencentIMService] IM凭证已保存供原生层使用
[TencentIMService] IM凭证已保存供原生层使用
I/imsdk   (15282): TIM: |-server_config.cpp:228                   ProcessCommercialAbilityPushed          |commercial_ability_bits:0x0000020C00002000
I/imsdk   (15282): TIM: |-server_config.cpp:189                   HandleServerConfigResponse              |local config is already the newest
I/flutter (15282): [16:50:55.246] [D] [TencentIMService] IM用户资料更新成功
I/flutter (15282): [16:50:55.246] [D] [TencentIMService] 开始注册推送服务（sdkAppId: 1600095370）
I/flutter (15282): [16:50:55.247] [D] [TencentIMService] 🔍 推送调试信息:
[TencentIMService] IM用户资料更新成功
I/flutter (15282): [16:50:55.248] [D] [TencentIMService]   - 当前登录用户ID (SDK): Instance of 'V2TimValueCallback<String>'
I/flutter (15282): [16:50:55.248] [D] [TencentIMService]   - 当前登录用户ID (缓存): d88b940a44154acc8ef2cf1d82632d4a
[TencentIMService] 开始注册推送服务（sdkAppId: 1600095370）
[TencentIMService] 🔍 推送调试信息:
[TencentIMService]   - 当前登录用户ID (SDK): Instance of 'V2TimValueCallback<String>'
[TencentIMService]   - 当前登录用户ID (缓存): d88b940a44154acc8ef2cf1d82632d4a
[TencentIMService]   - 设备厂商: brand=HONOR, manufacturer=HONOR, model=ALI-AN00, SDK=35, release=15
I/flutter (15282): [16:50:55.257] [D] [TencentIMService]   - 设备厂商: brand=HONOR, manufacturer=HONOR, model=ALI-AN00, SDK=35, release=15
D/imsdk   (15282): TIM: |-flutter_imsdk                                                                   |TIMPush TencentCloudChatPushFlutter registerPush start
D/imsdk   (15282): TIM: |-flutter_imsdk                                                                   |TIMPush TencentCloudChatPushFlutter registerPush checked login status complete
D/imsdk   (15282): TIM: |-flutter_imsdk                                                                   |TIMPush TencentCloudChatPushFlutter registerPush registerOnNotificationClickedEvent completed
D/imsdk   (15282): TIM: |-TIMPush-TIMPushConfig                                                           |setRunningPlatform 4
D/TIMPush-TIMPushConfig(15282): setRunningPlatform 4
D/imsdk   (15282): TIM: |-TIMPush-TIMPushManagerImpl                                                      |register push mDeviceInfo = HONOR_HONOR_ALI-AN00_2006
D/TIMPush-TIMPushManagerImpl(15282): register push mDeviceInfo = HONOR_HONOR_ALI-AN00_2006
D/imsdk   (15282): TIM: |-TIMPush-TIMPushManagerImpl                                                      |push sdk version:8.8.7357, type:1, platform:4, scene:4
D/TIMPush-TIMPushManagerImpl(15282): push sdk version:8.8.7357, type:1, platform:4, scene:4
W/imsdk   (15282): TIM: |-NetworkInfoCenter                                                               |NetworkInfoCenter has init
D/SystemUtil(15282): SDK Init Path: /data/user/0/com.yuluo.kissu/files
D/SystemUtil(15282): SDK LOG Path: /sdcard/Android/data/com.yuluo.kissu/files/log/tencent/imsdk/
I/imsdk   (15282): TIM: |-system_config.cpp:1016                  EnableAPITypeBits                       |api_type:Java
D/imsdk   (15282): TIM: |-TIMPush-TIMPushManagerImpl                                                      |register with loginUserID: d88b940a44154acc8ef2cf1d82632d4a
D/imsdk   (15282): TIM: |-TIMPush-TIMPushProvider                                                         |already login
D/imsdk   (15282): TIM: |-TIMPush-TIMPushManagerImpl                                                      |systemLanguage: zh_CN_Hans
I/imsdk   (15282): TIM: |-im_offlinepush_impl.cpp:33              SetOfflinePushInfo                      |offline_push_plugin_version:8.8.7357|notification_bar_state:1|system_language:zh_CN_Hans
I/imsdk   (15282): TIM: |-TIMPush-TIMPushProvider                                                         |reportTIMPushInfo success
I/imsdk   (15282): TIM: |-TIMPush-TIMPushProvider                                                         |reportTIMPushComponentUsage success
D/imsdk   (15282): TIM: |-TIMPush-TokenLogic                                                              |requestPushToken channelId = 2006, channelType = 2
D/ServiceManager(15282): callService : TIMHonorPushPlugin method : registerTIMHonorPush
D/imsdk   (15282): TIM: |-TIMPush-TIMPushHonorService                                                     |onCall method = registerTIMHonorPush
E/imsdk   (15282): TIM: |-TIMPush-TIMPushManagerImpl                                                      |Note: registrationID is d88b940a44154acc8ef2cf1d82632d4a
I/imsdk   (15282): TIM: |-TIMPush-TIMPushProvider                                                         |reportPushSDKEvent success
D/imsdk   (15282): TIM: |-TIMPush-StatisticDataStorage                                                    |report size:0
D/imsdk   (15282): TIM: |-TIMPush-TIMPushManagerImpl                                                      |queryOfflineEventData is null
I/HonorApiManager(15282): sendRequest start
I/HonorApiManager(15282): connect and send request, create new connection manager.
I/PushConnectionClient(15282):  ==== PUSHSDK VERSION 70061302 ====
I/PushConnectionClient(15282): enter connect, connection Status: 1
I/PushConnectionClient(15282): enter bindCoreService.
I/AIDLSrvConnection(15282): enter onServiceConnected.
I/HonorApiManager(15282): onConnected
I/IpcTransport(15282): start transport parse. up_msg_request_push_token
I/IpcTransport(15282): end transport parse.
I/IPCCallback(15282): onResult parse start.
I/HonorApiManager(15282): sendResolveResult start
I/PushConnectionClient(15282): enter disconnect, connection Status: 3
I/AIDLSrvConnection(15282): trying to unbind service from com.hihonor.push.sdk.f0@3a9a6f3
I/IPCCallback(15282): onResult parse end.
I/imsdk   (15282): TIM: |-TIMPush-TIMPushHonorDataAdapter                                                 |Honor get pushToken onSuccess:BAEAAAAAB.jq8ogAcDK33QeA6TZHoE3BrKP2QGbNB6mCVxwxgnp9v005mrESZFkXpGbCPPy3IJeuSHraRZwphxYlH8GkaUhDMMrPNkxrx8VUmPJ1J4js4eWwf-w0xeGk
D/imsdk   (15282): TIM: |-TIMPush-TokenRequester                                                          |register success: 2006
D/imsdk   (15282): TIM: |-TIMPush-TokenLogic                                                              |request success, channelId = 2006,token =BAEAAAAAB.jq8ogAcDK33QeA6TZHoE3BrKP2QGbNB6mCVxwxgnp9v005mrESZFkXpGbCPPy3IJeuSHraRZwphxYlH8GkaUhDMMrPNkxrx8VUmPJ1J4js4eWwf-w0xeGk
I/imsdk   (15282): TIM: |-im_conversation_impl.cpp:149            GetUnreadMessageCount                   |Get unread message count by filter:|conversation_type:unknown|last_sequence:0|count:0
D/imsdk   (15282): TIM: |-TIMPush-TIMPushProvider                                                         |setOfflinePushConfig businessID = 45164 pushToken = BAEAAAAAB.jq8ogAcDK33QeA6TZHoE3BrKP2QGbNB6mCVxwxgnp9v005mrESZFkXpGbCPPy3IJeuSHraRZwphxYlH8GkaUhDMMrPNkxrx8VUmPJ1J4js4eWwf-w0xeGk
I/imsdk   (15282): TIM: |-im_offlinepush_impl.cpp:45              SetOfflinePushToken                     |business_id:45164|device_brand:2006|device_token size:128|token_type:default|live_activity_id:
I/imsdk   (15282): TIM: |-TIMPush-TIMPushProvider                                                         |reportPushSDKEvent success
I/imsdk   (15282): TIM: |-conversation_list_synchronizer.cpp:200  HandleSynchronizeResponse               |normal_conversation_ts:1773391853ms|normal_conversation_index:0|pin_conversation_ts:1773391853 ms|pin_conversation_index:0|conversation_list.size:2|is_synchronize_complete:true
I/imsdk   (15282): TIM: |-conversation_list_synchronizer.cpp:490  OnGetExistenceOfRemoteConversation      |conversation changed|conversation_key:c2c_administrator|unread_message_count:0|active_time:25|message_receive_option:auto receive|c2c_receipt_timestamp:0|c2c_unread_info_sequence:0|last_message:<sender_user_id:d88b940a44154acc8ef2cf1d82632d4a|client_time:1773391816|server_time:1773391817|sequence:4173484694|random:2692222729|message_status:success>
I/imsdk   (15282): TIM: |-conversation_list_synchronizer.cpp:490  OnGetExistenceOfRemoteConversation      |conversation changed|conversation_key:c2c_6c7117ce6670410f901e231228d5cfad|unread_message_count:104|active_time:26|message_receive_option:auto receive|c2c_receipt_timestamp:1773380122|c2c_unread_info_sequence:0|last_message:<sender_user_id:6c7117ce6670410f901e231228d5cfad|client_time:1773391831|server_time:1773391831|sequence:1227783199|random:105270|message_status:success>
I/imsdk   (15282): TIM: |-conversation_list_synchronizer.cpp:563  OnGetPinConversationList                |local pin conversations count: 0|remote pin conversations count:0
I/imsdk   (15282): TIM: |-sync_server_info_impl_chat.cpp:91       OnSynchronizeConversationList           |synchronize conversation complete|task_id:5|error_code:0|error_message:Success
I/imsdk   (15282): TIM: |-group_info_logic.cpp:105                GetJoinedGroupList                      |GetJoinedGroupListFromServer
E/imsdk   (15282): TIM: |-group_list_fetcher.cpp:85               HandleJoinedGroupListResponse           |error_code:11000|error_message:community group not open|offset:0|count:500
E/imsdk   (15282): TIM: |-group_list_provider.cpp:58              HandleJoinedCommunityGroupList          |error_code:11000|error_message:community group not open
I/imsdk   (15282): TIM: |-group_info_logic.cpp:144                HandleJoinedGroupListFromServer         |group count:0
I/imsdk   (15282): TIM: |-sync_server_info_impl_chat.cpp:130      OnGetJoinedGroupList                    |synchronize server, joined group list is empty|task_id:5
I/imsdk   (15282): TIM: |-receive_message_option.cpp:228          HandleGetMessageReceiveOptionResponse   |local user receive message options is the latest
I/flutter (15282): [16:50:55.395] [D] [App] VIP推广标识已保存: false
[App] VIP推广标识已保存: false
I/flutter (15282): [16:50:55.396] [I] [AppUsageAutoReportService] 🔄 重启App使用记录自动上报服务（强制全量上报）
I/flutter (15282): [16:50:55.396] [I] [Login] ✅ App使用记录自动上报服务已重启（登录后，强制全量上报）
[AppUsageAutoReportService] 🔄 重启App使用记录自动上报服务（强制全量上报）
[Login] ✅ App使用记录自动上报服务已重启（登录后，强制全量上报）
I/flutter (15282): [16:50:55.397] [D] [PermissionUpload] 🔄 权限上传会话标记已重置（重新登录）
I/flutter (15282): [16:50:55.398] [D] [LoginNavLock] 🔄 登录页导航锁已重置
[PermissionUpload] 🔄 权限上传会话标记已重置（重新登录）
[LoginNavLock] 🔄 登录页导航锁已重置
[GETX] GOING TO ROUTE /kisssu_app/home
[GETX] REMOVING ROUTE /kisssu_app/login
I/flutter (15282): [LogManager] Error in appender FileAppender: Bad state: StreamSink is bound to a stream
[GETX] Instance "HomeController" has been created
[App] 🏠 HomeController 初始化 - 绑定弹窗标志位状态: false
I/flutter (15282): [16:50:55.411] [D] [App] 🏠 HomeController 初始化 - 绑定弹窗标志位状态: false
[App] ✅ 从本地加载用户头像: https://kissustatic.yuluojishu.com/uploads/2025/08/21/c995803f84b964e9b191b1f6a7422a2a.png
I/flutter (15282): [16:50:55.412] [D] [App] ✅ 从本地加载用户头像: https://kissustatic.yuluojishu.com/uploads/2025/08/21/c995803f84b964e9b191b1f6a7422a2a.png
I/flutter (15282): [16:50:55.412] [D] [App] ✅ 从halfUserInfo加载伴侣头像: https://kissustatic.yuluojishu.com/uploads/2026/03/11/5f960f38fcef68037abd4cebddaa9cd8.webp
I/flutter (15282): [16:50:55.413] [D] [App] 🏠 加载恋爱天数: 0天
I/flutter (15282): [16:50:55.414] [W] [App] 🔄 首页：静默刷新用户信息
[App] ✅ 从halfUserInfo加载伴侣头像: https://kissustatic.yuluojishu.com/uploads/2026/03/11/5f960f38fcef68037abd4cebddaa9cd8.webp
I/flutter (15282): [16:50:55.414] [D] [App] 🔄 开始从服务器刷新用户信息...
[App] 🏠 加载恋爱天数: 0天
I/flutter (15282): [16:50:55.415] [D] [App] 🎯 使用自适应居中偏移创建ScrollController: 屏幕宽度=369.2307692307692, 动态背景宽度=1130.5418719211823, 默认偏移=380.6555513452065
I/flutter (15282): [16:50:55.415] [W] [App] ! 没有预设位置，使用默认居中偏移
I/flutter (15282): [16:50:55.415] [D] [App] 🏠 开始加载首页数据...
I/flutter (15282): INFO: 🏠 开始请求首页数据...
I/flutter (15282): [16:50:55.416] [D] [App] 📱 首页应用生命周期监听已设置
[App] 🔄 首页：静默刷新用户信息
[App] 🔄 开始从服务器刷新用户信息...
[App] 🎯 使用自适应居中偏移创建ScrollController: 屏幕宽度=369.2307692307692, 动态背景宽度=1130.5418719211823, 默认偏移=380.6555513452065
[App] ⚠️ 没有预设位置，使用默认居中偏移
[App] 🏠 开始加载首页数据...
[App] 📱 首页应用生命周期监听已设置
[GETX] Instance "HomeController" has been initialized
I/imsdk   (15282): TIM: |-offline_push_manager.cpp:125            HandleSetTokenResponse                  |Set offline push token successfully|business_id:45164|device_brand:2006|device_token size:128|token_type:default|live_activity_id:
I/flutter (15282): [16:50:55.518] [D] [App] 🔄 开始检查版本更新
I/flutter (15282): [16:50:55.518] [D] [App] 🚀 启动弹窗流程...
I/flutter (15282): [16:50:55.518] [D] [App] 🔍 检查绑定弹窗条件: isBound=true, hasShown=false
I/flutter (15282): [16:50:55.518] [D] [App] 🔗 用户已绑定，不显示绑定弹窗
I/flutter (15282): [16:50:55.519] [I] [AppUsageAutoReportService] 🚀 开始启动App使用记录自动上报服务
I/flutter (15282): [16:50:55.519] [W] [App] ✅ App使用记录自动上报服务已启动
I/flutter (15282): [16:50:55.519] [D] [HomeController] 📤 触发权限状态上传
I/flutter (15282): [16:50:55.520] [D] [App] ✅ 头像预加载成功: https://kissustatic.yuluojishu.com/uploads/2026/03/11/5f960f38fcef68037abd4cebddaa9cd8.webp
I/flutter (15282): [LogManager] Error in appender FileAppender: Bad state: StreamSink is bound to a stream
I/flutter (15282): [16:50:55.521] [D] [App] 加载视图模式: 屏视图
2
I/flutter (15282): [LogManager] Error in appender FileAppender: Bad state: StreamSink is bound to a stream
I/flutter (15282): [16:50:55.522] [D] [PermissionUpload] 📤 开始上传权限状态...
D/imsdk   (15282): TIM: |-TIMPush-TIMPushProvider                                                         |setOfflinePushToken success
[App] 🔄 开始检查版本更新
[App] 🚀 启动弹窗流程...
[App] 🔍 检查绑定弹窗条件: isBound=true, hasShown=false
[App] 🔗 用户已绑定，不显示绑定弹窗
[AppUsageAutoReportService] 🚀 开始启动App使用记录自动上报服务
[App] ✅ App使用记录自动上报服务已启动
[HomeController] 📤 触发权限状态上传
[App] ✅ 头像预加载成功: https://kissustatic.yuluojishu.com/uploads/2026/03/11/5f960f38fcef68037abd4cebddaa9cd8.webp
[App] 加载视图模式: 屏视图
[PermissionUpload] 📤 开始上传权限状态...
I/imsdk   (15282): TIM: |-c2c_message_synchronizer.cpp:217        ProcessUnreadMessageInfo                |user_id:6c7117ce6670410f901e231228d5cfad|message_read_timestamp:1773323156|unread_message_count:105|last_update_sequence:3801608631103783332|abstract_message_count:0|concrete_message_count:2
I/imsdk   (15282): TIM: |-conversation_unread_info.cpp:286        OnProcessC2CUnreadInfo                  |conversation_key:c2c_6c7117ce6670410f901e231228d5cfad|unread_message_count:105|message_read_timestamp:1773323156|c2c_unread_info_sequence:3801608631103783332
I/imsdk   (15282): TIM: |-sync_server_info_impl_chat.cpp:331      OnProcessC2CUnreadInfoCompleted         |synchronize c2c unread info complete|task_id:5
I/imsdk   (15282): TIM: |-sync_server_info_impl_chat.cpp:369      NotifySynchronizeServerInfoResult       |synchronize server complete|task_id:5
I/imsdk   (15282): TIM: |-message_dispatcher.cpp:315              HandleNewMessage                        |message_source:c2c synchronize|message:
I/imsdk   (15282): message_type:c2c|message_sub_type:0x6
I/imsdk   (15282): sender_user_id:6c7117ce6670410f901e231228d5cfad|receiver_user_id:d88b940a44154acc8ef2cf1d82632d4a|receive_time:1773391853354|excluded_from_muting:true
I/imsdk   (15282): client_time:1773391831|server_time:1773391831|sequence:1227783199|random:105270
I/imsdk   (15282): message_status:success|IsOnlineOnly:false|platform:Other
I/imsdk   (15282): message_elements:
I/imsdk   (15282): [custom] data size:470|description size:0
I/imsdk   (15282): 
2
I/flutter (15282): [16:50:55.535] [D] [App] 💬 IM 未读数更新: 104
I/flutter (15282): [16:50:55.536] [D] [App] 💬 IM 未读数更新: 104
I/flutter (15282): [16:50:55.536] [D] [TencentIMService] ✅ 同步未读数成功: 104
3
[App] 💬 IM 未读数更新: 104
[TencentIMService] ✅ 同步未读数成功: 104
I/flutter (15282): [16:50:55.542] [W] [DeviceUtil] DeviceUtil not initialized, using fallback deviceId
I/flutter (15282): [16:50:55.543] [I] [OaidUtil] 开始获取设备ID...
I/flutter (15282): [16:50:55.543] [I] [OaidUtil] 返回缓存的设备ID: 93ac3dd7...
2
I/flutter (15282): [LogManager] Error in appender FileAppender: Bad state: StreamSink is bound to a stream
I/flutter (15282): INFO: OAID 已添加到请求头
I/flutter (15282): INFO: ========== Request Headers ==========
I/flutter (15282): INFO: URL: http://dev-love-api.ikissu.cn/sync/auth/app
I/flutter (15282): INFO: Method: POST
I/flutter (15282): INFO: --- Business Headers ---
I/flutter (15282): INFO: token: eyJ0eXAiOiJKV1QiLCJh... (204 chars)
I/flutter (15282): INFO: sign: 2FEE016E5C7DF34732E6... (32 chars)
I/flutter (15282): INFO: version: 1.1.9
I/flutter (15282): INFO: channel: kissu_huawei
I/flutter (15282): INFO: pkg: com.yuluo.kissu
I/flutter (15282): INFO: os: 1
I/flutter (15282): INFO: network-name: wifi_YuluoKeji_5G
I/flutter (15282): INFO: deviceid: android-1773391855543
I/flutter (15282): INFO: mobile-model: HONOR ALI-AN00
I/flutter (15282): INFO: power: 73
[DeviceUtil] DeviceUtil not initialized, using fallback deviceId
I/flutter (15282): INFO: is-open-location: 1
I/flutter (15282): INFO: brand: HONOR
I/flutter (15282): INFO: oaid: 93ac3dd7-36c2-4b8d-94c1-1e4370103ba2
I/flutter (15282): INFO: --- Other Headers ---
I/flutter (15282): INFO: network_debounce: true
[OaidUtil] 开始获取设备ID...
I/flutter (15282): INFO: content-type: application/json
I/flutter (15282): INFO: timestamp: 1773391855544
I/flutter (15282): INFO: =====================================
[OaidUtil] 返回缓存的设备ID: 93ac3dd7...
[DeviceUtil] DeviceUtil not initialized, using fallback deviceId
[OaidUtil] 开始获取设备ID...
I/flutter (15282): [16:50:55.547] [W] [DeviceUtil] DeviceUtil not initialized, using fallback deviceId
I/flutter (15282): [16:50:55.547] [I] [OaidUtil] 开始获取设备ID...
[OaidUtil] 返回缓存的设备ID: 93ac3dd7...
I/flutter (15282): [16:50:55.547] [I] [OaidUtil] 返回缓存的设备ID: 93ac3dd7...
3
I/flutter (15282): [LogManager] Error in appender FileAppender: Bad state: StreamSink is bound to a stream
I/flutter (15282): INFO: OAID 已添加到请求头
I/flutter (15282): INFO: ========== Request Headers ==========
I/flutter (15282): INFO: URL: http://dev-love-api.ikissu.cn/get/user
I/flutter (15282): INFO: Method: GET
I/flutter (15282): INFO: --- Business Headers ---
I/flutter (15282): INFO: token: eyJ0eXAiOiJKV1QiLCJh... (204 chars)
I/flutter (15282): INFO: sign: DBDB12A9EBB7BE0CBA74... (32 chars)
I/flutter (15282): INFO: version: 1.1.9
I/flutter (15282): INFO: channel: kissu_huawei
I/flutter (15282): INFO: pkg: com.yuluo.kissu
I/flutter (15282): INFO: os: 1
I/flutter (15282): INFO: network-name: wifi_YuluoKeji_5G
I/flutter (15282): INFO: deviceid: android-1773391855547
I/flutter (15282): INFO: mobile-model: HONOR ALI-AN00
I/flutter (15282): INFO: power: 73
I/flutter (15282): INFO: is-open-location: 1
I/flutter (15282): INFO: brand: HONOR
I/flutter (15282): INFO: oaid: 93ac3dd7-36c2-4b8d-94c1-1e4370103ba2
I/flutter (15282): INFO: --- Other Headers ---
I/flutter (15282): INFO: network_debounce: true
I/flutter (15282): INFO: timestamp: 1773391855548
I/flutter (15282): INFO: =====================================
I/flutter (15282): [16:50:55.551] [W] [DeviceUtil] DeviceUtil not initialized, using fallback deviceId
I/flutter (15282): [16:50:55.551] [I] [OaidUtil] 开始获取设备ID...
I/flutter (15282): [16:50:55.552] [I] [OaidUtil] 返回缓存的设备ID: 93ac3dd7...
3
I/flutter (15282): [LogManager] Error in appender FileAppender: Bad state: StreamSink is bound to a stream
I/flutter (15282): INFO: OAID 已添加到请求头
I/flutter (15282): INFO: ========== Request Headers ==========
I/flutter (15282): INFO: URL: http://dev-love-api.ikissu.cn/index
I/flutter (15282): INFO: Method: GET
I/flutter (15282): INFO: --- Business Headers ---
I/flutter (15282): INFO: token: eyJ0eXAiOiJKV1QiLCJh... (204 chars)
I/flutter (15282): INFO: sign: 17C8EAB3EE113418300A... (32 chars)
I/flutter (15282): INFO: version: 1.1.9
I/flutter (15282): INFO: channel: kissu_huawei
I/flutter (15282): INFO: pkg: com.yuluo.kissu
I/flutter (15282): INFO: os: 1
I/flutter (15282): INFO: network-name: wifi_YuluoKeji_5G
I/flutter (15282): INFO: deviceid: android-1773391855551
I/flutter (15282): INFO: mobile-model: HONOR ALI-AN00
[DeviceUtil] DeviceUtil not initialized, using fallback deviceId
I/flutter (15282): INFO: power: 73
I/flutter (15282): INFO: is-open-location: 1
I/flutter (15282): INFO: brand: HONOR
I/flutter (15282): INFO: oaid: 93ac3dd7-36c2-4b8d-94c1-1e4370103ba2
I/flutter (15282): INFO: --- Other Headers ---
I/flutter (15282): INFO: cache_control: noCache
I/flutter (15282): INFO: timestamp: 1773391855553
I/flutter (15282): INFO: =====================================
[OaidUtil] 开始获取设备ID...
[OaidUtil] 返回缓存的设备ID: 93ac3dd7...
I/flutter (15282): [16:50:55.558] [D] [TencentIMService] 📨 收到新消息
[TencentIMService] 📨 收到新消息
I/flutter (15282): [16:50:55.558] [D] [TencentIMService] 消息基本信息 - ID: 144115248282199667-1773391831-105270, 发送者: 6c7117ce6670410f901e231228d5cfad, 类型: 2
[TencentIMService] 消息基本信息 - ID: 144115248282199667-1773391831-105270, 发送者: 6c7117ce6670410f901e231228d5cfad, 类型: 2
I/flutter (15282): [16:50:55.558] [D] [TencentIMService] 🎯 自定义消息 - data: {"msg_type":"sensitive","icon":"https:\/\/kissustatic.yuluojishu.com\/uploads\/2026\/03\/13\/76e448eecd90cd04e47a89180125f375.png","vip_icon":"https:\/\/kissustatic.yuluojishu.com\/uploads\/2026\/03\/13\/76e448eecd90cd04e47a89180125f375.png","is_vip":0,"content":"对方锁定了你的手机","im_vip_content":"对方锁定了你的手机","jump_page":"","message_type":"text","im_font_color":[{"change_text":"锁定了你的手机","color":"#4E90FF"}],"default_ext":{}}, desc: , extension: 
I/flutter (15282): [16:50:55.558] [D] [TencentIMService] 处理关系消息 - msg_type: sensitive
I/flutter (15282): [16:50:55.559] [D] [TencentIMService] 未知的消息类型: sensitive
[TencentIMService] 处理关系消息 - msg_type: sensitive
[TencentIMService] 未知的消息类型: sensitive
[AppUsageAutoReportService] ⏳ 等待 3000ms 后启动上报服务（确保权限已生效，系统数据已准备好）
I/flutter (15282): [16:50:55.559] [I] [AppUsageAutoReportService] ⏳ 等待 3000ms 后启动上报服务（确保权限已生效，系统数据已准备好）
I/flutter (15282): [LogManager] Error in appender FileAppender: Bad state: StreamSink is bound to a stream
[TencentIMService] 🎯 自定义消息 - data: {"msg_type":"sensitive","icon":"https:\/\/kissustatic.yuluojishu.com\/uploads\/2026\/03\/13\/76e448eecd90cd04e47a89180125f375.png","vip_icon":"https:\/\/kissustatic.yuluojishu.com\/uploads\/2026\/03\/13\/76e448eecd90cd04e47a89180125f375.png","is_vip":0,"content":"对方锁定了你的手机","im_vip_content":"对方锁定了你的手机","jump_page":"","message_type":"text","im_font_color":[{"change_text":"锁定了你的手机","color":"#4E90FF"}],"default_ext":{}}, desc: , extension:
I/flutter (15282): [16:50:55.704] [D] [HTTP] POST http://dev-love-api.ikissu.cn/sync/auth/app
I/flutter (15282): [16:50:55.705] [D] [HTTP] Headers: {network_debounce: true, content-type: application/json, token: ***HIDDEN***, version: 1.1.9, pkg: com.yuluo.kissu, os: 1, deviceid: android-1773391855543, oaid: 93ac3dd7-36c2-4b8d-94c1-1e4370103ba2, mobile-model: HONOR ALI-AN00, brand: HONOR, is-open-location: 1, channel: kissu_huawei, network-name: wifi_YuluoKeji_5G, power: 73, timestamp: 1773391855544, sign: 2FEE016E5C7DF34732E6B6F0D6E4516E}
I/flutter (15282): [16:50:55.705] [D] [HTTP] Request: {}
I/flutter (15282): [16:50:55.705] [D] [HTTP] GET http://dev-love-api.ikissu.cn/get/user
I/flutter (15282): [16:50:55.705] [D] [HTTP] Headers: {network_debounce: true, token: ***HIDDEN***, version: 1.1.9, pkg: com.yuluo.kissu, os: 1, deviceid: android-1773391855547, oaid: 93ac3dd7-36c2-4b8d-94c1-1e4370103ba2, mobile-model: HONOR ALI-AN00, brand: HONOR, is-open-location: 1, channel: kissu_huawei, network-name: wifi_YuluoKeji_5G, power: 73, timestamp: 1773391855548, sign: DBDB12A9EBB7BE0CBA7403AEA65BE373}
I/flutter (15282): [16:50:55.706] [D] [HTTP] GET http://dev-love-api.ikissu.cn/index
I/flutter (15282): [16:50:55.706] [D] [HTTP] Headers: {cache_control: noCache, token: ***HIDDEN***, version: 1.1.9, pkg: com.yuluo.kissu, os: 1, deviceid: android-1773391855551, oaid: 93ac3dd7-36c2-4b8d-94c1-1e4370103ba2, mobile-model: HONOR ALI-AN00, brand: HONOR, is-open-location: 1, channel: kissu_huawei, network-name: wifi_YuluoKeji_5G, power: 73, timestamp: 1773391855553, sign: 17C8EAB3EE113418300A87824C79E6A1}
[HTTP] POST http://dev-love-api.ikissu.cn/sync/auth/app
[HTTP] Request: {}
[HTTP] GET http://dev-love-api.ikissu.cn/get/user
D/imsdk   (15282): TIM: |-TIMPush-TIMPushProvider                                                         |synchrorized message：V2TIMMessage--->msgID:144115248282199667-1773391831-105270, timestamp:1773391831, sender:6c7117ce6670410f901e231228d5cfad, nickname:落落, faceUrl:https://kissustatic.yuluojishu.com/uploads/2026/03/11/5f960f38fcef68037abd4cebddaa9cd8.webp, friendRemark:, nameCard:, groupID:null, userID:6c7117ce6670410f901e231228d5cfad, seq:1227783199, random:105270, status:2, isSelf:false, isRead:false, isPeerRead:true, needReadReceipt:false, priority:0, groupAtUserList:[], elemType:2, localCustomData:, localCustomInt:0, cloudCustomData:, isExcludeFromUnreadCount:false, isExcludeFromLastMessage:false, offlinePushInfo:com.tencent.imsdk.v2.V2TIMOfflinePushInfo@938a5ae, isBroadcastMessage:false, supportMessageExtension:false, hasRiskContent:false, elemDesc:V2TIMCustomElem--->data2String:{"msg_type":"sensitive","icon":"https:\/\/kissustatic.yuluojishu.com\/uploads\/2026\/03\/13\/76e448eecd90cd04e47a89180125f375.png","v
[HTTP] GET http://dev-love-api.ikissu.cn/index
D/imsdk   (15282): TIM: |-flutter_imsdk                                                                   |TIMPush TencentCloudChatPushFlutter registerPush completed
I/flutter (15282): [16:50:55.718] [D] [TencentIMService] ✅ 推送服务注册完成
I/flutter (15282): [16:50:55.719] [D] [TencentIMService] 📊 推送注册结果类型: TencentCloudChatPushResult<dynamic>
I/flutter (15282): [16:50:55.719] [D] [TencentIMService] 📊 推送注册结果详情: Instance of 'TencentCloudChatPushResult<dynamic>'
I/flutter (15282): [16:50:55.719] [D] [TencentIMService] ✅ 推送注册成功！结果: Instance of 'TencentCloudChatPushResult<dynamic>'
[TencentIMService] ✅ 推送服务注册完成
[TencentIMService] 📊 推送注册结果类型: TencentCloudChatPushResult<dynamic>
[TencentIMService] 📊 推送注册结果详情: Instance of 'TencentCloudChatPushResult<dynamic>'
[TencentIMService] ✅ 推送注册成功！结果: Instance of 'TencentCloudChatPushResult<dynamic>'
[HTTP] Headers: {network_debounce: true, content-type: application/json, token: ***HIDDEN***, version: 1.1.9, pkg: com.yuluo.kissu, os: 1, deviceid: android-1773391855543, oaid: 93ac3dd7-36c2-4b8d-94c1-1e4370103ba2, mobile-model: HONOR ALI-AN00, brand: HONOR, is-open-location: 1, channel: kissu_huawei, network-name: wifi_YuluoKeji_5G, power: 73, timestamp: 1773391855544, sign: 2FEE016E5C7DF34732E6B6F0D6E4516E}
[HTTP] Headers: {network_debounce: true, token: ***HIDDEN***, version: 1.1.9, pkg: com.yuluo.kissu, os: 1, deviceid: android-1773391855547, oaid: 93ac3dd7-36c2-4b8d-94c1-1e4370103ba2, mobile-model: HONOR ALI-AN00, brand: HONOR, is-open-location: 1, channel: kissu_huawei, network-name: wifi_YuluoKeji_5G, power: 73, timestamp: 1773391855548, sign: DBDB12A9EBB7BE0CBA7403AEA65BE373}
[HTTP] Headers: {cache_control: noCache, token: ***HIDDEN***, version: 1.1.9, pkg: com.yuluo.kissu, os: 1, deviceid: android-1773391855551, oaid: 93ac3dd7-36c2-4b8d-94c1-1e4370103ba2, mobile-model: HONOR ALI-AN00, brand: HONOR, is-open-location: 1, channel: kissu_huawei, network-name: wifi_YuluoKeji_5G, power: 73, timestamp: 1773391855553, sign: 17C8EAB3EE113418300A87824C79E6A1}
I/flutter (15282): [16:50:55.742] [D] [TencentIMService] 已禁用前台通知显示
[TencentIMService] 已禁用前台通知显示
D/imsdk   (15282): TIM: |-TIMPush-TIMPushManagerImpl                                                      |disablePostNotificationInForeground disable = true
D/imsdk   (15282): TIM: |-TIMPush-TIMPushConfig                                                           |enablePostNotificationInForeground = 0
D/UTILS   (15282): Usage permission is granted
D/imsdk   (15282): TIM: |-TIMPush-TIMPushManagerImpl                                                      |getRegistrationID = d88b940a44154acc8ef2cf1d82632d4a
I/TencentCloudChatPushPlugin(15282): getRegistrationID, RegistrationID: d88b940a44154acc8ef2cf1d82632d4a
I/flutter (15282): [16:50:55.752] [D] [TencentIMService] 📱 推送设备ID (RegistrationID): Instance of 'TencentCloudChatPushResult<dynamic>'
I/flutter (15282): [16:50:55.752] [D] [TencentIMService] 🔧 请按以下步骤检查配置：
I/flutter (15282): [16:50:55.752] [D] [TencentIMService] 1. ✅ timpush-configs.json 已放置在 android/app/src/main/assets/ 目录
[TencentIMService] 📱 推送设备ID (RegistrationID): Instance of 'TencentCloudChatPushResult<dynamic>'
I/flutter (15282): [16:50:55.753] [D] [TencentIMService] 2. ✅ Application类已继承TencentCloudChatPushApplication
I/flutter (15282): [16:50:55.753] [D] [TencentIMService] 3. ✅ 厂商SDK依赖已正确添加到build.gradle.kts
I/flutter (15282): [16:50:55.753] [D] [TencentIMService] 4. ❓ 腾讯云IM控制台推送证书配置检查：
I/flutter (15282): [16:50:55.753] [D] [TencentIMService]    - 登录腾讯云IM控制台
I/flutter (15282): [16:50:55.753] [D] [TencentIMService]    - 进入 [推送服务Push] > [接入设置]
I/flutter (15282): [16:50:55.754] [D] [TencentIMService]    - 确认客户端密钥(appKey)已正确配置
[TencentIMService] 🔧 请按以下步骤检查配置：
[TencentIMService] 1. ✅ timpush-configs.json 已放置在 android/app/src/main/assets/ 目录
I/flutter (15282): [16:50:55.754] [D] [TencentIMService]    - 为以下厂商配置推送证书：
I/flutter (15282): [16:50:55.754] [D] [TencentIMService]      * 小米推送 (businessId: 45159)
I/flutter (15282): [16:50:55.754] [D] [TencentIMService]      * 华为推送 (businessId: 45160)
I/flutter (15282): [16:50:55.754] [D] [TencentIMService]      * 魅族推送 (businessId: 45161)
I/flutter (15282): [16:50:55.755] [D] [TencentIMService]      * vivo推送 (businessId: 45162)
I/flutter (15282): [16:50:55.755] [D] [TencentIMService]      * OPPO推送 (businessId: 45163)
I/flutter (15282): [16:50:55.755] [D] [TencentIMService]      * 荣耀推送 (businessId: 45164)
I/flutter (15282): [16:50:55.755] [D] [TencentIMService]      * 鸿蒙推送 (businessId: 305)
I/flutter (15282): [16:50:55.756] [D] [TencentIMService] 5. ❓ 设备厂商推送服务检查：
I/flutter (15282): [16:50:55.756] [D] [TencentIMService]    - 华为设备：设置 > 应用 > 应用启动 > 允许自启动
I/flutter (15282): [16:50:55.756] [D] [TencentIMService]    - 小米设备：设置 > 应用设置 > 权限管理 > 允许后台运行
[TencentIMService] 2. ✅ Application类已继承TencentCloudChatPushApplication
[TencentIMService] 3. ✅ 厂商SDK依赖已正确添加到build.gradle.kts
[TencentIMService] 4. ❓ 腾讯云IM控制台推送证书配置检查：
[TencentIMService]    - 登录腾讯云IM控制台
[TencentIMService]    - 进入 [推送服务Push] > [接入设置]
[TencentIMService]    - 确认客户端密钥(appKey)已正确配置
[TencentIMService]    - 为以下厂商配置推送证书：
[TencentIMService]      * 小米推送 (businessId: 45159)
[TencentIMService]      * 华为推送 (businessId: 45160)
[TencentIMService]      * 魅族推送 (businessId: 45161)
[TencentIMService]      * vivo推送 (businessId: 45162)
[TencentIMService]      * OPPO推送 (businessId: 45163)
[TencentIMService]      * 荣耀推送 (businessId: 45164)
[TencentIMService]      * 鸿蒙推送 (businessId: 305)
[TencentIMService] 5. ❓ 设备厂商推送服务检查：
[TencentIMService]    - 华为设备：设置 > 应用 > 应用启动 > 允许自启动
[TencentIMService]    - 小米设备：设置 > 应用设置 > 权限管理 > 允许后台运行
[TencentIMService]    - vivo设备：设置 > 电池 > 高耗电应用 > 允许后台运行
[TencentIMService]    - OPPO设备：设置 > 电池 > 应用快速启动
[TencentIMService]    - 荣耀设备：设置 > 应用 > 权限管理 > 通知权限
I/flutter (15282): [16:50:55.756] [D] [TencentIMService]    - vivo设备：设置 > 电池 > 高耗电应用 > 允许后台运行
I/flutter (15282): [16:50:55.756] [D] [TencentIMService]    - OPPO设备：设置 > 电池 > 应用快速启动
I/flutter (15282): [16:50:55.756] [D] [TencentIMService]    - 荣耀设备：设置 > 应用 > 权限管理 > 通知权限
I/flutter (15282): [16:50:55.773] [D] [PermissionService] 相册权限检查: PermissionStatus.denied
[PermissionService] 相册权限检查: PermissionStatus.denied
[DeviceUtil] DeviceUtil not initialized, using fallback deviceId