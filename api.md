搭建开发环境
在你需要使用企业微信终端API的文件中导入相应的类。
import com.tencent.wework.api.model.WWMediaText;
在代码中使用开发工具包
注册到企业微信
要使你的程序启动后企业微信终端能响应你的程序，必须在代码中向企业微信终端注册你的id。可以在程序入口Activity的onCreate回调函数处，或其他合适的地方将你的应用schema注册到企业微信。
	private static final String APPID = "WW1e933be11645237c";
	private static final String AGENTID = "1000012";
	private static final String SCHEMA = "wwauth1e933be11645237c000012";

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_main);
		stringId = getApplicationInfo().labelRes;
		iwwapi = WWAPIFactory.createWWAPI(this);
		iwwapi.registerApp(SCHEMA);
		}
发送请求和接收返回值
现在，你的程序要发送请求到企业微信终端，可以通过IWWAPI的sendMessage方法来实现。
boolean sendMessage(BaseMessage msg);
sendMessage是第三方app主动发送消息给企业微信，发送完成之后会切回到第三方app界面。
boolean sendMessage(BaseMessage req, IWWAPIEventHandler callback)
带回调的sendMessage是第三方app向企业微信请求数据，企业微信回应数据之后会切回到第三方app界面。
sendMessage的实现示例，如下所示：
WWMediaText txt = new WWMediaText(((EditText) findViewById(R.id.et3)).getText().toString());
txt.appPkg = getPackageName();
txt.appName = getString(stringId);
txt.appId = APPID;
txt.agentId = AGENTID;
iwwapi.sendMessage(txt);

带回调的sendMessage的实现，如下所示：
final WWAuthMessage.Req req = new WWAuthMessage.Req();
req.sch = SCHEMA;
req.appId = APPID;
req.agentId = AGENTID;
req.state = "dd";
iwwapi.sendMessage(req, new IWWAPIEventHandler() {
	@Override
	public void handleResp(BaseMessage resp) {
		if (resp instanceof WWAuthMessage.Resp) {
			WWAuthMessage.Resp rsp = (WWAuthMessage.Resp) resp;
			if (rsp.errCode == WWAuthMessage.ERR_CANCEL) {
			Toast.makeText(MainActivity.this, "登录取消", Toast.LENGTH_SHORT).show();
			}else if (rsp.errCode == WWAuthMessage.ERR_FAIL) {
			Toast.makeText(MainActivity.this, "登录失败", Toast.LENGTH_SHORT).show();
			} else if (rsp.errCode == WWAuthMessage.ERR_OK) {
			Toast.makeText(MainActivity.this, "登录成功：" + rsp.code,
			Toast.LENGTH_SHORT).show();
			}
		}
	}
});

具体要发送的内容由第三方app开发者定义，具体可参考微信开发工具包中的SDK apitest源码。
注意
如果需要混淆代码，为了保证sdk的正常使用，需要在proguard.cfg加上下面两行配置：
-keep class com.tencent.wework.api.** {
   *;
}

至此，你已经能使用企业微信Android开发工具包的API内容了。如果想更详细了解每个API函数的用法，请查阅 Android 平台参考手册 或自行下载阅读企业微信apitest源码。
 

授权登录接入
开发者需要配合使用企业微信提供的SDK进行授权登录请求接入。正确接入SDK后开发者移动应用会在终端本地拉起企业微信应用进行授权登录，企业微信用户确认后企业微信将回调授权临时票据（code），同时返回开发者移动应用。
Android平台应用授权登录接入代码示例（请参考Android接入指南）：

final WWAuthMessage.Req req = new WWAuthMessage.Req();
req.sch = SCHEMA;
req.appId = APPID;
req.agentId = AGENTID;
req.state = "dd";
iwwapi.sendMessage(req, new IWWAPIEventHandler() {
	@Override
	public void handleResp(BaseMessage resp) {
		if (resp instanceof WWAuthMessage.Resp) {
			WWAuthMessage.Resp rsp = (WWAuthMessage.Resp) resp;
			if (rsp.errCode == WWAuthMessage.ERR_CANCEL) {
			Toast.makeText(MainActivity.this, "登录取消", Toast.LENGTH_SHORT).show();
			}else if (rsp.errCode == WWAuthMessage.ERR_FAIL) {
			Toast.makeText(MainActivity.this, "登录失败", Toast.LENGTH_SHORT).show();
			} else if (rsp.errCode == WWAuthMessage.ERR_OK) {
			Toast.makeText(MainActivity.this, "登录成功：" + rsp.code,
			Toast.LENGTH_SHORT).show();
			}
		}
	}
});
参数说明

参数	是否必须	说明
appid	是	企业唯一标识。创建企业后显示在，我的企业 CorpID字段
agentid	是	应用唯一标识。显示在具体应用下的 AgentId字段
sch	是	应用跳转标识，显示在具体应用下的 Schema字段
state	否	用于保持请求和回调的状态，授权请求后原样带回给第三方。该参数可用于防止csrf攻击（跨站请求伪造攻击），建议第三方带上该参数，可设置为简单的随机数加session进行校验
参数示例：
appid: WW1e933be11645237c
agentid: 1000012
sch：wwauth1e933be11645237c000012
state: wwapitest
可拉起企业微信打开授权登录页：
返回说明
用户点击授权后，企业微信客户端会被拉起，跳转至授权界面，用户在该界面点击允许或取消，SDK通过回调返回数据给调用方。
返回值
说明

errCode
ERR_OK = 0(用户同意)
ERR_FAIL = 1（授权失败）
ERR_CANCEL = -1（用户取消）
code
用户换取access_token的code，仅在ErrCode为0时有效
state
第三方程序发送时用来标识其请求的唯一性的标志，由第三方程序调用sendMessage时传入，由企业微信终端回传，state字符串长度不能超过1K

通过code获取用户信息
请求方式：GET（HTTPS）
请求地址：https://qyapi.weixin.qq.com/cgi-bin/user/getuserinfo?access_token=ACCESS_TOKEN&code=CODE

参数说明：

参数	必须	说明
access_token	是	调用接口凭证
code	是	通过成员授权获取到的code，每次成员授权带上的code将不一样，code只能使用一次，5分钟未被使用自动过期
 

权限说明：
跳转的域名须完全匹配企业内任一应用的可信域名。

返回结果：

{
   "UserId":"USERID"
}
参数	说明
UserId	成员UserID
出错返回示例：

{
   "errcode": 40029,
   "errmsg": "invalid code"
}
Android 11 系统策略更新，请开发者及时适配
Android 11 版本为加强用户隐私保护引入较多变更，第三方应用需要适配有变更：
软件包可见性变更，会导致第三方应用通过 sdk 接口拉起企业微信受限，从而影响分享消息到企业微信、登陆等功能的正常使用（该变更只对升级targetSdkVersion=30 的应用产生影响）
软件可见性适配方案
1、根据 Android 官方给出的适配方案，在主工程的AndroidManifest.xml 中增加 标签，即可解决以上影响，示例代码如下：

<manifest package="com.example.app">
      ...
      // 在应用的AndroidManifest.xml添加如下<queries>标签
    <queries>
        <package android:name="com.tencent.wework" />   // 指定企业微信包名
    </queries>
      ...
</manifest>