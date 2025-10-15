package com.yuluo.kissu

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import io.flutter.plugin.common.EventChannel

/**
 * 手机锁屏/解锁状态监听器
 * 
 * 监听系统锁屏和解锁事件，并通过EventChannel通知Flutter层
 * 
 * 实现原理：
 * 1. 通过BroadcastReceiver监听 ACTION_SCREEN_OFF 和 ACTION_USER_PRESENT 广播
 * 2. ACTION_SCREEN_OFF: 屏幕关闭（锁屏）
 * 3. ACTION_USER_PRESENT: 用户解锁设备
 * 4. 通过EventChannel实时推送状态变化到Flutter
 * 
 * 使用场景：
 * - 用户锁屏/解锁手机
 * - 需要实时上报锁屏/解锁事件
 * 
 * @author AI Assistant
 * @date 2025-10-15
 */
class ScreenLockReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "ScreenLockReceiver"
        
        // EventChannel相关
        private const val CHANNEL_NAME = "com.yuluo.kissu/screen_lock_events"
        
        // 静态变量保存EventSink
        private var eventSink: EventChannel.EventSink? = null
        
        /**
         * 设置EventSink
         */
        fun setEventSink(sink: EventChannel.EventSink?) {
            eventSink = sink
        }
        
        /**
         * 发送锁屏/解锁事件到Flutter
         */
        private fun sendScreenEvent(isUnlocked: Boolean) {
            try {
                val eventType = if (isUnlocked) "unlock" else "lock"
                val timestamp = System.currentTimeMillis()
                
                val eventData = mapOf(
                    "event_type" to eventType,
                    "timestamp" to timestamp
                )
                
                Log.d(TAG, "🔍 准备发送事件数据:")
                Log.d(TAG, "🔍 event_type: $eventType (${eventType::class.java.simpleName})")
                Log.d(TAG, "🔍 timestamp: $timestamp (${timestamp::class.java.simpleName})")
                Log.d(TAG, "🔍 完整数据: $eventData")
                Log.d(TAG, "🔍 EventSink状态: ${if (eventSink != null) "可用" else "null"}")
                
                if (eventSink != null) {
                    eventSink!!.success(eventData)
                    Log.d(TAG, "✅ 屏幕事件已发送: ${if (isUnlocked) "解锁" else "锁屏"}")
                } else {
                    Log.w(TAG, "❌ EventSink为null，无法发送事件")
                }
            } catch (e: Exception) {
                Log.e(TAG, "❌ 发送屏幕事件失败: ${e.message}", e)
            }
        }
    }
    
    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) return
        
        try {
            when (intent.action) {
                Intent.ACTION_SCREEN_OFF -> {
                    // 屏幕关闭（锁屏）
                    Log.d(TAG, "检测到屏幕关闭事件")
                    sendScreenEvent(false)
                }
                
                Intent.ACTION_USER_PRESENT -> {
                    // 用户解锁设备
                    Log.d(TAG, "检测到用户解锁事件")
                    sendScreenEvent(true)
                }
                
                else -> {
                    Log.w(TAG, "收到未知的Intent Action: ${intent.action}")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "处理屏幕事件时发生异常: ${e.message}", e)
        }
    }
}
