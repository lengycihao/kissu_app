I/flutter (31418): 📍 相机位置更新: 30.280722702178263, 120.21649467922214, zoom: 16.0
I/flutter (31418): !  没有当前停留点，跳过InfoWindow更新
I/AMapFlutter_MapController(31418): onCameraChange===>{position={bearing=0.0, zoom=16.0, tilt=0.0, target=[30.280627735371358, 120.21630156017635]}}
I/flutter (31418): 📍 相机位置更新: 30.280627735371358, 120.21630156017636, zoom: 16.0
I/flutter (31418): !  没有当前停留点，跳过InfoWindow更新
I/AMapFlutter_MapController(31418): onCameraChange===>{position={bearing=0.0, zoom=16.0, tilt=0.0, target=[30.280532768472547, 120.21610978223505]}}
I/flutter (31418): 📍 相机位置更新: 30.280532768472547, 120.21610978223504, zoom: 16.0
I/flutter (31418): !  没有当前停留点，跳过InfoWindow更新
I/AMapFlutter_MapController(31418): onCameraChange===>{position={bearing=0.0, zoom=16.0, tilt=0.0, target=[30.280437801481824, 120.21591666318928]}}
I/flutter (31418): 📍 相机位置更新: 30.280437801481824, 120.21591666318926, zoom: 16.0
I/flutter (31418): !  没有当前停留点，跳过InfoWindow更新
I/flutter (31418): 🔄 地图强制更新完成
I/flutter (31418): 🔄 已立即清空旧数据，显示加载状态
I/flutter (31418): 🌐 智能请求数据: 2025-09-19, isOneself=true
I/flutter (31418): 📅 缓存检查: 2025-09-19 不应缓存
I/flutter (31418): 🚫 2025-09-19 是今天或未来日期，不使用缓存
I/flutter (31418): 🔄 TrackApi: 缓存未命中，请求API数据: 2025-09-19, isOneself=1
I/flutter (31418): [LogManager] Not initialized. Message: GET https://service-api.ikissu.cn/get/trace?date=2025-09-19&is_oneself=1
I/flutter (31418): ℹ️ 无有效轨迹数据，不创建轨迹线。状态: false, 点数: 0
I/AMapFlutter_AMapPlatformView(31418): onMethodCall==>markers#update, arguments==> {markerIdsToRemove=[], markersToChange=[], markersToAdd=[]}
I/AMapFlutter_MarkersController(31418): doMethodCall===>markers#update
I/AMapFlutter_AMapPlatformView(31418): onMethodCall==>polylines#update, arguments==> {polylinesToAdd=[], polylinesToChange=[], polylineIdsToRemove=[]}
I/AMapFlutter_PolylinesController(31418): doMethodCall===>polylines#update
I/AMapFlutter_AMapPlatformView(31418): onMethodCall==>polygons#update, arguments==> {polygonsToChange=[], polygonIdsToRemove=[], polygonsToAdd=[]}
I/AMapFlutter_PolygonsController(31418): doMethodCall===>polygons#update
I/AMapFlutter_MapController(31418): onCameraChange===>{position={bearing=0.0, zoom=16.0, tilt=0.0, target=[30.28034630880628, 120.21573024966595]}}
I/flutter (31418): 📍 相机位置更新: 30.28034630880628, 120.21573024966597, zoom: 16.0
I/flutter (31418): !  没有当前停留点，跳过InfoWindow更新
I/AMapFlutter_MapController(31418): onCameraChange===>{position={bearing=0.0, zoom=16.0, tilt=0.0, target=[30.280306932185482, 120.21564978339687]}}
I/flutter (31418): 📍 相机位置更新: 30.280306932185482, 120.21564978339688, zoom: 16.0
I/flutter (31418): !  没有当前停留点，跳过InfoWindow更新
I/AMapFlutter_MapController(31418): onCameraChangeFinish===>{position={bearing=0.0, zoom=16.0, tilt=0.0, target=[30.280306932185482, 120.21564978339687]}}
I/flutter (31418): 🏁 地图移动结束，进行最终位置更新
I/flutter (31418): 📍 相机位置更新: 30.280306932185482, 120.21564978339688, zoom: 16.0
I/flutter (31418): !  没有当前停留点，跳过InfoWindow更新
I/flutter (31418): [LogManager] Not initialized. Message: 200 GET https://service-api.ikissu.cn/get/trace?date=2025-09-19&is_oneself=1 (155ms)
I/flutter (31418): [LogManager] Not initialized. Message: Response: {
I/flutter (31418):   "isSuccess": true,
I/flutter (31418):   "code": 0,
I/flutter (31418):   "msg": "",
I/flutter (31418):   "data": null,
I/flutter (31418):   "dataList": null,
I/flutter (31418):   "dataJson": {
I/flutter (31418):     "locations": [
I/flutter (31418):       {
I/flutter (31418):         "longitude": "120.220243",
I/flutter (31418):         "latitude": "30.275689"
I/flutter (31418):       },
I/flutter (31418):       {
I/flutter (31418):         "longitude": "120.22029",
I/flutter (31418):         "latitude": "30.27567"
I/flutter (31418):       },
I/flutter (31418):       {
I/flutter (31418):         "longitude": "119.984365",
I/flutter (31418):         "latitude": "30.283985"
I/flutter (31418):       }
I/flutter (31418):     ],
I/flutter (31418):     "trace": {
I/flutter (31418):       "start_point": {
I/flutter (31418):         "longitude": "120.220243",
I/flutter (31418):         "latitude": "30.275689",
I/flutter (31418):         "location_... (truncated)
I/flutter (31418): ✅ Request GET /get/trace - 160ms - Status: 200
I/flutter (31418): 🔍 Track API 返回数据结构: [locations, trace, user]
I/flutter (31418): 🔍 LocationResponse 解析JSON: [locations, trace, user]
I/flutter (31418): 📅 缓存检查: 2025-09-19 不应缓存
I/flutter (31418): 🚫 2025-09-19 是今天或未来日期，不进行缓存
I/flutter (31418): ✅ TrackApi: 获取到最新数据，已缓存历史数据
I/flutter (31418): 🎭 从API数据更新头像信息
I/flutter (31418): 🎭 更新我的头像: https://kissustatic.yuluojishu.com/uploads/2025/09/11/e00b3be4bb4801e07a62ff4080fb6d13.png
I/flutter (31418): 🎭 更新伴侣头像: https://kissustatic.yuluojishu.com/uploads/2025/09/11/e00b3be4bb4801e07a62ff4080fb6d13.png
I/flutter (31418): 🎭 更新绑定状态: false
I/flutter (31418): 🎭 头像更新完成 - 我的头像: https://kissustatic.yuluojishu.com/uploads/2025/09/11/e00b3be4bb4801e07a62ff4080fb6d13.png, 伴侣头像: https://kissustatic.yuluojishu.com/uploads/2025/09/11/e00b3be4bb4801e07a62ff4080fb6d13.png
I/flutter (31418): ✅ 获取到最新数据
I/flutter (31418): 🔍 开始更新停留记录列表
I/flutter (31418): 📊 trace.stops数量: 3
I/flutter (31418): 🔄 更新轨迹数据: 日期=2025-09-19, isOneself=1, 位置点=3个
I/flutter (31418): 📍 全局监听器收到定位数据: {callbackTime: 2025-09-19 16:10:12, locationTime: 2025-09-19 16:09:44, locationType: 2, latitude: 30.283854, longitude: 119.98432, accuracy: 50.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 余杭区, street: 余杭塘河滨水公园绿道, streetNumber: 19号, cityCode: 0571, adCode: 330110, address: 浙江省杭州市余杭区余杭塘河滨水公园绿道19号靠近云城·金龙中心, description: 在云城·金龙中心附近}
I/flutter (31418): 📍 _onLocationUpdate 被调用，收到数据: {callbackTime: 2025-09-19 16:10:12, locationTime: 2025-09-19 16:09:44, locationType: 2, latitude: 30.283854, longitude: 119.98432, accuracy: 50.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 余杭区, street: 余杭塘河滨水公园绿道, streetNumber: 19号, cityCode: 0571, adCode: 330110, address: 浙江省杭州市余杭区余杭塘河滨水公园绿道19号靠近云城·金龙中心, description: 在云城·金龙中心附近}
I/flutter (31418): ✅ 停留记录更新完成，总数量: 3
I/flutter (31418): 📍 轨迹点数量: 3 (使用原始精度)
I/flutter (31418): ✅ 轨迹点已更新，确保地图同步
I/flutter (31418): 🔄 地图强制更新完成
I/flutter (31418): 📍 原始停留点数量: 3
I/flutter (31418): 📍 调整后停留点数量: 3
I/flutter (31418): 🔄 更新停留点 markers...
I/flutter (31418): 📍 创建停留点标记: 3个点
I/flutter (31418): 🔄 更新轨迹起点和终点标记...
I/flutter (31418): ✅ 轨迹起点标记创建成功
I/flutter (31418): ✅ 轨迹终点标记创建成功
I/flutter (31418): ✅ 轨迹起终点标记更新成功: 2个
I/flutter (31418): 🔄 地图强制更新完成
I/flutter (31418): 🔍 开始更新统计数据
I/flutter (31418): ✅ 使用trace.stay_collect的统计数据 (主要数据源)
I/flutter (31418): 📊 统计数据: 停留次数=2, 停留时间=6小时44分钟, 移动距离=0米
I/flutter (31418): ✅ 创建轨迹线，点数: 3
I/flutter (31418): 🗺️ 开始自动调整地图视图，轨迹点数量: 3
I/flutter (31418): 🗺️ 轨迹范围计算: latDiff=0.009978000000000264, lngDiff=0.2831099999999367, maxDiff=0.2831099999999367, zoom=11.0
I/flutter (31418): 🗺️ 轨迹中心点: (30.279827500000003, 120.1023275)
I/flutter (31418): ✅ 停留点 2 自定义图标创建成功
I/flutter (31418): ✅ 停留点 2 (停留点 2) 标记创建成功
I/AMapFlutter_AMapPlatformView(31418): onMethodCall==>camera#move, arguments==> {duration=250, cameraUpdate=[newCameraPosition, {bearing=0.0, zoom=11.0, tilt=0.0, target=[30.279827500000003, 120.1023275]}], animated=true}
I/AMapFlutter_MapController(31418): doMethodCall===>camera#move
I/AMapFlutter_AMapPlatformView(31418): onMethodCall==>markers#update, arguments==> {markerIdsToRemove=[], markersToChange=[], markersToAdd=[{infoWindowEnable=true, visible=true, draggable=false, alpha=1.0, anchor=[0.5, 1.0], clickable=true, rotation=0.0, icon=[fromAssetImage, assets/kissu_location_start.webp, 1.0], id=742034271, position=[30.275689, 120.22024299999998], infoWindow={snippet=轨迹开始位置, title=起点}, zIndex=0.0}, {infoWindowEnable=true, visible=true, draggable=false, alpha=1.0, anchor=[0.5, 1.0], clickable=true, rotation=0.0, icon=[fromAssetImage, assets/kissu_location_end.webp, 1.0], id=353926403, position=[30.283985, 119.98436500000003], infoWindow={snippet=轨迹结束位置, title=终点}, zIndex=0.0}]}
I/AMapFlutter_MarkersController(31418): doMethodCall===>markers#update
I/AMapFlutter_AMapPlatformView(31418): onMethodCall==>polylines#update, arguments==> {polylinesToAdd=[{geodesic=false, visible=true, color=4282095359, alpha=1.0, joinType=0, width=5.0, id=945005220, dashLineType=0, capType=0, points=[[30.275689, 120.22024299999998], [30.27567, 120.22028999999998], [30.283985, 119.98436500000003]]}], polylinesToChange=[], polylineIdsToRemove=[]}
I/AMapFlutter_PolylinesController(31418): doMethodCall===>polylines#update
I/AMapFlutter_AMapPlatformView(31418): onMethodCall==>polygons#update, arguments==> {polygonsToChange=[], polygonIdsToRemove=[], polygonsToAdd=[]}
I/AMapFlutter_PolygonsController(31418): doMethodCall===>polygons#update
I/flutter (31418): ✅ 停留点 1 自定义图标创建成功
I/flutter (31418): ✅ 停留点 1 (停留点 1) 标记创建成功
I/flutter (31418): ✅ 更新停留点标记成功: 2个
I/flutter (31418): 🔄 地图强制更新完成
I/flutter (31418): ✅ 创建轨迹线，点数: 3
I/AMapFlutter_AMapPlatformView(31418): onMethodCall==>markers#update, arguments==> {markerIdsToRemove=[], markersToChange=[], markersToAdd=[{infoWindowEnable=true, visible=true, draggable=false, alpha=1.0, anchor=[0.5, 1.0], clickable=true, rotation=0.0, icon=[fromBytes, [B@77e3499], id=634963557, position=[30.283985, 119.98436500000003], infoWindow={}, zIndex=0.0}, {infoWindowEnable=true, visible=true, draggable=false, alpha=1.0, anchor=[0.5, 1.0], clickable=true, rotation=0.0, icon=[fromBytes, [B@c19335e], id=535817675, position=[30.275689, 120.22024299999998], infoWindow={}, zIndex=0.0}]}
I/AMapFlutter_MarkersController(31418): doMethodCall===>markers#update
I/AMapFlutter_AMapPlatformView(31418): onMethodCall==>polylines#update, arguments==> {polylinesToAdd=[{geodesic=false, visible=true, color=4282095359, alpha=1.0, joinType=0, width=5.0, id=306522578, dashLineType=0, capType=0, points=[[30.275689, 120.22024299999998], [30.27567, 120.22028999999998], [30.283985, 119.98436500000003]]}], polylinesToChange=[], polylineIdsToRemove=[945005220]}
I/AMapFlutter_PolylinesController(31418): doMethodCall===>polylines#update
I/AMapFlutter_AMapPlatformView(31418): onMethodCall==>polygons#update, arguments==> {polygonsToChange=[], polygonIdsToRemove=[], polygonsToAdd=[]}
I/AMapFlutter_PolygonsController(31418): doMethodCall===>polygons#update
I/AMapFlutter_MapController(31418): onCameraChange===>{position={bearing=0.0, zoom=15.5, tilt=0.0, target=[30.28025944859233, 120.20431745050283]}}
I/flutter (31418): 📍 相机位置更新: 30.28025944859233, 120.2043174505028, zoom: 15.5
I/flutter (31418): !  没有当前停留点，跳过InfoWindow更新
I/AMapFlutter_MapController(31418): onCameraChange===>{position={bearing=0.0, zoom=15.3, tilt=0.0, target=[30.280240918403397, 120.1997845173452]}}
I/flutter (31418): 📍 相机位置更新: 30.280240918403397, 120.19978451734517, zoom: 15.300000190734863
I/flutter (31418): !  没有当前停留点，跳过InfoWindow更新
I/AMapFlutter_MapController(31418): onCameraChange===>{position={bearing=0.0, zoom=14.62, tilt=0.0, target=[30.28017606271459, 120.18437254460927]}}
I/flutter (31418): 📍 相机位置更新: 30.28017606271459, 120.18437254460929, zoom: 14.619999885559082
I/flutter (31418): !  没有当前停留点，跳过InfoWindow更新
I/AMapFlutter_MapController(31418): onCameraChange===>{position={bearing=0.0, zoom=13.940001, tilt=0.0, target=[30.28011004884448, 120.16896057187337]}}
I/flutter (31418): 📍 相机位置更新: 30.28011004884448, 120.16896057187336, zoom: 13.940000534057617
I/flutter (31418): !  没有当前停留点，跳过InfoWindow更新
I/AMapFlutter_MapController(31418): onCameraChange===>{position={bearing=0.0, zoom=13.26, tilt=0.0, target=[30.280045193069178, 120.15354859913744]}}
I/flutter (31418): 📍 相机位置更新: 30.280045193069178, 120.15354859913742, zoom: 13.260000228881836
I/flutter (31418): !  没有当前停留点，跳过InfoWindow更新
I/AMapFlutter_MapController(31418): onCameraChange===>{position={bearing=0.0, zoom=12.58, tilt=0.0, target=[30.279980337251015, 120.13813662640153]}}
I/flutter (31418): 📍 相机位置更新: 30.279980337251015, 120.13813662640155, zoom: 12.579999923706055
I/flutter (31418): !  没有当前停留点，跳过InfoWindow更新
I/AMapFlutter_MapController(31418): onCameraChange===>{position={bearing=0.0, zoom=11.88, tilt=0.0, target=[30.279913165108443, 120.12227136034986]}}
I/flutter (31418): 📍 相机位置更新: 30.279913165108443, 120.12227136034983, zoom: 11.880000114440918
I/flutter (31418): !  没有当前停留点，跳过InfoWindow更新
I/AMapFlutter_MapController(31418): onCameraChange===>{position={bearing=0.0, zoom=11.22, tilt=0.0, target=[30.2798506254861, 120.1073126809297]}}
I/flutter (31418): 📍 相机位置更新: 30.2798506254861, 120.10731268092968, zoom: 11.220000267028809
I/flutter (31418): !  没有当前停留点，跳过InfoWindow更新
I/AMapFlutter_MapController(31418): onCameraChange===>{position={bearing=0.0, zoom=11.0, tilt=0.0, target=[30.27982862079468, 120.10232645445633]}}
I/flutter (31418): 📍 相机位置更新: 30.27982862079468, 120.10232645445632, zoom: 11.0
I/flutter (31418): !  没有当前停留点，跳过InfoWindow更新
I/AMapFlutter_MapController(31418): onCameraChangeFinish===>{position={bearing=0.0, zoom=11.0, tilt=0.0, target=[30.27982862079468, 120.10232645445633]}}
I/flutter (31418): 🏁 地图移动结束，进行最终位置更新
I/flutter (31418): 📍 相机位置更新: 30.27982862079468, 120.10232645445632, zoom: 11.0
I/flutter (31418): !  没有当前停留点，跳过InfoWindow更新
I/flutter (31418): 📍 全局监听器收到定位数据: {callbackTime: 2025-09-19 16:10:15, locationTime: 2025-09-19 16:09:44, locationType: 2, latitude: 30.283854, longitude: 119.98432, accuracy: 50.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 余杭区, street: 余杭塘河滨水公园绿道, streetNumber: 19号, cityCode: 0571, adCode: 330110, address: 浙江省杭州市余杭区余杭塘河滨水公园绿道19号靠近云城·金龙中心, description: 在云城·金龙中心附近}
I/flutter (31418): 📍 _onLocationUpdate 被调用，收到数据: {callbackTime: 2025-09-19 16:10:15, locationTime: 2025-09-19 16:09:44, locationType: 2, latitude: 30.283854, longitude: 119.98432, accuracy: 50.0, altitude: 0.0, bearing: 0.0, speed: 0.0, country: 中国, province: 浙江省, city: 杭州市, district: 余杭区, street: 余杭塘河滨水公园绿道, streetNumber: 19号, cityCode: 0571, adCode: 330110, address: 浙江省杭州市余杭区余杭塘河滨水公园绿道19号靠近云城·金龙中心, description: 在云城·金龙中心附近}