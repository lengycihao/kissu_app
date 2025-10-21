package com.yuluo.kissu

import android.app.KeyguardManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.EventChannel

/**
 * 手机锁屏/解锁状态监听器 (增强版)
 * 
 * 监听系统锁屏和解锁事件，并通过EventChannel通知Flutter层
 * 
 * 实现原理：
 * 1. 通过BroadcastReceiver监听 ACTION_SCREEN_OFF, ACTION_SCREEN_ON 和 ACTION_USER_PRESENT 广播
 * 2. ACTION_SCREEN_OFF: 屏幕关闭（锁屏）- 立即发送锁屏事件
 * 3. ACTION_SCREEN_ON: 屏幕亮起 - 延迟检查是否已解锁（兼容指纹/面部识别）
 * 4. ACTION_USER_PRESENT: 用户解锁设备 - 传统解锁方式（密码/图案）
 * 5. 通过KeyguardManager判断锁屏状态，提高准确性
 * 
 * 使用场景：
 * - 用户锁屏/解锁手机
 * - 需要实时上报锁屏/解锁事件
 * - 兼容面部识别、指纹解锁等快速解锁方式
 * 
 * @author AI Assistant
 * @date 2025-10-17 (增强版)
 */
class ScreenLockReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "ScreenLockReceiver"
        
        // EventChannel相关
        private const val CHANNEL_NAME = "com.yuluo.kissu/screen_lock_events"
        
        // 静态变量保存EventSink
        private var eventSink: EventChannel.EventSink? = null
        
        // 初始延迟检查解锁状态的时间（毫秒）
        private const val UNLOCK_CHECK_DELAY = 500L
        // 连续检查间隔与总时长，用于兼容部分设备（指纹/面容识别较慢）
        private const val UNLOCK_CHECK_INTERVAL = 300L
        private const val UNLOCK_CHECK_TOTAL_DURATION = 5000L
        
        // Handler用于延迟检查
        private val handler = Handler(Looper.getMainLooper())
        
        // 上次事件类型，避免重复发送
        private var lastEventType: String? = null
        
        /**
         * 设置EventSink
         */
        fun setEventSink(sink: EventChannel.EventSink?) {
            eventSink = sink
            if (sink == null) {
                // 清理状态
                lastEventType = null
                handler.removeCallbacksAndMessages(null)
            }
        }
        
        /**
         * 发送锁屏/解锁事件到Flutter
         * @param isUnlocked true表示解锁，false表示锁屏
         * @param force 是否强制发送（忽略重复检查）
         */
        private fun sendScreenEvent(isUnlocked: Boolean, force: Boolean = false) {
            try {
                val eventType = if (isUnlocked) "unlock" else "lock"
                
                // 避免重复发送相同事件（除非强制发送）
                if (!force && lastEventType == eventType) {
                    Log.d(TAG, "⚠️ 跳过重复事件: $eventType")
                    return
                }
                
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
                    // 确保在主线程发送
                    handler.post {
                        try {
                            eventSink!!.success(eventData)
                            lastEventType = eventType
                            Log.d(TAG, "✅ 屏幕事件已发送: ${if (isUnlocked) "解锁" else "锁屏"}")
                        } catch (e: Exception) {
                            Log.e(TAG, "❌ 发送事件时异常: ${e.message}", e)
                        }
                    }
                } else {
                    Log.w(TAG, "❌ EventSink为null，无法发送事件")
                }
            } catch (e: Exception) {
                Log.e(TAG, "❌ 发送屏幕事件失败: ${e.message}", e)
            }
        }
        
        /**
         * 检查设备是否已解锁
         */
        private fun isDeviceUnlocked(context: Context): Boolean {
            val keyguardManager = context.getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
            return keyguardManager?.isKeyguardLocked == false
        }

        /**
         * 在一段时间窗口内重复检查是否已解锁，首个检测到解锁即上报
         */
        private fun repeatCheckUntilUnlocked(context: Context) {
            val startAt = System.currentTimeMillis()
            handler.removeCallbacksAndMessages(null)

            fun loop() {
                try {
                    if (isDeviceUnlocked(context)) {
                        Log.d(TAG, "🔓 连续检查：检测到设备已解锁 (KeyguardManager)")
                        sendScreenEvent(true)
                        return
                    }
                    val elapsed = System.currentTimeMillis() - startAt
                    if (elapsed < UNLOCK_CHECK_TOTAL_DURATION) {
                        handler.postDelayed({ loop() }, UNLOCK_CHECK_INTERVAL)
                    } else {
                        Log.d(TAG, "⌛ 连续检查结束：仍处于锁屏状态 (elapsed=${elapsed}ms)")
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "❌ 连续检查解锁状态失败: ${e.message}", e)
                }
            }

            // 先做一次初始延迟再进入循环，兼容极快亮屏后立即解锁的设备
            handler.postDelayed({ loop() }, UNLOCK_CHECK_DELAY)
        }
    }
    
    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) return
        
        try {
            when (intent.action) {
                Intent.ACTION_SCREEN_OFF -> {
                    // 屏幕关闭（锁屏）- 立即发送锁屏事件
                    Log.d(TAG, "🔒 检测到屏幕关闭事件 (ACTION_SCREEN_OFF)")
                    handler.removeCallbacksAndMessages(null) // 取消之前的延迟检查
                    sendScreenEvent(false, force = true)
                }
                
                Intent.ACTION_SCREEN_ON -> {
                    // 屏幕亮起 - 连续检查是否已解锁，兼容指纹/面部识别较慢或未触发USER_PRESENT的设备
                    Log.d(TAG, "💡 检测到屏幕亮起事件 (ACTION_SCREEN_ON)")
                    handler.removeCallbacksAndMessages(null)
                    repeatCheckUntilUnlocked(context)
                }
                
                Intent.ACTION_USER_PRESENT, Intent.ACTION_USER_UNLOCKED -> {
                    // 用户解锁设备（传统方式：密码/图案）
                    // 立即发送解锁事件
                    Log.d(TAG, "🔓 检测到用户解锁事件 (${intent.action})")
                    handler.removeCallbacksAndMessages(null) // 取消延迟检查
                    sendScreenEvent(true)
                }
                
                else -> {
                    Log.w(TAG, "⚠️ 收到未知的Intent Action: ${intent.action}")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ 处理屏幕事件时发生异常: ${e.message}", e)
        }
    }
}
