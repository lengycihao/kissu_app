ervice(10092): 📍 距离不足，跳过收集: 移动23米 < 50米
I/HiTouch_PressGestureDetector(10092): checkDoublePointerLimit: false
I/imsdk   (10092): TIM: |-message_sender.cpp:1052                 SendMessageComplete                     |error code:0|error message:Success|message:
I/imsdk   (10092): message_type:c2c|message_sub_type:0x0
I/imsdk   (10092): sender_user_id:6c6e84a84eb4443db7a76ce88f59924f|receiver_user_id:db3ac41e24bd45a9b8a173f0883c9e46
I/imsdk   (10092): client_time:1765817854|server_time:1765817853|sequence:1517175963|random:2053060028
I/imsdk   (10092): message_status:success|IsOnlineOnly:true|platform:Android
I/imsdk   (10092): message_elements:
I/imsdk   (10092): [custom] data size:6|description size:0
I/imsdk   (10092): 
I/flutter (10092): [LogManager] Not initialized. Message: 已发送正在输入在线消息给 db3ac41e24bd45a9b8a173f0883c9e46
I/flutter (10092): 🔔 定时刷新首页数据...
I/flutter (10092): 🏠 开始加载首页数据...
I/flutter (10092): INFO: 🏠 开始请求首页数据...
I/flutter (10092): [LogManager] Not initialized. Message: DeviceUtil not initialized, using fallback deviceId
I/flutter (10092): INFO: OAID 已添加到请求头
I/flutter (10092): INFO: ========== Request Headers ==========
I/flutter (10092): INFO: URL: https://service-api.ikissu.cn/index
I/flutter (10092): INFO: Method: GET
I/flutter (10092): INFO: --- Business Headers ---
I/flutter (10092): INFO: token: eyJ0eXAiOiJKV1QiLCJh... (205 chars)
I/flutter (10092): INFO: sign: D8510CBC24F4F5F6ACAC... (32 chars)
I/flutter (10092): INFO: version: 1.0.11
I/flutter (10092): INFO: channel: kissu_huawei
I/flutter (10092): INFO: pkg: com.yuluo.kissu
I/flutter (10092): INFO: network-name: wifi_YuluoKeji_5G
I/flutter (10092): INFO: deviceid: android-1765817855243
I/flutter (10092): INFO: mobile-model: HONOR ALI-AN00
I/flutter (10092): INFO: power: 67
I/flutter (10092): INFO: is-open-location: 1
I/flutter (10092): INFO: brand: HONOR
I/flutter (10092): INFO: oaid: 18887152-1202-4a74-9d32-2b825f7d3d73
I/flutter (10092): INFO: --- Other Headers ---
I/flutter (10092): INFO: cache_control: noCache
I/flutter (10092): INFO: timestamp: 1765817855244
I/flutter (10092): INFO: =====================================
I/flutter (10092): [LogManager] Not initialized. Message: GET https://service-api.ikissu.cn/index
I/flutter (10092): [LogManager] Not initialized. Message: Headers: {cache_control: noCache, token: ***HIDDEN***, version: 1.0.11, pkg: com.yuluo.kissu, deviceid: android-1765817855243, oaid: 18887152-1202-4a74-9d32-2b825f7d3d73, mobile-model: HONOR ALI-AN00, brand: HONOR, is-open-location: 1, channel: kissu_huawei, network-name: wifi_YuluoKeji_5G, power: 67, timestamp: 1765817855244, sign: D8510CBC24F4F5F6ACAC48A4694B80FD}
I/flutter (10092): [LogManager] Not initialized. Message: 发送文本消息: receiverID=db3ac41e24bd45a9b8a173f0883c9e46, text=摸摸, isGroup=false
D/InputMethodManager(10092): updateSelection
V/InputMethodManager(10092): SELECTION CHANGE: com.android.internal.inputmethod.IInputMethodSession$Stub$Proxy@7990d69
I/ImeTracker(10092): com.yuluo.kissu:6fb05797: onRequestHide at ORIGIN_CLIENT reason HIDE_SOFT_INPUT fromUser false
I/InputMethodManager(10092): hideSoftInputFromWindow: reason is 4,mAsyncShowHideMethodEnabled=true
D/InsetsController(10092): hide(ime(), fromIme=true)
D/FullScreenUtils(10092): isNeedToHideStatusBar: splitscreenstate=-1
I/SurfaceControl(10092): nativeRelease 0xb400006fb1f83fd0 count: 1 name: Surface(name=259c9f InputMethod)/@0xe1ef9b5 - animation-leash of insets_animation#175121
I/SurfaceControl(10092): nativeRelease 0xb400006fb1f87030 count: 1 name: Surface(name=24d886c StatusBar)/@0x25a4e6c - animation-leash of insets_animation#175114
I/ImeBackDispatcher(10092): onReceiveResult dispatcher:android.window.WindowOnBackInvokedDispatcher@fad592e, resultCode:1
I/WindowOnBackDispatcher(10092): UnregisterOnBackInvokedCallback, remove ime callback.
W/WindowOnBackDispatcher(10092): sendCancelIfRunning: isInProgress=false callback=ImeCallback=ImeOnBackInvokedCallback@28817386 Callback=android.window.IOnBackInvokedCallback$Stub$Proxy@ac7d6ab
I/HwViewRootImpl(10092): removeInvalidNode all the node in jank list is out of time
I/flutter (10092): [LogManager] Not initialized. Message: 200 GET https://service-api.ikissu.cn/index (199ms)
I/flutter (10092): [LogManager] Not initialized. Message: Response: {
I/flutter (10092):   "isSuccess": true,
I/flutter (10092):   "code": 0,
I/flutter (10092):   "msg": "",
I/flutter (10092):   "data": null,
I/flutter (10092):   "dataList": null,
I/flutter (10092):   "dataJson": {
I/flutter (10092):     "is_red_dot": 0,
I/flutter (10092):     "is_system_notice_red_dot": 0,
I/flutter (10092):     "is_interaction_notice_red_dot": 0,
I/flutter (10092):     "activity": {
I/flutter (10092):       "is_pop_ads": 0,
I/flutter (10092):       "watch_ads_nums": 0,
I/flutter (10092):       "is_ads_exempt": 0,
I/flutter (10092):       "is_ads_count_down": 0,
I/flutter (10092):       "ads_count_down": 0,
I/flutter (10092):       "is_activity": 0,
I/flutter (10092):       "is_activity_icon": "https://kissustatic.yuluojishu.com/uploads/2025/09/05/3e4bcaa18cd0b27710bbce9d748a258e.png",
I/flutter (10092):       "a... (truncated)
I/flutter (10092): ✅ Request GET /index - 207ms - Status: 200
I/flutter (10092): SUCCESS: 🏠 首页数据请求成功
I/flutter (10092): INFO: 首页数据结构: [is_red_dot, is_system_notice_red_dot, is_interaction_notice_red_dot, activity, location, user, photo, weather, vip_data]
I/flutter (10092): 📊 红点信息更新: 系统消息=0, 互动消息=0, 总数=0, 显示红点=false
I/flutter (10092): ✅ 用户头像已更新: https://kissustatic.yuluojishu.com/uploads/2025/12/09/fcc2ba99f8b972b3aef7c13b300c16d0.png
I/flutter (10092): ✅ 伴侣头像已更新: https://kissustatic.yuluojishu.com/uploads/2025/12/03/7f9b77cf39aca41b541a5c0321834251.jpg
I/flutter (10092): 📸 照片墙URL: https://kissustatic.yuluojishu.com/uploads/2025/12/10/026f45ba52e32f424f31f7db0f524446.jpg
I/flutter (10092): 🌤️ 开始解析首页天气数据
I/flutter (10092): 🌤️ 解析 base 数据: icon=https://kissustatic.yuluojishu.com/uploads/2025/09/23/a15966ed707eb3a3d4c09147bca181bd.png, weather=晴, temp=6
I/flutter (10092): 🌤️ 解析 all 数据: min=5, max=13
I/flutter (10092): ✅ 天气数据解析成功
I/flutter (10092): ✅ 首页数据加载成功: 绑定状态=true, 恋爱天数=0, 距离=<100米
I/flutter (10092): ✅ 头像预加载成功: https://kissustatic.yuluojishu.com/uploads/2025/12/09/fcc2ba99f8b972b3aef7c13b300c16d0.png
I/flutter (10092): ✅ 头像预加载成功: https://kissustatic.yuluojishu.com/uploads/2025/12/03/7f9b77cf39aca41b541a5c0321834251.jpg
I/imsdk   (10092): TIM: |-message_sender.cpp:1052                 SendMessageComplete                     |error code:0|error message:Success|message:
I/imsdk   (10092): message_type:c2c|message_sub_type:0x0
I/imsdk   (10092): sender_user_id:6c6e84a84eb4443db7a76ce88f59924f|receiver_user_id:db3ac41e24bd45a9b8a173f0883c9e46
I/imsdk   (10092): client_time:1765817853|server_time:1765817853|sequence:1517175964|random:2053060029
I/imsdk   (10092): message_status:success|IsOnlineOnly:false|platform:Android
I/imsdk   (10092): message_elements:
I/imsdk   (10092): [text] content size:6
I/imsdk   (10092): 
I/flutter (10092): [LogManager] Not initialized. Message: 消息发送成功
I/ImeTracker(10092): com.yuluo.kissu:15188901: onRequestHide at ORIGIN_CLIENT reason HIDE_SOFT_INPUT_ON_ANIMATION_STATE_CHANGED fromUser false
I/InputMethodManager(10092): notifyImeHidden true
I/ImeTracker(10092): com.yuluo.kissu:6fb05797: onHidden
W/InputMethodManager(10092): startInputReason = 4
V/InputMethodManager(10092): Starting input: editorInfo=android.view.inputmethod.EditorInfo@52c00a1 ic=null
V/InputMethodManager(10092): START INPUT: view=io.flutter.embedding.android.FlutterView{3073c73 VFE...... .F...... 0,0-1200,2652 #1 aid=1073741824},focus=true,windowFocus=true,window=android.view.ViewRootImpl$W@896f7c5,displayId=0,temporaryDetach=false,hasImeFocus=true ic=null editorInfo=android.view.inputmethod.EditorInfo@52c00a1 startInputFlags=VIEW_HAS_FOCUS
I/SurfaceControl(10092): nativeRelease 0xb400006fb1f8dc30 count: 2 name: Surface(name=259c9f InputMethod)/@0xe1ef9b5 - animation-leash of insets_animation#175121
V/InputMethodManager(10092): Starting input: Bind result=InputBindResult{result=SUCCESS_WITH_IME_SESSION method=com.android.internal.inputmethod.IInputMethodSession$Stub$Proxy@97382c6 id=com.baidu.input_hihonor/com.baidu.input_honor.ImeService sequence=12879 result=0 isInputMethodSuppressingSpellChecker=false}
I/imsdk   (10092): TIM: |-message_read_report.cpp:620             UpdateC2CReceiptInfo                    |user_id:db3ac41e24bd45a9b8a173f0883c9e46|receipt_timestamp:1765817854|message_id:|is_peer_read:0|peer_read_timestamp:0
I/flutter (10092): [LogManager] Not initialized. Message: ✅ 收到单聊消息已读回执
I/flutter (10092): [LogManager] Not initialized. Message: C2C已读 - userID: db3ac41e24bd45a9b8a173f0883c9e46, msgID: , isPeerRead: false, timestamp: 1765817854
I/imsdk   (10092): TIM: |-c2c_message_synchronizer.cpp:217        ProcessUnreadMessageInfo                |user_id:db3ac41e24bd45a9b8a173f0883c9e46|message_read_timestamp:1765817854|unread_message_count:0|last_update_sequence:3792054983159971884|abstract_message_count:0|concrete_message_count:1
I/imsdk   (10092): TIM: |-conversation_unread_info.cpp:419        HandleUpdateC2CUnreadInfo               |conversation_key:c2c_db3ac41e24bd45a9b8a173f0883c9e46|unread_message_count:0|message_read_timestamp:1765817854|c2c_unread_info_sequence:3792054983159971884
I/imsdk   (10092): TIM: |-message_read_report.cpp:620             UpdateC2CReceiptInfo                    |user_id:db3ac41e24bd45a9b8a173f0883c9e46|receipt_timestamp:1765817854|message_id:|is_peer_read:0|peer_read_timestamp:0
I/flutter (10092): [LogManager] Not initialized. Message: ✅ 收到单聊消息已读回执
I/flutter (10092): [LogManager] Not initialized. Message: C2C已读 - userID: db3ac41e24bd45a9b8a173f0883c9e46, msgID: , isPeerRead: false, timestamp: 1765817854
I/flutter (10092): [LogManager] Not initialized. Message: 权限状态更新:
I/flutter (10092): [LogManager] Not initialized. Message: 前台定位: granted
I/flutter (10092): [LogManager] Not initialized. Message: 后台定位: granted
I/flutter (10092): INFO: 定位权限状态缓存已更新: 1
D/ForegroundLocationService(10092): 📍 原生定位成功: 30.275049758118932, 120.2210026240614, 精度: 75.0m
D/ForegroundLocationService(10092): 定位成功，静默模式（不更新通知）
D/LocationReportService(10092): 📍 距离不足，跳过收集: 移动23米 < 50米
D/LocationReportService(10092): ✅ 保活检查：定时器运行正常
D/ForegroundLocationService(10092): ❤️ 心跳闹钟已设置，3分钟后触发
D/LocationReportService(10092): ⏰ 执行定时上报，位置数量: 1
D/LocationReportService(10092): 🚀 开始上报定位数据
D/LocationReportService(10092): 📡 API地址: https://service-api.ikissu.cn/location/report
D/LocationReportService(10092): 📦 上报数据: [{"longitude":"120.22076113791819","latitude":"30.275000035218675","location_time":"1765817803","speed":"0.0","altitude":"62.12","accuracy":"43.0","location_name":"浙江省杭州市上城区运河东路301号靠近中豪·湘和国际"}]
D/LocationReportService(10092): 🔐 签名已生成: C4794EDE93E9F752672CDB69F60591CF
D/LocationReportService(10092): 📡 HTTP响应码: 200
D/LocationReportService(10092): 📡 服务器响应: {"code":0,"msg":"位置上报成功","time":1765817859,"data":{}}
D/LocationReportService(10092): ✅ 定位上报成功
D/LocationReportService(10092): ✅ 定时上报成功，缓冲区已清空
I/WM-Processor(10092): Moving WorkSpec (820b9f87-2576-4e28-bbfe-730b764e7831) to the foreground
W/LocationReportService(10092): ! 保活检查：定时器未运行，重新启动
I/WM-SystemFgDispatcher(10092): Started foreground service Intent { act=ACTION_START_FOREGROUND cmp=com.yuluo.kissu/androidx.work.impl.foreground.SystemForegroundService (has extras) }
D/LocationReportService(10092): ⏰ 定时上报器已启动，间隔: 60秒
2
D/LocationReportService(10092): 🛠️ 已调度 WorkManager 单次兜底任务（2分钟后尝试重启服务/定时器）
D/LocationReportWorker(10092): 兜底重启定时器/服务完成
I/WM-SystemFgDispatcher(10092): Stopping foreground service
I/NotificationManager(10092): com.yuluo.kissu: cancel(1001)
D/ForegroundLocationService(10092): 📍 原生定位成功: 30.275049758118932, 120.2210026240614, 精度: 75.0m
D/ForegroundLocationService(10092): 定位成功，静默模式（不更新通知）
D/LocationReportService(10092): 📦 收集池为空，直接放入: 30.275049758118932, 120.2210026240614, 精度: 75.0m
D/LocationReportService(10092): 🔑 读取用户信息: token=已存在(eyJ0eXAiOiJKV1QiLCJh...), userId=4277, baseUrl=https://service-api.ikissu.cn
D/LocationReportService(10092): 📦 位置已收集到缓冲区 (1/12): 30.275049758118932, 120.2210026240614
D/LocationReportService(10092): 📍 最后收集位置已更新: 30.275049758118932, 120.2210026240614
D/ForegroundLocationService(10092): 📍 原生定位成功: 30.275049758118932, 120.2210026240614, 精度: 75.0m
D/ForegroundLocationService(10092): 定位成功，静默模式（不更新通知）
D/LocationReportService(10092): 📍 距离不足，跳过收集: 移动0米 < 50米
I/flutter (10092): 🔔 定时刷新首页数据...
I/flutter (10092): 🏠 开始加载首页数据...
I/flutter (10092): INFO: 🏠 开始请求首页数据...
I/flutter (10092): [LogManager] Not initialized. Message: DeviceUtil not initialized, using fallback deviceId
I/flutter (10092): INFO: OAID 已添加到请求头
I/flutter (10092): INFO: ========== Request Headers ==========
I/flutter (10092): INFO: URL: https://service-api.ikissu.cn/index
I/flutter (10092): INFO: Method: GET
I/flutter (10092): INFO: --- Business Headers ---
I/flutter (10092): INFO: token: eyJ0eXAiOiJKV1QiLCJh... (205 chars)
I/flutter (10092): INFO: sign: 5F088C0DBC81A2907B35... (32 chars)
I/flutter (10092): INFO: version: 1.0.11
I/flutter (10092): INFO: channel: kissu_huawei
I/flutter (10092): INFO: pkg: com.yuluo.kissu
I/flutter (10092): INFO: network-name: wifi_YuluoKeji_5G
I/flutter (10092): INFO: deviceid: android-1765817865246
I/flutter (10092): INFO: mobile-model: HONOR ALI-AN00
I/flutter (10092): INFO: power: 67
I/flutter (10092): INFO: is-open-location: 1
I/flutter (10092): INFO: brand: HONOR
I/flutter (10092): INFO: oaid: 18887152-1202-4a74-9d32-2b825f7d3d73
I/flutter (10092): INFO: --- Other Headers ---
I/flutter (10092): INFO: cache_control: noCache
I/flutter (10092): INFO: timestamp: 1765817865247
I/flutter (10092): INFO: =====================================
I/flutter (10092): [LogManager] Not initialized. Message: GET https://service-api.ikissu.cn/index
I/flutter (10092): [LogManager] Not initialized. Message: Headers: {cache_control: noCache, token: ***HIDDEN***, version: 1.0.11, pkg: com.yuluo.kissu, deviceid: android-1765817865246, oaid: 18887152-1202-4a74-9d32-2b825f7d3d73, mobile-model: HONOR ALI-AN00, brand: HONOR, is-open-location: 1, channel: kissu_huawei, network-name: wifi_YuluoKeji_5G, power: 67, timestamp: 1765817865247, sign: 5F088C0DBC81A2907B35B08E9EC987A7}
I/flutter (10092): [LogManager] Not initialized. Message: 200 GET https://service-api.ikissu.cn/index (156ms)
I/flutter (10092): [LogManager] Not initialized. Message: Response: {
I/flutter (10092):   "isSuccess": true,
I/flutter (10092):   "code": 0,
I/flutter (10092):   "msg": "",
I/flutter (10092):   "data": null,
I/flutter (10092):   "dataList": null,
I/flutter (10092):   "dataJson": {
I/flutter (10092):     "is_red_dot": 0,
I/flutter (10092):     "is_system_notice_red_dot": 0,
I/flutter (10092):     "is_interaction_notice_red_dot": 0,
I/flutter (10092):     "activity": {
I/flutter (10092):       "is_pop_ads": 0,
I/flutter (10092):       "watch_ads_nums": 0,
I/flutter (10092):       "is_ads_exempt": 0,
I/flutter (10092):       "is_ads_count_down": 0,
I/flutter (10092):       "ads_count_down": 0,
I/flutter (10092):       "is_activity": 0,
I/flutter (10092):       "is_activity_icon": "https://kissustatic.yuluojishu.com/uploads/2025/09/05/3e4bcaa18cd0b27710bbce9d748a258e.png",
I/flutter (10092):       "a... (truncated)
I/flutter (10092): ✅ Request GET /index - 183ms - Status: 200
I/flutter (10092): SUCCESS: 🏠 首页数据请求成功
I/flutter (10092): INFO: 首页数据结构: [is_red_dot, is_system_notice_red_dot, is_interaction_notice_red_dot, activity, location, user, photo, weather, vip_data]
I/flutter (10092): 📊 红点信息更新: 系统消息=0, 互动消息=0, 总数=0, 显示红点=false
I/flutter (10092): ✅ 用户头像已更新: https://kissustatic.yuluojishu.com/uploads/2025/12/09/fcc2ba99f8b972b3aef7c13b300c16d0.png
I/flutter (10092): ✅ 伴侣头像已更新: https://kissustatic.yuluojishu.com/uploads/2025/12/03/7f9b77cf39aca41b541a5c0321834251.jpg
I/flutter (10092): 📸 照片墙URL: https://kissustatic.yuluojishu.com/uploads/2025/12/10/026f45ba52e32f424f31f7db0f524446.jpg
I/flutter (10092): 🌤️ 开始解析首页天气数据
I/flutter (10092): 🌤️ 解析 base 数据: icon=https://kissustatic.yuluojishu.com/uploads/2025/09/23/a15966ed707eb3a3d4c09147bca181bd.png, weather=晴, temp=6
I/flutter (10092): 🌤️ 解析 all 数据: min=5, max=13
I/flutter (10092): ✅ 天气数据解析成功
I/flutter (10092): ✅ 首页数据加载成功: 绑定状态=true, 恋爱天数=0, 距离=<100米
I/flutter (10092): ✅ 头像预加载成功: https://kissustatic.yuluojishu.com/uploads/2025/12/09/fcc2ba99f8b972b3aef7c13b300c16d0.png
I/flutter (10092): ✅ 头像预加载成功: https://kissustatic.yuluojishu.com/uploads/2025/12/03/7f9b77cf39aca41b541a5c0321834251.jpg
I/imsdk   (10092): TIM: |-login.cpp:533                           RequestHeartbeat                        |send heartbeat request
I/imsdk   (10092): TIM: |-login.cpp:574                           HandleHeartbeatResponse                 |receive heartbeat response|client_address:60.176.4.40:44630|heartbeat_interval:120|sync_timestamp:1765817866
I/flutter (10092): [LogManager] Not initialized. Message: 权限状态更新:
I/flutter (10092): [LogManager] Not initialized. Message: 前台定位: granted
I/flutter (10092): [LogManager] Not initialized. Message: 后台定位: granted
I/flutter (10092): INFO: 定位权限状态缓存已更新: 1
D/ForegroundLocationService(10092): 📱 执行App使用记录采集和上报（前台/后台统一原生）
W/AppUsageReportService(10092): ! 没有使用情况访问权限，无法采集数据
D/ForegroundLocationService(10092): 📍 原生定位成功: 30.275049758118932, 120.2210026240614, 精度: 75.0m
D/ForegroundLocationService(10092): 定位成功，静默模式（不更新通知）
D/LocationReportService(10092): 📍 距离不足，跳过收集: 移动0米 < 50米
I/imsdk   (10092): TIM: |-message_dispatcher.cpp:315              HandleNewMessage                        |message_source:receive message|message:
I/imsdk   (10092): message_type:c2c|message_sub_type:0x6
I/imsdk   (10092): sender_user_id:db3ac41e24bd45a9b8a173f0883c9e46|receiver_user_id:6c6e84a84eb4443db7a76ce88f59924f|receive_time:1765817870227
I/imsdk   (10092): client_time:1765817869|server_time:1765817869|sequence:2316657282|random:1596018459
I/imsdk   (10092): message_status:success|IsOnlineOnly:false|platform:Android
I/imsdk   (10092): message_elements:
I/imsdk   (10092): [text] content size:15
I/imsdk   (10092): 
I/flutter (10092): [LogManager] Not initialized. Message: 📨 收到新消息
I/flutter (10092): [LogManager] Not initialized. Message: 消息基本信息 - ID: 144115249482111601-1765817869-1596018459, 发送者: db3ac41e24bd45a9b8a173f0883c9e46, 类型: 1
I/flutter (10092): [LogManager] Not initialized. Message: 📝 文本消息: 哈哈哈哈家
I/flutter (10092): [LogManager] Not initialized. Message: 标记单聊消息已读: userID=db3ac41e24bd45a9b8a173f0883c9e46, count=1
I/imsdk   (10092): TIM: |-message_read_report.cpp:305             SendC2CMessageReadRequest               |c2c_user_id:db3ac41e24bd45a9b8a173f0883c9e46|c2c_tiny_id:144115249482111601|c2c_read_time:1765817870
I/imsdk   (10092): TIM: |-conversation_unread_info.cpp:419        HandleUpdateC2CUnreadInfo               |conversation_key:c2c_db3ac41e24bd45a9b8a173f0883c9e46|unread_message_count:0|message_read_timestamp:1765817870|c2c_unread_info_sequence:3792054983159971886
I/flutter (10092): [LogManager] Not initialized. Message: 标记单聊消息已读成功
I/imsdk   (10092): TIM: |-c2c_message_synchronizer.cpp:217        ProcessUnreadMessageInfo                |user_id:db3ac41e24bd45a9b8a173f0883c9e46|message_read_timestamp:1765817868|unread_message_count:1|last_update_sequence:3792054983159971885|abstract_message_count:0|concrete_message_count:1
I/imsdk   (10092): TIM: |-message_read_report.cpp:620             UpdateC2CReceiptInfo                    |user_id:db3ac41e24bd45a9b8a173f0883c9e46|receipt_timestamp:1765817854|message_id:|is_peer_read:0|peer_read_timestamp:0
I/flutter (10092): [LogManager] Not initialized. Message: ✅ 收到单聊消息已读回执
I/flutter (10092): [LogManager] Not initialized. Message: C2C已读 - userID: db3ac41e24bd45a9b8a173f0883c9e46, msgID: , isPeerRead: false, timestamp: 1765817854
I/imsdk   (10092): TIM: |-message_dispatcher.cpp:315              HandleNewMessage                        |message_source:receive message|message:
I/imsdk   (10092): message_type:c2c|message_sub_type:0x6
I/imsdk   (10092): sender_user_id:db3ac41e24bd45a9b8a173f0883c9e46|receiver_user_id:6c6e84a84eb4443db7a76ce88f59924f|receive_time:1765817870458
I/imsdk   (10092): client_time:1765817870|server_time:1765817869|sequence:2316657283|random:1596018460
I/imsdk   (10092): message_status:success|IsOnlineOnly:true|platform:Android
I/imsdk   (10092): message_elements:
I/imsdk   (10092): [custom] data size:6|description size:0
I/imsdk   (10092): 
I/flutter (10092): [LogManager] Not initialized. Message: 📨 收到新消息
I/flutter (10092): [LogManager] Not initialized. Message: 消息基本信息 - ID: 144115249482111601-1765817870-1596018460, 发送者: db3ac41e24bd45a9b8a173f0883c9e46, 类型: 2
I/flutter (10092): [LogManager] Not initialized. Message: 🎯 自定义消息 - data: typing, desc: , extension: 
I/flutter (10092): [LogManager] Not initialized. Message: 解析关系消息失败: FormatException: Unexpected character (at character 1)
I/flutter (10092): typing
I/flutter (10092): ^
I/flutter (10092): , 原始数据: typing
D/ForegroundLocationService(10092): 📍 原生定位成功: 30.275049758118932, 120.2210026240614, 精度: 75.0m
D/ForegroundLocationService(10092): 定位成功，静默模式（不更新通知）
D/LocationReportService(10092): 📍 距离不足，跳过收集: 移动0米 < 50米
I/HiTouch_PressGestureDetector(10092): checkDoublePointerLimit: false
I/flutter (10092): 💬 键盘抬起，关闭所有面板
W/InputMethodManager(10092): startInputReason = 4
V/InputMethodManager(10092): Starting input: editorInfo=android.view.inputmethod.EditorInfo@45213e4 ic=io.flutter.plugin.editing.InputConnectionAdaptor@f5a204d
V/InputMethodManager(10092): START INPUT: view=io.flutter.embedding.android.FlutterView{3073c73 VFE...... .F...... 0,0-1200,2652 #1 aid=1073741824},focus=true,windowFocus=true,window=android.view.ViewRootImpl$W@896f7c5,displayId=0,temporaryDetach=false,hasImeFocus=true ic=io.flutter.plugin.editing.InputConnectionAdaptor@f5a204d editorInfo=android.view.inputmethod.EditorInfo@45213e4 startInputFlags=VIEW_HAS_FOCUS
I/ImeTracker(10092): com.yuluo.kissu:173748b9: onRequestShow at ORIGIN_CLIENT reason SHOW_SOFT_INPUT fromUser false
I/InputMethodManager(10092): showSoftInput: reason is 1,mAsyncShowHideMethodEnabled=true
D/InputMethodManager(10092): showSoftInput() view=io.flutter.embedding.android.FlutterView{3073c73 VFE...... .F...... 0,0-1200,2652 #1 aid=1073741824} flags=0 reason=SHOW_SOFT_INPUT
V/InputMethodManager(10092): Starting input: Bind result=InputBindResult{result=SUCCESS_WITH_IME_SESSION method=com.android.internal.inputmethod.IInputMethodSession$Stub$Proxy@7c56702 id=com.baidu.input_hihonor/com.baidu.input_honor.ImeService sequence=12880 result=0 isInputMethodSuppressingSpellChecker=false}
V/InputMethodManager(10092): Calling View.onInputConnectionOpened: view= io.flutter.embedding.android.FlutterView{3073c73 VFE...... .F...... 0,0-1200,2652 #1 aid=1073741824}, ic=io.flutter.plugin.editing.InputConnectionAdaptor@f5a204d, editorInfo=android.view.inputmethod.EditorInfo@45213e4, handler=null, startInputSeq=10
I/RmeSchedManager(10092): init Rme, version is: v1.0
D/RtgSched(10092): resetRtgSchedHandle failed enable:0
I/ImeBackDispatcher(10092): onReceiveResult dispatcher:android.window.WindowOnBackInvokedDispatcher@fad592e, resultCode:0
I/WindowOnBackDispatcher(10092): Ime setTopOnBackInvokedCallback: OnBackInvokedCallbackInfo{mCallback=android.window.WindowOnBackInvokedDispatcher$OnBackInvokedCallbackWrapper@70e8a50, mPriority=0, mIsAnimationCallback=true}
I/InsetsController(10092): show(ime(), fromIme=true)
D/FullScreenUtils(10092): isNeedToHideStatusBar: splitscreenstate=-1
I/SurfaceControl(10092): nativeRelease 0xb400006fb1f8f4f0 count: 1 name: Surface(name=3dae7ed NavigationBar0)/@0x421bb1f - animation-leash of insets_animation#175134
I/SurfaceControl(10092): nativeRelease 0xb400006fb1ecaa50 count: 1 name: Surface(name=259c9f InputMethod)/@0xe1ef9b5 - animation-leash of insets_animation#175121
I/SurfaceControl(10092): nativeRelease 0xb400006fb1f8f610 count: 1 name: Surface(name=24d886c StatusBar)/@0x25a4e6c - animation-leash of insets_animation#175114
I/HwViewRootImpl(10092): removeInvalidNode all the node in jank list is out of time
I/RmeSchedManager(10092): init Rme, version is: v1.0
I/RtgSchedEvent(10092): current pid:10092 AppType:-1
I/ImeTracker(10092): com.yuluo.kissu:173748b9: onShown
I/SurfaceControl(10092): nativeRelease 0xb400006fb1f84d50 count: 2 name: Surface(name=259c9f InputMethod)/@0xe1ef9b5 - animation-leash of insets_animation#175121
D/ForegroundLocationService(10092): 📍 原生定位成功: 30.275049758118932, 120.2210026240614, 精度: 75.0m
D/ForegroundLocationService(10092): 定位成功，静默模式（不更新通知）
D/LocationReportService(10092): 📍 距离不足，跳过收集: 移动0米 < 50米
I/flutter (10092): 🔔 定时刷新首页数据...
I/flutter (10092): 🏠 开始加载首页数据...
I/flutter (10092): INFO: 🏠 开始请求首页数据...
I/flutter (10092): [LogManager] Not initialized. Message: DeviceUtil not initialized, using fallback deviceId
I/flutter (10092): INFO: OAID 已添加到请求头
I/flutter (10092): INFO: ========== Request Headers ==========
I/flutter (10092): INFO: URL: https://service-api.ikissu.cn/index
I/flutter (10092): INFO: Method: GET
I/flutter (10092): INFO: --- Business Headers ---
I/flutter (10092): INFO: token: eyJ0eXAiOiJKV1QiLCJh... (205 chars)
I/flutter (10092): INFO: sign: F5152302D6FACAB38D67... (32 chars)
I/flutter (10092): INFO: version: 1.0.11
I/flutter (10092): INFO: channel: kissu_huawei
I/flutter (10092): INFO: pkg: com.yuluo.kissu
I/flutter (10092): INFO: network-name: wifi_YuluoKeji_5G
I/flutter (10092): INFO: deviceid: android-1765817875245
I/flutter (10092): INFO: mobile-model: HONOR ALI-AN00
I/flutter (10092): INFO: power: 67
I/flutter (10092): INFO: is-open-location: 1
I/flutter (10092): INFO: brand: HONOR
I/flutter (10092): INFO: oaid: 18887152-1202-4a74-9d32-2b825f7d3d73
I/flutter (10092): INFO: --- Other Headers ---
I/flutter (10092): INFO: cache_control: noCache
I/flutter (10092): INFO: timestamp: 1765817875246
I/flutter (10092): INFO: =====================================
I/flutter (10092): [LogManager] Not initialized. Message: GET https://service-api.ikissu.cn/index
I/flutter (10092): [LogManager] Not initialized. Message: Headers: {cache_control: noCache, token: ***HIDDEN***, version: 1.0.11, pkg: com.yuluo.kissu, deviceid: android-1765817875245, oaid: 18887152-1202-4a74-9d32-2b825f7d3d73, mobile-model: HONOR ALI-AN00, brand: HONOR, is-open-location: 1, channel: kissu_huawei, network-name: wifi_YuluoKeji_5G, power: 67, timestamp: 1765817875246, sign: F5152302D6FACAB38D67E1841191542D}
I/flutter (10092): [LogManager] Not initialized. Message: 200 GET https://service-api.ikissu.cn/index (143ms)
I/flutter (10092): [LogManager] Not initialized. Message: Response: {
I/flutter (10092):   "isSuccess": true,
I/flutter (10092):   "code": 0,
I/flutter (10092):   "msg": "",
I/flutter (10092):   "data": null,
I/flutter (10092):   "dataList": null,
I/flutter (10092):   "dataJson": {
I/flutter (10092):     "is_red_dot": 0,
I/flutter (10092):     "is_system_notice_red_dot": 0,
I/flutter (10092):     "is_interaction_notice_red_dot": 0,
I/flutter (10092):     "activity": {
I/flutter (10092):       "is_pop_ads": 0,
I/flutter (10092):       "watch_ads_nums": 0,
I/flutter (10092):       "is_ads_exempt": 0,
I/flutter (10092):       "is_ads_count_down": 0,
I/flutter (10092):       "ads_count_down": 0,
I/flutter (10092):       "is_activity": 0,
I/flutter (10092):       "is_activity_icon": "https://kissustatic.yuluojishu.com/uploads/2025/09/05/3e4bcaa18cd0b27710bbce9d748a258e.png",
I/flutter (10092):       "a... (truncated)
I/flutter (10092): ✅ Request GET /index - 152ms - Status: 200
I/flutter (10092): SUCCESS: 🏠 首页数据请求成功
I/flutter (10092): INFO: 首页数据结构: [is_red_dot, is_system_notice_red_dot, is_interaction_notice_red_dot, activity, location, user, photo, weather, vip_data]
I/flutter (10092): 📊 红点信息更新: 系统消息=0, 互动消息=0, 总数=0, 显示红点=false
I/flutter (10092): ✅ 用户头像已更新: https://kissustatic.yuluojishu.com/uploads/2025/12/09/fcc2ba99f8b972b3aef7c13b300c16d0.png
I/flutter (10092): ✅ 伴侣头像已更新: https://kissustatic.yuluojishu.com/uploads/2025/12/03/7f9b77cf39aca41b541a5c0321834251.jpg
I/flutter (10092): 📸 照片墙URL: https://kissustatic.yuluojishu.com/uploads/2025/12/10/026f45ba52e32f424f31f7db0f524446.jpg
I/flutter (10092): 🌤️ 开始解析首页天气数据
I/flutter (10092): 🌤️ 解析 base 数据: icon=https://kissustatic.yuluojishu.com/uploads/2025/09/23/a15966ed707eb3a3d4c09147bca181bd.png, weather=晴, temp=6
I/flutter (10092): 🌤️ 解析 all 数据: min=5, max=13
I/flutter (10092): ✅ 天气数据解析成功
I/flutter (10092): ✅ 首页数据加载成功: 绑定状态=true, 恋爱天数=0, 距离=<100米
I/flutter (10092): ✅ 头像预加载成功: https://kissustatic.yuluojishu.com/uploads/2025/12/09/fcc2ba99f8b972b3aef7c13b300c16d0.png
I/flutter (10092): ✅ 头像预加载成功: https://kissustatic.yuluojishu.com/uploads/2025/12/03/7f9b77cf39aca41b541a5c0321834251.jpg
D/InputMethodManager(10092): updateSelection
V/InputMethodManager(10092): SELECTION CHANGE: com.android.internal.inputmethod.IInputMethodSession$Stub$Proxy@7c56702
I/HiTouch_PressGestureDetector(10092): checkDoublePointerLimit: false
I/flutter (10092): [LogManager] Not initialized. Message: 发送文本消息: receiverID=db3ac41e24bd45a9b8a173f0883c9e46, text=嗯, isGroup=false
D/InputMethodManager(10092): updateSelection
V/InputMethodManager(10092): SELECTION CHANGE: com.android.internal.inputmethod.IInputMethodSession$Stub$Proxy@7c56702
I/ImeTracker(10092): com.yuluo.kissu:2a168177: onRequestHide at ORIGIN_CLIENT reason HIDE_SOFT_INPUT fromUser false
I/InputMethodManager(10092): hideSoftInputFromWindow: reason is 4,mAsyncShowHideMethodEnabled=true
D/InsetsController(10092): hide(ime(), fromIme=true)
D/FullScreenUtils(10092): isNeedToHideStatusBar: splitscreenstate=-1
I/SurfaceControl(10092): nativeRelease 0xb400006fb1f88fb0 count: 1 name: Surface(name=259c9f InputMethod)/@0xe1ef9b5 - animation-leash of insets_animation#175121
I/SurfaceControl(10092): nativeRelease 0xb400006fb1ede790 count: 1 name: Surface(name=24d886c StatusBar)/@0x25a4e6c - animation-leash of insets_animation#175114
I/ImeBackDispatcher(10092): onReceiveResult dispatcher:android.window.WindowOnBackInvokedDispatcher@fad592e, resultCode:1
I/WindowOnBackDispatcher(10092): UnregisterOnBackInvokedCallback, remove ime callback.
W/WindowOnBackDispatcher(10092): sendCancelIfRunning: isInProgress=false callback=ImeCallback=ImeOnBackInvokedCallback@28817386 Callback=android.window.IOnBackInvokedCallback$Stub$Proxy@f580c05
