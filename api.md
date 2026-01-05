20022): Starting input: Bind result=InputBindResult{result=SUCCESS_WITH_IME_SESSION method=com.android.internal.inputmethod.IInputMethodSession$Stub$Proxy@1e0ed2a id=com.baidu.input_hihonor/com.baidu.input_honor.ImeService sequence=1256 result=0 isInputMethodSuppressingSpellChecker=false}
I/flutter (20022): [LogManager] Not initialized. Message: GET https://service-api.ikissu.cn/v4/get/unbind/reason
I/flutter (20022): [LogManager] Not initialized. Message: Headers: {network_debounce: true, token: ***HIDDEN***, version: 1.1.1, pkg: com.yuluo.kissu, deviceid: android-1767611465471, oaid: 18887152-1202-4a74-9d32-2b825f7d3d73, mobile-model: HONOR ALI-AN00, brand: HONOR, is-open-location: 1, channel: kissu_meizu, network-name: wifi_YuluoKeji_5G, power: 71, timestamp: 1767611465471, sign: C8A879ECCE1F33401C293B0F3F6D5BCA}
I/flutter (20022): [LogManager] Not initialized. Message: 200 GET https://service-api.ikissu.cn/v4/get/unbind/reason (114ms)
I/flutter (20022): [LogManager] Not initialized. Message: Response: {
I/flutter (20022):   "isSuccess": true,
I/flutter (20022):   "code": 0,
I/flutter (20022):   "msg": "解绑原因",
I/flutter (20022):   "data": null,
I/flutter (20022):   "dataList": null,
I/flutter (20022):   "dataJson": null,
I/flutter (20022):   "listJson": [
I/flutter (20022):     {
I/flutter (20022):       "id": 1,
I/flutter (20022):       "reason": "两人已分手",
I/flutter (20022):       "is_require_reason": 0
I/flutter (20022):     },
I/flutter (20022):     {
I/flutter (20022):       "id": 2,
I/flutter (20022):       "reason": "用户隐私安全",
I/flutter (20022):       "is_require_reason": 0
I/flutter (20022):     },
I/flutter (20022):     {
I/flutter (20022):       "id": 3,
I/flutter (20022):       "reason": "App功能单一",
I/flutter (20022):       "is_require_reason": 0
I/flutter (20022):     },
I/flutter (20022):     {
I/flutter (20022):       "id": 4,
I/flutter (20022):       "reason": "App bug多",
I/flutter (20022):       "is_require_reason": 0
I/flutter (20022):     },
I/flutter (20022):     {
I/flutter (20022):       "id": 5,
I/flutter (20022):       "reason": "App... (truncated)
I/flutter (20022): ✅ Request GET /v4/get/unbind/reason - 149ms - Status: 200
[GETX] OPEN DIALOG 554365584
I/flutter (20022): [LogManager] Not initialized. Message: 全局监听器收到定位数据: {callbackTime: 2026-01-05 19:11:05, locationTime: 2026-01-05 19:07:45, locationType: 2, latitude: 30.275057, longitude: 120.220761, accuracy: 39.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 上城区, street: 运河东路, streetNumber: 301号, cityCode: 0571, adCode: 330102, address: 浙江省杭州市上城区运河东路301号靠近中豪·湘和国际, description: 在中豪·湘和国际附近}
I/flutter (20022): [LogManager] Not initialized. Message: 完整定位数据: {callbackTime: 2026-01-05 19:11:05, locationTime: 2026-01-05 19:07:45, locationType: 2, latitude: 30.275057, longitude: 120.220761, accuracy: 39.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 上城区, street: 运河东路, streetNumber: 301号, cityCode: 0571, adCode: 330102, address: 浙江省杭州市上城区运河东路301号靠近中豪·湘和国际, description: 在中豪·湘和国际附近}
D/ForegroundLocationService(20022): 📍 原生定位成功: 30.275057, 120.220761, 精度: 39.0m
D/ForegroundLocationService(20022): 定位成功，静默模式（不更新通知）
D/LocationReportService(20022): 📍 距离不足且时间未到，跳过收集: 移动0米 < 50米，距上次收集55秒
D/LocationReportService(20022): ⏰ 执行定时上报，位置数量: 1
D/LocationReportService(20022): 🚀 开始上报定位数据
D/LocationReportService(20022): 📡 API地址: https://service-api.ikissu.cn/location/report
D/LocationReportService(20022): 📦 上报数据: [{"longitude":"120.220761","latitude":"30.275057","location_time":"1767611411","speed":"0.0","altitude":"0.0","accuracy":"39.0","location_name":"浙江省杭州市上城区运河东路301号靠近中豪·湘和国际"}]
D/LocationReportService(20022): 🔐 签名已生成: E88AAE73FAE71731DE4C7053FD2500ED
I/HiTouch_PressGestureDetector(20022): checkDoublePointerLimit: false
D/LocationReportService(20022): 📡 HTTP响应码: 200
D/LocationReportService(20022): 📡 服务器响应: {"code":0,"msg":"位置上报成功","time":1767611467,"data":{}}
D/LocationReportService(20022): ✅ 定位上报成功
D/LocationReportService(20022): ✅ 定时上报成功，缓冲区已清空
I/flutter (20022): [LogManager] Not initialized. Message: CustomToast: Failed to get overlay from context: No Overlay widget found.
I/flutter (20022): Some widgets require an Overlay widget ancestor for correct operation.
I/flutter (20022): The most common way to add an Overlay to an application is to include a MaterialApp, CupertinoApp or Navigator widget in the runApp() call.
I/flutter (20022): The context from which that widget was searching for an overlay was:
I/flutter (20022):   Navigator-[LabeledGlobalKey<NavigatorState>#3088f Key Created by default]
I/flutter (20022): [LogManager] Not initialized. Message: CustomToast: Failed to get root overlay: No Overlay widget found.
I/flutter (20022): Some widgets require an Overlay widget ancestor for correct operation.
I/flutter (20022): The most common way to add an Overlay to an application is to include a MaterialApp, CupertinoApp or Navigator widget in the runApp() call.
I/flutter (20022): The context from which that widget was searching for an overlay was:
I/flutter (20022):   Navigator-[LabeledGlobalKey<NavigatorState>#3088f Key Created by default]
3
I/HiTouch_PressGestureDetector(20022): checkDoublePointerLimit: false
[GETX] CLOSE DIALOG 554365584
I/flutter (20022): [LogManager] Not initialized. Message: DeviceUtil not initialized, using fallback deviceId
I/flutter (20022): INFO: OAID 已添加到请求头
I/flutter (20022): INFO: ========== Request Headers ==========
I/flutter (20022): INFO: URL: https://service-api.ikissu.cn/unbind
I/flutter (20022): INFO: Method: POST
I/flutter (20022): INFO: --- Business Headers ---
I/flutter (20022): INFO: token: eyJ0eXAiOiJKV1QiLCJh... (205 chars)
I/flutter (20022): INFO: sign: 914B8CCB4790FD47BC0A... (32 chars)
I/flutter (20022): INFO: version: 1.1.1
I/flutter (20022): INFO: channel: kissu_meizu
I/flutter (20022): INFO: pkg: com.yuluo.kissu
I/flutter (20022): INFO: network-name: wifi_YuluoKeji_5G
I/flutter (20022): INFO: deviceid: android-1767611470448
I/flutter (20022): INFO: mobile-model: HONOR ALI-AN00
I/flutter (20022): INFO: power: 71
I/flutter (20022): INFO: is-open-location: 1
I/flutter (20022): INFO: brand: HONOR
I/flutter (20022): INFO: oaid: 18887152-1202-4a74-9d32-2b825f7d3d73
I/flutter (20022): INFO: --- Other Headers ---
I/flutter (20022): INFO: network_debounce: true
I/flutter (20022): INFO: content-type: application/json
I/flutter (20022): INFO: timestamp: 1767611470448
I/flutter (20022): INFO: =====================================
I/flutter (20022): [LogManager] Not initialized. Message: POST https://service-api.ikissu.cn/unbind
I/flutter (20022): [LogManager] Not initialized. Message: Headers: {network_debounce: true, content-type: application/json, token: ***HIDDEN***, version: 1.1.1, pkg: com.yuluo.kissu, deviceid: android-1767611470448, oaid: 18887152-1202-4a74-9d32-2b825f7d3d73, mobile-model: HONOR ALI-AN00, brand: HONOR, is-open-location: 1, channel: kissu_meizu, network-name: wifi_YuluoKeji_5G, power: 71, timestamp: 1767611470448, sign: 914B8CCB4790FD47BC0A5B9BB53BAA20}
I/flutter (20022): [LogManager] Not initialized. Message: Request: {
I/flutter (20022):   "reason_id": 2
I/flutter (20022): }
I/flutter (20022): [LogManager] Not initialized. Message: 全局监听器收到定位数据: {callbackTime: 2026-01-05 19:11:10, locationTime: 2026-01-05 19:07:45, locationType: 2, latitude: 30.275057, longitude: 120.220761, accuracy: 39.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 上城区, street: 运河东路, streetNumber: 301号, cityCode: 0571, adCode: 330102, address: 浙江省杭州市上城区运河东路301号靠近中豪·湘和国际, description: 在中豪·湘和国际附近}
I/flutter (20022): [LogManager] Not initialized. Message: 完整定位数据: {callbackTime: 2026-01-05 19:11:10, locationTime: 2026-01-05 19:07:45, locationType: 2, latitude: 30.275057, longitude: 120.220761, accuracy: 39.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 上城区, street: 运河东路, streetNumber: 301号, cityCode: 0571, adCode: 330102, address: 浙江省杭州市上城区运河东路301号靠近中豪·湘和国际, description: 在中豪·湘和国际附近}
I/imsdk   (20022): TIM: |-friend_notify_handler.cpp:53            OnReceiveRelationshipNotifyMessage      |message_source:receive message|message:
I/imsdk   (20022): message_type:c2c|message_sub_type:0x20
I/imsdk   (20022): sender_user_id:4a5b10af720f47389e40bb7981e28596|receiver_user_id:4a5b10af720f47389e40bb7981e28596
I/imsdk   (20022): client_time:1767611470|server_time:1767611470|sequence:6464114|random:1617578075
I/imsdk   (20022): message_status:success|IsOnlineOnly:false|platform:Other
I/imsdk   (20022): message_elements:
I/imsdk   (20022): [friendship_change] friendship_change_type:delete from friend list
I/imsdk   (20022):                     friend_del_user_id_list:cb32a838eb744994a78c8525ff57d8f6 
I/imsdk   (20022): 
I/flutter (20022): [LogManager] Not initialized. Message: 📨 检测到好友删除事件
I/flutter (20022): [LogManager] Not initialized. Message: 删除好友: userID=cb32a838eb744994a78c8525ff57d8f6
I/flutter (20022): [LogManager] Not initialized. Message: 💔 检测到好友删除事件，执行解绑逻辑
I/flutter (20022): [LogManager] Not initialized. Message: 📥 开始刷新用户信息...
I/flutter (20022): [LogManager] Not initialized. Message: DeviceUtil not initialized, using fallback deviceId
I/flutter (20022): INFO: OAID 已添加到请求头
I/flutter (20022): INFO: ========== Request Headers ==========
I/flutter (20022): INFO: URL: https://service-api.ikissu.cn/get/user
I/flutter (20022): INFO: Method: GET
I/flutter (20022): INFO: --- Business Headers ---
I/flutter (20022): INFO: token: eyJ0eXAiOiJKV1QiLCJh... (205 chars)
I/flutter (20022): INFO: sign: E91497232BF157E381B0... (32 chars)
I/flutter (20022): INFO: version: 1.1.1
I/flutter (20022): INFO: channel: kissu_meizu
I/flutter (20022): INFO: pkg: com.yuluo.kissu
I/flutter (20022): INFO: network-name: wifi_YuluoKeji_5G
I/flutter (20022): INFO: deviceid: android-1767611471123
I/flutter (20022): INFO: mobile-model: HONOR ALI-AN00
I/flutter (20022): INFO: power: 71
I/flutter (20022): INFO: is-open-location: 1
I/flutter (20022): INFO: brand: HONOR
I/flutter (20022): INFO: oaid: 18887152-1202-4a74-9d32-2b825f7d3d73
I/flutter (20022): INFO: --- Other Headers ---
I/flutter (20022): INFO: network_debounce: true
I/flutter (20022): INFO: timestamp: 1767611471124
I/flutter (20022): INFO: =====================================
I/flutter (20022): [LogManager] Not initialized. Message: 200 POST https://service-api.ikissu.cn/unbind (678ms)
I/flutter (20022): [LogManager] Not initialized. Message: Response: {
I/flutter (20022):   "isSuccess": true,
I/flutter (20022):   "code": 0,
I/flutter (20022):   "msg": "解绑成功",
I/flutter (20022):   "data": null,
I/flutter (20022):   "dataList": null,
I/flutter (20022):   "dataJson": {},
I/flutter (20022):   "listJson": null
I/flutter (20022): }
I/flutter (20022): ✅ Request POST /unbind - 689ms - Status: 200
I/flutter (20022): [LogManager] Not initialized. Message: GET https://service-api.ikissu.cn/get/user
I/flutter (20022): [LogManager] Not initialized. Message: Headers: {network_debounce: true, token: ***HIDDEN***, version: 1.1.1, pkg: com.yuluo.kissu, deviceid: android-1767611471123, oaid: 18887152-1202-4a74-9d32-2b825f7d3d73, mobile-model: HONOR ALI-AN00, brand: HONOR, is-open-location: 1, channel: kissu_meizu, network-name: wifi_YuluoKeji_5G, power: 71, timestamp: 1767611471124, sign: E91497232BF157E381B0EA889A3D8DA8}
I/flutter (20022): [LogManager] Not initialized. Message: DeviceUtil not initialized, using fallback deviceId
I/flutter (20022): INFO: OAID 已添加到请求头
I/flutter (20022): INFO: ========== Request Headers ==========
I/flutter (20022): INFO: URL: https://service-api.ikissu.cn/get/user
I/flutter (20022): INFO: Method: GET
I/flutter (20022): INFO: --- Business Headers ---
I/flutter (20022): INFO: token: eyJ0eXAiOiJKV1QiLCJh... (205 chars)
I/flutter (20022): INFO: sign: B001780AB0BDAFDCAEA6... (32 chars)
I/flutter (20022): INFO: version: 1.1.1
I/flutter (20022): INFO: channel: kissu_meizu
I/flutter (20022): INFO: pkg: com.yuluo.kissu
I/flutter (20022): INFO: network-name: wifi_YuluoKeji_5G
I/flutter (20022): INFO: deviceid: android-1767611471134
I/flutter (20022): INFO: mobile-model: HONOR ALI-AN00
I/flutter (20022): INFO: power: 71
I/flutter (20022): INFO: is-open-location: 1
I/flutter (20022): INFO: brand: HONOR
I/flutter (20022): INFO: oaid: 18887152-1202-4a74-9d32-2b825f7d3d73
I/flutter (20022): INFO: --- Other Headers ---
I/flutter (20022): INFO: network_debounce: true
I/flutter (20022): INFO: timestamp: 1767611471135
I/flutter (20022): INFO: =====================================
D/ForegroundLocationService(20022): 📍 原生定位成功: 30.275057, 120.220761, 精度: 39.0m
D/ForegroundLocationService(20022): 定位成功，静默模式（不更新通知）
D/LocationReportService(20022): 📦 收集池为空，直接放入: 30.275057, 120.220761, 精度: 39.0m
D/LocationReportService(20022): 🔑 读取用户信息: token=已存在(eyJ0eXAiOiJKV1QiLCJh...), userId=8176, baseUrl=https://service-api.ikissu.cn
D/LocationReportService(20022): 📦 位置已收集到缓冲区 (1/12): 30.275057, 120.220761
D/LocationReportService(20022): 📍 最后收集位置已更新: 30.275057, 120.220761
I/flutter (20022): ✅ Request GET /get/user - 154ms - Status: 200
I/flutter (20022): [LogManager] Not initialized. Message: 调用getUserInfo API
I/flutter (20022): INFO:  开始保存用户数据，用户ID: 8176, 数据长度: 2474
I/flutter (20022): SUCCESS:  用户数据保存成功
I/flutter (20022): [LogManager] Not initialized. Message: 200 GET https://service-api.ikissu.cn/get/user (159ms)
I/flutter (20022): [LogManager] Not initialized. Message: Response: {
I/flutter (20022):   "isSuccess": true,
I/flutter (20022):   "code": 0,
I/flutter (20022):   "msg": "获取用户信息",
I/flutter (20022):   "data": null,
I/flutter (20022):   "dataList": null,
I/flutter (20022):   "dataJson": {
I/flutter (20022):     "register_version": "1.1.1",
I/flutter (20022):     "unique_id": "4a5b10af720f47389e40bb7981e28596",
I/flutter (20022):     "is_order_vip": "0",
I/flutter (20022):     "current_mobile_sys": "android",
I/flutter (20022):     "id": 8176,
I/flutter (20022):     "channel_cate_id": "38",
I/flutter (20022):     "province_name": "浙江",
I/flutter (20022):     "login_nums": "1",
I/flutter (20022):     "friend_code": "1008182",
I/flutter (20022):     "device_id": "android-1767608938690",
I/flutter (20022):     "is_give_vip": "0",
I/flutter (20022):     "status": 1,
I/flutter (20022):     "lately_unbind_time": "1767611470... (truncated)
I/flutter (20022): ✅ Request GET /get/user - 183ms - Status: 200
I/flutter (20022): [LogManager] Not initialized. Message: 调用getUserInfo API
I/flutter (20022): INFO:  开始保存用户数据，用户ID: 8176, 数据长度: 2474
I/flutter (20022): SUCCESS:  验证保存成功，数据长度: 2474
I/flutter (20022): [LogManager] Not initialized. Message: 用户信息已更新
I/flutter (20022): [LogManager] Not initialized. Message: 用户信息已从服务器刷新
I/flutter (20022): SUCCESS:  用户数据保存成功
I/flutter (20022): SUCCESS:  验证保存成功，数据长度: 2474
I/flutter (20022): [LogManager] Not initialized. Message: 用户信息已更新
I/flutter (20022): [LogManager] Not initialized. Message: 用户信息已从服务器刷新
I/flutter (20022): [LogManager] Not initialized. Message: ✅ 用户信息刷新成功
I/flutter (20022): [LogManager] Not initialized. Message: 🔄 开始刷新当前页面...
I/flutter (20022): ✅ 从本地加载用户头像: https://kissustatic.yuluojishu.com/uploads/2025/12/03/7f9b77cf39aca41b541a5c0321834251.jpg
I/flutter (20022): 📌 未绑定状态，使用加号图标
I/flutter (20022): [LogManager] Not initialized. Message: ✅ 首页数据已刷新
I/flutter (20022): 👤 我的页面用户信息：
I/flutter (20022):    昵称: kissu2369
I/flutter (20022):    另一半昵称: 小可爱
I/flutter (20022):    绑定状态: false
I/flutter (20022): [LogManager] Not initialized. Message: ✅ 我的页面数据已刷新
I/flutter (20022): [LogManager] Not initialized. Message: ✅ 页面刷新完成
I/flutter (20022): [LogManager] Not initialized. Message: 🎬 开始播放解绑动画
I/flutter (20022): [LogManager] Not initialized. Message: 显示解绑成功动画: assets/gif/unbind_success.gif, 时长: 2秒
[GETX] OPEN DIALOG 1044982533
I/imsdk   (20022): TIM: |-c2c_message_synchronizer.cpp:217        ProcessUnreadMessageInfo                |user_id:4a5b10af720f47389e40bb7981e28596|message_read_timestamp:1767611470|unread_message_count:0|last_update_sequence:0|abstract_message_count:0|concrete_message_count:1
I/flutter (20022): ✅ 从本地加载用户头像: https://kissustatic.yuluojishu.com/uploads/2025/12/03/7f9b77cf39aca41b541a5c0321834251.jpg
I/flutter (20022): 📌 未绑定状态，使用加号图标
I/flutter (20022): [LogManager] Not initialized. Message: ✅ 已刷新首页绑定状态
I/flutter (20022): 👤 我的页面用户信息：
I/flutter (20022):    昵称: kissu2369
I/flutter (20022):    另一半昵称: 小可爱
I/flutter (20022):    绑定状态: false
I/flutter (20022): 👤 我的页面重新获得焦点，静默刷新用户信息
I/flutter (20022): 🔄 我的页面：静默刷新用户信息
I/flutter (20022): 📊 从HomeController获取红点状态: false
I/flutter (20022): [LogManager] Not initialized. Message: ✅ 已刷新"我的"页面数据
I/flutter (20022): [LogManager] Not initialized. Message: 动画正在播放中，跳过本次请求
I/flutter (20022): [LogManager] Not initialized. Message: DeviceUtil not initialized, using fallback deviceId
I/flutter (20022): INFO: OAID 已添加到请求头
I/flutter (20022): INFO: ========== Request Headers ==========
I/flutter (20022): INFO: URL: https://service-api.ikissu.cn/get/user
I/flutter (20022): INFO: Method: GET
I/flutter (20022): INFO: --- Business Headers ---
I/flutter (20022): INFO: token: eyJ0eXAiOiJKV1QiLCJh... (205 chars)
I/flutter (20022): INFO: sign: 446B2FE74F5B6C7632C7... (32 chars)
I/flutter (20022): INFO: version: 1.1.1
I/flutter (20022): INFO: channel: kissu_meizu
I/flutter (20022): INFO: pkg: com.yuluo.kissu
I/flutter (20022): INFO: network-name: wifi_YuluoKeji_5G
I/flutter (20022): INFO: deviceid: android-1767611471415
I/flutter (20022): INFO: mobile-model: HONOR ALI-AN00
I/flutter (20022): INFO: power: 71
I/flutter (20022): INFO: is-open-location: 1
I/flutter (20022): INFO: brand: HONOR
I/flutter (20022): INFO: oaid: 18887152-1202-4a74-9d32-2b825f7d3d73
I/flutter (20022): INFO: --- Other Headers ---
I/flutter (20022): INFO: network_debounce: true
I/flutter (20022): INFO: timestamp: 1767611471415
I/flutter (20022): INFO: =====================================
I/flutter (20022): ❌ Request GET /get/user - 10ms - Status: 210
I/flutter (20022): [LogManager] Not initialized. Message: 调用getUserInfo API
I/flutter (20022): [LogManager] Not initialized. Message: 从服务器刷新用户信息失败
D/UTILS   (20022): Usage permission is not granted
I/flutter (20022): [LogManager] Not initialized. Message: 相册权限检查: PermissionStatus.denied
I/flutter (20022): [LogManager] Not initialized. Message: 权限状态检查完成: 位置=true, 通知=true, 电池=false, 使用情况=false, 防休眠=false, 后台运行指引=false, 锁后台指引=false, 是否小米系=false
I/flutter (20022): [LogManager] Not initialized. Message: 系统权限开关是否全部开启: false
I/flutter (20022): [LogManager] Not initialized. Message: 解绑成功动画播放完成，准备关闭对话框
[GETX] CLOSE DIALOG 1044982533
I/flutter (20022): [LogManager] Not initialized. Message: 对话框已关闭，执行完成回调
I/flutter (20022): [LogManager] Not initialized. Message: 权限状态更新:
I/flutter (20022): [LogManager] Not initialized. Message: 前台定位: granted
I/flutter (20022): [LogManager] Not initialized. Message: 后台定位: denied
I/flutter (20022): INFO: 定位权限状态缓存已更新: 1
I/flutter (20022): [LogManager] Not initialized. Message: 全局监听器收到定位数据: {callbackTime: 2026-01-05 19:11:15, locationTime: 2026-01-05 19:07:45, locationType: 2, latitude: 30.275057, longitude: 120.220761, accuracy: 39.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 上城区, street: 运河东路, streetNumber: 301号, cityCode: 0571, adCode: 330102, address: 浙江省杭州市上城区运河东路301号靠近中豪·湘和国际, description: 在中豪·湘和国际附近}
I/flutter (20022): [LogManager] Not initialized. Message: 完整定位数据: {callbackTime: 2026-01-05 19:11:15, locationTime: 2026-01-05 19:07:45, locationType: 2, latitude: 30.275057, longitude: 120.220761, accuracy: 39.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 上城区, street: 运河东路, streetNumber: 301号, cityCode: 0571, adCode: 330102, address: 浙江省杭州市上城区运河东路301号靠近中豪·湘和国际, description: 在中豪·湘和国际附近}
D/ForegroundLocationService(20022): 📍 原生定位成功: 30.275057, 120.220761, 精度: 39.0m
D/ForegroundLocationService(20022): 定位成功，静默模式（不更新通知）
D/LocationReportService(20022): 📍 距离不足且时间未到，跳过收集: 移动0米 < 50米，距上次收集4秒
I/flutter (20022): [LogManager] Not initialized. Message: 全局监听器收到定位数据: {callbackTime: 2026-01-05 19:11:20, locationTime: 2026-01-05 19:07:45, locationType: 2, latitude: 30.275057, longitude: 120.220761, accuracy: 39.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 上城区, street: 运河东路, streetNumber: 301号, cityCode: 0571, adCode: 330102, address: 浙江省杭州市上城区运河东路301号靠近中豪·湘和国际, description: 在中豪·湘和国际附近}
I/flutter (20022): [LogManager] Not initialized. Message: 完整定位数据: {callbackTime: 2026-01-05 19:11:20, locationTime: 2026-01-05 19:07:45, locationType: 2, latitude: 30.275057, longitude: 120.220761, accuracy: 39.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 上城区, street: 运河东路, streetNumber: 301号, cityCode: 0571, adCode: 330102, address: 浙江省杭州市上城区运河东路301号靠近中豪·湘和国际, description: 在中豪·湘和国际附近}
I/HiTouch_PressGestureDetector(20022): checkDoublePointerLimit: false
[GETX] OPEN DIALOG 569874400
D/ForegroundLocationService(20022): 📍 原生定位成功: 30.275057, 120.220761, 精度: 39.0m
D/ForegroundLocationService(20022): 定位成功，静默模式（不更新通知）
D/LocationReportService(20022): 📍 距离不足且时间未到，跳过收集: 移动0米 < 50米，距上次收集9秒
I/HiTouch_PressGestureDetector(20022): checkDoublePointerLimit: false
[GETX] CLOSE DIALOG 569874400
[GETX] CLOSE TO ROUTE /BreakRelationshipPage
[GETX] "BreakRelationshipController" onDelete() called
[GETX] "BreakRelationshipController" deleted from memory
[GETX] CLOSE TO ROUTE /PrivacySettingPage
I/flutter (20022): [LogManager] Not initialized. Message: 权限状态更新:
I/flutter (20022): [LogManager] Not initialized. Message: 前台定位: granted
I/flutter (20022): [LogManager] Not initialized. Message: 后台定位: denied
I/flutter (20022): INFO: 定位权限状态缓存已更新: 1
I/flutter (20022): [LogManager] Not initialized. Message: 全局监听器收到定位数据: {callbackTime: 2026-01-05 19:11:25, locationTime: 2026-01-05 19:07:45, locationType: 2, latitude: 30.275057, longitude: 120.220761, accuracy: 39.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 上城区, street: 运河东路, streetNumber: 301号, cityCode: 0571, adCode: 330102, address: 浙江省杭州市上城区运河东路301号靠近中豪·湘和国际, description: 在中豪·湘和国际附近}
I/flutter (20022): [LogManager] Not initialized. Message: 完整定位数据: {callbackTime: 2026-01-05 19:11:25, locationTime: 2026-01-05 19:07:45, locationType: 2, latitude: 30.275057, longitude: 120.220761, accuracy: 39.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 上城区, street: 运河东路, streetNumber: 301号, cityCode: 0571, adCode: 330102, address: 浙江省杭州市上城区运河东路301号靠近中豪·湘和国际, description: 在中豪·湘和国际附近}
D/ForegroundLocationService(20022): 📍 原生定位成功: 30.275057, 120.220761, 精度: 39.0m
D/ForegroundLocationService(20022): 定位成功，静默模式（不更新通知）
D/LocationReportService(20022): 📍 距离不足且时间未到，跳过收集: 移动0米 < 50米，距上次收集15秒
I/flutter (20022): [LogManager] Not initialized. Message: 全局监听器收到定位数据: {callbackTime: 2026-01-05 19:11:30, locationTime: 2026-01-05 19:07:45, locationType: 2, latitude: 30.275057, longitude: 120.220761, accuracy: 39.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 上城区, street: 运河东路, streetNumber: 301号, cityCode: 0571, adCode: 330102, address: 浙江省杭州市上城区运河东路301号靠近中豪·湘和国际, description: 在中豪·湘和国际附近}
I/flutter (20022): [LogManager] Not initialized. Message: 完整定位数据: {callbackTime: 2026-01-05 19:11:30, locationTime: 2026-01-05 19:07:45, locationType: 2, latitude: 30.275057, longitude: 120.220761, accuracy: 39.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 上城区, street: 运河东路, streetNumber: 301号, cityCode: 0571, adCode: 330102, address: 浙江省杭州市上城区运河东路301号靠近中豪·湘和国际, description: 在中豪·湘和国际附近}
D/ForegroundLocationService(20022): 📍 原生定位成功: 30.275057, 120.220761, 精度: 39.0m
D/ForegroundLocationService(20022): 定位成功，静默模式（不更新通知）
D/LocationReportService(20022): 📍 距离不足且时间未到，跳过收集: 移动0米 < 50米，距上次收集20秒
I/flutter (20022): [LogManager] Not initialized. Message: 权限状态更新:
I/flutter (20022): [LogManager] Not initialized. Message: 前台定位: granted
I/flutter (20022): [LogManager] Not initialized. Message: 后台定位: denied
I/flutter (20022): INFO: 定位权限状态缓存已更新: 1
I/flutter (20022): [LogManager] Not initialized. Message: 全局监听器收到定位数据: {callbackTime: 2026-01-05 19:11:35, locationTime: 2026-01-05 19:07:45, locationType: 2, latitude: 30.275057, longitude: 120.220761, accuracy: 39.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 上城区, street: 运河东路, streetNumber: 301号, cityCode: 0571, adCode: 330102, address: 浙江省杭州市上城区运河东路301号靠近中豪·湘和国际, description: 在中豪·湘和国际附近}
I/flutter (20022): [LogManager] Not initialized. Message: 完整定位数据: {callbackTime: 2026-01-05 19:11:35, locationTime: 2026-01-05 19:07:45, locationType: 2, latitude: 30.275057, longitude: 120.220761, accuracy: 39.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 上城区, street: 运河东路, streetNumber: 301号, cityCode: 0571, adCode: 330102, address: 浙江省杭州市上城区运河东路301号靠近中豪·湘和国际, description: 在中豪·湘和国际附近}
D/ForegroundLocationService(20022): 📍 原生定位成功: 30.275057, 120.220761, 精度: 39.0m
D/ForegroundLocationService(20022): 定位成功，静默模式（不更新通知）
D/LocationReportService(20022): 📍 距离不足且时间未到，跳过收集: 移动0米 < 50米，距上次收集25秒
I/flutter (20022): [LogManager] Not initialized. Message: 全局监听器收到定位数据: {callbackTime: 2026-01-05 19:11:40, locationTime: 2026-01-05 19:07:45, locationType: 2, latitude: 30.275057, longitude: 120.220761, accuracy: 39.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 上城区, street: 运河东路, streetNumber: 301号, cityCode: 0571, adCode: 330102, address: 浙江省杭州市上城区运河东路301号靠近中豪·湘和国际, description: 在中豪·湘和国际附近}
I/flutter (20022): [LogManager] Not initialized. Message: 完整定位数据: {callba