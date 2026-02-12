[19:49:43.224] [D] [TencentIMService] 📨 收到新消息
I/flutter (29857): [19:49:43.225] [D] [TencentIMService] 消息基本信息 - ID: 144115244956988994-1770896982-193145, 发送者: administrator, 类型: 2
I/flutter (29857): [19:49:43.225] [D] [TencentIMService] 🎯 自定义消息 - data: {"time":"2026-02-12 19:49:42","desc":"绑定情侣关系","msg_type":"bindAndroid","from_user":"b78b45b0f8224b079248fcaf9e1cc303","nickname":"kissu0001"}, desc: 绑定情侣关系, extension: 
I/flutter (29857): [19:49:43.225] [D] [TencentIMService] 处理关系消息 - msg_type: bindAndroid
I/flutter (29857): [19:49:43.225] [D] [TencentIMService] 🎉 收到绑定消息 (bindAndroid/bind)，A和B都会收到此消息，统一处理绑定逻辑
[TencentIMService] 📨 收到新消息
[TencentIMService] 消息基本信息 - ID: 144115244956988994-1770896982-193145, 发送者: administrator, 类型: 2
[TencentIMService] 处理关系消息 - msg_type: bindAndroid
[TencentIMService] 🎉 收到绑定消息 (bindAndroid/bind)，A和B都会收到此消息，统一处理绑定逻辑
[TencentIMService] 💬 触发绑定消息回调，准备关闭绑定弹窗...
[TencentIMService] 📥 开始刷新用户信息...
I/flutter (29857): [19:49:43.225] [D] [TencentIMService] 💬 触发绑定消息回调，准备关闭绑定弹窗...
[DeviceUtil] DeviceUtil not initialized, using fallback deviceId
[OaidUtil] 开始获取设备ID...
[OaidUtil] 返回缓存的设备ID: 8355f50e...
I/flutter (29857): [19:49:43.226] [D] [TencentIMService] 📥 开始刷新用户信息...
I/flutter (29857): [19:49:43.227] [W] [DeviceUtil] DeviceUtil not initialized, using fallback deviceId
I/flutter (29857): [19:49:43.227] [I] [OaidUtil] 开始获取设备ID...
I/flutter (29857): [19:49:43.227] [I] [OaidUtil] 返回缓存的设备ID: 8355f50e...
2
I/flutter (29857): [LogManager] Error in appender FileAppender: Bad state: StreamSink is bound to a stream
I/flutter (29857): INFO: OAID 已添加到请求头
I/flutter (29857): INFO: ========== Request Headers ==========
I/flutter (29857): INFO: URL: https://service-api.ikissu.cn/get/user
I/flutter (29857): INFO: Method: GET
I/flutter (29857): INFO: --- Business Headers ---
I/flutter (29857): INFO: token: eyJ0eXAiOiJKV1QiLCJh... (207 chars)
I/flutter (29857): INFO: sign: C9BF72168E3C88A68469... (32 chars)
I/flutter (29857): INFO: version: 1.1.5
I/flutter (29857): INFO: channel: kissu_rongyao
I/flutter (29857): INFO: pkg: com.yuluo.kissu
I/flutter (29857): INFO: os: 1
I/flutter (29857): INFO: network-name: wifi_YuluoKeji_5G
I/flutter (29857): INFO: deviceid: android-1770896983227
I/flutter (29857): INFO: mobile-model: Xiaomi 23127PN0CC
I/flutter (29857): INFO: power: 30
I/flutter (29857): INFO: is-open-location: 1
I/flutter (29857): INFO: brand: Xiaomi
I/flutter (29857): INFO: oaid: 8355f50e457c2989
I/flutter (29857): INFO: --- Other Headers ---
I/flutter (29857): INFO: network_debounce: true
I/flutter (29857): INFO: timestamp: 1770896983228
I/flutter (29857): INFO: =====================================
[TencentIMService] 🎯 自定义消息 - data: {"time":"2026-02-12 19:49:42","desc":"绑定情侣关系","msg_type":"bindAndroid","from_user":"b78b45b0f8224b079248fcaf9e1cc303","nickname":"kissu0001"}, desc: 绑定情侣关系, extension:
[AuthService] 调用getUserInfo API
I/flutter (29857): ✅ Request GET /get/user - 132ms - Status: 200
I/flutter (29857): [19:49:43.326] [I] [AuthService] 调用getUserInfo API | Extra: {isSuccess: true, msg: Success}
I/flutter (29857): INFO:  开始保存用户数据，用户ID: 18390, 数据长度: 2516
[AuthService] 调用getUserInfo API
I/flutter (29857): ✅ Request GET /get/user - 101ms - Status: 200
I/flutter (29857): [19:49:43.328] [I] [AuthService] 调用getUserInfo API | Extra: {isSuccess: true, msg: Success}
I/flutter (29857): INFO:  开始保存用户数据，用户ID: 18390, 数据长度: 2516
I/flutter (29857): [LogManager] Error in appender FileAppender: Bad state: StreamSink is bound to a stream
I/flutter (29857): SUCCESS:  用户数据保存成功
I/flutter (29857): [19:49:43.343] [I] [HTTP] 200 GET https://service-api.ikissu.cn/get/user (157ms)
[HTTP] 200 GET https://service-api.ikissu.cn/get/user (157ms)
I/flutter (29857): [19:49:43.349] [D] [HTTP] Response: {
I/flutter (29857):   "isSuccess": true,
I/flutter (29857):   "code": 0,
I/flutter (29857):   "msg": "获取用户信息",
I/flutter (29857):   "data": null,
I/flutter (29857):   "dataList": null,
I/flutter (29857):   "dataJson": {
I/flutter (29857):     "register_version": "1.1.5",
I/flutter (29857):     "unique_id": "26e7ced9091949db89a9a5bb8fb47238",
I/flutter (29857):     "is_order_vip": "0",
I/flutter (29857):     "current_mobile_sys": "android",
I/flutter (29857):     "id": 18390,
I/flutter (29857):     "channel_cate_id": "33",
I/flutter (29857):     "province_name": "浙江",
I/flutter (29857):     "login_nums": "1",
I/flutter (29857):     "friend_code": "1018396",
I/flutter (29857):     "device_id": "android-1770896597666",
I/flutter (29857):     "is_give_vip": "0",
I/flutter (29857):     "status": 1,
I/flutter (29857):     "is_check_in": 0,
I/flutter (29857):     "lately_un... (truncated)
I/flutter (29857): ✅ Request GET /get/user - 191ms - Status: 200
I/flutter (29857): [19:49:43.350] [I] [AuthService] 调用getUserInfo API | Extra: {isSuccess: true, msg: 获取用户信息}
I/flutter (29857): INFO:  开始保存用户数据，用户ID: 18390, 数据长度: 2516
I/flutter (29857): [LogManager] Error in appender FileAppender: Bad state: StreamSink is bound to a stream
I/flutter (29857): SUCCESS:  用户数据保存成功
[AuthService] 调用getUserInfo API
I/flutter (29857): SUCCESS:  验证保存成功，数据长度: 2516
[AuthService] 用户信息已更新
I/flutter (29857): [19:49:43.355] [I] [AuthService] 用户信息已更新 | Extra: {userId: 18390, nickname: kissu6888}
I/flutter (29857): [19:49:43.355] [I] [AuthService] 用户信息已从服务器刷新 | Extra: {userId: 18390, nickname: kissu6888, hasToken: true, hasImSign: true}
I/flutter (29857): [19:49:43.355] [D] [TencentIMService] ✅ 用户信息刷新成功
I/flutter (29857): [19:49:43.355] [I] [RelationshipAnimationService] 🔄 开始刷新当前页面...
I/flutter (29857): [19:49:43.355] [D] [App] ✅ 从本地加载用户头像: https://kissustatic.yuluojishu.com/uploads/2025/12/03/7f9b77cf39aca41b541a5c0321834251.jpg
[AuthService] 用户信息已从服务器刷新
[TencentIMService] ✅ 用户信息刷新成功
I/flutter (29857): [19:49:43.356] [D] [App] 📌 未绑定状态，使用加号图标
I/flutter (29857): [19:49:43.356] [I] [RelationshipAnimationService] ✅ 首页数据已刷新
I/flutter (29857): [19:49:43.356] [I] [RelationshipAnimationService] ✅ 页面刷新完成
I/flutter (29857): [19:49:43.356] [D] [TencentIMService] 🎬 开始播放绑定动画
I/flutter (29857): [19:49:43.357] [I] [RelationshipAnimationService] 显示绑定成功动画: assets/gif/bind_success.gif, 时长: 3秒
5
I/flutter (29857): [LogManager] Error in appender FileAppender: Bad state: StreamSink is bound to a stream
I/flutter (29857): SUCCESS:  用户数据保存成功
I/flutter (29857): SUCCESS:  验证保存成功，数据长度: 2516
I/flutter (29857): [19:49:43.360] [I] [AuthService] 用户信息已更新 | Extra: {userId: 18390, nickname: kissu6888}
[RelationshipAnimationService] 🔄 开始刷新当前页面...
[App] ✅ 从本地加载用户头像: https://kissustatic.yuluojishu.com/uploads/2025/12/03/7f9b77cf39aca41b541a5c0321834251.jpg
[App] 📌 未绑定状态，使用加号图标
[RelationshipAnimationService] ✅ 首页数据已刷新
[RelationshipAnimationService] ✅ 页面刷新完成
[TencentIMService] 🎬 开始播放绑定动画
[RelationshipAnimationService] 显示绑定成功动画: assets/gif/bind_success.gif, 时长: 3秒
[GETX] OPEN DIALOG 829464193
[AuthService] 用户信息已更新
I/flutter (29857): [19:49:43.360] [I] [AuthService] 用户信息已从服务器刷新 | Extra: {userId: 18390, nickname: kissu6888, hasToken: true, hasImSign: true}
I/flutter (29857): [19:49:43.360] [D] [TencentIMService] ✅ 用户信息刷新成功
I/flutter (29857): [19:49:43.360] [I] [RelationshipAnimationService] 🔄 开始刷新当前页面...
I/flutter (29857): [19:49:43.361] [D] [App] ✅ 从本地加载用户头像: https://kissustatic.yuluojishu.com/uploads/2025/12/03/7f9b77cf39aca41b541a5c0321834251.jpg
I/flutter (29857): [19:49:43.361] [D] [App] 📌 未绑定状态，使用加号图标
I/flutter (29857): [19:49:43.361] [I] [RelationshipAnimationService] ✅ 首页数据已刷新
I/flutter (29857): [19:49:43.361] [I] [RelationshipAnimationService] ✅ 页面刷新完成
I/flutter (29857): [19:49:43.361] [D] [TencentIMService] 🎬 开始播放绑定动画
I/flutter (29857): [19:49:43.362] [W] [RelationshipAnimationService] 动画正在播放中，跳过本次请求
I/flutter (29857): [LogManager] Error in appender FileAppender: Bad state: StreamSink is bound to a stream
[AuthService] 用户信息已从服务器刷新
[TencentIMService] ✅ 用户信息刷新成功
[RelationshipAnimationService] 🔄 开始刷新当前页面...
I/flutter (29857): [LogManager] Error in appender FileAppender: Bad state: StreamSink is bound to a stream
[App] ✅ 从本地加载用户头像: https://kissustatic.yuluojishu.com/uploads/2025/12/03/7f9b77cf39aca41b541a5c0321834251.jpg
[App] 📌 未绑定状态，使用加号图标
[RelationshipAnimationService] ✅ 首页数据已刷新
[RelationshipAnimationService] ✅ 页面刷新完成
3
I/flutter (29857): [LogManager] Error in appender FileAppender: Bad state: StreamSink is bound to a stream
[TencentIMService] 🎬 开始播放绑定动画
[RelationshipAnimationService] 动画正在播放中，跳过本次请求
[HTTP] Response: {
         "isSuccess": true,
         "code": 0,
         "msg": "获取用户信息",
         "data": null,
         "dataList": null,
         "dataJson": {
           "register_version": "1.1.5",
           "unique_id": "26e7ced9091949db89a9a5bb8fb47238",
           "is_order_vip": "0",
           "current_mobile_sys": "android",
           "id": 18390,
           "channel_cate_id": "33",
           "province_name": "浙江",
           "login_nums": "1",
           "friend_code": "1018396",
           "device_id": "android-1770896597666",
           "is_give_vip": "0",
           "status": 1,
           "is_check_in": 0,
           "lately_un... (truncated)
I/flutter (29857): SUCCESS:  验证保存成功，数据长度: 2516
I/flutter (29857): [19:49:43.370] [I] [AuthService] 用户信息已更新 | Extra: {userId: 18390, nickname: kissu6888}
I/flutter (29857): [19:49:43.370] [I] [AuthService] 用户信息已从服务器刷新 | Extra: {userId: 18390, nickname: kissu6888, hasToken: true, hasImSign: true}
I/flutter (29857): [19:49:43.370] [D] [TencentIMService] ✅ 用户信息刷新成功
I/flutter (29857): [19:49:43.371] [I] [RelationshipAnimationService] 🔄 开始刷新当前页面...
I/flutter (29857): [19:49:43.371] [D] [App] ✅ 从本地加载用户头像: https://kissustatic.yuluojishu.com/uploads/2025/12/03/7f9b77cf39aca41b541a5c0321834251.jpg
I/flutter (29857): [19:49:43.371] [D] [App] 📌 未绑定状态，使用加号图标
I/flutter (29857): [19:49:43.371] [I] [RelationshipAnimationService] ✅ 首页数据已刷新
I/flutter (29857): [19:49:43.371] [I] [RelationshipAnimationService] ✅ 页面刷新完成
I/flutter (29857): [19:49:43.372] [D] [TencentIMService] 🎬 开始播放绑定动画
I/flutter (29857): [19:49:43.372] [W] [RelationshipAnimationService] 动画正在播放中，跳过本次请求
5
I/flutter (29857): [LogManager] Error in appender FileAppender: Bad state: StreamSink is bound to a stream
[AuthService] 用户信息已更新
[AuthService] 用户信息已从服务器刷新
[TencentIMService] ✅ 用户信息刷新成功
[RelationshipAnimationService] 🔄 开始刷新当前页面...
[App] ✅ 从本地加载用户头像: https://kissustatic.yuluojishu.com/uploads/2025/12/03/7f9b77cf39aca41b541a5c0321834251.jpg
[App] 📌 未绑定状态，使用加号图标
[RelationshipAnimationService] ✅ 首页数据已刷新
[RelationshipAnimationService] ✅ 页面刷新完成
[TencentIMService] 🎬 开始播放绑定动画
[RelationshipAnimationService] 动画正在播放中，跳过本次请求
I/imsdk   (29857): TIM: |-c2c_message_synchronizer.cpp:217        ProcessUnreadMessageInfo                |user_id:b78b45b0f8224b079248fcaf9e1cc303|message_read_timestamp:1770896982|unread_message_count:0|last_update_sequence:3802972025522225152|abstract_message_count:0|concrete_message_count:1
D/ForegroundLocationService(29857): 📍 原生定位成功: 30.274956, 120.220863, 精度: 43.0m
D/ForegroundLocationService(29857): [NativeKeepAlive] 📍 原生定位成功
D/ForegroundLocationService(29857): 定位成功，静默模式（不更新通知）
D/LocationReportService(29857): 📍 距离不足且时间未到，跳过收集: 移动0米 < 50米，距上次收集9秒
[RelationshipAnimationService] 绑定成功动画播放完成，准备关闭对话框
I/flutter (29857): [19:49:46.676] [I] [RelationshipAnimationService] 绑定成功动画播放完成，准备关闭对话框
[GETX] CLOSE DIALOG 829464193
W/WindowOnBackDispatcher(29857): sendCancelIfRunning: isInProgress=false callback=io.flutter.embedding.android.FlutterActivity$1@11bcce2
I/flutter (29857): [19:49:46.784] [I] [RelationshipAnimationService] 对话框已关闭，执行完成回调
I/flutter (29857): [19:49:46.785] [D] [TencentIMService] 🎯 绑定动画播放完成回调被触发
I/flutter (29857): [19:49:46.785] [D] [TencentIMService] 当前用户VIP状态: false
[RelationshipAnimationService] 对话框已关闭，执行完成回调
I/flutter (29857): [19:49:46.785] [D] [TencentIMService] 📍 当前为非会员用户，准备跳转到VIP页面...
[TencentIMService] 🎯 绑定动画播放完成回调被触发
[TencentIMService] 当前用户VIP状态: false
[TencentIMService] 📍 当前为非会员用户，准备跳转到VIP页面...
[GETX] GOING TO ROUTE /kisssu_app/vip
[TencentIMService] ✅ VIP页面跳转已触发，返回值: Instance of 'Future<dynamic>'
I/flutter (29857): [19:49:46.790] [D] [TencentIMService] ✅ VIP页面跳转已触发，返回值: Instance of 'Future<dynamic>'
[GETX] Instance "VipController" has been created
[GETX] Instance "VipController" has been initialized
I/flutter (29857): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (29857): │ #0   VipController._resetControllerState (package:kissu_app/pages/vip/vip_controller.dart:229:13)
vip_controller.dart:229
I/flutter (29857): │ #1   VipController.onReady (package:kissu_app/pages/vip/vip_controller.dart:191:7)
vip_controller.dart:191
I/flutter (29857): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (29857): │ 💡 重置控制器状态
I/flutter (29857): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (29857): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (29857): │ #0   VipController._loadVipBannerData (package:kissu_app/pages/vip/vip_controller.dart:441:15)
vip_controller.dart:441
I/flutter (29857): │ #1   VipController.onReady.<anonymous closure> (package:kissu_app/pages/vip/vip_controller.dart:220:9)
vip_controller.dart:220
I/flutter (29857): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (29857): │ 💡 开始加载VIP横幅和评价数据...
I/flutter (29857): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (29857): [19:49:46.955] [W] [DeviceUtil] DeviceUtil not initialized, using fallback deviceId
I/flutter (29857): [19:49:46.955] [I] [OaidUtil] 开始获取设备ID...
I/flutter (29857): [19:49:46.956] [I] [OaidUtil] 返回缓存的设备ID: 8355f50e...
2
I/flutter (29857): [LogManager] Error in appender FileAppender: Bad state: StreamSink is bound to a stream
I/flutter (29857): INFO: OAID 已添加到请求头
I/flutter (29857): INFO: ========== Request Headers ==========
I/flutter (29857): INFO: URL: https://service-api.ikissu.cn/v4/pay/iconBanner
I/flutter (29857): INFO: Method: GET
I/flutter (29857): INFO: --- Business Headers ---
I/flutter (29857): INFO: token: eyJ0eXAiOiJKV1QiLCJh... (207 chars)
I/flutter (29857): INFO: sign: AB1213B11B2083AD9A2C... (32 chars)
I/flutter (29857): INFO: version: 1.1.5
I/flutter (29857): INFO: channel: kissu_rongyao
I/flutter (29857): INFO: pkg: com.yuluo.kissu
I/flutter (29857): INFO: os: 1
I/flutter (29857): INFO: network-name: wifi_YuluoKeji_5G
I/flutter (29857): INFO: deviceid: android-1770896986955
I/flutter (29857): INFO: mobile-model: Xiaomi 23127PN0CC
I/flutter (29857): INFO: power: 30
I/flutter (29857): INFO: is-open-location: 1
I/flutter (29857): INFO: brand: Xiaomi
I/flutter (29857): INFO: oaid: 8355f50e457c2989
I/flutter (29857): INFO: --- Other Headers ---
I/flutter (29857): INFO: network_debounce: true
I/flutter (29857): INFO: timestamp: 1770896986956
I/flutter (29857): INFO: =====================================
I/flutter (29857): [19:49:46.959] [W] [DeviceUtil] DeviceUtil not initialized, using fallback deviceId
I/flutter (29857): [19:49:46.959] [I] [OaidUtil] 开始获取设备ID...
I/flutter (29857): [19:49:46.959] [I] [OaidUtil] 返回缓存的设备ID: 8355f50e...
3
I/flutter (29857): [LogManager] Error in appender FileAppender: Bad state: StreamSink is bound to a stream
I/flutter (29857): INFO: OAID 已添加到请求头
[DeviceUtil] DeviceUtil not initialized, using fallback deviceId
[OaidUtil] 开始获取设备ID...
[OaidUtil] 返回缓存的设备ID: 8355f50e...
I/flutter (29857): INFO: ========== Request Headers ==========
I/flutter (29857): INFO: URL: https://service-api.ikissu.cn/get/vipPackageList?os=1
I/flutter (29857): INFO: Method: GET
I/flutter (29857): INFO: --- Business Headers ---
I/flutter (29857): INFO: token: eyJ0eXAiOiJKV1QiLCJh... (207 chars)
I/flutter (29857): INFO: sign: 323F5EC72EB6CD4BBB35... (32 chars)
I/flutter (29857): INFO: version: 1.1.5
I/flutter (29857): INFO: channel: kissu_rongyao
I/flutter (29857): INFO: pkg: com.yuluo.kissu
I/flutter (29857): INFO: os: 1
I/flutter (29857): INFO: network-name: wifi_YuluoKeji_5G
I/flutter (29857): INFO: deviceid: android-1770896986959
I/flutter (29857): INFO: mobile-model: Xiaomi 23127PN0CC
I/flutter (29857): INFO: power: 30
I/flutter (29857): INFO: is-open-location: 1
I/flutter (29857): INFO: brand: Xiaomi
I/flutter (29857): INFO: oaid: 8355f50e457c2989
I/flutter (29857): INFO: --- Other Headers ---
I/flutter (29857): INFO: network_debounce: true
I/flutter (29857): INFO: timestamp: 1770896986960
I/flutter (29857): INFO: =====================================
[DeviceUtil] DeviceUtil not initialized, using fallback deviceId
[OaidUtil] 开始获取设备ID...
[OaidUtil] 返回缓存的设备ID: 8355f50e...
I/flutter (29857): [19:49:46.975] [D] [HTTP] GET https://service-api.ikissu.cn/v4/pay/iconBanner
I/flutter (29857): [19:49:46.975] [D] [HTTP] Headers: {network_debounce: true, token: ***HIDDEN***, version: 1.1.5, pkg: com.yuluo.kissu, os: 1, deviceid: android-1770896986955, oaid: 8355f50e457c2989, mobile-model: Xiaomi 23127PN0CC, brand: Xiaomi, is-open-location: 1, channel: kissu_rongyao, network-name: wifi_YuluoKeji_5G, power: 30, timestamp: 1770896986956, sign: AB1213B11B2083AD9A2CDA6CD94C6C3F}
I/flutter (29857): [19:49:46.975] [D] [HTTP] GET https://service-api.ikissu.cn/get/vipPackageList?os=1
I/flutter (29857): [19:49:46.975] [D] [HTTP] Headers: {network_debounce: true, token: ***HIDDEN***, version: 1.1.5, pkg: com.yuluo.kissu, os: 1, deviceid: android-1770896986959, oaid: 8355f50e457c2989, mobile-model: Xiaomi 23127PN0CC, brand: Xiaomi, is-open-location: 1, channel: kissu_rongyao, network-name: wifi_YuluoKeji_5G, power: 30, timestamp: 1770896986960, sign: 323F5EC72EB6CD4BBB35DF39109BA114}
[HTTP] GET https://service-api.ikissu.cn/v4/pay/iconBanner
[HTTP] GET https://service-api.ikissu.cn/get/vipPackageList?os=1
[HTTP] Headers: {network_debounce: true, token: ***HIDDEN***, version: 1.1.5, pkg: com.yuluo.kissu, os: 1, deviceid: android-1770896986955, oaid: 8355f50e457c2989, mobile-model: Xiaomi 23127PN0CC, brand: Xiaomi, is-open-location: 1, channel: kissu_rongyao, network-name: wifi_YuluoKeji_5G, power: 30, timestamp: 1770896986956, sign: AB1213B11B2083AD9A2CDA6CD94C6C3F}
[HTTP] Headers: {network_debounce: true, token: ***HIDDEN***, version: 1.1.5, pkg: com.yuluo.kissu, os: 1, deviceid: android-1770896986959, oaid: 8355f50e457c2989, mobile-model: Xiaomi 23127PN0CC, brand: Xiaomi, is-open-location: 1, channel: kissu_rongyao, network-name: wifi_YuluoKeji_5G, power: 30, timestamp: 1770896986960, sign: 323F5EC72EB6CD4BBB35DF39109BA114}
I/flutter (29857): [19:49:47.085] [I] [HTTP] 200 GET https://service-api.ikissu.cn/v4/pay/iconBanner (110ms)
[HTTP] 200 GET https://service-api.ikissu.cn/v4/pay/iconBanner (110ms)
I/flutter (29857): [19:49:47.091] [D] [HTTP] Response: {
I/flutter (29857):   "isSuccess": true,
I/flutter (29857):   "code": 0,
I/flutter (29857):   "msg": "",
I/flutter (29857):   "data": null,
I/flutter (29857):   "dataList": null,
I/flutter (29857):   "dataJson": {
I/flutter (29857):     "comment_list": [
I/flutter (29857):       {
I/flutter (29857):         "date": "02月12日",
I/flutter (29857):         "nickname": "嘟噜噜",
I/flutter (29857):         "content": "让恋爱更有仪式感的小工具，我们都超爱！已经安利给身边所有情侣朋友了！",
I/flutter (29857):         "avatar": "https://kissustatic.yuluojishu.com/uploads/2025/11/12/5c2f222276748148038a2ada2d18c5d7.png",
I/flutter (29857):         "vip_icon": "https://kissustatic.yuluojishu.com/uploads/2025/11/12/4cddff093726fd1219fe2dc378a3c2a5.png",
I/flutter (29857):         "star_image": "https://ki... (truncated)
I/flutter (29857): ✅ Request GET /v4/pay/iconBanner - 138ms - Status: 200
I/flutter (29857): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (29857): │ #0   VipController._loadVipBannerData (package:kissu_app/pages/vip/vip_controller.dart:448:17)
vip_controller.dart:448
I/flutter (29857): │ #1   <asynchronous suspension>
I/flutter (29857): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (29857): │ 💡 VIP页面数据加载完成，轮播图数量: 4, 评价数量: 5
I/flutter (29857): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
[HTTP] Response: {
         "isSuccess": true,
         "code": 0,
         "msg": "",
         "data": null,
         "dataList": null,
         "dataJson": {
           "comment_list": [
             {
               "date": "02月12日",
               "nickname": "嘟噜噜",
               "content": "让恋爱更有仪式感的小工具，我们都超爱！已经安利给身边所有情侣朋友了！",
               "avatar": "https://kissustatic.yuluojishu.com/uploads/2025/11/12/5c2f222276748148038a2ada2d18c5d7.png",
               "vip_icon": "https://kissustatic.yuluojishu.com/uploads/2025/11/12/4cddff093726fd1219fe2dc378a3c2a5.png",
               "star_image": "https://ki... (truncated)
[HTTP] 200 GET https://service-api.ikissu.cn/get/vipPackageList?os=1 (208ms)
I/flutter (29857): [19:49:47.184] [I] [HTTP] 200 GET https://service-api.ikissu.cn/get/vipPackageList?os=1 (208ms)
I/flutter (29857): [19:49:47.184] [D] [HTTP] Response: {
I/flutter (29857):   "isSuccess": true,
I/flutter (29857):   "code": 0,
I/flutter (29857):   "msg": "会员套餐列表",
I/flutter (29857):   "data": null,
I/flutter (29857):   "dataList": null,
I/flutter (29857):   "dataJson": null,
I/flutter (29857):   "listJson": [
I/flutter (29857):     {
I/flutter (29857):       "id": 1,
I/flutter (29857):       "title": "双人月度会员",
I/flutter (29857):       "is_double_vip": 1,
I/flutter (29857):       "is_for_ever_vip": 0,
I/flutter (29857):       "vip_price": "29.00",
I/flutter (29857):       "vip_original_price": "49.90",
I/flutter (29857):       "vip_days": 30,
I/flutter (29857):       "product_id": "",
I/flutter (29857):       "is_subscribe": 0,
I/flutter (29857):       "type": 1,
I/flutter (29857):       "is_checked": 0,
I/flutter (29857):       "daily_average_price": "0.96",
I/flutter (29857):       "is_discounts": 0,
I/flutter (29857):       "discounts_img": ""
I/flutter (29857):     },
I/flutter (29857):   ... (truncated)
I/flutter (29857): ✅ Request GET /get/vipPackageList?os=1 - 230ms - Status: 200
I/flutter (29857): 📦 根据 isChecked 字段选择套餐
I/flutter (29857): ✅ 找到 isChecked=1 的套餐: 双人永久会员
[HTTP] Response: {
         "isSuccess": true,
         "code": 0,
         "msg": "会员套餐列表",
         "data": null,
         "dataList": null,
         "dataJson": null,
         "listJson": [
           {
             "id": 1,
             "title": "双人月度会员",
             "is_double_vip": 1,
             "is_for_ever_vip": 0,
             "vip_price": "29.00",
             "vip_original_price": "49.90",
             "vip_days": 30,
             "product_id": "",
             "is_subscribe": 0,
             "type": 1,
             "is_checked": 0,
             "daily_average_price": "0.96",
             "is_discounts": 0,
             "discounts_img": ""
           },
         ... (truncated)
[Location] 权限状态更新: 前台=granted, 后台=denied
I/flutter (29857): [19:49:47.886] [D] [Location] 权限状态更新: 前台=granted, 后台=denied
I/flutter (29857): INFO: 定位权限状态缓存已更新: 1
I/MIUIInput(29857): [MotionEvent] ViewRootImpl windowName 'com.yuluo.kissu/com.yuluo.kissu.MainActivityDefault', { action=ACTION_DOWN, id[0]=0, pointerCount=1, eventTime=152780038, downTime=152780038, phoneEventTime=19:49:48.263 } moveCount:0
D/VRI[MainActivityDefault](29857): getMiuiFreeformStackInfo mTmpFrames.miuiFreeFormStackInfo: null
I/MIUIInput(29857): [MotionEvent] ViewRootImpl windowName 'com.yuluo.kissu/com.yuluo.kissu.MainActivityDefault', { action=ACTION_UP, id[0]=0, pointerCount=1, eventTime=152780096, downTime=152780038, phoneEventTime=19:49:48.322 } moveCount:0
I/MIUIInput(29857): [MotionEvent] ViewRootImpl windowName 'com.yuluo.kissu/com.yuluo.kissu.MainActivityDefault', { action=ACTION_DOWN, id[0]=0, pointerCount=1, eventTime=152780623, downTime=152780623, phoneEventTime=19:49:48.849 } moveCount:0
D/VRI[MainActivityDefault](29857): getMiuiFreeformStackInfo mTmpFrames.miuiFreeFormStackInfo: null
I/MIUIInput(29857): [MotionEvent] ViewRootImpl windowName 'com.yuluo.kissu/com.yuluo.kissu.MainActivityDefault', { action=ACTION_UP, id[0]=0, pointerCount=1, eventTime=152780673, downTime=152780623, phoneEventTime=19:49:48.899 } moveCount:0
I/flutter (29857): 📊 构建埋点参数，当前虚拟用户ID: 8355f50e457c2989
I/flutter (29857): 📊 记录事件: vip_page_reback_exposure_popup_event, 队列长度: 1
I/MIUIInput(29857): [MotionEvent] ViewRootImpl windowName 'com.yuluo.kissu/com.yuluo.kissu.MainActivityDefault', { action=ACTION_DOWN, id[0]=0, pointerCount=1, eventTime=152781535, downTime=152781535, phoneEventTime=19:49:49.761 } moveCount:0
D/VRI[MainActivityDefault](29857): getMiuiFreeformStackInfo mTmpFrames.miuiFreeFormStackInfo: null
I/MIUIInput(29857): [MotionEvent] ViewRootImpl windowName 'com.yuluo.kissu/com.yuluo.kissu.MainActivityDefault', { action=ACTION_UP, id[0]=0, pointerCount=1, eventTime=152781601, downTime=152781535, phoneEventTime=19:49:49.826 } moveCount:0
I/flutter (29857): 📊 构建埋点参数，当前虚拟用户ID: 8355f50e457c2989
I/flutter (29857): 📊 记录事件: vip_page_reback_popup_event, 队列长度: 2
[GETX] CLOSE TO ROUTE /kisssu_app/vip
W/WindowOnBackDispatcher(29857): sendCancelIfRunning: isInProgress=false callback=io.flutter.embedding.android.FlutterActivity$1@11bcce2
D/ForegroundLocationService(29857): 📍 原生定位成功: 30.274956, 120.220863, 精度: 43.0m
D/ForegroundLocationService(29857): [NativeKeepAlive] 📍 原生定位成功
D/ForegroundLocationService(29857): 定位成功，静默模式（不更新通知）
D/LocationReportService(29857): 📍 距离不足且时间未到，跳过收集: 移动0米 < 50米，距上次收集14秒
I/flutter (29857): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (29857): │ #0   VipController.onClose (package:kissu_app/pages/vip/vip_controller.dart:307:13)
vip_controller.dart:307
I/flutter (29857): │ #1   GetLifeCycleBase._onDelete (package:get/get_instance/src/lifecycle.dart:79:5)
lifecycle.dart:79
I/flutter (29857): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (29857): │ 💡 📦 VipController onClose 被调用
I/flutter (29857): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (29857): 📊 构建埋点参数，当前虚拟用户ID: 8355f50e457c2989
I/flutter (29857): 📊 记录事件: vip_page_event, 队列长度: 3
[GETX] "VipController" onDelete() called
I/flutter (29857): 📊 开始上报事件，数量: 3
I/flutter (29857): 📊 上报数据: {"point_data":[{"event_id":"vip_page_reback_exposure_popup_event","page_id":"vip_page","device_id":"8355f50e457c2989","vip_status":0,"bind_status":2,"bind_num":1,"is_check_in":0,"page_enter_time":1770896988},{"event_id":"vip_page_reback_popup_event","page_id":"vip_page","device_id":"8355f50e457c2989","vip_status":0,"bind_status":2,"bind_num":1,"is_check_in":0,"click_time":1770896989,"btn_status":0},{"event_id":"vip_page_event","page_id":"vip_page","device_id":"8355f50e457c2989","vip_status":0,"bind_status":2,"bind_num":1,"is_check_in":0,"page_enter_time":1770896986,"page_duration":4,"source_page":"home_page","source_event":"bind_page","exit_type":1,"page_scroll_num":0}]}
[DeviceUtil] DeviceUtil not initialized, using fallback deviceId
I/flutter (29857): [19:49:52.381] [W] [DeviceUtil] DeviceUtil not initialized, using fallback deviceId
I/flutter (29857): [19:49:52.381] [I] [OaidUtil] 开始获取设备ID...
I/flutter (29857): [19:49:52.381] [I] [OaidUtil] 返回缓存的设备ID: 8355f50e...
2
I/flutter (29857): [LogManager] Error in appender FileAppender: Bad state: StreamSink is bound to a stream
I/flutter (29857): INFO: OAID 已添加到请求头
I/flutter (29857): INFO: ========== Request Headers ==========
[OaidUtil] 开始获取设备ID...
[OaidUtil] 返回缓存的设备ID: 8355f50e...
I/flutter (29857): INFO: URL: https://service-api.ikissu.cn/upload/point
I/flutter (29857): INFO: Method: POST
I/flutter (29857): INFO: --- Business Headers ---
I/flutter (29857): INFO: token: eyJ0eXAiOiJKV1QiLCJh... (207 chars)
I/flutter (29857): INFO: sign: D79B132B9187EFBC2B04... (32 chars)
I/flutter (29857): INFO: version: 1.1.5
I/flutter (29857): INFO: channel: kissu_rongyao
I/flutter (29857): INFO: pkg: com.yuluo.kissu
I/flutter (29857): INFO: os: 1
I/flutter (29857): INFO: network-name: wifi_YuluoKeji_5G
I/flutter (29857): INFO: deviceid: android-1770896992381
I/flutter (29857): INFO: mobile-model: Xiaomi 23127PN0CC
I/flutter (29857): INFO: power: 30
I/flutter (29857): INFO: is-open-location: 1
I/flutter (29857): INFO: brand: Xiaomi
I/flutter (29857): INFO: oaid: 8355f50e457c2989
I/flutter (29857): INFO: --- Other Headers ---
I/flutter (29857): INFO: network_debounce: true
I/flutter (29857): INFO: content-type: application/json
I/flutter (29857): INFO: timestamp: 1770896992382
I/flutter (29857): INFO: =====================================
I/flutter (29857): [19:49:52.388] [D] [HTTP] POST https://service-api.ikissu.cn/upload/point