帮我对接用机记录页面的接口   /v2/get/sensitive/record   
参数  date  值  2025-09-26，不传的话默认当天
返回的数据格式在api.md,请注意
1.返回的数据  all_record  是全部记录  ，sensitive_record  敏感记录 ， unlock_mobile_record  是解锁记录  ， location_stay_abnormal_record是  定位/足迹异常记录，mobile_screen_usage_duration_record  是  屏幕使用时长。
其中 敏感记录，解锁记录，定位/足迹异常记录 他们三个的数据结构是一样的
2.返回的数据  sensitive_level  123分别代表，高敏感，中敏感，低敏感数据 （屏幕使用时长  没有）
3.其中最主要的是  ext  参数，他是一个字典  里面一共有10个key  在api_sub.md,要注意并不是每个都全部返回，可能有的ext是{}，可能有的ext 里只有一个key,可能两个 三个四个等
4.请注意event_type 这个字段对应的 app上展示的UI ext扩展参数说明  在api_type.md， 请注意区分当前是否是会员
5.我已经写好对应类型的样式
请好好分析需求和数据结构以及我的页面UI，然后把  敏感记录，解锁记录，屏幕使用时长，定位/足迹异常的内容用真实数据渲染出来 （解锁记录上的折线图和解锁手机次数先不用管，因为接口数据还没做好）