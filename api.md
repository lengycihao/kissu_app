1.聊天页面一键锁机点击事件埋点
页面id : chat_page
事件id :chat_page_click_lock_phone_event
参数，注意lock_status这个是新增的  0无状态 1锁机中  2已解锁
虚拟用户id	device_id	string
用户id	user_id	int
点击时间	click_time	int
会员状态	vip_status	int
绑定状态	bind_status	int
参与188活动	is_check_in	int
绑定次数	bind_num	int
锁机状态	lock_status	int

2.非会员时点击一键锁机（入口聊天页面，我的页面）弹出的弹窗有两个埋点事件
（1）曝光事件
如果在聊天页面弹出，则页面id为chat_page，事件id为chat_page_vip_lock_phone_exposure_dialog_event
如果在个人页面弹出，则页面id为my_page，事件id为my_page_vip_lock_phone_exposure_dialog_event
参数 注意previous_page这个参数 如果在聊天页面弹出，则previous_page为chat，如果在个人页面弹出，则previous_page为mine
曝光时间	page_enter_time	int
虚拟用户id	device_id	string
用户id	user_id	int
会员状态	vip_status	int
绑定状态	bind_status	int
是否参与188活动	is_check_in	int
绑定次数	bind_num	int
位置	previous_page	string
(2)点击事件
如果在聊天页面弹出，则页面id为chat_page，事件id为chat_page_vip_lock_phone_click_dialog_event
如果在个人页面弹出，则页面id为my_page，事件id为my_page_vip_lock_phone_click_dialog_event
参数 注意btn_status  1进入 0关闭
虚拟用户id	device_id	string
用户id	user_id	int
点击时间	click_time	int
会员状态	vip_status	int
绑定状态	bind_status	int
参与188活动	is_check_in	int
绑定次数	bind_num	int
点击的状态	btn_status	int

3.我的页面一键锁机点击事件埋点,注意这个埋点事件已经存在了，只是新增了lock_status这个参数，且这个参数只有一键锁机这个功能有
页面id : my_page
事件id :my_page_functions_moudle_event
参数，注意lock_status这个是新增的  0无状态 1锁机中 2已解锁
虚拟用户id	device_id	string
用户id	user_id	int
点击时间	click_time	int
会员状态	vip_status	int
绑定状态	bind_status	int
参与188活动	is_check_in	int
按钮名称	btn_name	string
绑定次数	bind_num	int
锁机状态	lock_status	int

4.一键锁机页面的长按锁机按钮点击事件
页面id : lock_phone_page
事件id :lock_phone_page_long_press_levent
参数 
虚拟用户id	device_id	string
用户id	user_id	int
点击时间	click_time	int
会员状态	vip_status	int
绑定状态	bind_status	int
参与188活动	is_check_in	int
绑定次数	bind_num	int

5.锁定成功之后，主动解锁按钮的点击事件
页面id : lock_phone_page
事件id :lock_phone_page_initiative_unlock_phone_event
参数 
虚拟用户id	device_id	string
用户id	user_id	int
点击时间	click_time	int
会员状态	vip_status	int
绑定状态	bind_status	int
参与188活动	is_check_in	int
绑定次数	bind_num	int

6.被锁定方在回答问题时，选择答案时的埋点,注意这个埋点事件是每次选择答案都会触发
页面id : lock_phone_page
事件id :lock_phone_page_answer_unlock_phone_event
参数  注意unlock_status  1解锁成功0解锁失败
虚拟用户id	device_id	string
用户id	user_id	int
点击时间	click_time	int
会员状态	vip_status	int
绑定状态	bind_status	int
参与188活动	is_check_in	int
绑定次数	bind_num	int
解锁状态	unlock_status	int

7.注意这个开通会员页面的事件vip_page_event 和绑定弹窗页面bind_page_event也要更新，因为他们有source_event，source_page这两个参数，在两个一键锁机入口触发这两个页面的时候要把对应的来源页和来源事件传入
