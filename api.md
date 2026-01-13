用户协议	用户协议弹窗	user_agreement_page	user_agreement_popout_event	虚拟用户id	deviec_id	string			
				进入页面时间	page_enter_time	int	十位时间戳		
				页面停留时长	page_duration	int	秒		
	协议操作		user_agreement_operation_event	虚拟用户id	deviec_id	string			
				点击时间	click_time	int	十位时间戳		
				操作协议	operation	int	1同意 0不同意		
登录	登录页面	login_page	login_page_event	虚拟用户id	deviec_id	string			
				进入页面时间	page_enter_time	int	十位时间戳		
				页面停留时长	page_duration	int	秒		
				离开方式	exit_type	int	1=>返回 2关闭APP 3=>切换到后台 4进入下一页		
	手机号文本框		login_page_phone_input_event	虚拟用户id	deviec_id	string			
				点击时间	click_time	int	十位时间戳		
				是否输入	is_input	int	1是 0否		
	验证码文本框		login_page_code_input_event	虚拟用户id	deviec_id	string			
				点击时间	click_time	int	十位时间戳		
				是否输入	is_input	int	1是 0否		
	获取验证码		login_page_get_code_event

	虚拟用户id	deviec_id	string			
				点击时间	click_time	int	十位时间戳		
				发送状态	send_status	int	1成功 0失败		
	登录/注册		login_page_button_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				登录状态	login_status	int	1成功 0失败		
个人信息	个人信息	perfect_user_info_page	login_info_page_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				进入页面时间	page_enter_time	int	十位时间戳		
				页面停留时长	page_duration	int	秒		
				离开方式	exit_type	int	1=>返回 2关闭APP 3=>切换到后台 4进入下一页		
	性别		login_info_page_gender_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				性别	sex	string	1;//默认男性2;//男性3;//女性		
	生日		login_info_page_birthday_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				选择的日期	select_date	string	2025/9/7		
	开始陪伴		login_info_page_button_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				是否更换头像	is_change_avatar	int	1是 0否		
				是否修改昵称	is_change_nickname	int	1是 0否		
				点击时间	click_time	int	十位时间戳		
绑定页面	绑定页面	bind_page	bind_page_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				页面停留时长	page_duration	int	秒		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定次数	bind_num	int			
				绑定状态	bind_status	int	1绑定成功 0绑定失败		
				来源页	source_page	string			
				离开方式	exit_type	int	1=>返回 2关闭APP 3=>切换到后台 4进入下一页		
	输入匹配码框		bind_page_friend_code_input_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int			
	确定按钮		bind_page_sure_button_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int			
				绑定状态	bind_status	int	1绑定成功 0绑定失败		
	关闭按钮		bind_page_cancel_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
	挽留弹窗		bind_page_reback_dialog_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				点击按钮	btn_status	int	0=》再想想  1=》立马绑定		
首页	首页	home_page	home_page_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				进入页面时间	page_enter_time	int	十位时间戳		
				页面停留时长	page_duration	int	秒		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				是否参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
				离开方式	exit_type	string	1=>返回 2关闭APP 3=>切换到后台 4进入下一页		
	导航		home_page_bottom_navigation_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				导航名称	navigation_name	string	location=>定位 track=>足迹 chat=>聊天 用机记录=>mobile_use 我的=>my		
				点击时间	click_time	int	十位时间戳		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	1=>返回 2关闭APP 3=>切换到后台 4进入下一页		
				参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
	首页头像		home_page_bind_partner_avatar_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
	会员福利		home_page_vip_action_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
	一起便便		home_page_poop_together_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
	首页底部广告		home_page_seeding_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				点击状态	btn_status	int	1进入 0关闭		
				绑定次数	bind_num	int			
	充值提醒弹窗		home_page_vip_recharge_dialog_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑
		
				参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
				点击的状态	btn_status	int	1进入 0关闭		
	续费提示弹窗		home_page_renewal_reminder_dialog_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
				点击的状态	btn_status		1进入 0关闭		
	会员过期提醒弹窗		home_page_vip_expire_dialog_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
				点击的状态	btn_status		1进入 0关闭		
定位	定位	location_page	location_page_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				进入页面时间	page_enter_time	int	十位时间戳		
				页面停留时长	page_duration	int	秒		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
				离开方式	exit_type	int	1=>返回 2关闭APP 3=>切换到后台 4进入下一页		
	定位返回		location_page_back_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
	我的心情		location_page_mood_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				是否设置状态	is_set_mood	int	是否设置心情 1是 0否		
				绑定次数	bind_num	int			
	Ta的足迹		location_page_track_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
	位置提醒		location_page_remind_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int			
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
	定位-绑定/会员按钮		location_page_vip_bind_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int			
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				按钮名称	btn_name	string			
				绑定次数	bind_num	int			
足迹	足迹	track_page	track_page_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				进入页面时间	page_enter_time	int	十位时间戳		
				页面停留时长	page_duration	int	秒		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
				离开方式	exit_type	string	1=>返回 2关闭APP 3=>切换到后台 4进入下一页		
	头像切换		track_page_change_avatar_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				头像身份	is_oneself	int	1自己 0另一半		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
	足迹返回		track_page_back_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
	视频回放		track_page_history_video_replay_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
	足迹-绑定/会员按钮		track_page_vip_bind_event
	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				按钮名称	btn_name	int			
				绑定次数	bind_num	int			
