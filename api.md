: │ 💡 重置控制器状态
I/flutter (23619): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): [LogManager] Not initialized. Message: 200 GET http://dev-love-api.ikissu.cn/index (328ms)
I/flutter (23619): [LogManager] Not initialized. Message: Response: {
I/flutter (23619):   "isSuccess": true,
I/flutter (23619):   "code": 0,
I/flutter (23619):   "msg": "",
I/flutter (23619):   "data": null,
I/flutter (23619):   "dataList": null,
I/flutter (23619):   "dataJson": {
I/flutter (23619):     "is_red_dot": 0,
I/flutter (23619):     "is_system_notice_red_dot": 0,
I/flutter (23619):     "is_interaction_notice_red_dot": 0,
I/flutter (23619):     "activity": {
I/flutter (23619):       "is_pop_ads": 0,
I/flutter (23619):       "watch_ads_nums": 0,
I/flutter (23619):       "is_ads_exempt": 0,
I/flutter (23619):       "is_ads_count_down": 0,
I/flutter (23619):       "ads_count_down": 0,
I/flutter (23619):       "is_activity": 1,
I/flutter (23619):       "is_activity_icon": "https://kissustatic.yuluojishu.com/uploads/2025/09/05/3e4bcaa18cd0b27710bbce9d748a258e.png",
I/flutter (23619):       "a... (truncated)
I/flutter (23619): ✅ Request GET /index - 340ms - Status: 200
I/flutter (23619): SUCCESS: 🏠 首页数据请求成功
I/flutter (23619): INFO: 首页数据结构: [is_red_dot, is_system_notice_red_dot, is_interaction_notice_red_dot, activity, location, user, photo, weather, vip_data]
I/flutter (23619): 📊 红点信息更新: 系统消息=0, 互动消息=0, 总数=0, 显示红点=false
I/flutter (23619): ✅ 用户头像已更新: https://kissustatic.yuluojishu.com/uploads/2025/09/11/e00b3be4bb4801e07a62ff4080fb6d13.png
I/flutter (23619): ✅ 伴侣头像已更新: https://kissustatic.yuluojishu.com/uploads/2025/09/11/e00b3be4bb4801e07a62ff4080fb6d13.png
I/flutter (23619): 📸 照片墙URL: https://kissustatic.yuluojishu.com/uploads/2025/10/21/87783e72474a60d2ed35d7cd3f769dea.png
I/flutter (23619): 🌤️ 开始解析首页天气数据
I/flutter (23619): 🌤️ 解析 base 数据: icon=https://kissustatic.yuluojishu.com/uploads/2025/09/23/b17d2ef38497f4ca09a61cb0a93eefa2.png, weather=多云, temp=29
I/flutter (23619): 🌤️ 解析 all 数据: min=24, max=32
I/flutter (23619): ✅ 天气数据解析成功
I/flutter (23619): ✅ 首页数据加载成功: 绑定状态=true, 恋爱天数=0, 距离=未知
2
I/flutter (23619): ✅ 头像预加载成功: https://kissustatic.yuluojishu.com/uploads/2025/09/11/e00b3be4bb4801e07a62ff4080fb6d13.png
I/flutter (23619): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): │ #0   VipController._loadVipBannerData (package:kissu_app/pages/vip/vip_controller.dart:387:15)
vip_controller.dart:387
I/flutter (23619): │ #1   VipController.onReady.<anonymous closure> (package:kissu_app/pages/vip/vip_controller.dart:159:9)
vip_controller.dart:159
I/flutter (23619): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (23619): │ 💡 开始加载VIP横幅和评价数据...
I/flutter (23619): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): [LogManager] Not initialized. Message: DeviceUtil not initialized, using fallback deviceId
I/flutter (23619): INFO: OAID 已添加到请求头
I/flutter (23619): [LogManager] Not initialized. Message: DeviceUtil not initialized, using fallback deviceId
I/flutter (23619): INFO: OAID 已添加到请求头
I/flutter (23619): [LogManager] Not initialized. Message: GET http://dev-love-api.ikissu.cn/pay/iconBanner
I/flutter (23619): [LogManager] Not initialized. Message: Headers: {network_debounce: true, token: ***HIDDEN***, version: 1.0.6, pkg: com.yuluo.kissu, deviceid: android-1763704949947, oaid: 18887152-1202-4a74-9d32-2b825f7d3d73, mobile-model: HONOR ALI-AN00, brand: HONOR, channel: kissu_meizu, network-name: wifi_YuluoKeji_5G, power: 79, timestamp: 1763704949948, sign: 5E29707BB46E6E752DACEEC9E305793E}
I/flutter (23619): [LogManager] Not initialized. Message: GET http://dev-love-api.ikissu.cn/get/vipPackageList?os=1
I/flutter (23619): [LogManager] Not initialized. Message: Headers: {network_debounce: true, token: ***HIDDEN***, version: 1.0.6, pkg: com.yuluo.kissu, deviceid: android-1763704949949, oaid: 18887152-1202-4a74-9d32-2b825f7d3d73, mobile-model: HONOR ALI-AN00, brand: HONOR, channel: kissu_meizu, network-name: wifi_YuluoKeji_5G, power: 79, timestamp: 1763704949949, sign: E1F0ABE2D885A144712CD0BA8ECCB30E}
I/flutter (23619): [LogManager] Not initialized. Message: 200 GET http://dev-love-api.ikissu.cn/pay/iconBanner (96ms)
I/flutter (23619): [LogManager] Not initialized. Message: Response: {
I/flutter (23619):   "isSuccess": true,
I/flutter (23619):   "code": 0,
I/flutter (23619):   "msg": "",
I/flutter (23619):   "data": null,
I/flutter (23619):   "dataList": null,
I/flutter (23619):   "dataJson": {
I/flutter (23619):     "comment_list": [
I/flutter (23619):       {
I/flutter (23619):         "date": "11月21日",
I/flutter (23619):         "nickname": "嘟噜噜",
I/flutter (23619):         "content": "让恋爱更有仪式感的小工具，我们都超爱！已经安利给身边所有情侣朋友了！",
I/flutter (23619):         "avatar": "https://kissustatic.yuluojishu.com/uploads/2025/11/12/5c2f222276748148038a2ada2d18c5d7.png",
I/flutter (23619):         "vip_icon": "https://kissustatic.yuluojishu.com/uploads/2025/11/12/4cddff093726fd1219fe2dc378a3c2a5.png",
I/flutter (23619):         "star_image": "https://ki... (truncated)
I/flutter (23619): ✅ Request GET /pay/iconBanner - 135ms - Status: 200
I/flutter (23619): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): │ #0   VipController._loadVipBannerData (package:kissu_app/pages/vip/vip_controller.dart:394:17)
vip_controller.dart:394
I/flutter (23619): │ #1   <asynchronous suspension>
I/flutter (23619): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (23619): │ 💡 VIP页面数据加载完成，轮播图数量: 4, 评价数量: 5
I/flutter (23619): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): [LogManager] Not initialized. Message: 200 GET http://dev-love-api.ikissu.cn/get/vipPackageList?os=1 (122ms)
I/flutter (23619): [LogManager] Not initialized. Message: Response: {
I/flutter (23619):   "isSuccess": true,
I/flutter (23619):   "code": 0,
I/flutter (23619):   "msg": "会员套餐列表",
I/flutter (23619):   "data": null,
I/flutter (23619):   "dataList": null,
I/flutter (23619):   "dataJson": null,
I/flutter (23619):   "listJson": [
I/flutter (23619):     {
I/flutter (23619):       "id": 4,
I/flutter (23619):       "title": "双人永久会员",
I/flutter (23619):       "is_double_vip": 1,
I/flutter (23619):       "is_for_ever_vip": 1,
I/flutter (23619):       "vip_price": "0.01",
I/flutter (23619):       "vip_original_price": "99.99",
I/flutter (23619):       "vip_days": 0,
I/flutter (23619):       "product_id": "",
I/flutter (23619):       "is_subscribe": 0,
I/flutter (23619):       "type": 4,
I/flutter (23619):       "is_discounts": 0,
I/flutter (23619):       "discounts_img": "",
I/flutter (23619):       "activity_desc": "限时特惠",
I/flutter (23619):       "activity_remain_duration": 35850... (truncated)
I/flutter (23619): ✅ Request GET /get/vipPackageList?os=1 - 140ms - Status: 200
D/ForegroundLocationService(23619): 📍 原生定位成功: 30.274879, 120.220996, 精度: 54.0m
D/ForegroundLocationService(23619): 使用RunningAppProcesses检测: 应用在前台
D/ForegroundLocationService(23619): 检测到应用在前台，跳过原生位置上报
D/ForegroundLocationService(23619): ⏸️ 应用在前台，跳过原生位置上报（Flutter正在处理）
D/ForegroundLocationService(23619): 定位成功，静默模式（不更新通知）
I/HiTouch_PressGestureDetector(23619): checkDoublePointerLimit: false
D/Choreographer(23619): still have 1 traversal callbacks
I/HiTouch_PressGestureDetector(23619): checkDoublePointerLimit: false
W/HiTouch_PressGestureDetector(23619): [HiTouch Stop]checkDoublePointerMove
I/HiTouch_PressGestureDetector(23619): checkDoublePointerLimit: false
I/flutter (23619): 🎯 selectPrice被调用: index=1
I/flutter (23619): 🎯 当前套餐数量: 3
I/flutter (23619): 🎯 当前选中索引: 0
I/flutter (23619): 🎯 价格选择成功: 新索引=1, 套餐=双人月度会员
I/flutter (23619): [LogManager] Not initialized. Message: 权限状态更新:
I/flutter (23619): [LogManager] Not initialized. Message: 前台定位: granted
I/flutter (23619): [LogManager] Not initialized. Message: 后台定位: denied
I/HiTouch_PressGestureDetector(23619): checkDoublePointerLimit: false
W/HiTouch_PressGestureDetector(23619): [HiTouch Stop]checkDoublePointerMove
I/flutter (23619): [LogManager] Not initialized. Message: 全局监听器收到定位数据: {callbackTime: 2025-11-21 14:02:33, locationTime: 2025-11-21 14:02:20, locationType: 2, latitude: 30.274879, longitude: 120.220996, accuracy: 54.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 上城区, street: 运河东路, streetNumber: 301号, cityCode: 0571, adCode: 330102, address: 浙江省杭州市上城区运河东路301号靠近中豪·湘和国际, description: 在中豪·湘和国际附近}
I/flutter (23619): [LogManager] Not initialized. Message: 完整定位数据: {callbackTime: 2025-11-21 14:02:33, locationTime: 2025-11-21 14:02:20, locationType: 2, latitude: 30.274879, longitude: 120.220996, accuracy: 54.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 上城区, street: 运河东路, streetNumber: 301号, cityCode: 0571, adCode: 330102, address: 浙江省杭州市上城区运河东路301号靠近中豪·湘和国际, description: 在中豪·湘和国际附近}
I/flutter (23619): [LogManager] Not initialized. Message: _handleLocationReporting: _isFirstLocationSuccess = false
I/flutter (23619): [LogManager] Not initialized. Message: 收集缓冲区当前大小: 1
I/flutter (23619): [LogManager] Not initialized. Message: 位置更新被抛弃: 距离2.9m<50m，抛弃
I/HiTouch_PressGestureDetector(23619): checkDoublePointerLimit: false
W/HiTouch_PressGestureDetector(23619): [HiTouch Stop]checkDoublePointerMove
I/HiTouch_PressGestureDetector(23619): checkDoublePointerLimit: false
W/HiTouch_PressGestureDetector(23619): [HiTouch Stop]checkDoublePointerMove
I/HiTouch_PressGestureDetector(23619): checkDoublePointerLimit: false
I/flutter (23619): 💫 支付按钮被点击，开始购买VIP流程
I/flutter (23619): 💫 当前协议勾选状态: true
I/flutter (23619): 💫 当前是否正在购买: false
I/flutter (23619): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): │ #0   PaymentService.thoroughCheckAndResetPaymentState (package:kissu_app/services/payment_service.dart:698:13)
payment_service.dart:698
I/flutter (23619): │ #1   VipController.purchaseVip (package:kissu_app/pages/vip/vip_controller.dart:868:23)
vip_controller.dart:868
I/flutter (23619): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (23619): │ 💡 开始彻底检查支付状态...
I/flutter (23619): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): │ #0   PaymentService.thoroughCheckAndResetPaymentState (package:kissu_app/services/payment_service.dart:699:13)
payment_service.dart:699
I/flutter (23619): │ #1   VipController.purchaseVip (package:kissu_app/pages/vip/vip_controller.dart:868:23)
vip_controller.dart:868
I/flutter (23619): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (23619): │ 💡 当前支付状态: false
I/flutter (23619): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): │ #0   PaymentService.thoroughCheckAndResetPaymentState (package:kissu_app/services/payment_service.dart:714:13)
payment_service.dart:714
I/flutter (23619): │ #1   VipController.purchaseVip (package:kissu_app/pages/vip/vip_controller.dart:868:23)
vip_controller.dart:868
I/flutter (23619): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (23619): │ 💡 支付状态检查完成，当前状态: false
I/flutter (23619): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): 💫 开始处理支付，支付方式: 支付宝支付
I/flutter (23619): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): │ #0   VipController.purchaseVip (package:kissu_app/pages/vip/vip_controller.dart:877:15)
vip_controller.dart:877
I/flutter (23619): │ #1   VipPage._buildPaymentComponent.<anonymous closure>.<anonymous closure> (package:kissu_app/pages/vip/vip_page.dart:1005:28)
vip_page.dart:1005
I/flutter (23619): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (23619): │ 💡 💫 开始新的支付流程，清理之前的状态
I/flutter (23619): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): │ #0   VipController._processPurchase (package:kissu_app/pages/vip/vip_controller.dart:1034:15)
vip_controller.dart:1034
I/flutter (23619): │ #1   VipController.purchaseVip (package:kissu_app/pages/vip/vip_controller.dart:880:13)
vip_controller.dart:880
I/flutter (23619): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (23619): │ 💡 💫 开始处理购买流程，套餐: 双人月度会员, 支付方式: 1
I/flutter (23619): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): │ #0   VipController._processPurchase (package:kissu_app/pages/vip/vip_controller.dart:1070:17)
vip_controller.dart:1070
I/flutter (23619): │ #1   VipController.purchaseVip (package:kissu_app/pages/vip/vip_controller.dart:880:13)
vip_controller.dart:880
I/flutter (23619): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (23619): │ 💡 💫 开始创建支付宝支付订单
I/flutter (23619): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): [LogManager] Not initialized. Message: DeviceUtil not initialized, using fallback deviceId
I/flutter (23619): INFO: OAID 已添加到请求头
I/flutter (23619): [LogManager] Not initialized. Message: POST http://dev-love-api.ikissu.cn/pay/aliPay
I/flutter (23619): [LogManager] Not initialized. Message: Headers: {network_debounce: true, content-type: application/json, token: ***HIDDEN***, version: 1.0.6, pkg: com.yuluo.kissu, deviceid: android-1763704954975, oaid: 18887152-1202-4a74-9d32-2b825f7d3d73, mobile-model: HONOR ALI-AN00, brand: HONOR, channel: kissu_meizu, network-name: wifi_YuluoKeji_5G, power: 79, timestamp: 1763704954976, sign: 2682C9651DBA1D17A3D0F82D9FB20D54}
I/flutter (23619): [LogManager] Not initialized. Message: Request: {
I/flutter (23619):   "vip_package_id": 1
I/flutter (23619): }
I/flutter (23619): [LogManager] Not initialized. Message: 200 POST http://dev-love-api.ikissu.cn/pay/aliPay (132ms)
I/flutter (23619): [LogManager] Not initialized. Message: Response: {
I/flutter (23619):   "isSuccess": true,
I/flutter (23619):   "code": 0,
I/flutter (23619):   "msg": "订单创建成功",
I/flutter (23619):   "data": null,
I/flutter (23619):   "dataList": null,
I/flutter (23619):   "dataJson": {
I/flutter (23619):     "ali_pay_str": "format=json&charset=utf-8&sign_type=RSA2&version=1.0&method=alipay.trade.app.pay&notify_url=http%3A%2F%2Fdev-love-api.ikissu.cn%2Fnotify%2FaliPayNotify&app_id=2021005173620334&biz_content=%7B%22subject%22%3A%22%5Cu53cc%5Cu4eba%5Cu6708%5Cu5ea6%5Cu4f1a%5Cu5458%22%2C%22out_trade_no%22%3A%22202511211402356862999616%22%2C%22total_amount%22%3A%220.01%22%2C%22product_code%22%3A... (truncated)
I/flutter (23619): ✅ Request POST /pay/aliPay - 147ms - Status: 200
I/flutter (23619): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): │ #0   VipController._processPurchase (package:kissu_app/pages/vip/vip_controller.dart:1072:17)
vip_controller.dart:1072
I/flutter (23619): │ #1   <asynchronous suspension>
I/flutter (23619): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (23619): │ 💡 💫 支付宝订单创建结果: isSuccess=true, msg=订单创建成功
I/flutter (23619): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): │ #0   VipController._processPurchase (package:kissu_app/pages/vip/vip_controller.dart:1077:19)
vip_controller.dart:1077
I/flutter (23619): │ #1   <asynchronous suspension>
I/flutter (23619): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (23619): │ 💡 💫 支付宝订单创建成功，orderString长度: 840
I/flutter (23619): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): │ #0   VipController._processPurchase (package:kissu_app/pages/vip/vip_controller.dart:1080:19)
vip_controller.dart:1080
I/flutter (23619): │ #1   <asynchronous suspension>
I/flutter (23619): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (23619): │ 💡 💫 支付宝订单字符串前100字符: format=json&charset=utf-8&sign_type=RSA2&version=1.0&method=alipay.trade.app.pay&notify_url=http%3A%...
I/flutter (23619): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): │ #0   VipController._processPurchase (package:kissu_app/pages/vip/vip_controller.dart:1085:19)
vip_controller.dart:1085
I/flutter (23619): │ #1   <asynchronous suspension>
I/flutter (23619): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (23619): │ 💡 💫 开始调用支付宝支付SDK
I/flutter (23619): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): │ #0   PaymentService.payWithAlipay (package:kissu_app/services/payment_service.dart:430:15)
payment_service.dart:430
I/flutter (23619): │ #1   VipController._processPurchase (package:kissu_app/pages/vip/vip_controller.dart:1086:42)
vip_controller.dart:1086
I/flutter (23619): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (23619): │ 💡 开始支付宝支付流程，orderInfo长度: 840
I/flutter (23619): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): │ #0   PaymentService.payWithAlipay (package:kissu_app/services/payment_service.dart:463:15)
payment_service.dart:463
I/flutter (23619): │ #1   VipController._processPurchase (package:kissu_app/pages/vip/vip_controller.dart:1086:42)
vip_controller.dart:1086
I/flutter (23619): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (23619): │ 💡 检查支付宝安装状态...
[GETX] OPEN DIALOG 226313540
I/flutter (23619): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): │ #0   PaymentService.isAlipayInstalled (package:kissu_app/services/payment_service.dart:566:15)
payment_service.dart:566
I/flutter (23619): │ #1   <asynchronous suspension>
I/flutter (23619): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (23619): │ 🐛 支付宝安装检测结果: true
I/flutter (23619): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): │ #0   PaymentService.payWithAlipay (package:kissu_app/services/payment_service.dart:465:15)
payment_service.dart:465
I/flutter (23619): │ #1   <asynchronous suspension>
I/flutter (23619): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (23619): │ 💡 支付宝安装状态: true
I/flutter (23619): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): │ #0   PaymentService.payWithAlipay (package:kissu_app/services/payment_service.dart:479:17)
payment_service.dart:479
I/flutter (23619): │ #1   <asynchronous suspension>
I/flutter (23619): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (23619): │ 💡 正在调用原生支付宝支付，orderInfo前100字符: format=json&charset=utf-8&sign_type=RSA2&version=1.0&method=alipay.trade.app.pay&notify_url=http%3A%...
I/flutter (23619): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
D/MainActivity(23619): 收到支付宝支付请求，orderInfo长度: 840
D/MainActivity(23619): 开始支付宝支付，orderInfo长度: 840
D/MainActivity(23619): orderInfo前100字符: format=json&charset=utf-8&sign_type=RSA2&version=1.0&method=alipay.trade.app.pay&notify_url=http%3A%...
D/MainActivity(23619): 创建PayTask并调用支付
D/MainActivity(23619): PayTask创建成功，开始调用payV2
D/FullScreenUtils(23619): isNeedToHideStatusBar: splitscreenstate=-1
D/InputEventReceiver(23619): dispatchInputInterval 1000000
I/HwForceDarkManager(23619): isSystemInDarkMode isResUiModeYes: false, isDarkMode: false
D/HiTouch_PressGestureDetector(23619): onAttached:2
D/FullScreenUtils(23619): isNeedToHideStatusBar: splitscreenstate=-1
D/VRI[MainActivity](23619): relayoutWindow: mRelayoutRequested = true
I/BufferQueueConsumer(23619): [](id:5c4300000005,api:0,p:-1,c:23619) connect: controlledByApp=false
D/FullScreenUtils(23619): isNeedToHideStatusBar: splitscreenstate=-1
V/VRI[MainActivity](23619): Visible with new config: {1.0 460mcc1mnc [zh_CN_#Hans] ldltr sw369dp w369dp h816dp 520dpi nrml long port finger -keyb/v/h -nav/h winConfig={ mBounds=Rect(0, 0 - 1200, 2652) mAppBounds=Rect(0, 0 - 1200, 2652) mMaxBounds=Rect(0, 0 - 1200, 2652) mDisplayRotation=ROTATION_0 mWindowingMode=fullscreen mActivityType=standard mAlwaysOnTop=undefined mRotation=ROTATION_0 mPopOverMode=undefined} suim:1 fontWeightScale:100 changeUserFlag:0 changeUiModeFlag:0 fullScreenVideoFlag:0 splitScreenState:0 landScapeFreeformFlag:1 hoverMode:0 changeIconStyleFlag:0 changeThemeStyleFlag:0 s.2 fontWeightAdjustment=0}
V/VRI[MainActivity](23619): Applying new config to window com.yuluo.kissu/com.yuluo.kissu.MainActivity, globalConfig: {1.0 460mcc1mnc [zh_CN_#Hans] ldltr sw369dp w369dp h816dp 520dpi nrml long port finger -keyb/v/h -nav/h winConfig={ mBounds=Rect(0, 0 - 1200, 2652) mAppBounds=Rect(0, 0 - 1200, 2652) mMaxBounds=Rect(0, 0 - 1200, 2652) mDisplayRotation=ROTATION_0 mWindowingMode=fullscreen mActivityType=undefined mAlwaysOnTop=undefined mRotation=ROTATION_0 mPopOverMode=undefined} suim:1 fontWeightScale:100 changeUserFlag:0 changeUiModeFlag:0 fullScreenVideoFlag:0 splitScreenState:0 landScapeFreeformFlag:1 hoverMode:0 changeIconStyleFlag:0 changeThemeStyleFlag:0 s.14 fontWeightAdjustment=0}, overrideConfig: {1.0 460mcc1mnc [zh_CN_#Hans] ldltr sw369dp w369dp h816dp 520dpi nrml long port finger -keyb/v/h -nav/h winConfig={ mBounds=Rect(0, 0 - 1200, 2652) mAppBounds=Rect(0, 0 - 1200, 2652) mMaxBounds=Rect(0, 0 - 1200, 2652) mDisplayRotation=ROTATION_0 mWindowingMode=fullscreen mActivityType=standard mAlwaysOnTop=undefined mRotation=ROTATION_0 mPopOverMode=undefined} suim:1 fontWeightScale:100 changeUserFlag:0 changeUiModeFlag:0 fullScreenVideoFlag:0 splitScreenState:0 landScapeFreeformFlag:1 hoverMode:0 changeIconStyleFlag:0 changeThemeStyleFlag:0 s.2 fontWeightAdjustment=0}
D/FullScreenUtils(23619): isNeedToHideStatusBar: splitscreenstate=-1
I/HwForceDarkManager(23619): isSystemInDarkMode isResUiModeYes: false, isDarkMode: false
D/FullScreenUtils(23619): isNeedToHideStatusBar: splitscreenstate=-1
D/libEGL  (23619): [eglCreateWindowSurface] start window is 12970367400264467392
I/BufferQueueProducer(23619): [VRI[MainActivity]#5(BLAST Consumer)5](id:5c4300000005,api:0,p:-1,c:23619) connect: api=1 producerControlledByApp=true
I/HwForceDarkManager(23619): setAllowedHwForceDark:false package:com.yuluo.kissu mCurrProcessState:0 mIsPackageNameChange:false hwForceDarkState:0 isViewAllowedForceDark:true isLastHonorForceDark:false
D/HWUI    (23619): disableOutlineDraw is true
I/flutter (23619): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): │ #0   _AppLifecycleObserver.didChangeAppLifecycleState (package:kissu_app/services/payment_service.dart:779:29)
payment_service.dart:779
I/flutter (23619): │ #1   WidgetsBinding.handleAppLifecycleStateChanged (package:flutter/src/widgets/binding.dart:1063:16)
binding.dart:1063
I/flutter (23619): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (23619): │ 💡 应用生命周期变化: AppLifecycleState.inactive
I/flutter (23619): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): 应用状态变化: AppLifecycleState.inactive
I/flutter (23619): ⏸️ 应用变为非活跃状态
W/SQLiteLog(23619): (28) double-quoted string literal: "
W/SQLiteLog(23619): (28) double-quoted string literal: "ED44AA16A9287D620C343C6CF6CDBC87"
I/HwViewRootImpl(23619): removeInvalidNode all the node in jank list is out of time
I/SurfaceControl(23619): nativeRelease 0xb400006daf083af0 count: 1 name: Surface(name=8814df7 InputMethod)/@0xe19a6cd - animation-leash of insets_animation#159338
I/SurfaceControl(23619): nativeRelease 0xb400006daf084750 count: 1 name: Surface(name=aea8227 StatusBar)/@0xc7e7ccc - animation-leash of insets_animation#159335
I/SurfaceControl(23619): nativeRelease 0xb400006daf067230 count: 1 name: Surface(name=4ccc675 NavigationBar0)/@0xda97b15 - animation-leash of insets_animation#159362
I/SurfaceControl(23619): nativeRelease 0xb400006daf08e4d0 count: 1 name: Surface(name=aea8227 StatusBar)/@0xc7e7ccc - animation-leash of insets_animation#159366
I/SurfaceControl(23619): nativeRelease 0xb400006daf006510 count: 1 name: Surface(name=4ccc675 NavigationBar0)/@0xda97b15 - animation-leash of insets_animation#159367
I/VRI[MainActivity](23619): send MSG_WINDOW_FOCUS_CHANGED msg
I/InputEventReceiver(23619): consumeEvents focus, 0
D/RtgSchedIpcFile(23619): setCommandByIoctl failed ret:-1, cmdid:20, errno:101
I/SurfaceControl(23619): nativeRelease 0xb400006daf08c9d0 count: 1 name: Surface(name=aea8227 StatusBar)/@0xc7e7ccc - animation-leash of insets_animation#159366
I/SurfaceControl(23619): nativeRelease 0xb400006daf0544b0 count: 1 name: Surface(name=4ccc675 NavigationBar0)/@0xda97b15 - animation-leash of insets_animation#159367
D/RtgSchedIpcFile(23619): setCommandByIoctl failed ret:-1, cmdid:21, errno:101
I/SurfaceControl(23619): nativeRelease 0xb400006daefa2d30 count: 1 name: Surface(name=8814df7 InputMethod)/@0xe19a6cd - animation-leash of insets_animation#159338
D/RtgSchedIpcFile(23619): setCommandByIoctl failed ret:-1, cmdid:20, errno:101
D/RtgSchedIpcFile(23619): setCommandByIoctl failed ret:-1, cmdid:21, errno:101
I/RmeSchedManager(23619): init Rme, version is: v1.0
D/RtgSched(23619): resetRtgSchedHandle failed enable:0
I/VRI[MainActivity](23619): send MSG_WINDOW_FOCUS_CHANGED msg
I/InputEventReceiver(23619): consumeEvents focus, 1
D/ActivityThread(23619): Won't deliver top position change in state=4
I/DecorView[](23619): set decor visibility 0
I/SurfaceControl(23619): nativeRelease 0xb400006daeffadb0 count: 1 name: Surface(name=8814df7 InputMethod)/@0xe19a6cd - animation-leash of insets_animation#159338
I/SurfaceControl(23619): nativeRelease 0xb400006daf07a790 count: 1 name: Surface(name=aea8227 StatusBar)/@0xc7e7ccc - animation-leash of insets_animation#159371
I/SurfaceControl(23619): nativeRelease 0xb400006daf086130 count: 1 name: Surface(name=4ccc675 NavigationBar0)/@0xda97b15 - animation-leash of insets_animation#159372
D/FullScreenUtils(23619): isNeedToHideStatusBar: splitscreenstate=-1
D/MobclickAgent(23619): 延续上一个会话: ED44AA16A9287D620C343C6CF6CDBC87
W/SQLiteLog(23619): (28) double-quoted string literal: "ED44AA16A9287D620C343C6CF6CDBC87"
W/SQLiteLog(23619): (28) double-quoted string literal: ""
W/SQLiteLog(23619): (28) double-quoted string literal: "ED44AA16A9287D620C343C6CF6CDBC87"
W/SQLiteLog(23619): (28) double-quoted string literal: "-1"
D/UMLog   (23619): 当前发送策略为: 间隔发送。间隔时间为：90秒。详见链接 https://developer.umeng.com/docs/66632/detail/66976?um_channel=sdk
D/ForegroundLocationService(23619): 📍 原生定位成功: 30.274879, 120.220996, 精度: 54.0m
D/ForegroundLocationService(23619): 使用RunningAppProcesses检测: 应用在前台
D/ForegroundLocationService(23619): 检测到应用在前台，跳过原生位置上报
D/ForegroundLocationService(23619): ⏸️ 应用在前台，跳过原生位置上报（Flutter正在处理）
D/ForegroundLocationService(23619): 定位成功，静默模式（不更新通知）
I/SurfaceControl(23619): nativeRelease 0xb400006daf00dc50 count: 1 name: Surface(name=aea8227 StatusBar)/@0xc7e7ccc - animation-leash of insets_animation#159373
I/SurfaceControl(23619): nativeRelease 0xb400006daf08d630 count: 1 name: Surface(name=4ccc675 NavigationBar0)/@0xda97b15 - animation-leash of insets_animation#159374
I/SurfaceControl(23619): nativeRelease 0xb400006daf086d90 count: 1 name: Surface(name=8814df7 InputMethod)/@0xe19a6cd - animation-leash of insets_animation#159338
I/VRI[MainActivity](23619): send MSG_WINDOW_FOCUS_CHANGED msg
I/InputEventReceiver(23619): consumeEvents focus, 0
W/SQLiteLog(23619): (28) double-quoted string literal: "
W/SQLiteLog(23619): (28) double-quoted string literal: "ED44AA16A9287D620C343C6CF6CDBC87"
I/ViewRootImpl(23619): focus window changed, set pointer icon to default
W/WindowOnBackDispatcher(23619): sendCancelIfRunning: isInProgress=false callback=android.app.Dialog$$ExternalSyntheticLambda2@64f2c14
I/VRI[MainActivity](23619): dispatchDetachedFromWindow in doDie
D/HiTouch_PressGestureDetector(23619): onDetached:false
D/libEGL  (23619): [eglDestroySurface] start surface is 0xb400006e80fbb3a0
I/BufferQueueProducer(23619): [VRI[MainActivity]#5(BLAST Consumer)5](id:5c4300000005,api:1,p:23619,c:23619) disconnect: api 1
I/SurfaceControl(23619): nativeRelease 0xb400006daf087570 count: 8 name: com.yuluo.kissu/com.yuluo.kissu.MainActivity#159368
I/SurfaceControl(23619): nativeRelease 0xb400006daf083790 count: 1 name: Surface(name=8814df7 InputMethod)/@0xe19a6cd - animation-leash of insets_animation#159338
I/SurfaceControl(23619): nativeRelease 0xb400006daf08e4d0 count: 1 name: Surface(name=aea8227 StatusBar)/@0xc7e7ccc - animation-leash of insets_animation#159377
I/SurfaceControl(23619): nativeRelease 0xb400006daef78250 count: 1 name: Surface(name=4ccc675 NavigationBar0)/@0xda97b15 - animation-leash of insets_animation#159378
I/BufferQueueConsumer(23619): [VRI[MainActivity]#5(BLAST Consumer)5](id:5c4300000005,api:0,p:-1,c:23619) disconnect
D/ZrHung.AppEyeUiProbe(23619): not watching, wait.
I/InputMethodManager(23619): handleMessage: MSG_SET_ACTIVE false, was true
I/InputMethodManager(23619): handleMessage: MSG_UNBIND 12973 reason=SWITCH_CLIENT
V/InputMethodManager(23619): Clearing all accessibility bindings
V/InputMethodManager(23619): Clearing binding!
I/SurfaceControl(23619): nativeRelease 0xb400006daf08e950 count: 1 name: Surface(name=8814df7 InputMethod)/@0xe19a6cd - animation-leash of insets_animation#159338
D/TrafficStats(23619): tagSocket(190) with statsTag=0xffffffff, statsUid=-1
D/OpenInstall(23619): statEvents success
D/TrafficStats(23619): tagSocket(190) with statsTag=0xffffffff, statsUid=-1
I/flutter (23619): [LogManager] Not initialized. Message: 全局监听器收到定位数据: {callbackTime: 2025-11-21 14:02:38, locationTime: 2025-11-21 14:02:20, locationType: 2, latitude: 30.274879, longitude: 120.220996, accuracy: 54.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 上城区, street: 运河东路, streetNumber: 301号, cityCode: 0571, adCode: 330102, address: 浙江省杭州市上城区运河东路301号靠近中豪·湘和国际, description: 在中豪·湘和国际附近}
I/flutter (23619): [LogManager] Not initialized. Message: 完整定位数据: {callbackTime: 2025-11-21 14:02:38, locationTime: 2025-11-21 14:02:20, locationType: 2, latitude: 30.274879, longitude: 120.220996, accuracy: 54.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 上城区, street: 运河东路, streetNumber: 301号, cityCode: 0571, adCode: 330102, address: 浙江省杭州市上城区运河东路301号靠近中豪·湘和国际, description: 在中豪·湘和国际附近}
I/flutter (23619): [LogManager] Not initialized. Message: _handleLocationReporting: _isFirstLocationSuccess = false
I/flutter (23619): [LogManager] Not initialized. Message: 收集缓冲区当前大小: 1
I/flutter (23619): [LogManager] Not initialized. Message: 位置更新被抛弃: 距离2.9m<50m，抛弃
D/TrafficStats(23619): tagSocket(365) with statsTag=0xffffffff, statsUid=-1
I/flutter (23619): INFO: 电量缓存已清除
I/flutter (23619): INFO: 电池状态变化，已清除电量缓存
I/flutter (23619): 🔔 定时刷新首页数据...
I/flutter (23619): 🏠 开始加载首页数据...
I/flutter (23619): INFO: 🏠 开始请求首页数据...
I/flutter (23619): [LogManager] Not initialized. Message: DeviceUtil not initialized, using fallback deviceId
I/flutter (23619): INFO: OAID 已添加到请求头
I/flutter (23619): INFO: 电量缓存已更新: 79%
I/flutter (23619): [LogManager] Not initialized. Message: GET http://dev-love-api.ikissu.cn/index
I/flutter (23619): [LogManager] Not initialized. Message: Headers: {cache_control: noCache, token: ***HIDDEN***, version: 1.0.6, pkg: com.yuluo.kissu, deviceid: android-1763704959559, oaid: 18887152-1202-4a74-9d32-2b825f7d3d73, mobile-model: HONOR ALI-AN00, brand: HONOR, channel: kissu_meizu, network-name: wifi_YuluoKeji_5G, power: 79, timestamp: 1763704959562, sign: 70096899F4E10D208896C29DF14748B7}
I/flutter (23619): [LogManager] Not initialized. Message: 200 GET http://dev-love-api.ikissu.cn/index (263ms)
I/flutter (23619): [LogManager] Not initialized. Message: Response: {
I/flutter (23619):   "isSuccess": true,
I/flutter (23619):   "code": 0,
I/flutter (23619):   "msg": "",
I/flutter (23619):   "data": null,
I/flutter (23619):   "dataList": null,
I/flutter (23619):   "dataJson": {
I/flutter (23619):     "is_red_dot": 0,
I/flutter (23619):     "is_system_notice_red_dot": 0,
I/flutter (23619):     "is_interaction_notice_red_dot": 0,
I/flutter (23619):     "activity": {
I/flutter (23619):       "is_pop_ads": 0,
I/flutter (23619):       "watch_ads_nums": 0,
I/flutter (23619):       "is_ads_exempt": 0,
I/flutter (23619):       "is_ads_count_down": 0,
I/flutter (23619):       "ads_count_down": 0,
I/flutter (23619):       "is_activity": 1,
I/flutter (23619):       "is_activity_icon": "https://kissustatic.yuluojishu.com/uploads/2025/09/05/3e4bcaa18cd0b27710bbce9d748a258e.png",
I/flutter (23619):       "a... (truncated)
I/flutter (23619): ✅ Request GET /index - 276ms - Status: 200
I/flutter (23619): SUCCESS: 🏠 首页数据请求成功
I/flutter (23619): INFO: 首页数据结构: [is_red_dot, is_system_notice_red_dot, is_interaction_notice_red_dot, activity, location, user, photo, weather, vip_data]
I/flutter (23619): 📊 红点信息更新: 系统消息=0, 互动消息=0, 总数=0, 显示红点=false
I/flutter (23619): ✅ 用户头像已更新: https://kissustatic.yuluojishu.com/uploads/2025/09/11/e00b3be4bb4801e07a62ff4080fb6d13.png
I/flutter (23619): ✅ 伴侣头像已更新: https://kissustatic.yuluojishu.com/uploads/2025/09/11/e00b3be4bb4801e07a62ff4080fb6d13.png
I/flutter (23619): 📸 照片墙URL: https://kissustatic.yuluojishu.com/uploads/2025/10/21/87783e72474a60d2ed35d7cd3f769dea.png
I/flutter (23619): 🌤️ 开始解析首页天气数据
I/flutter (23619): 🌤️ 解析 base 数据: icon=https://kissustatic.yuluojishu.com/uploads/2025/09/23/b17d2ef38497f4ca09a61cb0a93eefa2.png, weather=多云, temp=29
I/flutter (23619): 🌤️ 解析 all 数据: min=24, max=32
I/flutter (23619): ✅ 天气数据解析成功
I/flutter (23619): ✅ 首页数据加载成功: 绑定状态=true, 恋爱天数=0, 距离=未知
2
I/flutter (23619): ✅ 头像预加载成功: https://kissustatic.yuluojishu.com/uploads/2025/09/11/e00b3be4bb4801e07a62ff4080fb6d13.png
D/ForegroundLocationService(23619): 📍 原生定位成功: 30.274879, 120.220996, 精度: 54.0m
D/ForegroundLocationService(23619): 使用RunningAppProcesses检测: 应用在前台
D/ForegroundLocationService(23619): 检测到应用在前台，跳过原生位置上报
D/ForegroundLocationService(23619): ⏸️ 应用在前台，跳过原生位置上报（Flutter正在处理）
D/ForegroundLocationService(23619): 定位成功，静默模式（不更新通知）
I/RmeSchedManager(23619): init Rme, version is: v1.0
I/RtgSchedEvent(23619): current pid:23619 AppType:-1
D/ActivityThread(23619): Won't deliver top position change in state=4
I/DecorView[](23619): set decor visibility 0
D/ZrHung.AppEyeUiProbe(23619): restart watching
D/FullScreenUtils(23619): isNeedToHideStatusBar: splitscreenstate=-1
I/VRI[MainActivity](23619): send MSG_WINDOW_FOCUS_CHANGED msg
I/InputEventReceiver(23619): consumeEvents focus, 1
I/flutter (23619): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): │ #0   _AppLifecycleObserver.didChangeAppLifecycleState (package:kissu_app/services/payment_service.dart:779:29)
payment_service.dart:779
I/flutter (23619): │ #1   WidgetsBinding.handleAppLifecycleStateChanged (package:flutter/src/widgets/binding.dart:1063:16)
binding.dart:1063
I/flutter (23619): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (23619): │ 💡 应用生命周期变化: AppLifecycleState.resumed
I/flutter (23619): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): │ #0   _AppLifecycleObserver.didChangeAppLifecycleState (package:kissu_app/services/payment_service.dart:783:31)
payment_service.dart:783
I/flutter (23619): │ #1   WidgetsBinding.handleAppLifecycleStateChanged (package:flutter/src/widgets/binding.dart:1063:16)
binding.dart:1063
I/flutter (23619): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (23619): │ 💡 应用回到前台，检查支付状态: true
I/flutter (23619): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): │ #0   _AppLifecycleObserver.didChangeAppLifecycleState (package:kissu_app/services/payment_service.dart:789:33)
payment_service.dart:789
I/flutter (23619): │ #1   WidgetsBinding.handleAppLifecycleStateChanged (package:flutter/src/widgets/binding.dart:1063:16)
binding.dart:1063
I/flutter (23619): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (23619): │ 💡 💰 用户从支付应用返回，等待支付结果回调...
I/flutter (23619): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): │ #0   PaymentService._checkForImmediatePaymentCancellation (package:kissu_app/services/payment_service.dart:719:13)
payment_service.dart:719
I/flutter (23619): │ #1   _AppLifecycleObserver.didChangeAppLifecycleState (package:kissu_app/services/payment_service.dart:792:25)
payment_service.dart:792
I/flutter (23619): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
[GETX] CLOSE DIALOG 226313540
I/flutter (23619): │ 💡 🔍 立即检查支付取消状态...
I/flutter (23619): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): │ #0   _AppLifecycleObserver.didChangeAppLifecycleState (package:kissu_app/services/payment_service.dart:795:33)
payment_service.dart:795
I/flutter (23619): │ #1   WidgetsBinding.handleAppLifecycleStateChanged (package:flutter/src/widgets/binding.dart:1063:16)
binding.dart:1063
I/flutter (23619): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (23619): │ 💡 检测到支付进行中，等待原生支付结果回调
I/flutter (23619): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): 📱 应用返回前台，检查是否需要提醒后台定位权限
I/flutter (23619): 📱 首页：应用返回前台，先获取红点数据再启动轮询
I/flutter (23619): 🏠 开始加载首页数据...
I/flutter (23619): INFO: 🏠 开始请求首页数据...
I/flutter (23619): 应用状态变化: AppLifecycleState.resumed
I/flutter (23619): 🔄 应用恢复前台，优化前台策略
I/flutter (23619): INFO: 网络信息缓存已清除
I/flutter (23619): 📡 已清除过期的网络信息缓存
I/flutter (23619): INFO: 电量缓存已清除
I/flutter (23619): 🔋 已清除过期的电量缓存
I/flutter (23619): [LogManager] Not initialized. Message: 外部调用：优化前台策略
I/flutter (23619): [LogManager] Not initialized. Message: 恢复前台位置采集模式
I/flutter (23619): [LogManager] Not initialized. Message: 前台模式参数已应用：Hight_Accuracy / 5000ms / distanceFilter=-1.0
I/flutter (23619): [LogManager] Not initialized. Message: 后台通知未显示，跳过隐藏
2
I/flutter (23619): ✅ 前台策略已优化
I/flutter (23619): 🏠 应用回到前台但首页不可见
V/ImeFocusController(23619): onWindowFocus: io.flutter.embedding.android.FlutterView{cb6e695 VFE...... .F...... 0,0-1200,2652 #1 aid=1073741824} softInputMode=STATE_UNSPECIFIED|ADJUST_RESIZE
V/InputMethodManager(23619): Restarting due to mRestartOnNextWindowFocus as true
W/InputMethodManager(23619): startInputReason = 1
V/InputMethodManager(23619): Starting input: editorInfo=android.view.inputmethod.EditorInfo@72dbf5d ic=null
V/InputMethodManager(23619): START INPUT: view=io.flutter.embedding.android.FlutterView{cb6e695 VFE...... .F...... 0,0-1200,2652 #1 aid=1073741824},focus=true,windowFocus=true,window=android.view.ViewRootImpl$W@a8928d2,displayId=0,temporaryDetach=false,hasImeFocus=true ic=null editorInfo=android.view.inputmethod.EditorInfo@72dbf5d startInputFlags=VIEW_HAS_FOCUS|INITIAL_CONNECTION
I/flutter (23619): 📱 通知权限无变化: true
I/flutter (23619): [LogManager] Not initialized. Message: DeviceUtil not initialized, using fallback deviceId
I/flutter (23619): INFO: OAID 已添加到请求头
I/InputMethodManager(23619): handleMessage: MSG_SET_ACTIVE true, was false
V/InputMethodManager(23619): Starting input: Bind result=InputBindResult{result=SUCCESS_WAITING_IME_SESSION method=null id=com.baidu.input_hihonor/com.baidu.input_honor.ImeService sequence=12981 result=1 isInputMethodSuppressingSpellChecker=false}
I/InputMethodManager(23619): handleMessage: MSG_BIND 12981,com.baidu.input_hihonor/com.baidu.input_honor.ImeService
W/InputMethodManager(23619): startInputReason = 6
V/InputMethodManager(23619): Starting input: editorInfo=android.view.inputmethod.EditorInfo@eb5d82a ic=null
V/InputMethodManager(23619): Starting input: finished by someone else. view=io.flutter.embedding.android.FlutterView{cb6e695 VFE...... .F...... 0,0-1200,2652 #1 aid=1073741824},focus=true,windowFocus=true,window=android.view.ViewRootImpl$W@a8928d2,displayId=0,temporaryDetach=false,hasImeFocus=true servedView=io.flutter.embedding.android.FlutterView{cb6e695 VFE...... .F...... 0,0-1200,2652 #1 aid=1073741824},focus=true,windowFocus=true,window=android.view.ViewRootImpl$W@a8928d2,displayId=0,temporaryDetach=false,hasImeFocus=true mServedConnecting=false
I/flutter (23619): INFO: 电量缓存已更新: 79%
D/MobclickAgent(23619): 延续上一个会话: ED44AA16A9287D620C343C6CF6CDBC87
W/SQLiteLog(23619): (28) double-quoted string literal: "ED44AA16A9287D620C343C6CF6CDBC87"
W/SQLiteLog(23619): (28) double-quoted string literal: ""
I/flutter (23619): [LogManager] Not initialized. Message: GET http://dev-love-api.ikissu.cn/index
I/flutter (23619): [LogManager] Not initialized. Message: Headers: {cache_control: noCache, token: ***HIDDEN***, version: 1.0.6, pkg: com.yuluo.kissu, deviceid: android-1763704962703, oaid: 18887152-1202-4a74-9d32-2b825f7d3d73, mobile-model: HONOR ALI-AN00, brand: HONOR, channel: kissu_meizu, network-name: wifi_YuluoKeji_5G, power: 79, timestamp: 1763704962740, sign: A7F079C47876A8CE1410C954BE222BED}
W/SQLiteLog(23619): (28) double-quoted string literal: "ED44AA16A9287D620C343C6CF6CDBC87"
W/SQLiteLog(23619): (28) double-quoted string literal: "-1"
D/UMLog   (23619): 当前发送策略为: 间隔发送。间隔时间为：90秒。详见链接 https://developer.umeng.com/docs/66632/detail/66976?um_channel=sdk
D/MainActivity(23619): 支付宝支付完成，返回结果类型: HashMap
D/MainActivity(23619): 支付宝支付返回结果: {resultStatus=9000, result={"alipay_trade_app_pay_response":{"code":"10000","msg":"Success","app_id":"2021005173620334","auth_app_id":"2021005173620334","charset":"utf-8","timestamp":"2025-11-21 14:02:41","out_trade_no":"202511211402356862999616","total_amount":"0.01","trade_no":"2025112122001430251455813249","seller_id":"2088641110392595"},"sign":"fz/mXzGCC0+vfI4ZHxIPl6rTcHtKpM+Fz4HSHhvFIoZEtHIoThkYBl+wynGkykOhQmih0b3ayhSs4gAfFia8rHDg2sDoD/NWtZ+BoJopBnozjfgKREhlVN4SJszOfwj5X9UPvT/sv4BnxDcndjemAAj3/9buNzF7UQz6sXLMjG6I3+mG1WhDaGctbAJXKd44B3M4whofAwK2aWkoazi22wAZZBnt1kRL5Hlx3jD2+2MVek/YNtedU9ghIXMv/Yjd3U8plell/TPcmm/cu7B7F1D4kTSwv4qHEgxmz8jkUK0aEGRs+SaWMYAeiUDp9E4a1XZvLYmXCBE58X7h9vcU6w==","sign_type":"RSA2"}, externalSdkData={"preheatUserToken":"bb0eae908643a4c780be524731cc814a"}, memo=, extendInfo={"doNotExit":true,"isDisplayResult":true,"tradeNo":"2025112122001430251455813249"}}
D/MainActivity(23619): 解析支付宝支付结果: resultStatus=9000, 完整结果={resultStatus=9000, result={"alipay_trade_app_pay_response":{"code":"10000","msg":"Success","app_id":"2021005173620334","auth_app_id":"2021005173620334","charset":"utf-8","timestamp":"2025-11-21 14:02:41","out_trade_no":"202511211402356862999616","total_amount":"0.01","trade_no":"2025112122001430251455813249","seller_id":"2088641110392595"},"sign":"fz/mXzGCC0+vfI4ZHxIPl6rTcHtKpM+Fz4HSHhvFIoZEtHIoThkYBl+wynGkykOhQmih0b3ayhSs4gAfFia8rHDg2sDoD/NWtZ+BoJopBnozjfgKREhlVN4SJszOfwj5X9UPvT/sv4BnxDcndjemAAj3/9buNzF7UQz6sXLMjG6I3+mG1WhDaGctbAJXKd44B3M4whofAwK2aWkoazi22wAZZBnt1kRL5Hlx3jD2+2MVek/YNtedU9ghIXMv/Yjd3U8plell/TPcmm/cu7B7F1D4kTSwv4qHEgxmz8jkUK0aEGRs+SaWMYAeiUDp9E4a1XZvLYmXCBE58X7h9vcU6w==","sign_type":"RSA2"}, externalSdkData={"preheatUserToken":"bb0eae908643a4c780be524731cc814a"}, memo=, extendInfo={"doNotExit":true,"isDisplayResult":true,"tradeNo":"2025112122001430251455813249"}}
D/MainActivity(23619): 支付宝支付成功
D/MainActivity(23619): 解析后的支付结果: success=true, message=支付成功
I/flutter (23619): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): │ #0   PaymentService.payWithAlipay (package:kissu_app/services/payment_service.dart:486:17)
payment_service.dart:486
I/flutter (23619): │ #1   <asynchronous suspension>
I/flutter (23619): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (23619): │ 💡 支付宝支付调用完成，返回结果类型: _Map<Object?, Object?>
I/flutter (23619): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): │ #0   PaymentService.payWithAlipay (package:kissu_app/services/payment_service.dart:487:17)
payment_service.dart:487
I/flutter (23619): │ #1   <asynchronous suspension>
I/flutter (23619): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (23619): │ 💡 支付宝支付返回结果: {success: true, message: 支付成功, result: {resultStatus=9000, result={"alipay_trade_app_pay_response":{"code":"10000","msg":"Success","app_id":"2021005173620334","auth_app_id":"2021005173620334","charset":"utf-8","timestamp":"2025-11-21 14:02:41","out_trade_no":"202511211402356862999616","total_amount":"0.01","trade_no":"2025112122001430251455813249","seller_id":"2088641110392595"},"sign":"fz/mXzGCC0+vfI4ZHxIPl6rTcHtKpM+Fz4HSHhvFIoZEtHIoThkYBl+wynGkykOhQmih0b3ayhSs4gAfFia8rHDg2sDoD/NWtZ+BoJopBnozjfgKREhlVN4SJszOfwj5X9UPvT/sv4BnxDcndjemAAj3/9buNzF7UQz6sXLMjG6I3+mG1WhDaGctbAJXKd44B3M4whofAwK2aWkoazi22wAZZBnt1kRL5Hlx3jD2+2MVek/YNtedU9ghIXMv/Yjd3U8plell/TPcmm/cu7B7F1D4kTSwv4qHEgxmz8jkUK0aEGRs+SaWMYAeiUDp9E4a1XZvLYmXCBE58X7h9vcU6w==","sign_type":"RSA2"}, externalSdkData={"preheatUserToken":"bb0eae908643a4c780be524731cc814a"}, memo=, extendInfo={"doNotExit":true,"isDisplayResult":true,"tradeNo":"2025112122001430251455813249"}}}
I/flutter (23619): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): │ #0   PaymentService.payWithAlipay (package:kissu_app/services/payment_service.dart:497:19)
payment_service.dart:497
I/flutter (23619): │ #1   <asynchronous suspension>
I/flutter (23619): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (23619): │ 💡 支付宝支付结果解析: success=true, message=支付成功
I/flutter (23619): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): │ #0   PaymentService.payWithAlipay (package:kissu_app/services/payment_service.dart:499:21)
payment_service.dart:499
I/flutter (23619): │ #1   <asynchronous suspension>
I/flutter (23619): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (23619): │ 💡 支付宝支付详细结果: {resultStatus=9000, result={"alipay_trade_app_pay_response":{"code":"10000","msg":"Success","app_id":"2021005173620334","auth_app_id":"2021005173620334","charset":"utf-8","timestamp":"2025-11-21 14:02:41","out_trade_no":"202511211402356862999616","total_amount":"0.01","trade_no":"2025112122001430251455813249","seller_id":"2088641110392595"},"sign":"fz/mXzGCC0+vfI4ZHxIPl6rTcHtKpM+Fz4HSHhvFIoZEtHIoThkYBl+wynGkykOhQmih0b3ayhSs4gAfFia8rHDg2sDoD/NWtZ+BoJopBnozjfgKREhlVN4SJszOfwj5X9UPvT/sv4BnxDcndjemAAj3/9buNzF7UQz6sXLMjG6I3+mG1WhDaGctbAJXKd44B3M4whofAwK2aWkoazi22wAZZBnt1kRL5Hlx3jD2+2MVek/YNtedU9ghIXMv/Yjd3U8plell/TPcmm/cu7B7F1D4kTSwv4qHEgxmz8jkUK0aEGRs+SaWMYAeiUDp9E4a1XZvLYmXCBE58X7h9vcU6w==","sign_type":"RSA2"}, externalSdkData={"preheatUserToken":"bb0eae908643a4c780be524731cc814a"}, memo=, extendInfo={"doNotExit":true,"isDisplayResult":true,"tradeNo":"2025112122001430251455813249"}}
I/flutter (23619): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): │ #0   PaymentService.payWithAlipay (package:kissu_app/services/payment_service.dart:503:21)
payment_service.dart:503
I/flutter (23619): │ #1   <asynchronous suspension>
I/flutter (23619): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (23619): │ 💡 支付宝支付成功
I/flutter (23619): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): │ #0   VipController._processPurchase (package:kissu_app/pages/vip/vip_controller.dart:1089:19)
vip_controller.dart:1089
I/flutter (23619): │ #1   <asynchronous suspension>
I/flutter (23619): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (23619): │ 💡 💫 支付宝支付SDK调用完成，结果: true
I/flutter (23619): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): │ #0   VipController._processPurchase (package:kissu_app/pages/vip/vip_controller.dart:1096:15)
vip_controller.dart:1096
I/flutter (23619): │ #1   <asynchronous suspension>
I/flutter (23619): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (23619): │ 💡 💫 支付SDK调用结果: true
I/flutter (23619): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): │ #0   VipController._processPurchase (package:kissu_app/pages/vip/vip_controller.dart:1099:17)
vip_controller.dart:1099
I/flutter (23619): │ #1   <asynchronous suspension>
I/flutter (23619): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (23619): │ 💡 💫 成功唤起支付应用，等待支付结果回调...
I/flutter (23619): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/SurfaceControl(23619): nativeRelease 0xb400006daf008b50 count: 1 name: Surface(name=aea8227 StatusBar)/@0xc7e7ccc - animation-leash of insets_animation#159402
I/SurfaceControl(23619): nativeRelease 0xb400006daeffbfb0 count: 1 name: Surface(name=4ccc675 NavigationBar0)/@0xda97b15 - animation-leash of insets_animation#159403
I/flutter (23619): [LogManager] Not initialized. Message: 全局监听器收到定位数据: {callbackTime: 2025-11-21 14:02:42, locationTime: 2025-11-21 14:02:20, locationType: 2, latitude: 30.274879, longitude: 120.220996, accuracy: 54.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 上城区, street: 运河东路, streetNumber: 301号, cityCode: 0571, adCode: 330102, address: 浙江省杭州市上城区运河东路301号靠近中豪·湘和国际, description: 在中豪·湘和国际附近}
I/flutter (23619): [LogManager] Not initialized. Message: 完整定位数据: {callbackTime: 2025-11-21 14:02:42, locationTime: 2025-11-21 14:02:20, locationType: 2, latitude: 30.274879, longitude: 120.220996, accuracy: 54.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 上城区, street: 运河东路, streetNumber: 301号, cityCode: 0571, adCode: 330102, address: 浙江省杭州市上城区运河东路301号靠近中豪·湘和国际, description: 在中豪·湘和国际附近}
I/flutter (23619): [LogManager] Not initialized. Message: _handleLocationReporting: _isFirstLocationSuccess = false
I/flutter (23619): [LogManager] Not initialized. Message: 收集缓冲区当前大小: 1
I/flutter (23619): [LogManager] Not initialized. Message: 位置更新被抛弃: 距离2.9m<50m，抛弃
3
I/Environment(23619): path /storage/emulated/0 state is mounted
W/Thread-31(23619): type=1400 audit(0.0:1210189): avc:  denied  { read } for  name="drivers" dev="proc" ino=4026531852 scontext=u:r:untrusted_app:s0:c192,c257,c512,c768 tcontext=u:object_r:proc_tty_drivers:s0 tclass=file permissive=0
W/Settings(23619): Setting airplane_mode_on has moved from android.provider.Settings.System to android.provider.Settings.Global, returning read-only value.
V/AudioManager(23619): getStreamVolume streamType: 0 volume: 9
V/AudioManager(23619): getStreamVolume streamType: 1 volume: 4
V/AudioManager(23619): getStreamVolume streamType: 2 volume: 4
V/AudioManager(23619): getStreamVolume streamType: 3 volume: 5
V/AudioManager(23619): getStreamVolume streamType: 4 volume: 15
I/flutter (23619): [LogManager] Not initialized. Message: 200 GET http://dev-love-api.ikissu.cn/index (241ms)
I/flutter (23619): [LogManager] Not initialized. Message: Response: {
I/flutter (23619):   "isSuccess": true,
I/flutter (23619):   "code": 0,
I/flutter (23619):   "msg": "",
I/flutter (23619):   "data": null,
I/flutter (23619):   "dataList": null,
I/flutter (23619):   "dataJson": {
I/flutter (23619):     "is_red_dot": 0,
I/flutter (23619):     "is_system_notice_red_dot": 0,
I/flutter (23619):     "is_interaction_notice_red_dot": 0,
I/flutter (23619):     "activity": {
I/flutter (23619):       "is_pop_ads": 0,
I/flutter (23619):       "watch_ads_nums": 0,
I/flutter (23619):       "is_ads_exempt": 0,
I/flutter (23619):       "is_ads_count_down": 0,
I/flutter (23619):       "ads_count_down": 0,
I/flutter (23619):       "is_activity": 1,
I/flutter (23619):       "is_activity_icon": "https://kissustatic.yuluojishu.com/uploads/2025/09/05/3e4bcaa18cd0b27710bbce9d748a258e.png",
I/flutter (23619):       "a... (truncated)
I/flutter (23619): ✅ Request GET /index - 299ms - Status: 200
I/flutter (23619): SUCCESS: 🏠 首页数据请求成功
I/flutter (23619): INFO: 首页数据结构: [is_red_dot, is_system_notice_red_dot, is_interaction_notice_red_dot, activity, location, user, photo, weather, vip_data]
I/flutter (23619): 📊 红点信息更新: 系统消息=0, 互动消息=0, 总数=0, 显示红点=false
I/flutter (23619): ✅ 用户头像已更新: https://kissustatic.yuluojishu.com/uploads/2025/09/11/e00b3be4bb4801e07a62ff4080fb6d13.png
I/flutter (23619): ✅ 伴侣头像已更新: https://kissustatic.yuluojishu.com/uploads/2025/09/11/e00b3be4bb4801e07a62ff4080fb6d13.png
I/flutter (23619): 📸 照片墙URL: https://kissustatic.yuluojishu.com/uploads/2025/10/21/87783e72474a60d2ed35d7cd3f769dea.png
I/flutter (23619): 🌤️ 开始解析首页天气数据
I/flutter (23619): 🌤️ 解析 base 数据: icon=https://kissustatic.yuluojishu.com/uploads/2025/09/23/b17d2ef38497f4ca09a61cb0a93eefa2.png, weather=多云, temp=29
I/flutter (23619): 🌤️ 解析 all 数据: min=24, max=32
I/flutter (23619): ✅ 天气数据解析成功
I/flutter (23619): ✅ 首页数据加载成功: 绑定状态=true, 恋爱天数=0, 距离=未知
I/flutter (23619): ⏹️ 红点轮询已停止
I/flutter (23619): ✅ 红点轮询已启动（每10秒刷新）
2
I/flutter (23619): ✅ 头像预加载成功: https://kissustatic.yuluojishu.com/uploads/2025/09/11/e00b3be4bb4801e07a62ff4080fb6d13.png
I/flutter (23619): [LogManager] Not initialized. Message: 权限状态更新:
I/flutter (23619): [LogManager] Not initialized. Message: 前台定位: granted
I/flutter (23619): [LogManager] Not initialized. Message: 后台定位: denied
I/flutter (23619): 📱 提醒冷却中，剩余时间: 3:07:01.674507
I/flutter (23619): 📱 不满足提醒条件，跳过
I/flutter (23619): 📱 已清空后台时间记录，为下次后台检测做准备
D/ForegroundLocationService(23619): 📍 原生定位成功: 30.274879, 120.220996, 精度: 54.0m
D/ForegroundLocationService(23619): 使用RunningAppProcesses检测: 应用在前台
D/ForegroundLocationService(23619): 检测到应用在前台，跳过原生位置上报
D/ForegroundLocationService(23619): ⏸️ 应用在前台，跳过原生位置上报（Flutter正在处理）
D/ForegroundLocationService(23619): 定位成功，静默模式（不更新通知）
I/flutter (23619): [LogManager] Not initialized. Message: 全局监听器收到定位数据: {callbackTime: 2025-11-21 14:02:47, locationTime: 2025-11-21 14:02:20, locationType: 2, latitude: 30.274879, longitude: 120.220996, accuracy: 54.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 上城区, street: 运河东路, streetNumber: 301号, cityCode: 0571, adCode: 330102, address: 浙江省杭州市上城区运河东路301号靠近中豪·湘和国际, description: 在中豪·湘和国际附近}
I/flutter (23619): [LogManager] Not initialized. Message: 完整定位数据: {callbackTime: 2025-11-21 14:02:47, locationTime: 2025-11-21 14:02:20, locationType: 2, latitude: 30.274879, longitude: 120.220996, accuracy: 54.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 上城区, street: 运河东路, streetNumber: 301号, cityCode: 0571, adCode: 330102, address: 浙江省杭州市上城区运河东路301号靠近中豪·湘和国际, description: 在中豪·湘和国际附近}
I/flutter (23619): [LogManager] Not initialized. Message: _handleLocationReporting: _isFirstLocationSuccess = false
I/flutter (23619): [LogManager] Not initialized. Message: 收集缓冲区当前大小: 1
I/flutter (23619): [LogManager] Not initialized. Message: 位置更新被抛弃: 距离2.9m<50m，抛弃
I/imsdk   (23619): TIM: |-database.cpp:776                        InternalCreateMessageIndexByTime        |create message_index_by_time success|time_cost:5ms
I/flutter (23619): INFO: 电量缓存已清除
I/flutter (23619): INFO: 电池状态变化，已清除电量缓存
D/ForegroundLocationService(23619): 📍 原生定位成功: 30.274879, 120.220996, 精度: 54.0m
D/ForegroundLocationService(23619): 使用RunningAppProcesses检测: 应用在前台
D/ForegroundLocationService(23619): 检测到应用在前台，跳过原生位置上报
D/ForegroundLocationService(23619): ⏸️ 应用在前台，跳过原生位置上报（Flutter正在处理）
D/ForegroundLocationService(23619): 定位成功，静默模式（不更新通知）
I/flutter (23619): ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
I/flutter (23619): │ #0   _AppLifecycleObserver.didChangeAppLifecycleState.<anonymous closure> (package:kissu_app/services/payment_service.dart:804:37)
payment_service.dart:804
I/flutter (23619): │ #1   new Future.delayed.<anonymous closure> (dart:async/future.dart:440:42)
future.dart:440
I/flutter (23619): ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
I/flutter (23619): │ 💡 支付状态已正常结束
I/flutter (23619): └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
D/LocationReportService(23619): 📦 缓冲区为空，跳过定时上报
I/flutter (23619): [LogManager] Not initialized. Message: 全局监听器收到定位数据: {callbackTime: 2025-11-21 14:02:52, locationTime: 2025-11-21 14:02:20, locationType: 2, latitude: 30.274879, longitude: 120.220996, accuracy: 54.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 上城区, street: 运河东路, streetNumber: 301号, cityCode: 0571, adCode: 330102, address: 浙江省杭州市上城区运河东路301号靠近中豪·湘和国际, description: 在中豪·湘和国际附近}
I/flutter (23619): [LogManager] Not initialized. Message: 完整定位数据: {callbackTime: 2025-11-21 14:02:52, locationTime: 2025-11-21 14:02:20, locationType: 2, latitude: 30.274879, longitude: 120.220996, accuracy: 54.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 上城区, street: 运河东路, streetNumber: 301号, cityCode: 0571, adCode: 330102, address: 浙江省杭州市上城区运河东路301号靠近中豪·湘和国际, description: 在中豪·湘和国际附近}
I/flutter (23619): [LogManager] Not initialized. Message: _handleLocationReporting: _isFirstLocationSuccess = false
I/flutter (23619): [LogManager] Not initialized. Message: 收集缓冲区当前大小: 1
I/flutter (23619): [LogManager] Not initialized. Message: 位置更新被抛弃: 距离2.9m<50m，抛弃
I/flutter (23619): 🔔 定时刷新首页数据...
I/flutter (23619): 🏠 开始加载首页数据...
I/flutter (23619): INFO: 🏠 开始请求首页数据...
I/flutter (23619): [LogManager] Not initialized. Message: 权限状态更新:
I/flutter (23619): [LogManager] Not initialized. Message: 前台定位: granted
I/flutter (23619): [LogManager] Not initialized. Message: 后台定位: denied
I/flutter (23619): [LogManager] Not initialized. Message: DeviceUtil not initialized, using fallback deviceId
I/flutter (23619): INFO: OAID 已添加到请求头
I/flutter (23619): INFO: 电量缓存已更新: 79%
I/flutter (23619): [LogManager] Not initialized. Message: GET http://dev-love-api.ikissu.cn/index
I/flutter (23619): [LogManager] Not initialized. Message: Headers: {cache_control: noCache, token: ***HIDDEN***, version: 1.0.6, pkg: com.yuluo.kissu, deviceid: android-1763704973004, oaid: 18887152-1202-4a74-9d32-2b825f7d3d73, mobile-model: HONOR ALI-AN00, brand: HONOR, channel: kissu_meizu, network-name: wifi_YuluoKeji_5G, power: 79, timestamp: 1763704973007, sign: 9A7E9CC1CFAA88EB200CFB1CE0A30F4D}
I/flutter (23619): [LogManager] Not initialized. Message: 200 GET http://dev-love-api.ikissu.cn/index (238ms)
I/flutter (23619): [LogManager] Not initialized. Message: Response: {
I/flutter (23619):   "isSuccess": true,
I/flutter (23619):   "code": 0,
I/flutter (23619):   "msg": "",
I/flutter (23619):   "data": null,
I/flutter (23619):   "dataList": null,
I/flutter (23619):   "dataJson": {
I/flutter (23619):     "is_red_dot": 0,
I/flutter (23619):     "is_system_notice_red_dot": 0,
I/flutter (23619):     "is_interaction_notice_red_dot": 0,
I/flutter (23619):     "activity": {
I/flutter (23619):       "is_pop_ads": 0,
I/flutter (23619):       "watch_ads_nums": 0,
I/flutter (23619):       "is_ads_exempt": 0,
I/flutter (23619):       "is_ads_count_down": 0,
I/flutter (23619):       "ads_count_down": 0,
I/flutter (23619):       "is_activity": 1,
I/flutter (23619):       "is_activity_icon": "https://kissustatic.yuluojishu.com/uploads/2025/09/05/3e4bcaa18cd0b27710bbce9d748a258e.png",
I/flutter (23619):       "a... (truncated)
I/flutter (23619): ✅ Request GET /index - 273ms - Status: 200
I/flutter (23619): SUCCESS: 🏠 首页数据请求成功
I/flutter (23619): INFO: 首页数据结构: [is_red_dot, is_system_notice_red_dot, is_interaction_notice_red_dot, activity, location, user, photo, weather, vip_data]
I/flutter (23619): 📊 红点信息更新: 系统消息=0, 互动消息=0, 总数=0, 显示红点=false
I/flutter (23619): ✅ 用户头像已更新: https://kissustatic.yuluojishu.com/uploads/2025/09/11/e00b3be4bb4801e07a62ff4080fb6d13.png
I/flutter (23619): ✅ 伴侣头像已更新: https://kissustatic.yuluojishu.com/uploads/2025/09/11/e00b3be4bb4801e07a62ff4080fb6d13.png
I/flutter (23619): 📸 照片墙URL: https://kissustatic.yuluojishu.com/uploads/2025/10/21/87783e72474a60d2ed35d7cd3f769dea.png
I/flutter (23619): 🌤️ 开始解析首页天气数据
I/flutter (23619): 🌤️ 解析 base 数据: icon=https://kissustatic.yuluojishu.com/uploads/2025/09/23/b17d2ef38497f4ca09a61cb0a93eefa2.png, weather=多云, temp=29
I/flutter (23619): 🌤️ 解析 all 数据: min=24, max=32
I/flutter (23619): ✅ 天气数据解析成功
I/flutter (23619): ✅ 首页数据加载成功: 绑定状态=true, 恋爱天数=0, 距离=未知
2
I/flutter (23619): ✅ 头像预加载成功: https://kissustatic.yuluojishu.com/uploads/2025/09/11/e00b3be4bb4801e07a62ff4080fb6d13.png
D/ForegroundLocationService(23619): 📍 原生定位成功: 30.274879, 120.220996, 精度: 54.0m
D/ForegroundLocationService(23619): 使用RunningAppProcesses检测: 应用在前台
D/ForegroundLocationService(23619): 检测到应用在前台，跳过原生位置上报
D/ForegroundLocationService(23619): ⏸️ 应用在前台，跳过原生位置上报（Flutter正在处理）
D/ForegroundLocationService(23619): 定位成功，静默模式（不更新通知）
I/flutter (23619): [LogManager] Not initialized. Message: 全局监听器收到定位数据: {callbackTime: 2025-11-21 14:02:57, locationTime: 2025-11-21 14:02:20, locationType: 2, latitude: 30.274879, longitude: 120.220996, accuracy: 54.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 上城区, street: 运河东路, streetNumber: 301号, cityCode: 0571, adCode: 330102, address: 浙江省杭州市上城区运河东路301号靠近中豪·湘和国际, description: 在中豪·湘和国际附近}
I/flutter (23619): [LogManager] Not initialized. Message: 完整定位数据: {callbackTime: 2025-11-21 14:02:57, locationTime: 2025-11-21 14:02:20, locationType: 2, latitude: 30.274879, longitude: 120.220996, accuracy: 54.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 上城区, street: 运河东路, streetNumber: 301号, cityCode: 0571, adCode: 330102, address: 浙江省杭州市上城区运河东路301号靠近中豪·湘和国际, description: 在中豪·湘和国际附近}
I/flutter (23619): [LogManager] Not initialized. Message: _handleLocationReporting: _isFirstLocationSuccess = false
I/flutter (23619): [LogManager] Not initialized. Message: 收集缓冲区当前大小: 1
I/flutter (23619): [LogManager] Not initialized. Message: 位置更新被抛弃: 距离2.9m<50m，抛弃
D/ForegroundLocationService(23619): 📍 原生定位成功: 30.274879, 120.220996, 精度: 54.0m
D/ForegroundLocationService(23619): 使用RunningAppProcesses检测: 应用在前台
D/ForegroundLocationService(23619): 检测到应用在前台，跳过原生位置上报
D/ForegroundLocationService(23619): ⏸️ 应用在前台，跳过原生位置上报（Flutter正在处理）
D/ForegroundLocationService(23619): 定位成功，静默模式（不更新通知）
I/flutter (23619): [LogManager] Not initialized. Message: 全局监听器收到定位数据: {callbackTime: 2025-11-21 14:03:02, locationTime: 2025-11-21 14:02:20, locationType: 2, latitude: 30.274879, longitude: 120.220996, accuracy: 54.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 上城区, street: 运河东路, streetNumber: 301号, cityCode: 0571, adCode: 330102, address: 浙江省杭州市上城区运河东路301号靠近中豪·湘和国际, description: 在中豪·湘和国际附近}
I/flutter (23619): [LogManager] Not initialized. Message: 完整定位数据: {callbackTime: 2025-11-21 14:03:02, locationTime: 2025-11-21 14:02:20, locationType: 2, latitude: 30.274879, longitude: 120.220996, accuracy: 54.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 上城区, street: 运河东路, streetNumber: 301号, cityCode: 0571, adCode: 330102, address: 浙江省杭州市上城区运河东路301号靠近中豪·湘和国际, description: 在中豪·湘和国际附近}
I/flutter (23619): [LogManager] Not initialized. Message: _handleLocationReporting: _isFirstLocationSuccess = false
I/flutter (23619): [LogManager] Not initialized. Message: 收集缓冲区当前大小: 1
I/flutter (23619): [LogManager] Not initialized. Message: 位置更新被抛弃: 距离2.9m<50m，抛弃
I/flutter (23619): 🔔 定时刷新首页数据...
I/flutter (23619): 🏠 开始加载首页数据...
I/flutter (23619): INFO: 🏠 开始请求首页数据...
I/flutter (23619): [LogManager] Not initialized. Message: 权限状态更新:
I/flutter (23619): [LogManager] Not initialized. Message: 前台定位: granted
I/flutter (23619): [LogManager] Not initialized. Message: 后台定位: denied
I/flutter (23619): [LogManager] Not initialized. Message: DeviceUtil not initialized, using fallback deviceId
I/flutter (23619): INFO: OAID 已添加到请求头
I/flutter (23619): [LogManager] Not initialized. Message: GET http://dev-love-api.ikissu.cn/index
I/flutter (23619): [LogManager] Not initialized. Message: Headers: {cache_control: noCache, token: ***HIDDEN***, version: 1.0.6, pkg: com.yuluo.kissu, deviceid: android-1763704983004, oaid: 18887152-1202-4a74-9d32-2b825f7d3d73, mobile-model: HONOR ALI-AN00, brand: HONOR, channel: kissu_meizu, network-name: wifi_YuluoKeji_5G, power: 79, timestamp: 1763704983005, sign: 0D6B98A887CA0915056677B5EED16FAC}
I/flutter (23619): [LogManager] Not initialized. Message: 200 GET http://dev-love-api.ikissu.cn/index (270ms)
I/flutter (23619): [LogManager] Not initialized. Message: Response: {
I/flutter (23619):   "isSuccess": true,
I/flutter (23619):   "code": 0,
I/flutter (23619):   "msg": "",
I/flutter (23619):   "data": null,
I/flutter (23619):   "dataList": null,
I/flutter (23619):   "dataJson": {
I/flutter (23619):     "is_red_dot": 0,
I/flutter (23619):     "is_system_notice_red_dot": 0,
I/flutter (23619):     "is_interaction_notice_red_dot": 0,
I/flutter (23619):     "activity": {
I/flutter (23619):       "is_pop_ads": 0,
I/flutter (23619):       "watch_ads_nums": 0,
I/flutter (23619):       "is_ads_exempt": 0,
I/flutter (23619):       "is_ads_count_down": 0,
I/flutter (23619):       "ads_count_down": 0,
I/flutter (23619):       "is_activity": 1,
I/flutter (23619):       "is_activity_icon": "https://kissustatic.yuluojishu.com/uploads/2025/09/05/3e4bcaa18cd0b27710bbce9d748a258e.png",
I/flutter (23619):       "a... (truncated)
I/flutter (23619): ✅ Request GET /index - 307ms - Status: 200
I/flutter (23619): SUCCESS: 🏠 首页数据请求成功
I/flutter (23619): INFO: 首页数据结构: [is_red_dot, is_system_notice_red_dot, is_interaction_notice_red_dot, activity, location, user, photo, weather, vip_data]
I/flutter (23619): 📊 红点信息更新: 系统消息=0, 互动消息=0, 总数=0, 显示红点=false
I/flutter (23619): ✅ 用户头像已更新: https://kissustatic.yuluojishu.com/uploads/2025/09/11/e00b3be4bb4801e07a62ff4080fb6d13.png
I/flutter (23619): ✅ 伴侣头像已更新: https://kissustatic.yuluojishu.com/uploads/2025/09/11/e00b3be4bb4801e07a62ff4080fb6d13.png
I/flutter (23619): 📸 照片墙URL: https://kissustatic.yuluojishu.com/uploads/2025/10/21/87783e72474a60d2ed35d7cd3f769dea.png
I/flutter (23619): 🌤️ 开始解析首页天气数据
I/flutter (23619): 🌤️ 解析 base 数据: icon=https://kissustatic.yuluojishu.com/uploads/2025/09/23/b17d2ef38497f4ca09a61cb0a93eefa2.png, weather=多云, temp=29
I/flutter (23619): 🌤️ 解析 all 数据: min=24, max=32
I/flutter (23619): ✅ 天气数据解析成功
I/flutter (23619): ✅ 首页数据加载成功: 绑定状态=true, 恋爱天数=0, 距离=未知
2
I/flutter (23619): ✅ 头像预加载成功: https://kissustatic.yuluojishu.com/uploads/2025/09/11/e00b3be4bb4801e07a62ff4080fb6d13.png
D/ForegroundLocationService(23619): 📍 原生定位成功: 30.274879, 120.220996, 精度: 54.0m
D/ForegroundLocationService(23619): 使用RunningAppProcesses检测: 应用在前台
D/ForegroundLocationService(23619): 检测到应用在前台，跳过原生位置上报
D/ForegroundLocationService(23619): ⏸️ 应用在前台，跳过原生位置上报（Flutter正在处理）
D/ForegroundLocationService(23619): 定位成功，静默模式（不更新通知）
I/flutter (23619): [LogManager] Not initialized. Message: 全局监听器收到定位数据: {callbackTime: 2025-11-21 14:03:07, locationTime: 2025-11-21 14:02:20, locationType: 2, latitude: 30.274879, longitude: 120.220996, accuracy: 54.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 上城区, street: 运河东路, streetNumber: 301号, cityCode: 0571, adCode: 330102, address: 浙江省杭州市上城区运河东路301号靠近中豪·湘和国际, description: 在中豪·湘和国际附近}
I/flutter (23619): [LogManager] Not initialized. Message: 完整定位数据: {callbackTime: 2025-11-21 14:03:07, locationTime: 2025-11-21 14:02:20, locationType: 2, latitude: 30.274879, longitude: 120.220996, accuracy: 54.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 上城区, street: 运河东路, streetNumber: 301号, cityCode: 0571, adCode: 330102, address: 浙江省杭州市上城区运河东路301号靠近中豪·湘和国际, description: 在中豪·湘和国际附近}
I/flutter (23619): [LogManager] Not initialized. Message: _handleLocationReporting: _isFirstLocationSuccess = false
I/flutter (23619): [LogManager] Not initialized. Message: 收集缓冲区当前大小: 1
I/flutter (23619): [LogManager] Not initialized. Message: 位置更新被抛弃: 距离2.9m<50m，抛弃
D/ForegroundLocationService(23619): 📍 原生定位成功: 30.274879, 120.220996, 精度: 54.0m
D/ForegroundLocationService(23619): 使用RunningAppProcesses检测: 应用在前台
D/ForegroundLocationService(23619): 检测到应用在前台，跳过原生位置上报
D/ForegroundLocationService(23619): ⏸️ 应用在前台，跳过原生位置上报（Flutter正在处理）
D/ForegroundLocationService(23619): 定位成功，静默模式（不更新通知）
I/flutter (23619): [LogManager] Not initialized. Message: 单点上报：时间戳已修改为当前时间 1763704991
I/flutter (23619): [LogManager] Not initialized. Message: 定时上报: 1个位置点
I/flutter (23619): [LogManager] Not initialized. Message: 开始批量上报: 定时上报
I/flutter (23619): [LogManager] Not initialized. Message: 批量上报数量: 1个位置点
I/flutter (23619): [LogManager] Not initialized. Message: [0] 30.274897725149444, 120.22101658246676, 精度: 54.00m
I/flutter (23619): [LogManager] Not initialized. Message: 🚀 位置上报API调用开始
I/flutter (23619): [LogManager] Not initialized. Message: 📝 API端点: /location/report
I/flutter (23619): [LogManager] Not initialized. Message: 📦 请求数据: [{"longitude":"120.22101658246676","latitude":"30.274897725149444","location_time":"1763704991","speed":"0.00","altitude":"99.16","location_name":"","accuracy":"54.00"}]
I/flutter (23619): [LogManager] Not initialized. Message: 📊 有效位置数据数量: 1
I/flutter (23619): [LogManager] Not initialized. Message: DeviceUtil not initialized, using fallback deviceId
I/flutter (23619): INFO: OAID 已添加到请求头
I/flutter (23619): [LogManager] Not initialized. Message: POST http://dev-love-api.ikissu.cn/location/report
I/flutter (23619): [LogManager] Not initialized. Message: Headers: {network_debounce: true, content-type: application/json, token: ***HIDDEN***, version: 1.0.6, pkg: com.yuluo.kissu, deviceid: android-1763704991473, oaid: 18887152-1202-4a74-9d32-2b825f7d3d73, mobile-model: HONOR ALI-AN00, brand: HONOR, channel: kissu_meizu, network-name: wifi_YuluoKeji_5G, power: 79, timestamp: 1763704991474, sign: 0DB54EA61858BA9016751CDF7D4BBB03}
I/flutter (23619): [LogManager] Not initialized. Message: Request: {
I/flutter (23619):   "locations": "[{\"longitude\":\"120.22101658246676\",\"latitude\":\"30.274897725149444\",\"location_time\":\"1763704991\",\"speed\":\"0.00\",\"altitude\":\"99.16\",\"location_name\":\"\",\"accuracy\":\"54.00\"}]"
I/flutter (23619): }
I/flutter (23619): [LogManager] Not initialized. Message: 200 POST http://dev-love-api.ikissu.cn/location/report (193ms)
I/flutter (23619): [LogManager] Not initialized. Message: Response: {
I/flutter (23619):   "isSuccess": true,
I/flutter (23619):   "code": 0,
I/flutter (23619):   "msg": "位置上报成功",
I/flutter (23619):   "data": null,
I/flutter (23619):   "dataList": null,
I/flutter (23619):   "dataJson": {},
I/flutter (23619):   "listJson": null
I/flutter (23619): }
I/flutter (23619): ✅ Request POST /location/report - 197ms - Status: 200
I/flutter (23619): [LogManager] Not initialized. Message: 📡 API响应状态: true
I/flutter (23619): [LogManager] Not initialized. Message: 📡 API响应码: 0
I/flutter (23619): [LogManager] Not initialized. Message: 📡 API响应消息: 位置上报成功
I/flutter (23619): [LogManager] Not initialized. Message: 📡 原始响应dataJson: {}
I/flutter (23619): [LogManager] Not initialized. Message: 📡 原始响应listJson: null
I/flutter (23619): [LogManager] Not initialized. Message: 📡 完整响应对象: HttpResultN<dynamic>(Success, code: 0, hasData: true, msg: 位置上报成功)
I/flutter (23619): [LogManager] Not initialized. Message: ✅ 位置上报成功
I/flutter (23619): [LogManager] Not initialized. Message: 批量位置上报成功: 定时上报
I/flutter (23619): [LogManager] Not initialized. Message: 上报数量: 1个位置点
I/flutter (23619): [LogManager] Not initialized. Message: 服务器响应: 位置上报成功
I/flutter (23619): [LogManager] Not initialized. Message: 全局监听器收到定位数据: {callbackTime: 2025-11-21 14:03:12, locationTime: 2025-11-21 14:02:20, locationType: 2, latitude: 30.274879, longitude: 120.220996, accuracy: 54.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 上城区, street: 运河东路, streetNumber: 301号, cityCode: 0571, adCode: 330102, address: 浙江省杭州市上城区运河东路301号靠近中豪·湘和国际, description: 在中豪·湘和国际附近}
I/flutter (23619): [LogManager] Not initialized. Message: 完整定位数据: {callbackTime: 2025-11-21 14:03:12, locationTime: 2025-11-21 14:02:20, locationType: 2, latitude: 30.274879, longitude: 120.220996, accuracy: 54.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 上城区, street: 运河东路, streetNumber: 301号, cityCode: 0571, adCode: 330102, address: 浙江省杭州市上城区运河东路301号靠近中豪·湘和国际, description: 在中豪·湘和国际附近}
I/flutter (23619): [LogManager] Not initialized. Message: _handleLocationReporting: _isFirstLocationSuccess = false
I/flutter (23619): [LogManager] Not initialized. Message: 收集缓冲区当前大小: 0
I/flutter (23619): [LogManager] Not initialized. Message: 位置收集: 收集池为空，直接放入 (缓冲区: 1/12)
I/flutter (23619): [LogManager] Not initialized. Message: 收集位置: 30.274879, 120.220996, 精度: 54.00m
I/flutter (23619): 🔔 定时刷新首页数据...
I/flutter (23619): 🏠 开始加载首页数据...
I/flutter (23619): INFO: 🏠 开始请求首页数据...
I/flutter (23619): [LogManager] Not initialized. Message: 权限状态更新:
I/flutter (23619): [LogManager] Not initialized. Message: 前台定位: granted
I/flutter (23619): [LogManager] Not initialized. Message: 后台定位: denied
I/flutter (23619): [LogManager] Not initialized. Message: DeviceUtil not initialized, using fallback deviceId
I/flutter (23619): INFO: OAID 已添加到请求头
I/flutter (23619): [LogManager] Not initialized. Message: GET http://dev-love-api.ikissu.cn/index
I/flutter (23619): [LogManager] Not initialized. Message: Headers: {cache_control: noCache, token: ***HIDDEN***, version: 1.0.6, pkg: com.yuluo.kissu, deviceid: android-1763704993016, oaid: 18887152-1202-4a74-9d32-2b825f7d3d73, mobile-model: HONOR ALI-AN00, brand: HONOR, channel: kissu_meizu, network-name: wifi_YuluoKeji_5G, power: 79, timestamp: 1763704993017, sign: B152297B1552A9EE0A5B