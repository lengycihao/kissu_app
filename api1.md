删除消息分为两种：删除本地消息和删除云端消息。
删除云端消息会在删除本地消息的基础上，同步删除云端存储的消息，且无法恢复。
如果删除的是最后一条消息，会话的 lastMessage 会变为前一条消息。
删除本地消息
您可以调用 deleteMessageFromLocalStorage (点击查看详情) 删除本地消息。
说明：
该接口只能删除本地历史，消息删除后，SDK 会在本地把这条消息标记为已删除状态，调用 getHistoryMessage 不能再拉取到。
如果程序卸载重装，本地会失去对这条消息的删除标记，调用 getHistoryMessage 还能再拉取到该条消息。
示例代码如下：
TencentImSDKPlugin.v2TIMManager.getMessageManager().deleteMessageFromLocalStorage(msgID: "");
删除云端存储的消息
您可以调用 deleteMessages (点击查看详情) 删除云端存储的消息。
该接口会在删除本地消息的基础上，同步删除云端存储的消息，且无法恢复。
说明：
每次调用，最多只能删除 30 条消息。
每次调用，待删除的消息必须属于同一会话。
1 秒钟最多只能调用 1 次该接口。
如果一个账号在某设备上拉取过这些消息，那么调用该接口删除云端消息后，这些消息仍然会保存在该设备上，即删除消息不支持多端同步。
示例代码如下：
TencentImSDKPlugin.v2TIMManager.getMessageManager().deleteMessages(msgIDs: ['messageid']);

---------------------------------
撤回消息
功能描述
撤回消息方法在核心类 TencentImSDKPlugin.v2TIMManager.getMessageManager()  中。
通过 addAdvancedMsgListener 监听消息撤回通知。
撤回消息
发送方可以撤回一条已经发送成功的消息。
默认情况下，发送者只能撤回2分钟以内的消息，您可以按需更改消息撤回时间限制，具体操作请参见 消息撤回设置。
消息的撤回同时需要接收方 UI 代码的配合：当发送方撤回一条消息后，接收方会收到消息撤回通知 onRecvMessageRevoked。通知中包含了撤回消息的 msgID，您可以根据这个 msgID 判断 UI 层是哪一条消息撤回了，然后把对应的消息气泡切换成 "消息已被撤回" 状态。
发送方撤回一条消息
调用 revokeMessage (点击查看详情) 撤回一条消息。
示例代码如下：
 V2TimCallback revokeMessage = await  TencentImSDKPlugin.v2TIMManager.getMessageManager().revokeMessage(msgID: "");
接收方感知消息被撤回
调用 addAdvancedMsgListener (点击查看详情) 设置高级消息监听。
通过 onRecvMessageRevoked (点击查看详情) 接收消息撤回通知。
示例代码如下：
onRecvMessageRevoked: (String messageid) {
      // 在本地维护的消息中处理被对方撤回的消息
},
----------------
在线消息

功能描述
某些场景下，您可能希望发出去的消息只被在线用户接收，即当接收者不在线时就不会感知到该消息。您只需在 sendMessage 时，将参数 onlineUserOnly 设置为 true，此时发送出去的消息跟普通消息相比，会有如下差异点：
不支持离线存储，即如果接收方不在线就无法收到。
不支持多端漫游，即如果接收方在一台终端设备上一旦接收过该消息，无论是否已读，都不会在另一台终端上再次收到。
不支持本地存储，即本地的、云端的历史消息中均无法找回。
经典示例
实现“对方正在输入”功能
在 C2C 单聊场景下，您可以通过 sendMessage (点击查看详情) 接口发送 "自己正在输入" 的提示性消息，接收方收到该消息时可以在 UI 界面展示 "对方正在输入"，
示例代码如下：
V2TimValueCallback<V2TimMsgCreateInfoResult> createCustomMessageRes =
      await TencentImSDKPlugin.v2TIMManager
          .getMessageManager()
          .createCustomMessage(
            data: '正在输入中',
          );
  TencentImSDKPlugin.v2TIMManager.getMessageManager().sendMessage(id: createCustomMessageRes.data.id, rece