聊天	聊天	chat_page	chat_page_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				进入页面时间	page_enter_time	int	十位时间戳		
				页面停留时长	page_duration	int	秒		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
				单方发送消息次数	send_num	int			
				离开方式	exit_type	int	1=>返回 2关闭APP 3=>切换到后台 4进入下一页		
	聊天返回		chat_page_back_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
	设置		chat_page_setting_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
	聊天背景按钮		chat_page_bg_btn_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int			
				背景的名称	bg_name	string			
	聊天气泡按钮		chat_page_buddle_btn_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int			
				气泡名称	buddle_name	string			
	聊天主题按钮		chat_page_theme_btn_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				聊天主体名称	theme_name	string			
用机记录	用机记录	mobile_use_page	mobile_use_page_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				进入页面时间	page_enter_time	int	十位时间戳		
				页面停留时长	page_duration	int	秒		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
				离开方式	exit_type	int	1=>返回 2关闭APP 3=>切换到后台 4进入下一页		
	引导开启权限		mobile_use_page_permission_guide_btn_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
	用机记录返回		mobile_use_page_back_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
	用机记录设置		mobile_use_page_setting_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
	手机使用记录		mobile_use_page_module_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				按钮名称	btn_name	string			
				绑定次数	bind_num	int			
	App使用记录		mobile_use_page_app_use_module_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				按钮名称	btn_name	int			
				绑定次数	bind_num	int			
	敏感操作记录		mobile_use_page_sensitive_operation_module_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				按钮名称	btn_name	int			
				绑定次数	bind_num	int			
手机使用统计	手机使用统计	mobile_use_stat_page	mobile_use_stat_page_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				进入页面时间	page_enter_time	int	十位时间戳		
				页面停留时长	page_duration	int	秒		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
				离开方式	exit_type	int	1=>返回 2关闭APP 3=>切换到后台 4进入下一页		
App使用统计	App使用统计	app_use_stat_page	app_use_stat_page_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				进入页面时间	page_enter_time	int	十位时间戳		
				页面停留时长	page_duration	int	秒		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
				离开方式	exit_type	int	1=>返回 2关闭APP 3=>切换到后台 4进入下一页		
敏感操作记录	敏感操作记录	sensitive_page	sensitive_page_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				进入页面时间	page_enter_time	int	十位时间戳		
				页面停留时长	page_duration	int	秒		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
				离开方式	exit_type	int	1=>返回 2关闭APP 3=>切换到后台 4进入下一页		
	VIP入口		sensitive_page_event_item_vip_btn_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
我的	我的	my_page	my_page_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				进入页面时间	page_enter_time	int	十位时间戳		
				页面停留时长	page_duration	int	秒		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
				离开方式	exit_type	int			
	我的返回		my_page_back_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
	头像		my_page_avatar_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
	会员中心		my_page_vip_btn_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				按钮名称	btn_name	string			
				绑定次数	bind_num	int			
	权限设置		my_page_permission_btn_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
	常用功能入口		my_page_functions_moudle_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				按钮名称	btn_name	string			
				绑定次数	bind_num	int			
	更换app图标		my_page_change_logo_page_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				进入页面时间	page_enter_time	int	十位时间戳		
				页面停留时长	page_duration	int	秒		
				会员状态	vip_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				绑定状态	bind_status	int			
				参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
				离开方式	exit_type	int	1=>返回 2关闭APP 3=>切换到后台 4进入下一页		
	更换图标		my_page_change_logo_item_btn_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
				App图标名称	logo_name	string			
	分享App		my_page_share_btn_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
	分享渠道		my_page_share_channel_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
				分享渠道名称	share_type	int	1=》微信 2=》QQ 3=>复制链接		
				分享状态	share_status	int	0=》分享失败 1分享成功 2复制成功 3未分享		
	分享关闭按钮		my_page_share_close_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
会员中心	会员中心	vip_page	vip_page_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				进入页面时间	page_enter_time	int	十位时间戳		
				页面停留时长	page_duration	int	秒		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
				页面滑动次数	page_scroll_num	int			
				来源页	source_page	string			
				离开方式	exit_type	int	1=>返回 2关闭APP 3=>切换到后台 4进入下一页		
	会员类型		vip_page_type_click_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
				点击的状态	vip_type	int	1=>月度会员  2年度会员  3永久会员		
	立即支付		vip_page_pay_btn_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
				会员类型	vip_type	int	1=>月度会员  2年度会员  3永久会员		
				支付方式	int		1=》支付宝 2=>微信 3=》苹果		
				支付状态	pay_status	int	0=》支付失败  1=》支付成功  2=》取消支付		
				按钮名称	btn_name	string			
				支付用时	pay_duration	int			
	99元立即开通		vip_page_99_pay_event	虚拟用户id	deviec_id	int			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
				会员类型	vip_type	int	1=>月度会员  2年度会员  3永久会员		
				支付方式	pay_type	int	1=》支付宝 2=>微信 3=》苹果		
				支付状态	pay_status	int	0=》支付失败  1=》支付成功  2=》取消支付		
				按钮名称	btn_name	string			
				支付用时	pay_duration	int			
	会员页挽留弹窗		vip_page_reback_popup_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
				点击的状态	btn_status	int	1=》进入 0=》取消		
	19元弹窗		vip_page_19_dialog_event	虚拟用户id	deviec_id	string			
				用户id	user_id	int			
				点击时间	click_time	int	十位时间戳		
				会员状态	vip_status	int	0非会员 1会员中  2会员到期		
				绑定状态	bind_status	int	0=》未绑定 1=》已绑定  2=》已解绑		
				参与188活动	is_check_in	int	1已参与 0未参与		
				绑定次数	bind_num	int			
				点击的状态	btn_status	int	1=》立即 0=》取消		
	 	