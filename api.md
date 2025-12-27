vice(16306): ! 没有使用情况访问权限，无法采集数据
I/flutter (16306): 🔍 检查VIP推广标识: false
I/flutter (16306): ℹ️ 无需显示VIP推广弹窗
I/flutter (16306): [LogManager] Not initialized. Message: 200 GET http://dev-love-api.ikissu.cn/version/checkVersion (309ms)
I/flutter (16306): [LogManager] Not initialized. Message: Response: {
I/flutter (16306):   "isSuccess": true,
I/flutter (16306):   "code": 0,
I/flutter (16306):   "msg": "版本检测",
I/flutter (16306):   "data": null,
I/flutter (16306):   "dataList": null,
I/flutter (16306):   "dataJson": {
I/flutter (16306):     "upgrade_type": 0,
I/flutter (16306):     "version": "",
I/flutter (16306):     "version_num": 0,
I/flutter (16306):     "content_txt": "",
I/flutter (16306):     "url": ""
I/flutter (16306):   },
I/flutter (16306):   "listJson": null
I/flutter (16306): }
I/flutter (16306): ✅ Request GET /version/checkVersion - 1288ms - Status: 200
I/flutter (16306): ✅ 版本检查完成
I/flutter (16306): [LogManager] Not initialized. Message: 200 GET http://dev-love-api.ikissu.cn/get/location (363ms)
I/flutter (16306): [LogManager] Not initialized. Message: Response: {
I/flutter (16306):   "isSuccess": true,
I/flutter (16306):   "code": 0,
I/flutter (16306):   "msg": "",
I/flutter (16306):   "data": null,
I/flutter (16306):   "dataList": null,
I/flutter (16306):   "dataJson": {
I/flutter (16306):     "user_location_mobile_device": {
I/flutter (16306):       "power": "3%",
I/flutter (16306):       "network_name": "wifi_YuluoKeji_5G",
I/flutter (16306):       "mobile_model": "HUAWEI",
I/flutter (16306):       "is_wifi": "0",
I/flutter (16306):       "longitude": "120.22071923152217",
I/flutter (16306):       "location": "浙江省杭州市上城区运河东路301号靠近中豪·湘和国际 附近",
I/flutter (16306):       "real_speed": "2.87",
I/flutter (16306):       "speed": "3m/s",
I/flutter (16306):       "latitude": "30.27504608948789",
I/flutter (16306):       "location_time": "1766846599",
I/flutter (16306):       "calculate_location... (truncated)
I/flutter (16306): ✅ Request GET /get/location - 2574ms - Status: 200
I/flutter (16306): CHECK: API原始JSON数据:
I/flutter (16306): CHECK:   JSON keys: [user_location_mobile_device, half_location_mobile_device, user]
I/flutter (16306): CHECK:   user_location_mobile_device keys: [power, network_name, mobile_model, is_wifi, longitude, location, real_speed, speed, latitude, location_time, calculate_location_time, is_open_location, is_oneself, distance, stops, stay_collect, head_portrait, face]
I/flutter (16306): CHECK:   user_location_mobile_device stops: [{latitude: 30.274932, longitude: 120.220766, location_name: 浙江省杭州市上城区四季青街道运河东路中豪·湘和国际 附近, start_time: 当前, end_time: , duration: 1小时47分钟, duration_int: 6458, status: staying, point_type: stop, serial_number: 3}, {latitude: 30.27654074591645, longitude: 120.22015721327992, location_name: 浙江省杭州市上城区四季青街道可霖臻民宿(杭州东站店)中豪·湘和国际 附近, start_time: 20:38, end_time: 20:58, duration: 20分钟36秒, duration_int: 1236, status: ended, point_type: stop, serial_number: 2}, {latitude: 30.27505, longitude: 120.220753, location_name: 浙江省杭州市上城区四季青街道运河东路中豪·湘和国际 附近, start_time: 20:16, end_time: 20:38, duration: 21分钟17秒, duration_int: 1277, status: ended, point_type: stop, serial_number: 1}]
I/flutter (16306): CHECK:   half_location_mobile_device keys: [power, network_name, mobile_model, is_wifi, longitude, real_speed, location, speed, latitude, location_time, calculate_location_time, is_open_location, is_oneself, distance, stops, stay_collect, head_portrait, face, online, lives]
I/flutter (16306): CHECK:   half_location_mobile_device stops: [{latitude: 30.274992, longitude: 120.220835, location_name: 浙江省杭州市上城区四季青街道运河东路中豪·湘和国际 附近, start_time: 当前, end_time: , duration: 19小时4分钟, duration_int: 68657, status: staying, point_type: stop, serial_number: 1}]
I/flutter (16306): 📍 获取到距离信息: <100米
I/flutter (16306): 📍 获取到停留点数量: 1
I/flutter (16306): [LogManager] Not initialized. Message: 200 GET http://dev-love-api.ikissu.cn/get/user (359ms)
I/flutter (16306): [LogManager] Not initialized. Message: Response: {
I/flutter (16306):   "isSuccess": true,
I/flutter (16306):   "code": 0,
I/flutter (16306):   "msg": "获取用户信息",
I/flutter (16306):   "data": null,
I/flutter (16306):   "dataList": null,
I/flutter (16306):   "dataJson": {
I/flutter (16306):     "current_channel": "kissu_wdj",
I/flutter (16306):     "province_name": "浙江",
I/flutter (16306):     "open_app_nums": "0",
I/flutter (16306):     "oaid": "2b774804-8723-451d-af95-fbebb2a4bd84",
I/flutter (16306):     "lover_id": 357,
I/flutter (16306):     "is_give_vip": "0",
I/flutter (16306):     "is_alert_give_vip": "0",
I/flutter (16306):     "register_version": "1.0.1",
I/flutter (16306):     "gender": 1,
I/flutter (16306):     "channel_cate_id": "0",
I/flutter (16306):     "lately_login_time": "1766739987",
I/flutter (16306):     "is_test": "1",
I/flutter (16306):     "channel_id": "0",
I/flutter (16306):     "birthday": "... (truncated)
I/flutter (16306): ✅ Request GET /get/user - 2571ms - Status: 200
I/flutter (16306): [LogManager] Not initialized. Message: 调用getUserInfo API
I/flutter (16306): INFO:  开始保存用户数据，用户ID: 189, 数据长度: 2724
I/flutter (16306): [LogManager] Not initialized. Message: 200 GET http://dev-love-api.ikissu.cn/index (353ms)
I/flutter (16306): [LogManager] Not initialized. Message: Response: {
I/flutter (16306):   "isSuccess": true,
I/flutter (16306):   "code": 0,
I/flutter (16306):   "msg": "",
I/flutter (16306):   "data": null,
I/flutter (16306):   "dataList": null,
I/flutter (16306):   "dataJson": {
I/flutter (16306):     "is_red_dot": 0,
I/flutter (16306):     "is_system_notice_red_dot": 0,
I/flutter (16306):     "is_interaction_notice_red_dot": 0,
I/flutter (16306):     "activity": {
I/flutter (16306):       "is_pop_ads": 0,
I/flutter (16306):       "watch_ads_nums": 0,
I/flutter (16306):       "is_ads_exempt": 0,
I/flutter (16306):       "is_ads_count_down": 0,
I/flutter (16306):       "ads_count_down": 0,
I/flutter (16306):       "is_activity": 1,
I/flutter (16306):       "is_activity_icon": "https://kissustatic.yuluojishu.com/uploads/2025/09/05/3e4bcaa18cd0b27710bbce9d748a258e.png",
I/flutter (16306):       "a... (truncated)
I/flutter (16306): ✅ Request GET /index - 2579ms - Status: 200
I/flutter (16306): SUCCESS: 🏠 首页数据请求成功
I/flutter (16306): INFO: 首页数据结构: [is_red_dot, is_system_notice_red_dot, is_interaction_notice_red_dot, activity, location, user, photo, weather, vip_data, half_user_data, crap_game]
I/flutter (16306): 📊 系统消息红点变化，更新总红点数: 0
I/flutter (16306): 📊 互动消息红点变化，更新总红点数: 0
I/flutter (16306): 💩 拉屎游戏信息更新: link=http://devweb.ikissu.cn/share/couplesdeFecating.html, status=1
I/flutter (16306): 📊 红点信息更新: 系统消息=0, 互动消息=0, 总数=0, 显示红点=false
I/flutter (16306): 📱 half_user_data 更新: power=59%, network=wifi_YuluoKeji_5G, model=HONOR, distance=<100米
I/flutter (16306): ✅ 用户头像已更新: https://kissustatic.yuluojishu.com/uploads/2025/08/21/c995803f84b964e9b191b1f6a7422a2a.png
I/flutter (16306): ✅ 伴侣头像已更新: https://kissustatic.yuluojishu.com/uploads/2025/12/25/f4a399f1032cc3afecee8e2adf0be067.jpg
I/flutter (16306): 📸 照片墙URL: https://kissustatic.yuluojishu.com/uploads/2025/10/21/87783e72474a60d2ed35d7cd3f769dea.png
I/flutter (16306): 🌤️ 开始解析首页天气数据
I/flutter (16306): 🌤️ 解析 base 数据: icon=https://kissustatic.yuluojishu.com/uploads/2025/09/23/a15966ed707eb3a3d4c09147bca181bd.png, weather=晴, temp=5
I/flutter (16306): 🌤️ 解析 all 数据: min=3, max=11
I/flutter (16306): ✅ 天气数据解析成功
I/flutter (16306): ✅ 首页数据加载成功: 绑定状态=true, 恋爱天数=0, 距离=<100米
I/flutter (16306): ✅ 头像预加载成功: https://kissustatic.yuluojishu.com/uploads/2025/12/25/f4a399f1032cc3afecee8e2adf0be067.jpg
I/flutter (16306): SUCCESS:  用户数据保存成功
I/flutter (16306): SUCCESS:  验证保存成功，数据长度: 2724
I/flutter (16306): [LogManager] Not initialized. Message: 用户信息已更新
I/flutter (16306): [LogManager] Not initialized. Message: 用户信息已从服务器刷新
I/flutter (16306): ✅ 用户信息刷新成功，重新加载本地用户信息
I/flutter (16306): ✅ 从本地加载用户头像: https://kissustatic.yuluojishu.com/uploads/2025/08/21/c995803f84b964e9b191b1f6a7422a2a.png
I/flutter (16306): ✅ 从halfUserInfo加载伴侣头像: https://kissustatic.yuluojishu.com/uploads/2025/12/25/f4a399f1032cc3afecee8e2adf0be067.jpg
I/flutter (16306): 📍 开始获取距离信息和停留点数量...
I/flutter (16306): 🏠 加载恋爱天数: 0天
I/flutter (16306): ✅ 头像预加载成功: https://kissustatic.yuluojishu.com/uploads/2025/12/25/f4a399f1032cc3afecee8e2adf0be067.jpg
I/flutter (16306): [LogManager] Not initialized. Message: DeviceUtil not initialized, using fallback deviceId
I/flutter (16306): INFO: OAID 已添加到请求头
I/flutter (16306): INFO: ========== Request Headers ==========
I/flutter (16306): INFO: URL: http://dev-love-api.ikissu.cn/get/location
I/flutter (16306): INFO: Method: GET
I/flutter (16306): INFO: --- Business Headers ---
I/flutter (16306): INFO: token: eyJ0eXAiOiJKV1QiLCJh... (204 chars)
I/flutter (16306): INFO: sign: 5F22F3192A94CD594144... (32 chars)
I/flutter (16306): INFO: version: 1.0.12
I/flutter (16306): INFO: channel: kissu_wdj
I/flutter (16306): INFO: pkg: com.yuluo.kissu
I/flutter (16306): INFO: network-name: wifi_YuluoKeji_5G
I/flutter (16306): INFO: deviceid: android-1766846811003
I/flutter (16306): INFO: mobile-model: HUAWEI HMA-AL00
I/flutter (16306): INFO: power: 3
I/flutter (16306): INFO: is-open-location: 1
I/flutter (16306): INFO: brand: HUAWEI
I/flutter (16306): INFO: oaid: 2b774804-8723-451d-af95-fbebb2a4bd84
I/flutter (16306): INFO: --- Other Headers ---
I/flutter (16306): INFO: cache_control: noCache
I/flutter (16306): INFO: timestamp: 1766846811003
I/flutter (16306): INFO: =====================================
I/flutter (16306): [LogManager] Not initialized. Message: GET http://dev-love-api.ikissu.cn/get/location
I/flutter (16306): [LogManager] Not initialized. Message: Headers: {cache_control: noCache, token: ***HIDDEN***, version: 1.0.12, pkg: com.yuluo.kissu, deviceid: android-1766846811003, oaid: 2b774804-8723-451d-af95-fbebb2a4bd84, mobile-model: HUAWEI HMA-AL00, brand: HUAWEI, is-open-location: 1, channel: kissu_wdj, network-name: wifi_YuluoKeji_5G, power: 3, timestamp: 1766846811003, sign: 5F22F3192A94CD594144EA69F229E59F}
D/ForegroundLocationService(16306): 📍 原生定位成功: 30.275054, 120.220712, 精度: 45.0m
D/ForegroundLocationService(16306): 定位成功，静默模式（不更新通知）
D/LocationReportService(16306): 📦 收集池为空，直接放入: 30.275054, 120.220712, 精度: 45.0m
D/LocationReportService(16306): 🔑 读取用户信息: token=已存在(eyJ0eXAiOiJKV1QiLCJh...), userId=189, baseUrl=http://dev-love-api.ikissu.cn
D/LocationReportService(16306): 📦 位置已收集到缓冲区 (1/12): 30.275054, 120.220712
D/LocationReportService(16306): 📍 最后收集位置已更新: 30.275054, 120.220712
I/com.yuluo.kiss(16306): NativeAlloc concurrent copying GC freed 69491(2874KB) AllocSpace objects, 38(37MB) LOS objects, 49% free, 15MB/30MB, paused 64us total 158.969ms DisableRefAccess:1.684ms(1.622ms)
I/HwApiCacheMangerEx(16306): apicache path=/storage/emulated/0 state=mounted key=com.yuluo.kissu#10464#0
I/HwApiCacheMangerEx(16306): need clear apicache,because volumes changed,oldCnt=1 newCnt=1
I/HwApiCacheMangerEx(16306): apicache path=/storage/emulated/0 state=mounted key=com.yuluo.kissu#10464#256
I/HwApiCacheMangerEx(16306): need clear apicache,because volumes changed,oldCnt=1 newCnt=1
W/com.yuluo.kiss(16306): Accessing hidden method Landroid/os/storage/StorageManager;->getVolumeList()[Landroid/os/storage/StorageVolume; (greylist, reflection, allowed)
W/com.yuluo.kiss(16306): Accessing hidden method Landroid/os/storage/StorageVolume;->getPath()Ljava/lang/String; (greylist, reflection, allowed)
I/HwApiCacheMangerEx(16306): apicache path=/storage/emulated/0 state=mounted key=com.yuluo.kissu#10464#0
I/HwApiCacheMangerEx(16306): need clear apicache,because volumes changed,oldCnt=1 newCnt=1
I/flutter (16306): [LogManager] Not initialized. Message: 200 POST http://dev-love-api.ikissu.cn/v4/reporting/sensitive/record (617ms)
I/flutter (16306): [LogManager] Not initialized. Message: Response: {
I/flutter (16306):   "isSuccess": true,
I/flutter (16306):   "code": 0,
I/flutter (16306):   "msg": "敏感记录上报成功",
I/flutter (16306):   "data": null,
I/flutter (16306):   "dataList": null,
I/flutter (16306):   "dataJson": {},
I/flutter (16306):   "listJson": null
I/flutter (16306): }
I/flutter (16306): ✅ Request POST /v4/reporting/sensitive/record - 798ms - Status: 200
I/flutter (16306): SUCCESS: 敏感数据上报成功: APP打开
I/flutter (16306): SUCCESS: APP打开事件上报完成
I/flutter (16306): ✅ 头像预加载成功: https://kissustatic.yuluojishu.com/uploads/2025/08/21/c995803f84b964e9b191b1f6a7422a2a.png
I/flutter (16306): [LogManager] Not initialized. Message: 200 GET http://dev-love-api.ikissu.cn/get/location (215ms)
I/flutter (16306): [LogManager] Not initialized. Message: Response: {
I/flutter (16306):   "isSuccess": true,
I/flutter (16306):   "code": 0,
I/flutter (16306):   "msg": "",
I/flutter (16306):   "data": null,
I/flutter (16306):   "dataList": null,
I/flutter (16306):   "dataJson": {
I/flutter (16306):     "user_location_mobile_device": {
I/flutter (16306):       "power": "3%",
I/flutter (16306):       "network_name": "wifi_YuluoKeji_5G",
I/flutter (16306):       "mobile_model": "HUAWEI",
I/flutter (16306):       "is_wifi": "0",
I/flutter (16306):       "longitude": "120.22071923152217",
I/flutter (16306):       "location": "浙江省杭州市上城区运河东路301号靠近中豪·湘和国际 附近",
I/flutter (16306):       "real_speed": "2.87",
I/flutter (16306):       "speed": "3m/s",
I/flutter (16306):       "latitude": "30.27504608948789",
I/flutter (16306):       "location_time": "1766846599",
I/flutter (16306):       "calculate_location... (truncated)
I/flutter (16306): ✅ Request GET /get/location - 234ms - Status: 200
I/flutter (16306): CHECK: API原始JSON数据:
I/flutter (16306): CHECK:   JSON keys: [user_location_mobile_device, half_location_mobile_device, user]
I/flutter (16306): CHECK:   user_location_mobile_device keys: [power, network_name, mobile_model, is_wifi, longitude, location, real_speed, speed, latitude, location_time, calculate_location_time, is_open_location, is_oneself, distance, stops, stay_collect, head_portrait, face]
I/flutter (16306): CHECK:   user_location_mobile_device stops: [{latitude: 30.274932, longitude: 120.220766, location_name: 浙江省杭州市上城区四季青街道运河东路中豪·湘和国际 附近, start_time: 当前, end_time: , duration: 1小时47分钟, duration_int: 6458, status: staying, point_type: stop, serial_number: 3}, {latitude: 30.27654074591645, longitude: 120.22015721327992, location_name: 浙江省杭州市上城区四季青街道可霖臻民宿(杭州东站店)中豪·湘和国际 附近, start_time: 20:38, end_time: 20:58, duration: 20分钟36秒, duration_int: 1236, status: ended, point_type: stop, serial_number: 2}, {latitude: 30.27505, longitude: 120.220753, location_name: 浙江省杭州市上城区四季青街道运河东路中豪·湘和国际 附近, start_time: 20:16, end_time: 20:38, duration: 21分钟17秒, duration_int: 1277, status: ended, point_type: stop, serial_number: 1}]
I/flutter (16306): CHECK:   half_location_mobile_device keys: [power, network_name, mobile_model, is_wifi, longitude, real_speed, location, speed, latitude, location_time, calculate_location_time, is_open_location, is_oneself, distance, stops, stay_collect, head_portrait, face, online, lives]
I/flutter (16306): CHECK:   half_location_mobile_device stops: [{latitude: 30.274992, longitude: 120.220835, location_name: 浙江省杭州市上城区四季青街道运河东路中豪·湘和国际 附近, start_time: 当前, end_time: , duration: 19小时4分钟, duration_int: 68657, status: staying, point_type: stop, serial_number: 1}]
I/flutter (16306): 📍 获取到距离信息: <100米
I/flutter (16306): 📍 获取到停留点数量: 1
D/ForegroundLocationService(16306): 📍 原生定位成功: 30.275005109618835, 120.22069827341741, 精度: 37.0m
D/ForegroundLocationService(16306): 定位成功，静默模式（不更新通知）
D/LocationReportService(16306): 📍 距离不足，跳过收集: 移动5米 < 50米
I/Hwaps   (16306): APS: EventAnalyzed: initAPS: version is 11.0.0.4
2
D/Hwaps   (16306): Fpsrequest create,type:EXACTLY_IDENTIFY
D/Hwaps   (16306): Fpsrequest create,type:OPENGL_SETTING
D/Hwaps   (16306): FpsController create
D/Hwaps   (16306): APS: EventAnalyzed: reInitFpsPara :mBaseFps = 60; mMaxFps = 60
W/Settings(16306): Setting device_provisioned has moved from android.provider.Settings.Secure to android.provider.Settings.Global.
V/HiTouch_HiTouchSensor(16306): User setup is finished.
I/flutter (16306): 🔍 检查引导图1显示状态: true (已绑定: true)
I/flutter (16306): ℹ️ 引导图1已显示过，检查是否需要显示引导图2或VIP购买弹窗 (已绑定: true)
I/flutter (16306): 🔍 检查引导图2显示状态: true
I/flutter (16306): ℹ️ 引导图2已显示过，检查VIP购买弹窗
I/flutter (16306): 💎 用户已是VIP会员，不显示VIP购买弹窗
W/HwApsManager(16306): HwApsManagerService, registerCallback, start !
D/Hwaps   (16306): APS: EventAnalyzed: registerCallbackInApsManagerService, mPkgName:com.yuluo.kissu; result = true
I/flutter (16306): 🔍 底部导航按钮 0 被点击
I/flutter (16306): 📍 准备跳转到定位V2页面（检查会员状态）
I/flutter (16306): INFO: 🔍 检查会员状态后导航到定位页面
I/flutter (16306): INFO: 📊 会员信息 - isVip: 1, isForEverVip: 1, vipEndTime: 0
[GETX] GOING TO ROUTE /LocationV2Page
V/AudioManager(16306): querySoundEffectsEnabled...
[GETX] Instance "LocationV2Controller" has been created
I/flutter (16306): 🔄 定位页面：静默刷新用户信息
I/flutter (16306): 🚀 地图页面异步初始化流程开始（后台静默执行）
[GETX] Instance "LocationV2Controller" has been initialized
I/flutter (16306): 📍 已绑定状态，计算双人中心位置
I/flutter (16306): 📍 已绑定但无位置数据，使用默认位置（天安门）
I/flutter (16306): [LogManager] Not initialized. Message: 🗺️ SafeAMapWidget 初始化开始
I/flutter (16306): 🔍 LocationTipsManager: 开始检查所有提示
I/flutter (16306): 🔍 LocationTipsManager: 开始检查始终允许定位权限
I/flutter (16306): 👑 永久会员，不显示到期提示
I/flutter (16306): 🔍 LocationTipsManager: 所有提示检查完成
I/flutter (16306): [LogManager] Not initialized. Message: 🗺️ SafeAMapWidget 自定义样式加载成功
D/HwGalleryCacheManagerImpl(16306): mIsEffect:false
I/flutter (16306): [LogManager] Not initialized. Message: DeviceUtil not initialized, using fallback deviceId
I/flutter (16306): INFO: OAID 已添加到请求头
I/flutter (16306): INFO: ========== Request Headers ==========
I/flutter (16306): INFO: URL: http://dev-love-api.ikissu.cn/get/user
I/flutter (16306): INFO: Method: GET
I/flutter (16306): INFO: --- Business Headers ---
I/flutter (16306): INFO: token: eyJ0eXAiOiJKV1QiLCJh... (204 chars)
I/flutter (16306): INFO: sign: 3AEBE4642C8C29E7A6D9... (32 chars)
I/flutter (16306): INFO: version: 1.0.12
I/flutter (16306): INFO: channel: kissu_wdj
I/flutter (16306): INFO: pkg: com.yuluo.kissu
I/flutter (16306): INFO: network-name: wifi_YuluoKeji_5G
I/flutter (16306): INFO: deviceid: android-1766846811678
I/flutter (16306): INFO: mobile-model: HUAWEI HMA-AL00
I/flutter (16306): INFO: power: 3
I/flutter (16306): INFO: is-open-location: 1
I/flutter (16306): INFO: brand: HUAWEI
I/flutter (16306): INFO: oaid: 2b774804-8723-451d-af95-fbebb2a4bd84
I/flutter (16306): INFO: --- Other Headers ---
I/flutter (16306): INFO: network_debounce: true
I/flutter (16306): INFO: timestamp: 1766846811679
I/flutter (16306): INFO: =====================================
I/flutter (16306): [LogManager] Not initialized. Message: DeviceUtil not initialized, using fallback deviceId
I/flutter (16306): INFO: OAID 已添加到请求头
I/flutter (16306): INFO: ========== Request Headers ==========
I/flutter (16306): INFO: URL: http://dev-love-api.ikissu.cn/get/location
I/flutter (16306): INFO: Method: GET
I/flutter (16306): INFO: --- Business Headers ---
I/flutter (16306): INFO: token: eyJ0eXAiOiJKV1QiLCJh... (204 chars)
I/flutter (16306): INFO: sign: C368DEF3F3348F61E043... (32 chars)
I/flutter (16306): INFO: version: 1.0.12
I/flutter (16306): INFO: channel: kissu_wdj
I/flutter (16306): INFO: pkg: com.yuluo.kissu
I/flutter (16306): INFO: network-name: wifi_YuluoKeji_5G
I/flutter (16306): INFO: deviceid: android-1766846811681
I/flutter (16306): INFO: mobile-model: HUAWEI HMA-AL00
I/flutter (16306): INFO: power: 3
I/flutter (16306): INFO: is-open-location: 1
I/flutter (16306): INFO: brand: HUAWEI
I/flutter (16306): INFO: oaid: 2b774804-8723-451d-af95-fbebb2a4bd84
I/flutter (16306): INFO: --- Other Headers ---
I/flutter (16306): INFO: cache_control: noCache
I/flutter (16306): INFO: timestamp: 1766846811681
I/flutter (16306): INFO: =====================================
I/flutter (16306): [LogManager] Not initialized. Message: 🗺️ SafeAMapWidget 渲染已启用
I/flutter (16306): initState AMapWidget
I/flutter (16306): 🔐 始终允许定位权限状态: PermissionStatus.granted
I/flutter (16306): 🔐 是否应该显示权限提示: false
I/flutter (16306): 🔐 当前提示状态: false
I/flutter (16306): 🔐 权限提示状态无变化，保持: false
I/flutter (16306): [LogManager] Not initialized. Message: GET http://dev-love-api.ikissu.cn/get/user
I/flutter (16306): [LogManager] Not initialized. Message: Headers: {network_debounce: true, token: ***HIDDEN***, version: 1.0.12, pkg: com.yuluo.kissu, deviceid: android-1766846811678, oaid: 2b774804-8723-451d-af95-fbebb2a4bd84, mobile-model: HUAWEI HMA-AL00, brand: HUAWEI, is-open-location: 1, channel: kissu_wdj, network-name: wifi_YuluoKeji_5G, power: 3, timestamp: 1766846811679, sign: 3AEBE4642C8C29E7A6D94330C2AC7987}
I/flutter (16306): [LogManager] Not initialized. Message: GET http://dev-love-api.ikissu.cn/get/location
I/flutter (16306): [LogManager] Not initialized. Message: Headers: {cache_control: noCache, token: ***HIDDEN***, version: 1.0.12, pkg: com.yuluo.kissu, deviceid: android-1766846811681, oaid: 2b774804-8723-451d-af95-fbebb2a4bd84, mobile-model: HUAWEI HMA-AL00, brand: HUAWEI, is-open-location: 1, channel: kissu_wdj, network-name: wifi_YuluoKeji_5G, power: 3, timestamp: 1766846811681, sign: C368DEF3F3348F61E043F0C362FFDD39}
I/AMapFlutter_AMapPlatformView(16306): onCreate==>
I/AMapFlutter_AMapPlatformView(16306): onStart==>
I/AMapFlutter_AMapPlatformView(16306): onResume==>
2
I/AMapFlutter_AMapPlatformView(16306): getView==>
I/PlatformViewsController(16306): Hosting view in view hierarchy for platform view: 0
I/PlatformViewsController(16306): PlatformView is using SurfaceProducer backend
D/HwCustConnectivityManagerImpl(16306): isBlockNetworkRequestByNonAis, INVALID_SUBSCRIPTION_ID
D/OpenGLRenderer(16306): disableOutlineDraw is true
D/mali_winsys(16306): EGLint new_window_surface(egl_winsys_display *, void *, EGLSurface, EGLConfig, egl_winsys_surface **, EGLBoolean) returns 0x3000
I/AMapFlutter_AMapPlatformView(16306): getView==>
W/Gralloc3(16306): allocator 3.x is not supported
I/flutter (16306): [LogManager] Not initialized. Message: 隐私合规设置完成
I/flutter (16306): [LogManager] Not initialized. Message: 定位服务已启动，先停止旧服务
I/flutter (16306): 🛑 停止前台定位服务...
I/flutter (16306): [LogManager] Not initialized. Message: 高德定位服务已停止（全局监听器保持激活）
I/flutter (16306): [LogManager] Not initialized. Message: 收集缓冲区和智能状态已清理
D/OpenGLRenderer(16306): disableOutlineDraw is true
2
D/mali_winsys(16306): EGLint new_window_surface(egl_winsys_display *, void *, EGLSurface, EGLConfig, egl_winsys_surface **, EGLBoolean) returns 0x3000
D/BootCompletedReceiver(16306): 定位服务状态已保存: enabled=false
D/ForegroundServiceHandler(16306): 定位服务已停止，开机将不会自动启动
I/flutter (16306): ✅ 前台定位服务停止成功
I/flutter (16306): [LogManager] Not initialized. Message: 前台服务停止成功
D/ImageReaderSurfaceProducer(16306): ImageTextureEntry can't wait on the fence on Android < 33
W/ForegroundLocationService(16306): ! 前台定位服务被销毁，尝试自恢复
D/ForegroundLocationService(16306): 原生定位监听已停止
D/ForegroundLocationService(16306): 已释放所有上报服务
D/ForegroundLocationService(16306): ❤️ 心跳闹钟已停止
D/ForegroundLocationService(16306): 🌙 息屏心跳闹钟已停止
D/ForegroundLocationService(16306): 🌙 息屏保活机制已停止
D/ForegroundLocationService(16306): App使用记录上报已停止
D/ForegroundLocationService(16306): 锁屏/解锁广播接收器已注销
D/ForegroundLocationService(16306): 网络状态广播接收器已注销
D/ForegroundLocationService(16306): 充电状态广播接收器已注销
D/ForegroundLocationService(16306): WakeLock 已释放
D/ForegroundLocationService(16306): 🔄 已安排重启（onDestroy），delay=1200ms
E/ForegroundLocationService(16306): 安排 WorkManager 重启失败（onDestroy）
E/ForegroundLocationService(16306): java.lang.IllegalArgumentException: Expedited jobs cannot be delayed
E/ForegroundLocationService(16306): 	at androidx.work.WorkRequest$Builder.build(WorkRequest.kt:271)
E/ForegroundLocationService(16306): 	at com.yuluo.kissu.ForegroundLocationService.scheduleWorkRestart(ForegroundLocationService.kt:865)
E/ForegroundLocationService(16306): 	at com.yuluo.kissu.ForegroundLocationService.onDestroy(ForegroundLocationService.kt:411)
E/ForegroundLocationService(16306): 	at android.app.ActivityThread.handleStopService(ActivityThread.java:4993)
E/ForegroundLocationService(16306): 	at android.app.ActivityThread.access$3400(ActivityThread.java:259)
E/ForegroundLocationService(16306): 	at android.app.ActivityThread$H.handleMessage(ActivityThread.java:2502)
E/ForegroundLocationService(16306): 	at android.os.Handler.dispatchMessage(Handler.java:110)
E/ForegroundLocationService(16306): 	at android.os.Looper.loop(Looper.java:219)
E/ForegroundLocationService(16306): 	at android.app.ActivityThread.main(ActivityThread.java:8679)
E/ForegroundLocationService(16306): 	at java.lang.reflect.Method.invoke(Native Method)
E/ForegroundLocationService(16306): 	at com.android.internal.os.RuntimeInit$MethodAndArgsCaller.run(RuntimeInit.java:513)
E/ForegroundLocationService(16306): 	at com.android.internal.os.ZygoteInit.main(ZygoteInit.java:1109)
D/ForegroundLocationService(16306): 前台定位服务销毁
I/HwViewRootImpl(16306): removeInvalidNode all the node in jank list is out of time
I/flutter (16306): [LogManager] Not initialized. Message: 200 GET http://dev-love-api.ikissu.cn/get/user (148ms)
I/flutter (16306): [LogManager] Not initialized. Message: Response: {
I/flutter (16306):   "isSuccess": true,
I/flutter (16306):   "code": 0,
I/flutter (16306):   "msg": "获取用户信息",
I/flutter (16306):   "data": null,
I/flutter (16306):   "dataList": null,
I/flutter (16306):   "dataJson": {
I/flutter (16306):     "current_channel": "kissu_wdj",
I/flutter (16306):     "province_name": "浙江",
I/flutter (16306):     "open_app_nums": "0",
I/flutter (16306):     "oaid": "2b774804-8723-451d-af95-fbebb2a4bd84",
I/flutter (16306):     "lover_id": 357,
I/flutter (16306):     "is_give_vip": "0",
I/flutter (16306):     "is_alert_give_vip": "0",
I/flutter (16306):     "register_version": "1.0.1",
I/flutter (16306):     "gender": 1,
I/flutter (16306):     "channel_cate_id": "0",
I/flutter (16306):     "lately_login_time": "1766739987",
I/flutter (16306):     "is_test": "1",
I/flutter (16306):     "channel_id": "0",
I/flutter (16306):     "birthday": "... (truncated)
I/flutter (16306): ✅ Request GET /get/user - 468ms - Status: 200
W/BufferQueueProducer(16306): [ImageReader-1x1f22m7-16306-0]:1397: disconnect: not connected (req=1)
W/libEGL  (16306): EGLNativeWindowType 0x7165065b90 disconnect failed
I/flutter (16306): [LogManager] Not initialized. Message: 调用getUserInfo API
I/flutter (16306): INFO:  开始保存用户数据，用户ID: 189, 数据长度: 2724
I/flutter (16306): [LogManager] Not initialized. Message: 200 GET http://dev-love-api.ikissu.cn/get/location (152ms)
I/flutter (16306): [LogManager] Not initialized. Message: Response: {
I/flutter (16306):   "isSuccess": true,
I/flutter (16306):   "code": 0,
I/flutter (16306):   "msg": "",
I/flutter (16306):   "data": null,
I/flutter (16306):   "dataList": null,
I/flutter (16306):   "dataJson": {
I/flutter (16306):     "user_location_mobile_device": {
I/flutter (16306):       "power": "3%",
I/flutter (16306):       "network_name": "wifi_YuluoKeji_5G",
I/flutter (16306):       "mobile_model": "HUAWEI",
I/flutter (16306):       "is_wifi": "0",
I/flutter (16306):       "longitude": "120.22071923152217",
I/flutter (16306):       "location": "浙江省杭州市上城区运河东路301号靠近中豪·湘和国际 附近",
I/flutter (16306):       "real_speed": "2.87",
I/flutter (16306):       "speed": "3m/s",
I/flutter (16306):       "latitude": "30.27504608948789",
I/flutter (16306):       "location_time": "1766846599",
I/flutter (16306):       "calculate_location... (truncated)
I/flutter (16306): ✅ Request GET /get/location - 467ms - Status: 200
I/flutter (16306): CHECK: API原始JSON数据:
I/flutter (16306): CHECK:   JSON keys: [user_location_mobile_device, half_location_mobile_device, user]
I/flutter (16306): CHECK:   user_location_mobile_device keys: [power, network_name, mobile_model, is_wifi, longitude, location, real_speed, speed, latitude, location_time, calculate_location_time, is_open_location, is_oneself, distance, stops, stay_collect, head_portrait, face]
I/flutter (16306): CHECK:   user_location_mobile_device stops: [{latitude: 30.274932, longitude: 120.220766, location_name: 浙江省杭州市上城区四季青街道运河东路中豪·湘和国际 附近, start_time: 当前, end_time: , duration: 1小时47分钟, duration_int: 6458, status: staying, point_type: stop, serial_number: 3}, {latitude: 30.27654074591645, longitude: 120.22015721327992, location_name: 浙江省杭州市上城区四季青街道可霖臻民宿(杭州东站店)中豪·湘和国际 附近, start_time: 20:38, end_time: 20:58, duration: 20分钟36秒, duration_int: 1236, status: ended, point_type: stop, serial_number: 2}, {latitude: 30.27505, longitude: 120.220753, location_name: 浙江省杭州市上城区四季青街道运河东路中豪·湘和国际 附近, start_time: 20:16, end_time: 20:38, duration: 21分钟17秒, duration_int: 1277, status: ended, point_type: stop, serial_number: 1}]
I/flutter (16306): CHECK:   half_location_mobile_device keys: [power, network_name, mobile_model, is_wifi, longitude, real_speed, location, speed, latitude, location_time, calculate_location_time, is_open_location, is_oneself, distance, stops, stay_collect, head_portrait, face, online, lives]
I/flutter (16306): CHECK:   half_location_mobile_device stops: [{latitude: 30.274992, longitude: 120.220835, location_name: 浙江省杭州市上城区四季青街道运河东路中豪·湘和国际 附近, start_time: 当前, end_time: , duration: 19小时4分钟, duration_int: 68657, status: staying, point_type: stop, serial_number: 1}]
I/flutter (16306): 📍 另一半定位开关提示状态: false
I/flutter (16306): ✅ [已绑定] 更新头像和对方位置数据
I/flutter (16306): 📍 [已绑定] 使用接口数据更新我的位置
I/HwApiCacheMangerEx(16306): apicache path=/storage/emulated/0 state=mounted key=com.yuluo.kissu#10464#256
I/HwApiCacheMangerEx(16306): need clear apicache,because volumes changed,oldCnt=1 newCnt=1
I/flutter (16306): 📱 ============ Marker创建调试信息 ============
I/flutter (16306): 📱 设备像素比(DPI): 3.0
I/flutter (16306): 📱 屏幕宽度: 360逻辑像素 (1080物理像素)
I/flutter (16306): 📱 设计稿比例: 0.960x (360 / 375.0)
I/flutter (16306): 📱 头像尺寸: 144.0px (设计稿50.0px × 0.96 × 3.0)
I/flutter (16306): 📱 底座尺寸: 576.0px (设计稿200.0px × 0.96 × 3.0)
I/flutter (16306): 📱 Canvas尺寸: 592.0 x 176.8px
I/flutter (16306): 📱 边框宽度: 8.81px
I/flutter (16306): SUCCESS:  用户数据保存成功
I/flutter (16306): 📍 已绑定状态，计算双人中心位置
I/flutter (16306): 📍 双人位置：我(30.275012, 120.22070500000001) 伴侣(30.275012, 120.22070500000001) 中心(LatLng(30.275012, 120.22070500000001))
I/HwApiCacheMangerEx(16306): apicache path=/storage/emulated/0 state=mounted key=com.yuluo.kissu#10464#0
I/HwApiCacheMangerEx(16306): need clear apicache,because volumes changed,oldCnt=1 newCnt=1
I/HwApiCacheMangerEx(16306): apicache path=/storage/emulated/0 state=mounted key=com.yuluo.kissu#10464#256
I/HwApiCacheMangerEx(16306): need clear apicache,because volumes changed,oldCnt=1 newCnt=1
I/HwApiCacheMangerEx(16306): apicache path=/storage/emulated/0 state=mounted key=com.yuluo.kissu#10464#0
I/HwApiCacheMangerEx(16306): need clear apicache,because volumes changed,oldCnt=1 newCnt=1
I/flutter (16306): SUCCESS:  验证保存成功，数据长度: 2724
I/flutter (16306): [LogManager] Not initialized. Message: 用户信息已更新
I/flutter (16306): [LogManager] Not initialized. Message: 用户信息已从服务器刷新
I/AMapFlutter_MapController(16306): onCameraChange===>{position={bearing=0.0, zoom=3.0, tilt=0.0, target=[39.90420000000002, 116.40740000000004]}}
I/AMapFlutter_MapController(16306): onCameraChangeFinish===>{position={bearing=0.0, zoom=3.0, tilt=0.0, target=[39.90420000000002, 116.40740000000004]}}
I/AMapFlutter_MapController(16306): onMapLoaded==>
W/System.err(16306): java.lang.ArrayIndexOutOfBoundsException: length=0; index=0
W/System.err(16306): 	at com.amap.flutter.map.core.MapController.onMapLoaded(MapController.java:237)
W/System.err(16306): 	at com.amap.api.mapcore.util.b$1.handleMessage(AMapDelegateImp.java:400)
W/System.err(16306): 	at android.os.Handler.dispatchMessage(Handler.java:110)
W/System.err(16306): 	at android.os.Looper.loop(Looper.java:219)
W/System.err(16306): 	at android.app.ActivityThread.main(ActivityThread.java:8679)
W/System.err(16306): 	at java.lang.reflect.Method.invoke(Native Method)
W/System.err(16306): 	at com.android.internal.os.RuntimeInit$MethodAndArgsCaller.run(RuntimeInit.java:513)
W/System.err(16306): 	at com.android.internal.os.ZygoteInit.main(ZygoteInit.java:1109)
I/SmartSlideOverScroller(16306): start init SmartSlideOverScroller and get the overscroller config
I/SmartSlideOverScrollerConfig(16306): get the overscroller config
I/flutter (16306): [LogManager] Not initialized. Message: 🗺️ SafeAMapWidget 地图创建成功
I/flutter (16306): [LogManager] Not initialized. Message: 🗺️ SafeAMapWidget 地图就绪完成
I/flutter (16306): 📱 ============ Marker创建调试信息 ============
I/flutter (16306): 📱 设备像素比(DPI): 3.0
I/flutter (16306): 📱 屏幕宽度: 360逻辑像素 (1080物理像素)
I/flutter (16306): 📱 设计稿比例: 0.960x (360 / 375.0)
I/flutter (16306): 📱 头像尺寸: 144.0px (设计稿50.0px × 0.96 × 3.0)
I/flutter (16306): 📱 底座尺寸: 576.0px (设计稿200.0px × 0.96 × 3.0)
I/flutter (16306): 📱 Canvas尺寸: 592.0 x 176.8px
I/flutter (16306): 📱 边框宽度: 8.81px
W/com.yuluo.kiss(16306): Accessing hidden field Landroid/net/SSLSessionCache;->mSessionCache:Lcom/android/org/conscrypt/SSLClientSessionCache; (greylist, reflection, allowed)
I/flutter (16306): [LogManager] Not initialized. Message: 高德定位插件状态正常
I/flutter (16306): [LogManager] Not initialized. Message: 高德定位插件已停止
I/flutter (16306): [LogManager] Not initialized. Message: 所有流监听器清理完成
I/flutter (16306): [LogManager] Not initialized. Message: 🗺️ SafeAMapWidget 已设置渲染帧率: 30fps
I/flutter (16306): 📱 图片尺寸: 592 x 176px
I/flutter (16306): 📱 头像底部Y: 160.8px
I/flutter (16306): 📱 锚点位置: (0.5, 0.909)
I/flutter (16306): 📱 创建耗时: 533ms
I/flutter (16306): 📱 ============================================
I/flutter (16306): 💾 缓存Marker: marker_266091311_null (总缓存数: 1)
I/flutter (16306): 📱 ============ 底座Marker创建 ============
I/flutter (16306): 📱 设备像素比(DPI): 3.0
I/flutter (16306): 📱 屏幕宽度: 360px
I/flutter (16306): 📱 设计稿比例: 0.960x (360 / 375.0)
I/flutter (16306): 📱 请求底座尺寸: 800.0px
I/flutter (16306): 📱 设计稿尺寸: 200.0px
I/flutter (16306): 📱 实际底座尺寸: 576.0px (200.0px × 0.96 × 3.0)
I/flutter (16306): 📱 ==========================================
I/flutter (16306): 📱 图片尺寸: 592 x 176px
I/flutter (16306): 📱 头像底部Y: 160.8px
I/flutter (16306): 📱 锚点位置: (0.5, 0.909)
I/flutter (16306): 📱 创建耗时: 280ms
I/flutter (16306): 📱 ============================================
I/flutter (16306): 💾 缓存Marker: marker_266091311_null (总缓存数: 1)
I/flutter (16306): 📱 ============ 底座Marker创建 ============
I/flutter (16306): 📱 设备像素比(DPI): 3.0
I/flutter (16306): 📱 屏幕宽度: 360px
I/flutter (16306): 📱 设计稿比例: 0.960x (360 / 375.0)
I/flutter (16306): 📱 请求底座尺寸: 800.0px
I/flutter (16306): 📱 设计稿尺寸: 200.0px
I/flutter (16306): 📱 实际底座尺寸: 576.0px (200.0px × 0.96 × 3.0)
I/flutter (16306): 📱 ==========================================
I/flutter (16306): 📍 已绑定状态，计算双人地图位置
I/flutter (16306): 📍 已绑定，使用原生LatLngBounds移动地图到双人中心位置
I/flutter (16306): 📍 bounds: southwest(30.275012, 120.22070500000001), northeast(30.275012, 120.22070500000001)
I/flutter (16306): 📱 ============ Marker创建调试信息 ============
I/flutter (16306): 📱 设备像素比(DPI): 3.0
I/flutter (16306): 📱 屏幕宽度: 360逻辑像素 (1080物理像素)
I/flutter (16306): 📱 设计稿比例: 0.960x (360 / 375.0)
I/flutter (16306): 📱 头像尺寸: 144.0px (设计稿50.0px × 0.96 × 3.0)
I/flutter (16306): 📱 底座尺寸: 40.3px (设计稿14.0px × 0.96 × 3.0)
I/flutter (16306): 📱 Canvas尺寸: 160.0 x 176.8px
I/flutter (16306): 📱 边框宽度: 8.81px
I/AMapFlutter_MapController(16306): onCameraChange===>{position={bearing=0.0, zoom=3.0, tilt=0.0, target=[39.904201019805136, 116.40739986833479]}}
I/flutter (16306): 📱 ============ Marker创建调试信息 ============
I/flutter (16306): 📱 设备像素比(DPI): 3.0
I/flutter (16306): 📱 屏幕宽度: 360逻辑像素 (1080物理像素)
I/flutter (16306): 📱 设计稿比例: 0.960x (360 / 375.0)
I/flutter (16306): 📱 头像尺寸: 144.0px (设计稿50.0px × 0.96 × 3.0)
I/flutter (16306): 📱 底座尺寸: 40.3px (设计稿14.0px × 0.96 × 3.0)
I/flutter (16306): 📱 Canvas尺寸: 160.0 x 176.8px
I/flutter (16306): 📱 边框宽度: 8.81px
I/AMapFlutter_MapController(16306): onCameraChange===>{position={bearing=0.0, zoom=4.9266667, tilt=0.0, target=[38.87103266013015, 116.83957347067499]}}
I/AMapFlutter_MapController(16306): onCameraChange===>{position={bearing=0.0, zoom=6.7966666, tilt=0.0, target=[37.85367874320033, 117.25903742581558]}}
I/flutter (16306): [LogManager] Not initialized. Message: 为收集池请求单次定位...
I/AMapFlutter_MapController(16306): onCameraChange===>{position={bearing=0.0, zoom=8.723333, tilt=0.0, target=[36.79060749589382, 117.6912123692603]}}
I/AMapFlutter_MapController(16306): onCameraChange===>{position={bearing=0.0, zoom=10.593333, tilt=0.0, target=[35.744496975474476, 118.11067498329639]}}
I/flutter (16306): 📱 图片尺寸: 160 x 176px
I/flutter (16306): 📱 头像底部Y: 160.8px
I/flutter (16306): 📱 锚点位置: (0.5, 0.909)
I/flutter (16306): 📱 创建耗时: 162ms
I/flutter (16306): 📱 ============================================
I/flutter (16306): 💾 缓存Marker: marker_252976438_null (总缓存数: 2)
I/flutter (16306): 📱 ============ 底座Marker创建 ============
I/flutter (16306): 📱 设备像素比(DPI): 3.0
I/flutter (16306): 📱 屏幕宽度: 360px
I/flutter (16306): 📱 设计稿比例: 0.960x (360 / 375.0)
I/flutter (16306): 📱 请求底座尺寸: 40.0px
I/flutter (16306): 📱 设计稿尺寸: 21.0px
I/flutter (16306): 📱 实际底座尺寸: 60.5px (21.0px × 0.96 × 3.0)
I/flutter (16306): 📱 ==========================================
I/AMapFlutter_MapController(16306): onCameraChange===>{position={bearing=0.0, zoom=12.463333, tilt=0.0, target=[34.684456570571925, 118.53013893843698]}}
I/flutter (16306): 📱 图片尺寸: 160 x 176px
I/flutter (16306): 📱 头像底部Y: 160.8px
I/flutter (16306): 📱 锚点位置: (0.5, 0.909)
I/flutter (16306): 📱 创建耗时: 154ms
I/flutter (16306): 📱 ============================================
I/flutter (16306): 💾 缓存Marker: marker_252976438_null (总缓存数: 2)
I/AMapFlutter_MapController(16306): onCameraChange===>{position={bearing=0.0, zoom=14.333334, tilt=0.0, target=[33.61066841198652, 118.94960289357756]}}
I/flutter (16306): 📊 Marker创建/缓存耗时: 838ms
I/flutter (16306): 📍 距离判断: <100米 = 100.0米, 近距离模式: true
I/flutter (16306): 🎯 进入近距离模式，创建摇摆头像和GIF
I/flutter (16306): 🎯 近距离模式头像: 我=https://kissustatic.yuluojishu.com/uploads/2025/08/21/c995803f84b964e9b191b1f6a7422a2a.png, Ta=https://kissustatic.yuluojishu.com/uploads/2025/12/25/f4a399f1032cc3afecee8e2adf0be067.jpg, 位置=LatLng(30.275012, 120.22070500000001)
I/flutter (16306): 🎯 开始创建Ta的头像marker
I/flutter (16306): 📊 Marker创建/缓存耗时: 578ms
I/flutter (16306): 📍 距离判断: <100米 = 100.0米, 近距离模式: true
I/flutter (16306): 🎯 进入近距离模式，创建摇摆头像和GIF
I/flutter (16306): 🎯 近距离模式头像: 我=https://kissustatic.yuluojishu.com/uploads/2025/08/21/c995803f84b964e9b191b1f6a7422a2a.png, Ta=https://kissustatic.yuluojishu.com/uploads/2025/12/25/f4a399f1032cc3afecee8e2adf0be067.jpg, 位置=LatLng(30.275012, 120.22070500000001)
I/flutter (16306): 🎯 开始创建Ta的头像marker
I/flutter (16306): 停止Marker呼吸动画失败: PlatformException(MARKER_NOT_FOUND, 未找到markerId对应的Marker: my_marker, null, null)
I/flutter (16306): 📍 已绑定状态，计算双人中心位置
I/flutter (16306): 📍 双人位置：我(30.275012, 120.22070500000001) 伴侣(30.275012, 120.22070500000001) 中心(LatLng(30.275012, 120.22070500000001))
I/flutter (16306): 停止Marker呼吸动画失败: PlatformException(MARKER_NOT_FOUND, 未找到markerId对应的Marker: partner_marker, null, null)
I/flutter (16306): ✅ Marker呼吸动画已停止
I/AMapFlutter_MapController(16306): onCameraChange===>{position={bearing=0.0, zoom=16.259998, tilt=0.0, target=[32.490177782311314, 119.38177649591779]}}
I/flutter (16306): 📱 ============ 带背景头像Marker创建 ============
I/flutter (16306): 📱 背景图尺寸: 172.8 x 187.2px
I/flutter (16306): 📱 头像尺寸: 144.0px
I/flutter (16306): 📱 旋转角度: -20.0°
I/flutter (16306): 📱 画布尺寸: 254.8 x 254.8px
I/flutter (16306): [LogManager] Not initialized. Message: 为收集池的单次定位请求已发送
I/flutter (16306): 📱 ============ 带背景头像Marker创建 ============
I/flutter (16306): 📱 背景图尺寸: 172.8 x 187.2px
I/flutter (16306): 📱 头像尺寸: 144.0px
I/flutter (16306): 📱 旋转角度: -20.0°
I/flutter (16306): 📱 画布尺寸: 254.8 x 254.8px
I/AMapFlutter_MapController(16306): onCameraChange===>{position={bearing=0.0, zoom=18.073334, tilt=0.0, target=[31.42268549729939, 119.78852946275425]}}
I/flutter (16306): [LogManager] Not initialized. Message: 清理完成，等待结束
I/flutter (16306): [LogManager] Not initialized. Message: - 定位模式: 高精度模式（GPS+网络+WIFI）
I/flutter (16306): [LogManager] Not initialized. Message: - !  息屏后限制：Android系统会限制GPS访问，自动降级为基站+WIFI定位
I/flutter (16306): [LogManager] Not initialized. Message: - 定位间隔: 5000ms（平衡响应性与耗电）
I/flutter (16306): [LogManager] Not initialized. Message: 高德定位参数设置完成
I/flutter (16306): [LogManager] Not initialized. Message: 高德定位启动请求已发送
I/flutter (16306): [LogManager] Not initialized. Message: 立即启动前台服务以支持息屏后定位...
I/flutter (16306): 🚀 启动前台定位服务...
I/AMapFlutter_MapController(16306): onCameraChange===>{position={bearing=0.0, zoom=20.0, tilt=0.0, target=[30.27501410730366, 120.22070440619896]}}
D/BootCompletedReceiver(16306): 定位服务状态已保存: enabled=true
D/ForegroundServiceHandler(16306): 定位服务已启动，状态已保存用于开机自启动
I/flutter (16306): ✅ 前台定位服务启动成功
I/flutter (16306): [LogManager] Not initialized. Message: 前台服务启动成功（静默模式）
I/flutter (16306): [LogManager] Not initialized. Message: 智能启动策略检查：应用在前台
I/flutter (16306): [LogManager] Not initialized. Message: 应用在前台，仅启动基础定位（不启动后台定时器）
I/flutter (16306): [LogManager] Not initialized. Message: 恢复前台位置采集模式
I/flutter (16306): [LogManager] Not initialized. Message: 前台模式参数已应用：Hight_Accuracy / 5000ms / distanceFilter=-1.0
I/flutter (16306): [LogManager] Not initialized. Message: 后台通知未显示，跳过隐藏
I/flutter (16306): [LogManager] Not initialized. Message: 定位服务启动完成，立即尝试获取一次定位放入收集池
I/flutter (16306): [LogManager] Not initialized. Message: 主动获取初始定位，准备放入收集池...
I/flutter (16306): [LogManager] Not initialized. Message: 高德定位服务已启动完成
I/flutter (16306): 📊 定位权限检查完成
I/flutter (16306): 📱 旋转后锚点: (0.374, 0.845)
I/flutter (16306): 📱 ============================================
I/flutter (16306): 🎯 Ta的头像: icon=true, anchor=Offset(0.4, 0.8), adjusted=Offset(0.9, 0.8)
I/flutter (16306): ✅ 近距离模式: Ta的头像marker创建成功（左边），位置: LatLng(30.275012, 120.22070500000001)
I/flutter (16306): 🎯 开始创建我的头像marker，头像URL: https://kissustatic.yuluojishu.com/uploads/2025/08/21/c995803f84b964e9b191b1f6a7422a2a.png
I/flutter (16306): 📱 ============ 带背景头像Marker创建 ============
I/flutter (16306): 📱 背景图尺寸: 172.8 x 187.2px
I/flutter (16306): 📱 头像尺寸: 144.0px
I/flutter (16306): 📱 旋转角度: 20.0°
I/flutter (16306): 📱 画布尺寸: 254.8 x 254.8px
D/ForegroundLocationService(16306): 前台定位服务创建
D/ForegroundLocationService(16306): ⚡ 前台服务已立即启动（避免5秒超时）
D/ForegroundLocationService(16306): 服务期望状态已更新: true
D/ForegroundLocationService(16306): WakeLock 创建成功
D/ForegroundLocationService(16306): WakeLock 已立即获取（服务启动时）
D/ForegroundLocationService(16306): 定位上报服务初始化成功
D/ForegroundLocationService(16306): App使用记录上报服务初始化成功
D/ForegroundLocationService(16306): 锁屏/解锁广播接收器已注册（服务级）
D/ForegroundLocationService(16306): 网络状态广播接收器已注册
D/ForegroundLocationService(16306): 充电状态广播接收器已注册
D/ForegroundLocationService(16306): 敏感事件上报服务初始化成功
D/ForegroundLocationService(16306): 原生定位客户端初始化成功
D/ForegroundLocationService(16306): 🚑 原生保活健康检查已启动（60秒）
D/ForegroundLocationService(16306): 通知渠道创建成功: kissu_location_service
D/ForegroundLocationService(16306): 🚀 原生定位监听已启动（APP被杀后仍可工作）
W/LocationReportService(16306): ! 保活检查：定时器未运行，重新启动
D/LocationReportService(16306): ⏰ 定时上报器已启动，间隔: 60秒
2
D/LocationReportService(16306): 🛠️ 已调度 WorkManager 单次兜底任务（2分钟后尝试重启服务/定时器）
D/ForegroundLocationService(16306): 🚀 App使用记录上报已启动（每2分钟采集一次，前台/后台统一原生）
D/ForegroundLocationService(16306): 前台定位服务启动成功
W/AppUsageReportService(16306): ! 没有使用情况访问权限，无法采集数据
I/flutter (16306): 📱 旋转后锚点: (0.374, 0.845)
I/flutter (16306): 📱 ============================================
I/flutter (16306): 🎯 Ta的头像: icon=true, anchor=Offset(0.4, 0.8), adjusted=Offset(0.9, 0.8)
I/flutter (16306): ✅ 近距离模式: Ta的头像marker创建成功（左边），位置: LatLng(30.275012, 120.22070500000001)
I/flutter (16306): 🎯 开始创建我的头像marker，头像URL: https://kissustatic.yuluojishu.com/uploads/2025/08/21/c995803f84b964e9b191b1f6a7422a2a.png
I/flutter (16306): 📱 ============ 带背景头像Marker创建 ============
I/flutter (16306): 📱 背景图尺寸: 172.8 x 187.2px
I/flutter (16306): 📱 头像尺寸: 144.0px
I/flutter (16306): 📱 旋转角度: 20.0°
I/flutter (16306): 📱 画布尺寸: 254.8 x 254.8px
I/flutter (16306): 📱 旋转后锚点: (0.626, 0.845)
I/flutter (16306): 📱 ============================================
I/flutter (16306): 🎯 我的头像marker数据: {descriptor: Instance of 'BitmapDescriptor', anchor: Offset(0.6, 0.8)}
I/flutter (16306): 🎯 我的头像: icon=true, anchor=Offset(0.6, 0.8), adjusted=Offset(0.1, 0.8)
I/flutter (16306): ✅ 近距离模式: 我的头像marker创建成功（右边），位置: LatLng(30.275012, 120.22070500000001)
I/flutter (16306): ✅ 近距离模式: GIF占位marker创建成功
I/flutter (16306): 📊 位置数据加载完成
I/AMapFlutter_MapController(16306): onCameraChangeFinish===>{position={bearing=0.0, zoom=20.0, tilt=0.0, target=[30.27501410730366, 120.22070440619896]}}
I/com.yuluo.kiss(16306): NativeAlloc concurrent copying GC freed 21684(1025KB) AllocSpace objects, 4(76KB) LOS objects, 49% free, 6275KB/12MB, paused 435us total 107.417ms DisableRefAccess:0.522ms(0.522ms)
I/flutter (16306): 📍 已绑定状态，计算双人中心位置
I/flutter (16306): 📍 双人位置：我(30.275012, 120.22070500000001) 伴侣(30.275012, 120.22070500000001) 中心(LatLng(30.275012, 120.22070500000001))
I/flutter (16306): 📱 旋转后锚点: (0.626, 0.845)
I/flutter (16306): 📱 ============================================
I/flutter (16306): 🎯 我的头像marker数据: {descriptor: Instance of 'BitmapDescriptor', anchor: Offset(0.6, 0.8)}
I/flutter (16306): 🎯 我的头像: icon=true, anchor=Offset(0.6, 0.8), adjusted=Offset(0.1, 0.8)
I/flutter (16306): ✅ 近距离模式: 我的头像marker创建成功（右边），位置: LatLng(30.275012, 120.22070500000001)
I/flutter (16306): ✅ 近距离模式: GIF占位marker创建成功
D/ForegroundLocationService(16306): 📍 原生定位成功: 30.275005109618835, 120.22069827341741, 精度: 37.0m
D/ForegroundLocationService(16306): 定位成功，静默模式（不更新通知）
I/flutter (16306): 📍 已绑定状态，计算双人中心位置
I/flutter (16306): 📍 双人位置：我(30.275012, 120.22070500000001) 伴侣(30.275012, 120.22070500000001) 中心(LatLng(30.275012, 120.22070500000001))
D/LocationReportService(16306): 📦 收集池为空，直接放入: 30.275005109618835, 120.22069827341741, 精度: 37.0m
D/LocationReportService(16306): 🔑 读取用户信息: token=已存在(eyJ0eXAiOiJKV1QiLCJh...), userId=189, baseUrl=http://dev-love-api.ikissu.cn
D/LocationReportService(16306): 📦 位置已收集到缓冲区 (1/12): 30.275005109618835, 120.22069827341741
D/LocationReportService(16306): 📍 最后收集位置已更新: 30.275005109618835, 120.22069827341741
I/AMapFlutter_MarkersController(16306): GIF尺寸设置: 747x949
I/AMapFlutter_MarkersController(16306): ✅ 启动GIF异步加载: markerId=gif_marker, assetPath=assets/gif/ceshi.gif
I/flutter (16306): ✅ 近距离模式: GIF动画启动成功
I/AMapFlutter_MarkersController(16306): ✅ 启动Marker摆动动画: markerId=partner_marker, from=-20.0°, to=-5.0°, duration=800ms
I/flutter (16306): ✅ 近距离模式: Ta的摆动动画启动
I/AMapFlutter_MarkersController(16306): ✅ 启动Marker摆动动画: markerId=my_marker, from=20.0°, to=5.0°, duration=800ms
I/flutter (16306): ✅ 近距离模式: 我的摆动动画启动
I/AMapFlutter_GifMarkerController(16306): GIF动画已停止
I/AMapFlutter_GifMarkerController(16306): 已回收非缓存GIF帧资源
I/AMapFlutter_MarkersController(16306): GIF尺寸设置: 747x949
I/AMapFlutter_MarkersController(16306): ✅ 启动GIF异步加载: markerId=gif_marker, assetPath=assets/gif/ceshi.gif
I/flutter (16306): ✅ 近距离模式: GIF动画启动成功
I/AMapFlutter_MarkersController(16306): ✅ 启动Marker摆动动画: markerId=partner_marker, from=-20.0°, to=-5.0°, duration=800ms
I/flutter (16306): ✅ 近距离模式: Ta的摆动动画启动
I/AMapFlutter_MarkersController(16306): ✅ 启动Marker摆动动画: markerId=my_marker, from=20.0°, to=5.0°, duration=800ms
I/flutter (16306): ✅ 近距离模式: 我的摆动动画启动
I/AMapFlutter_GifFrameCache(16306): ✅ GIF预加载完成: assets/gif/ceshi.gif_747x949, 帧数: 210, 耗时: 3723ms
I/AMapFlutter_GifPreloadPlugin(16306): GIF预加载完成: assets/gif/ceshi.gif, 成功: true
I/AMapFlutter_GifMarkerController(16306): GIF帧数: 210
I/flutter (16306): [LogManager] Not initialized. Message: 为收集池请求单次定位...
I/flutter (16306): [LogManager] Not initialized. Message: 单次定位已在进行中，跳过重复请求
I/flutter (16306): [LogManager] Not initialized. Message: 5秒后检查：定位是否有数据回调...
I/flutter (16306): [LogManager] Not initialized. Message: 5秒后仍未收到定位数据，尝试单次定位...
I/flutter (16306): [LogManager] Not initialized. Message: 尝试单次定位作为备用方案...