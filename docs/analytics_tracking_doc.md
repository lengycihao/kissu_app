# 埋点实现文档

本文档记录了所有已实现的埋点，包括方法位置、参数说明和使用示例。

## 目录
- [登录页面](#登录页面)
- [个人信息页面](#个人信息页面)
- [绑定页面](#绑定页面)

---

## 登录页面

### 页面浏览埋点
**实现位置**: `lib/pages/login/login_page.dart` - `_LoginPageState.dispose()`

**事件信息**:
- 页面ID: `login_event`
- 事件ID: `login_page`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 页面进入时间 | page_enter_time | String | 格式: yyyy-MM-dd HH:mm:ss | "2024-01-07 10:30:00" |
| 页面停留时长 | page_duration | String | 格式: mm:ss | "02:30" |
| 来源页 | source_page | String | 来源页面ID | "9999" (被挤下线) |
| 离开方式 | exit_type | int | 1=返回, 2=关闭App, 3=后台, 4=下一页 | 1 |

**代码示例**:
```dart
AnalyticsManager.instance.trackPageView(
  pageId: LoginEvents.pageId,
  eventId: LoginEvents.page,
  enterTime: enterTimeStr,
  duration: durationStr,
  sourcePage: _sourcePage.toString(),
  exitType: exitType,
);
```

---

### 获取验证码事件
**实现位置**: `lib/pages/login/login_page.dart` - 验证码按钮点击处理

**事件信息**:
- 页面ID: `login_event`
- 事件ID: `login_get_verification_code`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 发送状态 | send_status | int | 1=成功, 0=失败 | 1 |

**调用方法**:
```dart
AnalyticsHelper.trackGetVerificationCode(success: true);
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:46`

---

### 登录按钮事件
**实现位置**: `lib/pages/login/login_page.dart` - 登录按钮点击处理

**事件信息**:
- 页面ID: `login_event`
- 事件ID: `login_button`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 登录状态 | login_status | int | 1=成功, 0=失败 | 1 |

**调用方法**:
```dart
AnalyticsHelper.trackLoginButton(success: true);
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:57`

---

## 个人信息页面

### 页面浏览埋点
**实现位置**: `lib/pages/login/info_setting/info_setting_page.dart` - `_InfoSettingPageState.dispose()`

**事件信息**:
- 页面ID: `login_info_event`
- 事件ID: `login_info_page`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 页面进入时间 | page_enter_time | String | 格式: yyyy-MM-dd HH:mm:ss | "2024-01-07 10:30:00" |
| 页面停留时长 | page_duration | String | 格式: mm:ss | "02:30" |
| 来源页 | source_page | String | 来源页面ID | "login_event" |
| 离开方式 | exit_type | int | 1=返回, 2=关闭App, 3=后台, 4=下一页 | 4 |

**代码示例**:
```dart
AnalyticsManager.instance.trackPageView(
  pageId: LoginInfoEvents.pageId,
  eventId: LoginInfoEvents.page,
  enterTime: enterTimeStr,
  duration: durationStr,
  sourcePage: _sourcePage.toString(),
  exitType: ExitTypeValue.nextPage,
);
```

---

### 性别选择事件
**实现位置**: `lib/pages/login/info_setting/info_setting_controller.dart` - `selectGender()`

**事件信息**:
- 页面ID: `login_info_event`
- 事件ID: `login_info_gender`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 性别 | sex | String | 1=默认男性(无操作), 2=男性, 3=女性 | "2" |

**调用方法**:
```dart
final sexValue = gender == '男' ? GenderValue.male.toString() : GenderValue.female.toString();
AnalyticsHelper.trackGenderSelect(gender: sexValue);
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:70`

---

### 生日选择事件
**实现位置**: `lib/pages/login/info_setting/info_setting_controller.dart` - `pickBirthday()` 确定按钮

**事件信息**:
- 页面ID: `login_info_event`
- 事件ID: `login_info_select_birthday`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 选择的日期 | select_date | String | 格式: yyyy-MM-dd | "2007-01-01" |

**调用方法**:
```dart
final dateStr = DateFormat('yyyy-MM-dd').format(tempPicked);
AnalyticsHelper.trackBirthdaySelect(date: dateStr);
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:81`

---

### 开启陪伴按钮事件
**实现位置**: `lib/pages/login/info_setting/info_setting_controller.dart` - `onSubmit()`

**事件信息**:
- 页面ID: `login_info_event`
- 事件ID: `login_info_sure_btn`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 是否修改头像 | change_avatar | int | 1=是, 0=否 | 1 |
| 是否修改昵称 | change_nickname | int | 1=是, 0=否 | 0 |

**调用方法**:
```dart
final hasChangedNickname = currentNickname != _initialNickname;
AnalyticsHelper.trackLoginInfoSure(
  changeAvatar: _hasChangedAvatar,
  changeNickname: hasChangedNickname,
);
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:92`

---

## 绑定页面

### 页面浏览埋点
**实现位置**: `lib/widgets/dialogs/custom_bottom_dialog_controller.dart` - `onClose()` 和 `_trackPageView()`

**事件信息**:
- 页面ID: `bind_event`
- 事件ID: `bind_page`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 页面进入时间 | page_enter_time | String | 格式: yyyy-MM-dd HH:mm:ss | "2024-01-07 10:30:00" |
| 页面停留时长 | page_duration | String | 格式: mm:ss | "02:30" |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定次数 | bind_num | int | 自动添加 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 来源页 | source_page | String | 来源页面ID | - |
| 离开方式 | exit_type | int | 1=返回, 2=关闭App, 3=后台, 4=下一页 | - |

**代码示例**:
```dart
// 在 onInit 中记录进入时间
_pageEnterTime = DateTime.now().millisecondsSinceEpoch;

// 在 onClose 中记录页面浏览
AnalyticsManager.instance.trackPageView(
  pageId: BindEvents.pageId,
  eventId: BindEvents.page,
  enterTime: enterTimeStr,
  duration: durationStr,
  sourcePage: _sourcePage?.toString(),
  exitType: _exitType,
);
```

---

### 输入匹配码事件
**实现位置**: `lib/widgets/dialogs/custom_bottom_dialog.dart` - `_showInputDialog()`

**事件信息**:
- 页面ID: `bind_event`
- 事件ID: `bind_input`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |

**调用方法**:
```dart
controller.trackBindInput();
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:109`

---

### 确认按钮事件
**实现位置**: `lib/widgets/dialogs/custom_bottom_dialog_controller.dart` - `bindPartner()`

**事件信息**:
- 页面ID: `bind_event`
- 事件ID: `bind_sure`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 绑定状态 | bind_status | int | 1=绑定成功, 0=绑定失败 | 1 |

**调用方法**:
```dart
trackBindSure(success: result.isSuccess);
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:117`

---

### 关闭按钮事件
**实现位置**: `lib/widgets/dialogs/custom_bottom_dialog.dart` - 关闭按钮 `onTap`

**事件信息**:
- 页面ID: `bind_event`
- 事件ID: `bind_cancel`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |

**调用方法**:
```dart
controller.trackBindCancel();
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:128`

---

### 返回弹窗事件
**实现位置**: `lib/widgets/dialogs/binding_close_confirm_dialog.dart` - 按钮 `onTap`

**事件信息**:
- 页面ID: `bind_event`
- 事件ID: `bind_reback_dialog`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 点击按钮 | btn_name | int | 0=再想想, 1=立马绑定 | 1 |

**调用方法**:
```dart
// 再想想按钮
AnalyticsHelper.trackBindRebackDialog(btnName: 0);

// 立马绑定按钮
AnalyticsHelper.trackBindRebackDialog(btnName: 1);
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:136`

---

## 首页

### 底部导航栏点击事件
**实现位置**: `lib/pages/home/home_controller.dart` - `onButtonTap()`

**事件信息**:
- 页面ID: `home_event`
- 事件ID: `home_bottom_navigation`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 导航名称 | navigation_name | String | 定位、足迹、聊天、用机记录、我的 | "定位" |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 参与188活动 | action_188 | int | 自动添加: 0=未参与, 1=已参与 | - |
| 绑定次数 | bind_num | int | 自动添加 | - |

**调用方法**:
```dart
AnalyticsHelper.trackBottomNavigation(navigationName: '定位');
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:147`

---

### 右上角头像点击事件
**实现位置**: `lib/pages/home/widget/home_avatar_section.dart` - 头像 `onTap`

**事件信息**:
- 页面ID: `home_event`
- 事件ID: `home_bind_partner_avatar`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 参与188活动 | action_188 | int | 自动添加: 0=未参与, 1=已参与 | - |
| 绑定次数 | bind_num | int | 自动添加 | - |

**调用方法**:
```dart
AnalyticsHelper.trackBindPartnerAvatar();
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:158`

---

### 会员福利按钮点击事件
**实现位置**: `lib/pages/home/widget/home_avatar_section.dart` - 会员福利按钮 `onTap`

**事件信息**:
- 页面ID: `home_event`
- 事件ID: `home_vip_action`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 参与188活动 | action_188 | int | 自动添加: 0=未参与, 1=已参与 | - |
| 绑定次数 | bind_num | int | 自动添加 | - |

**调用方法**:
```dart
AnalyticsHelper.trackVipAction();
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:166`

---

### 一起便便按钮点击事件
**实现位置**: `lib/pages/home/widget/home_avatar_section.dart` - 一起便便按钮 `onTap`

**事件信息**:
- 页面ID: `home_event`
- 事件ID: `home_poop_together`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 参与188活动 | action_188 | int | 自动添加: 0=未参与, 1=已参与 | - |
| 绑定次数 | bind_num | int | 自动添加 | - |

**调用方法**:
```dart
AnalyticsHelper.trackPoopTogether();
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:201`

---

### 充值弹窗事件
**实现位置**: `lib/widgets/dialogs/vip_purchase_dialog.dart`

**事件信息**:
- 页面ID: `home_event`
- 事件ID: `home_vip_recharge_dialog`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 参与188活动 | action_188 | int | 自动添加: 0=未参与, 1=已参与 | - |
| 绑定次数 | bind_num | int | 自动添加 | - |
| 点击的状态 | btn_name | int | 0=确认, 1=关闭 | 0 |

**调用方法**:
```dart
// 确认按钮
AnalyticsHelper.trackVipRechargeDialog(btnName: 0);

// 关闭按钮
AnalyticsHelper.trackVipRechargeDialog(btnName: 1);
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:174`

---

### 续费弹窗事件
**实现位置**: `lib/widgets/dialogs/vip_outtime_dialog.dart`

**事件信息**:
- 页面ID: `home_event`
- 事件ID: `home_renewal_reminder_dialog`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 参与188活动 | action_188 | int | 自动添加: 0=未参与, 1=已参与 | - |
| 绑定次数 | bind_num | int | 自动添加 | - |
| 点击的状态 | btn_name | int | 0=立即续费, 1=下次再说 | 0 |

**调用方法**:
```dart
// 立即续费按钮
AnalyticsHelper.trackRenewalReminderDialog(btnName: 0);

// 下次再说按钮
AnalyticsHelper.trackRenewalReminderDialog(btnName: 1);
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:183`

---

## 定位页面

### 定位页面浏览事件
**实现位置**: `lib/pages/location/widgets/location_page_layout.dart` - `_LocationPageLayoutState`

**事件信息**:
- 页面ID: `location_event`
- 事件ID: `location_page`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 进入页面时间 | page_enter_time | String | 格式: yyyy-MM-dd HH:mm:ss | "2024-01-07 23:30:00" |
| 页面停留时长 | page_duration | String | 格式: mm:ss | "05:30" |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 参与188活动 | action_188 | int | 自动添加: 0=未参与, 1=已参与 | - |
| 绑定次数 | bind_num | int | 自动添加 | - |
| 来源页 | source_page | String | 从路由参数获取 | - |
| 离开方式 | exit_type | int | 1=返回, 2=关闭App, 3=后台, 4=下一页 | 1 |

**实现说明**: 在页面的 `initState` 中记录进入时间，在 `dispose` 中计算停留时长并上报。

---

### 返回按钮事件
**实现位置**: `lib/pages/location/location_v2_controller.dart` - `handleBackButtonTap()`

**事件信息**:
- 页面ID: `location_event`
- 事件ID: `location_back`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 参与188活动 | action_188 | int | 自动添加: 0=未参与, 1=已参与 | - |
| 绑定次数 | bind_num | int | 自动添加 | - |

**调用方法**:
```dart
AnalyticsHelper.trackLocationBack();
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:211`

---

### 我的心情按钮事件
**实现位置**: `lib/pages/location/widgets/floating_action_buttons.dart` - 状态按钮 `onTap`

**事件信息**:
- 页面ID: `location_event`
- 事件ID: `location_current_state`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 参与188活动 | action_188 | int | 自动添加: 0=未参与, 1=已参与 | - |
| 是否设置状态 | set_status | int | 0=未设置, 1=已设置 | 1 |
| 绑定次数 | bind_num | int | 自动添加 | - |

**调用方法**:
```dart
AnalyticsHelper.trackLocationCurrentState(hasSet: true);
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:219`

---

### Ta的足迹按钮事件
**实现位置**: `lib/pages/location/widgets/floating_action_buttons.dart` - 轨迹按钮 `onTap`

**事件信息**:
- 页面ID: `location_event`
- 事件ID: `location_her_track`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 参与188活动 | action_188 | int | 自动添加: 0=未参与, 1=已参与 | - |
| 绑定次数 | bind_num | int | 自动添加 | - |

**调用方法**:
```dart
AnalyticsHelper.trackLocationHerTrack();
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:228`

---

### 位置提醒按钮事件
**实现位置**: `lib/pages/location/widgets/floating_action_buttons.dart` - 位置提醒按钮 `onTap`

**事件信息**:
- 页面ID: `location_event`
- 事件ID: `location_location_knock`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 参与188活动 | action_188 | int | 自动添加: 0=未参与, 1=已参与 | - |
| 绑定次数 | bind_num | int | 自动添加 | - |

**调用方法**:
```dart
AnalyticsHelper.trackLocationKnock();
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:238`

---

### 去绑定/开通会员按钮事件
**实现位置**: `lib/pages/location/location_v2_controller.dart` - `performBindAction()` 和 `onOpenMembershipButtonTap()`

**事件信息**:
- 页面ID: `location_event`
- 事件ID: `location_tobind`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 参与188活动 | action_188 | int | 自动添加: 0=未参与, 1=已参与 | - |
| 按钮名称 | btn_name | String | "bind"=立即去绑定, "vip"=立即开通会员 | "bind" |
| 绑定次数 | bind_num | int | 自动添加 | - |

**调用方法**:
```dart
// 去绑定按钮
AnalyticsHelper.trackLocationToBind(btnName: 'bind');

// 开通会员按钮
AnalyticsHelper.trackLocationToBind(btnName: 'vip');
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:246`

---

## 轨迹页面

### 轨迹页面浏览事件
**实现位置**: `lib/pages/track/widgets/track_page_layout.dart` - `_TrackPageLayoutState`

**事件信息**:
- 页面ID: `track_event`
- 事件ID: `track_page`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 进入页面时间 | page_enter_time | String | 格式: yyyy-MM-dd HH:mm:ss | "2024-01-07 23:30:00" |
| 页面停留时长 | page_duration | String | 格式: mm:ss | "05:30" |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 参与188活动 | action_188 | int | 自动添加: 0=未参与, 1=已参与 | - |
| 绑定次数 | bind_num | int | 自动添加 | - |
| 来源页 | source_page | String | 从路由参数获取 | - |
| 离开方式 | exit_type | int | 1=返回, 2=关闭App, 3=后台, 4=下一页 | 1 |

**实现说明**: 在页面的 `initState` 中记录进入时间，在 `dispose` 中计算停留时长并上报。

---

### 顶部头像切换事件
**实现位置**: `lib/pages/track/track_controller.dart` - `onAvatarTapped()`

**事件信息**:
- 页面ID: `track_event`
- 事件ID: `track_avatar_change`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 头像身份 | avatar_name | String | "mine"=本人头像, "partner"=Ta的头像 | "mine" |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 参与188活动 | action_188 | int | 自动添加: 0=未参与, 1=已参与 | - |
| 绑定次数 | bind_num | int | 自动添加 | - |

**调用方法**:
```dart
// 本人头像
AnalyticsHelper.trackTrackAvatarChange(avatarName: 'mine');

// Ta的头像
AnalyticsHelper.trackTrackAvatarChange(avatarName: 'partner');
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:259`

---

### 返回按钮事件
**实现位置**: `lib/pages/track/track_controller.dart` - `handleBackButtonTap()`

**事件信息**:
- 页面ID: `track_event`
- 事件ID: `track_back`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 参与188活动 | action_188 | int | 自动添加: 0=未参与, 1=已参与 | - |
| 绑定次数 | bind_num | int | 自动添加 | - |

**调用方法**:
```dart
AnalyticsHelper.trackTrackBack();
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:270`

---

### 轨迹回放按钮事件
**实现位置**: `lib/pages/track/widgets/track_replay_floating_button.dart` - `_onPlayButtonTap()`

**事件信息**:
- 页面ID: `track_event`
- 事件ID: `track_history_replay`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 参与188活动 | action_188 | int | 自动添加: 0=未参与, 1=已参与 | - |
| 绑定次数 | bind_num | int | 自动添加 | - |

**调用方法**:
```dart
AnalyticsHelper.trackTrackHistoryReplay();
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:278`

---

### 去绑定/开通会员按钮事件
**实现位置**: `lib/pages/track/widgets/track_sheet_manager.dart` - 蒙版按钮 `onTap`

**事件信息**:
- 页面ID: `track_event`
- 事件ID: `track_tobind`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 按钮名称 | btn_name | int | 使用YesNoValue枚举值 | 1 |

**按钮名称枚举值** (`YesNoValue`):
- `1` (yes) - 立即支付
- `0` (no) - 关闭了弹窗（包括空白位置）

**调用方法**:
```dart
AnalyticsHelper.trackPopup19Dialog(btnName: YesNoValue.yes); // 立即支付
AnalyticsHelper.trackPopup19Dialog(btnName: YesNoValue.no);  // 关闭弹窗
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:552`86`

---

## 聊天页面

### 聊天页面浏览事件
**实现位置**: `lib/pages/chat/chat_controller.dart` - `onInit()` 和 `onClose()`

**事件信息**:
- 页面ID: `chat_event_id`
- 事件ID: `chat_page_event`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 进入页面时间 | page_enter_time | String | 格式: yyyy-MM-dd HH:mm:ss | "2024-01-08 00:00:00" |
| 页面停留时长 | page_duration | String | 格式: mm:ss | "05:30" |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 参与188活动 | action_188 | int | 自动添加: 0=未参与, 1=已参与 | - |
| 绑定次数 | bind_num | int | 自动添加 | - |
| 单方发送消息次数 | send_sum | int | 单方主动发送消息次数（不包含系统发送的） | 5 |
| 来源页 | source_page | String | 从路由参数获取 | - |
| 离开方式 | exit_type | int | 1=返回, 2=关闭App, 3=后台, 4=下一页 | 1 |

**实现说明**: 
- 在控制器的 `onInit` 中记录进入时间
- 在 `sendTextMessage()` 和 `_sendImageMessage()` 中增加发送消息计数
- 在控制器的 `onClose` 中计算停留时长和发送消息次数并上报

---

### 返回按钮事件
**实现位置**: `lib/pages/chat/chat_page.dart` - 返回按钮 `onTap`

**事件信息**:
- 页面ID: `chat_event_id`
- 事件ID: `chat_back_event`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 参与188活动 | action_188 | int | 自动添加: 0=未参与, 1=已参与 | - |
| 绑定次数 | bind_num | int | 自动添加 | - |

**调用方法**:
```dart
AnalyticsHelper.trackChatBack();
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:299`

---

### 设置按钮事件
**实现位置**: `lib/pages/chat/chat_page.dart` - 设置按钮 `onTap`

**事件信息**:
- 页面ID: `chat_event_id`
- 事件ID: `chat_setting_event`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 参与188活动 | action_188 | int | 自动添加: 0=未参与, 1=已参与 | - |
| 绑定次数 | bind_num | int | 自动添加 | - |

**调用方法**:
```dart
AnalyticsHelper.trackChatSetting();
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:307`

---

### 聊天背景页面确认按钮事件
**实现位置**: `lib/pages/chat/chat_background_controller.dart` - `applyBackground()`

**事件信息**:
- 页面ID: `chat_event_id`
- 事件ID: `chat_bg_btn_event`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 背景的名称 | bg_name | String | 背景ID，见api1.md | "100016" |

**背景ID映射** (api1.md):
- `100016` = 第一套背景
- `100012` = 第二套背景
- `100013` = 第三套背景
- `100014` = 第四套背景
- `100011` = 第五套背景
- `100015` = 第六套背景
- `100099` = 自定义背景（从相册添加）

**调用方法**:
```dart
AnalyticsHelper.trackChatBgBtn(bgName: '100016');
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:314`

---

### 聊天气泡页面确认按钮事件
**实现位置**: `lib/pages/chat/chat_bubble_controller.dart` - `applyBubbleStyle()`

**事件信息**:
- 页面ID: `chat_event_id`
- 事件ID: `chat_buddle_btn_event`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 气泡名称 | buddle_name | String | 气泡ID，见api1.md | "300011" |

**气泡ID映射** (api1.md):
- `300011` = 第一套气泡
- `300012` = 第二套气泡
- `300013` = 第三套气泡
- `300014` = 第四套气泡

**调用方法**:
```dart
AnalyticsHelper.trackChatBuddleBtn(buddleName: '300011');
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:321`

---

### 聊天主题页面确认按钮事件
**实现位置**: `lib/pages/chat/chat_theme_controller.dart` - `applyTheme()`

**事件信息**:
- 页面ID: `chat_event_id`
- 事件ID: `chat_theme_btn_event`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 聊天主体名称 | theme_name | String | 主题ID，见api1.md | "200011" |

**主题ID映射** (api1.md):
- `200011` = 第一套主题
- `200012` = 第二套主题
- `200013` = 第三套主题
- `200014` = 第四套主题

**调用方法**:
```dart
AnalyticsHelper.trackChatThemeBtn(themeName: '200011');
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:328`

---

## 用机记录页面

### 用机记录页面浏览事件
**实现位置**: `lib/pages/mine/device_usage/device_usage_controller.dart` - `onInit()` 和 `onClose()`

**事件信息**:
- 页面ID: `phone_history_event_id`
- 事件ID: `phone_history_page_event`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 进入页面时间 | page_enter_time | String | 格式: yyyy-MM-dd HH:mm:ss | "2024-01-08 00:00:00" |
| 页面停留时长 | page_duration | String | 格式: mm:ss | "05:30" |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 参与188活动 | action_188 | int | 自动添加: 0=未参与, 1=已参与 | - |
| 绑定次数 | bind_num | int | 自动添加 | - |
| 来源页 | source_page | String | 从路由参数获取 | - |
| 离开方式 | exit_type | int | 1=返回, 2=关闭App, 3=后台, 4=下一页 | 1 |

**实现说明**: 
- 在控制器的 `onInit` 中记录进入时间
- 在控制器的 `onClose` 中计算停留时长并上报

---

### 权限引导按钮事件
**实现位置**: `lib/pages/mine/device_usage/device_usage_page.dart` - 权限横幅"去开启"按钮 `onTap`

**事件信息**:
- 页面ID: `phone_history_event_id`
- 事件ID: `permission_guide_btn_event`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 参与188活动 | action_188 | int | 自动添加: 0=未参与, 1=已参与 | - |
| 绑定次数 | bind_num | int | 自动添加 | - |

**调用方法**:
```dart
AnalyticsHelper.trackPermissionGuideBtn();
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:350`

---

### 返回按钮事件
**实现位置**: `lib/pages/mine/device_usage/device_usage_page.dart` - 返回按钮 `onTap`

**事件信息**:
- 页面ID: `phone_history_event_id`
- 事件ID: `phone_history_back_event`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 参与188活动 | action_188 | int | 自动添加: 0=未参与, 1=已参与 | - |
| 绑定次数 | bind_num | int | 自动添加 | - |

**调用方法**:
```dart
AnalyticsHelper.trackPhoneHistoryBack();
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:358`

---

### 设置按钮事件
**实现位置**: `lib/pages/mine/device_usage/device_usage_page.dart` - 设置按钮 `onTap`

**事件信息**:
- 页面ID: `phone_history_event_id`
- 事件ID: `phone_history_setting_event`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 参与188活动 | action_188 | int | 自动添加: 0=未参与, 1=已参与 | - |
| 绑定次数 | bind_num | int | 自动添加 | - |

**调用方法**:
```dart
AnalyticsHelper.trackPhoneHistorySetting();
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:366`

---

### 手机使用记录模块点击事件
**实现位置**: `lib/pages/mine/device_usage/device_usage_page.dart` - `DevicePhoneUsageCard` 的 `onTap`

**事件信息**:
- 页面ID: `phone_history_event_id`
- 事件ID: `phone_history_page_event`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 参与188活动 | action_188 | int | 自动添加: 0=未参与, 1=已参与 | - |
| 按钮名称 | btn_name | String | "bind"=未绑定, "vip"=未开会员 | "bind" |
| 绑定次数 | bind_num | int | 自动添加 | - |

**实现说明**: 
- **不管是否会员都记录埋点**，包括带蒙版的情况
- 未绑定时 `btn_name` 为 "bind"
- 已绑定但未开会员时 `btn_name` 为 "vip"
- 已绑定且是会员时不记录（因为可以直接进入）

**调用方法**:
```dart
AnalyticsHelper.trackPhoneUseModule(btnName: 'bind');
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:374`

---

### App使用记录模块点击事件
**实现位置**: `lib/pages/mine/device_usage/device_usage_page.dart` - `DeviceAppUsageCard` 的 `onTap`

**事件信息**:
- 页面ID: `phone_history_event_id`
- 事件ID: `ph_app_use_module_event`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 参与188活动 | action_188 | int | 自动添加: 0=未参与, 1=已参与 | - |
| 按钮名称 | btn_name | String | "bind"=未绑定, "vip"=未开会员 | "vip" |
| 绑定次数 | bind_num | int | 自动添加 | - |

**实现说明**: 
- **不管是否会员都记录埋点**，包括带蒙版的情况
- 未绑定时 `btn_name` 为 "bind"
- 已绑定但未开会员时 `btn_name` 为 "vip"
- 已绑定且是会员时不记录（因为可以直接进入）

**调用方法**:
```dart
AnalyticsHelper.trackAppUseModule(btnName: 'vip');
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:385`

---

### 敏感操作记录模块点击事件
**实现位置**: `lib/pages/mine/device_usage/device_usage_page.dart` - `DeviceSensitiveUsageCard` 的 `onTap`

**事件信息**:
- 页面ID: `phone_history_event_id`
- 事件ID: `ph_sensitive_operation_module_event`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 参与188活动 | action_188 | int | 自动添加: 0=未参与, 1=已参与 | - |
| 按钮名称 | btn_name | String | "bind"=未绑定, "vip"=未开会员 | "bind" |
| 绑定次数 | bind_num | int | 自动添加 | - |

**实现说明**: 
- **不管是否会员都记录埋点**，包括带蒙版的情况
- 未绑定时 `btn_name` 为 "bind"
- 已绑定但未开会员时 `btn_name` 为 "vip"
- 已绑定且是会员时不记录（因为可以直接进入）

**调用方法**:
```dart
AnalyticsHelper.trackSensitiveOperationModule(btnName: 'bind');
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:396`

---

## 手机使用统计页面

### 手机使用统计页面浏览事件
**实现位置**: `lib/pages/mine/device_usage/app_usage_detail_controller.dart` - `onInit()` 和 `onClose()`

**事件信息**:
- 页面ID: `phone_use_event_id`
- 事件ID: `phone_use_page_event`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 进入页面时间 | page_enter_time | String | 格式: yyyy-MM-dd HH:mm:ss | "2024-01-08 00:00:00" |
| 页面停留时长 | page_duration | String | 格式: mm:ss | "05:30" |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 参与188活动 | action_188 | int | 自动添加: 0=未参与, 1=已参与 | - |
| 绑定次数 | bind_num | int | 自动添加 | - |
| 来源页 | source_page | String | 从路由参数获取 | - |
| 离开方式 | exit_type | int | 1=返回, 2=关闭App, 3=后台, 4=下一页 | 1 |

**实现说明**: 
- 在控制器的 `onInit` 中记录进入时间
- 在控制器的 `onClose` 中计算停留时长并上报

---

## App使用统计页面

### App使用统计页面浏览事件
**实现位置**: `lib/pages/mine/app_usage/app_usage_controller.dart` - `onInit()` 和 `onClose()`

**事件信息**:
- 页面ID: `app_use_event_id`
- 事件ID: `app_use_page_event`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 进入页面时间 | page_enter_time | String | 格式: yyyy-MM-dd HH:mm:ss | "2024-01-08 00:00:00" |
| 页面停留时长 | page_duration | String | 格式: mm:ss | "05:30" |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 参与188活动 | action_188 | int | 自动添加: 0=未参与, 1=已参与 | - |
| 绑定次数 | bind_num | int | 自动添加 | - |
| 来源页 | source_page | String | 从路由参数获取，如"定位"页面 | - |
| 离开方式 | exit_type | int | 1=返回, 2=关闭App, 3=后台, 4=下一页 | 1 |

**实现说明**: 
- 在控制器的 `onInit` 中记录进入时间
- 在控制器的 `onClose` 中计算停留时长并上报

---

## 敏感操作记录页面

### 敏感操作记录页面浏览事件
**实现位置**: `lib/pages/usage_report/usage_report_controller.dart` - `onInit()` 和 `onClose()`

**事件信息**:
- 页面ID: `sensitive_event_id`
- 事件ID: `sensitive_operation_page_event`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 进入页面时间 | page_enter_time | String | 格式: yyyy-MM-dd HH:mm:ss | "2024-01-08 00:00:00" |
| 页面停留时长 | page_duration | String | 格式: mm:ss | "05:30" |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 参与188活动 | action_188 | int | 自动添加: 0=未参与, 1=已参与 | - |
| 绑定次数 | bind_num | int | 自动添加 | - |
| 来源页 | source_page | String | 从路由参数获取，如"定位"页面 | - |
| 离开方式 | exit_type | int | 1=返回, 2=关闭App, 3=后台, 4=下一页 | 1 |

**实现说明**: 
- 该页面已有页面浏览埋点实现（使用 `_trackPageView()` 方法）
- 在控制器的 `onInit` 中记录进入时间
- 在控制器的 `onClose` 中计算停留时长并上报

---

### 敏感操作记录item上的vip按钮点击事件
**实现位置**: `lib/pages/usage_report/usage_report_controller.dart` - `handleRecordItemClick()`

**事件信息**:
- 页面ID: `sensitive_event_id`
- 事件ID: `sensitive_item_vip_btn_event`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 参与188活动 | action_188 | int | 自动添加: 0=未参与, 1=已参与 | - |
| 绑定次数 | bind_num | int | 自动添加 | - |

**实现说明**: 
- 当用户点击带有"VIP查看"标签的敏感操作记录item时触发
- 仅在非会员状态下（`record.needsVip` 为 true）时记录

**调用方法**:
```dart
AnalyticsHelper.trackSensitiveItemVipBtn();
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:409`

---

## 我的页面

### 我的页面浏览事件
**实现位置**: `lib/pages/mine/mine_controller.dart` - `onInit()` 和 `onClose()`

**事件信息**:
- 页面ID: `my_page_event_id`
- 事件ID: `my_page_event`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 进入页面时间 | page_enter_time | String | 格式: yyyy-MM-dd HH:mm:ss | "2024-01-08 00:00:00" |
| 页面停留时长 | page_duration | String | 格式: mm:ss | "05:30" |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 参与188活动 | action_188 | int | 自动添加: 0=未参与, 1=已参与 | - |
| 绑定次数 | bind_num | int | 自动添加 | - |
| 来源页 | source_page | String | 从路由参数获取 | - |
| 离开方式 | exit_type | int | 1=返回, 2=关闭App, 3=后台, 4=下一页 | 1 |

**实现说明**: 
- 在控制器的 `onInit` 中记录进入时间
- 在控制器的 `onClose` 中计算停留时长并上报

---

### 我的页面返回按钮点击事件
**实现位置**: `lib/pages/mine/mine_controller.dart` - `onBackTap()`

**事件信息**:
- 页面ID: `my_page_event_id`
- 事件ID: `my_page_back_event`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 参与188活动 | action_188 | int | 自动添加: 0=未参与, 1=已参与 | - |
| 绑定次数 | bind_num | int | 自动添加 | - |

**调用方法**:
```dart
AnalyticsHelper.trackMyPageBack();
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:419`

---

### 我的页面头像点击事件
**实现位置**: `lib/pages/mine/mine_controller.dart` - `onAvatarTap()`

**事件信息**:
- 页面ID: `my_page_event_id`
- 事件ID: `my_page_avatar_event`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 参与188活动 | action_188 | int | 自动添加: 0=未参与, 1=已参与 | - |
| 绑定次数 | bind_num | int | 自动添加 | - |

**调用方法**:
```dart
AnalyticsHelper.trackMyPageAvatar();
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:427`

---

### 我的页面会员模块点击事件
**实现位置**: `lib/pages/mine/mine_controller.dart` - `onRenewTap()`

**事件信息**:
- 页面ID: `my_page_event_id`
- 事件ID: `my_page_vip_module_event`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 参与188活动 | action_188 | int | 自动添加: 0=未参与, 1=已参与 | - |
| 绑定次数 | bind_num | int | 自动添加 | - |
| 按钮名称 | btn_name | int | 使用VipModuleBtnValue枚举值 | 1 |

**按钮名称枚举值** (`VipModuleBtnValue`):
- `1` (bindNow) - 立即绑定
- `2` (openVip) - 开通会员
- `3` (renewVip) - 去续费
- `4` (vipCenter) - 会员中心

**调用方法**:
```dart
AnalyticsHelper.trackMyPageVipBtn(btnName: VipModuleBtnValue.bindNow);   // 立即绑定
AnalyticsHelper.trackMyPageVipBtn(btnName: VipModuleBtnValue.openVip);   // 开通会员
AnalyticsHelper.trackMyPageVipBtn(btnName: VipModuleBtnValue.renewVip);  // 去续费
AnalyticsHelper.trackMyPageVipBtn(btnName: VipModuleBtnValue.vipCenter); // 会员中心
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:435`

---

### 我的页面权限模块点击事件
**实现位置**: `lib/pages/mine/mine_page.dart` - `onPermissionSettingTap()`

**事件信息**:
- 页面ID: `my_page_event_id`
- 事件ID: `my_page_permission_btn_event`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 参与188活动 | action_188 | int | 自动添加: 0=未参与, 1=已参与 | - |
| 绑定次数 | bind_num | int | 自动添加 | - |

**实现说明**: 
- 当用户点击会员卡片上的权限设置按钮时触发
- 跳转到系统权限设置页面

**调用方法**:
```dart
AnalyticsHelper.trackMyPagePermissionBtn();
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:446`

---

### 我的页面常用功能模块点击事件
**实现位置**: `lib/pages/mine/mine_controller.dart` - 各功能点击方法

**事件信息**:
- 页面ID: `my_page_event_id`
- 事件ID: `my_page_functions_moudle_event`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 参与188活动 | action_188 | int | 自动添加: 0=未参与, 1=已参与 | - |
| 按钮名称 | btn_name | String | 使用FunctionModuleValue枚举值 | "real_time_location" |
| 绑定次数 | bind_num | int | 自动添加 | - |

**功能模块枚举值** (`FunctionModuleValue`):
- `real_time_location` - 实时定位
- `app_usage_record` - app使用记录
- `phone_history` - 用机记录
- `track` - 足迹
- `hotel_anti_spy` - 酒店防偷拍
- `personalized_home` - 个性化首页
- `sensitive_record` - 敏感操作记录
- `change_app_icon` - 更换app图标

**调用方法**:
```dart
AnalyticsHelper.trackMyPageFunctionsModule(btnName: FunctionModuleValue.realTimeLocation);
AnalyticsHelper.trackMyPageFunctionsModule(btnName: FunctionModuleValue.track);
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:454`

---

### 我的页面分享APP按钮点击事件
**实现位置**: `lib/pages/mine/mine_controller.dart` - `_onShareAppTap()`

**事件信息**:
- 页面ID: `my_page_event_id`
- 事件ID: `my_page_share_btn_event`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 参与188活动 | action_188 | int | 自动添加: 0=未参与, 1=已参与 | - |
| 绑定次数 | bind_num | int | 自动添加 | - |

**调用方法**:
```dart
AnalyticsHelper.trackMyPageShareBtn();
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:476`

---

### 我的页面分享弹窗渠道点击事件
**实现位置**: `lib/widgets/share_bottom_sheet.dart` - 分享方法中

**事件信息**:
- 页面ID: `my_page_event_id`
- 事件ID: `my_page_share_channel_event`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 参与188活动 | action_188 | int | 自动添加: 0=未参与, 1=已参与 | - |
| 绑定次数 | bind_num | int | 自动添加 | - |
| 分享渠道名称 | share_channel_name | String | 使用ShareChannelValue枚举值 | "wechat" |
| 分享状态 | share_status | int | 使用ShareStatusValue枚举值 | 1 |

**分享渠道枚举值** (`ShareChannelValue`):
- `wechat` - 微信
- `qq` - QQ
- `copy_link` - 复制链接

**分享状态枚举值** (`ShareStatusValue`):
- `1` - 分享成功
- `0` - 分享失败
- `2` - 未分享
- `3` - 复制成功

**调用方法**:
```dart
AnalyticsHelper.trackMyPageShareChannel(
  channelName: ShareChannelValue.wechat,
  shareStatus: ShareStatusValue.notShared,
);
AnalyticsHelper.trackMyPageShareChannel(
  channelName: ShareChannelValue.qq,
  shareStatus: ShareStatusValue.success,
);
AnalyticsHelper.trackMyPageShareChannel(
  channelName: ShareChannelValue.copyLink,
  shareStatus: ShareStatusValue.copied,
);
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:492`

---

### 我的页面分享弹窗关闭事件
**实现位置**: `lib/widgets/share_bottom_sheet.dart` - 关闭按钮点击

**事件信息**:
- 页面ID: `my_page_event_id`
- 事件ID: `my_page_share_close_event`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 参与188活动 | action_188 | int | 自动添加: 0=未参与, 1=已参与 | - |
| 绑定次数 | bind_num | int | 自动添加 | - |

**调用方法**:
```dart
AnalyticsHelper.trackMyPageShareClose();
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:507`

---

## 更换app图标页面

### 更换app图标页面浏览事件
**实现位置**: `lib/pages/app_icon_selector/app_icon_selector_controller.dart` - `onInit()` 和 `onClose()`

**事件信息**:
- 页面ID: `my_page_event_id`
- 事件ID: `change_logo_page_event`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 进入页面时间 | page_enter_time | String | 格式: yyyy-MM-dd HH:mm:ss | "2024-01-08 00:00:00" |
| 页面停留时长 | page_duration | String | 格式: mm:ss | "05:30" |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 参与188活动 | action_188 | int | 自动添加: 0=未参与, 1=已参与 | - |
| 绑定次数 | bind_num | int | 自动添加 | - |
| 来源页 | source_page | String | 从路由参数获取 | - |
| 离开方式 | exit_type | int | 1=返回, 2=关闭App, 3=后台, 4=下一页 | 1 |

**实现说明**: 
- 在控制器的 `onInit` 中记录进入时间
- 在控制器的 `onClose` 中计算停留时长并上报

---

### 更换图标点击图标事件
**实现位置**: `lib/pages/app_icon_selector/app_icon_selector_controller.dart` - `changeIcon()`

**事件信息**:
- 页面ID: `my_page_event_id`
- 事件ID: `change_logo_item_btn_event`

**参数**:
| 参数名 | 字段名 | 类型 | 说明 | 示例值 |
|--------|--------|------|------|--------|
| 虚拟用户ID | mock_user_id | String | 自动添加 | - |
| 用户ID | user_id | String | 自动添加 | - |
| 点击时间 | click_time | String | 自动添加，格式: yyyy/MM/dd HH:mm:ss | - |
| 会员状态 | vip_status | int | 自动添加: 0=未充值, 1=会员中, 2=已到期 | - |
| 绑定状态 | bind_status | int | 自动添加: 0=未绑定, 1=已绑定, 2=已解绑 | - |
| 参与188活动 | action_188 | int | 自动添加: 0=未参与, 1=已参与 | - |
| 绑定次数 | bind_num | int | 自动添加 | - |
| App图标名称 | logo_name | String | 由左到右由上到下400011-400020 | "400011" |

**图标名称说明**:
- `400011` - 默认
- `400012` - 暖心
- `400013` - 手绘
- `400014` - 简约
- `400015` - 霓虹
- `400016` - 爱意灼灼
- `400017` - 叶柔甜伴
- `400018` - 甜邻少年
- `400019` - 糖绒甜崽
- `400020` - 甜煦少年

**实现说明**: 
- 在图标切换成功后记录埋点
- 每个图标都有对应的 `logoName` 用于埋点

**调用方法**:
```dart
AnalyticsHelper.trackChangeLogoItemBtn(logoName: '400011');
```

**Helper方法位置**: `lib/services/analytics/analytics_helper.dart:465`

---

## 枚举值说明

### ExitTypeValue (离开方式)
```dart
class ExitTypeValue {
  static const int back = 1;          // 返回
  static const int closeApp = 2;      // 关闭App
  static const int toBackground = 3;  // 切换到后台
  static const int nextPage = 4;      // 进入下一页
}
```

### GenderValue (性别)
```dart
class GenderValue {
  static const int defaultMale = 1;  // 默认男性(无操作)
  static const int male = 2;         // 男性
  static const int female = 3;       // 女性
}
```

### YesNoValue (是/否)
```dart
class YesNoValue {
  static const int no = 0;   // 否
  static const int yes = 1;  // 是
}
```

### SendStatusValue (发送状态)
```dart
class SendStatusValue {
  static const int failed = 0;   // 失败
  static const int success = 1;  // 成功
}
```

### LoginStatusValue (登录状态)
```dart
class LoginStatusValue {
  static const int failed = 0;   // 失败
  static const int success = 1;  // 成功
}
```

### BindStatusValue (绑定状态)
```dart
class BindStatusValue {
  static const int notBound = 0;  // 未绑定
  static const int bound = 1;     // 已绑定
  static const int unbound = 2;   // 已解绑
}
```

### VipStatusValue (会员状态)
```dart
class VipStatusValue {
  static const int notPaid = 0;  // 未充值会员
  static const int active = 1;   // 会员中
  static const int expired = 2;  // 会员已到期
}
```

---

## 更新日志

### 2024-01-07
- ✅ 创建埋点文档
- ✅ 记录登录页面所有埋点（页面浏览、获取验证码、登录按钮）
- ✅ 记录个人信息页面所有埋点（页面浏览、性别选择、生日选择、开启陪伴按钮）
- ✅ 实现绑定页面所有埋点（页面浏览、输入匹配码、确认按钮、关闭按钮、返回弹窗）
- ✅ 实现首页所有埋点（底部导航栏点击、右上角头像点击、会员福利按钮、一起便便按钮）
- ✅ 实现首页弹窗埋点（充值弹窗、续费弹窗）
- ✅ 实现定位页面所有埋点（页面浏览、返回按钮、我的心情、Ta的足迹、位置提醒、去绑定/开通会员）
- ✅ 实现轨迹页面所有埋点（页面浏览、头像切换、返回按钮、轨迹回放、去绑定/开通会员）
- ✅ 实现聊天页面所有埋点（页面浏览含发送消息计数、返回按钮、设置按钮）
- ✅ 实现聊天背景页面埋点（确认按钮，含背景ID映射）
- ✅ 实现聊天气泡页面埋点（确认按钮，含气泡ID映射）
- ✅ 实现聊天主题页面埋点（确认按钮，含主题ID映射）
- ✅ 实现用机记录页面所有埋点（页面浏览、权限引导按钮、返回按钮、设置按钮）
- ✅ 实现用机记录页面三个模块点击埋点（手机使用、App使用、敏感操作，不管是否会员都记录）
- ✅ 实现手机使用统计页面埋点（页面浏览）
- ✅ 实现App使用统计页面埋点（页面浏览）
- ✅ 实现敏感操作记录页面埋点（页面浏览已有实现，新增item上vip按钮点击）
- ✅ 实现我的页面所有埋点（页面浏览、返回按钮、头像点击、会员模块、权限模块）
- ✅ 实现我的页面常用功能模块埋点（8个功能模块点击）
- ✅ 实现我的页面分享功能埋点（分享APP按钮、分享弹窗渠道点击、分享弹窗关闭）
- ✅ 实现更换app图标页面埋点（页面浏览、图标点击，包含10个图标的logoName）
- ✅ 实现会员中心页面埋点（页面浏览含滑动次数、套餐点击、挽留弹窗、19元弹窗）
- ✅ 优化埋点工具类型系统，统一使用 int/bool/string（英文）

---

## 使用说明

### 如何添加新埋点

1. 在对应页面实现埋点代码
2. 在本文档中添加埋点记录
3. 更新状态为 ✅ 已实现
4. 记录实现位置和调用示例

### 文档维护规范

- 每次新增埋点必须更新本文档
- 记录准确的文件路径和方法位置
- 提供完整的参数说明和示例
- 更新日志记录变更时间
