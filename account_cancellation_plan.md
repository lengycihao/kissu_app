# 注销账户功能实现计划

## 概述
实现注销账户功能，包含两个页面：
1. 注销账户页面 - 显示用户信息和注销须知
2. 手机号验证页面 - 验证用户身份后执行注销

## 页面设计

### 1. 注销账户页面 (account_cancellation_page.dart)

#### UI结构
- 背景色：#FFF5F0 (浅粉色)
- 顶部导航栏：返回按钮 + "注销账户" 标题
- 用户信息卡片：
  - 背景图：kissu_accout_info_bg.webp
  - 头像：kissu_accout_header_bg.webp (占位图)
  - 昵称：悠悠白茶
- 注销须知文本
- 注销按钮（灰色背景）

#### 功能逻辑
- 点击返回按钮返回上一页
- 点击注销按钮跳转到手机号验证页面

### 2. 手机号验证页面 (phone_verification_page.dart)

#### UI结构
- 背景色：#FFF5F0 (浅粉色)
- 顶部导航栏：返回按钮 + "注销账户" 标题
- "手机号验证" 标题
- 输入框组：
  - 左侧：输入手机号/验证码
  - 右侧：获取验证码按钮（粉色）
- 注销按钮（灰色背景）

#### 功能逻辑
- 手机号输入验证（11位数字）
- 获取验证码倒计时功能（60秒）
- 验证码输入验证（6位数字）
- 注销确认对话框
- 注销成功后返回登录页

## 控制器设计

### 1. AccountCancellationController
- 属性：
  - userAvatar: 用户头像
  - userName: 用户昵称
- 方法：
  - navigateToPhoneVerification(): 跳转到手机号验证页

### 2. PhoneVerificationController
- 属性：
  - phoneNumber: 手机号
  - verificationCode: 验证码
  - isCodeSent: 是否已发送验证码
  - countdown: 倒计时秒数
  - canResend: 是否可重新发送
- 方法：
  - validatePhoneNumber(): 验证手机号格式
  - sendVerificationCode(): 发送验证码
  - startCountdown(): 开始倒计时
  - validateCode(): 验证验证码
  - confirmCancellation(): 确认注销
  - showCancellationDialog(): 显示注销确认对话框

## 实现步骤

1. 创建页面文件和控制器文件
2. 实现注销账户页面UI
3. 实现手机号验证页面UI
4. 实现控制器逻辑
5. 添加页面路由
6. 测试功能流程

## 注意事项

- 使用GetX进行状态管理
- 遵循项目现有的代码风格
- 确保输入验证的准确性
- 添加适当的用户提示和错误处理
- 注销操作需要二次确认