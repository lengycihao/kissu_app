会员页面id:membership_event_id

页面事件id：membership_page_event
虚拟用户id	mock_user_id	通过设备号生产用户虚拟id
用户id	user_id	获取管理后台对应的用户id
进入页面时间	page_enter_time	进入此页面时间，事件格式为：年-月-日 时:分:秒
页面停留时长	page_duration	记录此用户的停留时长（如：22:22）（从进入此页面开始计算，到离开此页面，包含关闭App）
会员状态	vip_status	未充值会员、会员中、会员已到期（0、1、2）
绑定状态	bind_status	未绑定、已绑定、已解绑 (0、1、2)
参与188活动	action_188	1\0
绑定次数	bind_num	默认 0
页面滑动次数	page_scroll_num	默认0
来源页	source_page	 
离开方式	exit_type	返回、关闭App、切换到后台、进入下一页（1、2、3、4）

 
会员套餐点击事件id：membership_page_type_click_event
虚拟用户id	mock_user_id	通过设备号生产用户虚拟id
用户id	user_id	获取管理后台对应的用户id
点击时间	click_time	点击的时间，时间格式：年/月/日 时:分:秒
会员状态	vip_status	未充值会员、会员中、会员已到期（0、1、2）
绑定状态	bind_status	未绑定、已绑定、已解绑 (0、1、2)
参与188活动	action_188	1\0
绑定次数	bind_num	默认 0
点击的状态	click_status	（这个取套餐里的type字段）
 
立即支付点击事件id：membership_page_pay_btn_event
虚拟用户id	mock_user_id	通过设备号生产用户虚拟id
用户id	user_id	获取管理后台对应的用户id
点击时间	click_time	点击的时间，时间格式：年/月/日 时:分:秒
会员状态	vip_status	未充值会员、会员中、会员已到期（0、1、2）
绑定状态	bind_status	未绑定、已绑定、已解绑 (0、1、2)
参与188活动	action_188	1\0
绑定次数	bind_num	默认 0
会员类型	member_type	（这个取套餐里的type字段）
支付方式	pay_type	苹果、微信、支付宝（去找对应枚举）
支付状态	pay_status	支付成功、支付失败、用户取消（去找对应枚举）
按钮名称	btn_name	立即支付、立即续费（去找对应枚举）
支付用时	pay_duration	如：22s，从点击“支付按钮”开始到返回“支付状态”结束

 
返回时挽留弹窗点击事件id：membership_page_reback_popup_event
虚拟用户id	mock_user_id	通过设备号生产用户虚拟id
用户id	user_id	获取管理后台对应的用户id
点击时间	click_time	点击的时间，时间格式：年/月/日 时:分:秒
会员状态	vip_status	未充值会员、会员中、会员已到期（0、1、2）
绑定状态	bind_status	未绑定、已绑定、已解绑 (0、1、2)
参与188活动	action_188	1\0
绑定次数	bind_num	默认 0
点击的状态	btn_name	全部解锁、下次再说（去找枚举）

19元弹窗点击事件id：popup_19_dialog_event
虚拟用户id	mock_user_id	通过设备号生产用户虚拟id
用户id	user_id	获取管理后台对应的用户id
点击时间	click_time	点击的时间，时间格式：年/月/日 时:分:秒
会员状态	vip_status	未充值会员、会员中、会员已到期（0、1、2）
绑定状态	bind_status	未绑定、已绑定、已解绑 (0、1、2)
参与188活动	action_188	1\0
绑定次数	bind_num	默认 0
点击的状态	btn_name	立即支付、关闭了弹窗（包括空白位置），去找枚举


 
 
 

 
 







