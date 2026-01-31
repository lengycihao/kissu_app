package com.yuluo.kissu

import android.app.KeyguardManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.EventChannel
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import org.json.JSONObject

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
        private const val NATIVE_LOG_TAG = "NativeScreenLock"
        
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

        // 设备锁屏状态跟踪
        private var lastKeyguardLocked: Boolean? = null
        
        /**
         * 设置EventSink
         */
        fun setEventSink(sink: EventChannel.EventSink?) {
            eventSink = sink
            if (sink == null) {
                // 清理状态
                lastEventType = null
                lastKeyguardLocked = null
                handler.removeCallbacksAndMessages(null)
            } else {
                // 初始化时获取当前锁屏状态
                // 注意：这里无法直接获取context，所以在onReceive中初始化
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
         * 优化后的检查策略：更快的检查间隔，更智能的超时处理
         */
        private fun repeatCheckUntilUnlocked(context: Context) {
            val startAt = System.currentTimeMillis()
            var checkCount = 0
            handler.removeCallbacksAndMessages(null)

            fun loop() {
                try {
                    checkCount++
                    // 🔥 修复逻辑错误：isDeviceUnlocked 返回 true 表示已解锁，变量名改为 isUnlocked
                    val isUnlocked = isDeviceUnlocked(context)
                    val elapsed = System.currentTimeMillis() - startAt

                    Log.d(TAG, "🔄 连续检查 #$checkCount: isUnlocked=$isUnlocked, elapsed=${elapsed}ms")

                    if (isUnlocked) {
                        Log.d(TAG, "🔓 连续检查 #$checkCount：检测到设备已解锁 (KeyguardManager)")
                        lastKeyguardLocked = false
                        sendScreenEvent(true)
                        return
                    }

                    // 动态调整检查间隔：前1秒更频繁检查，后续放缓
                    val nextInterval = if (elapsed < 1000L) 100L else if (elapsed < 2000L) 200L else UNLOCK_CHECK_INTERVAL

                    if (elapsed < UNLOCK_CHECK_TOTAL_DURATION) {
                        handler.postDelayed({ loop() }, nextInterval)
                    } else {
                        Log.d(TAG, "⌛ 连续检查结束：${checkCount}次检查后仍处于锁屏状态 (elapsed=${elapsed}ms)")
                        // 超时后更新状态，但不发送解锁事件
                        lastKeyguardLocked = true
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "❌ 连续检查解锁状态失败: ${e.message}", e)
                }
            }

            // 立即开始第一次检查，而不是延迟
            Log.d(TAG, "🚀 开始连续检查解锁状态...")
            handler.post { loop() }
        }
    }
    
    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) return

        try {
            // 初始化锁屏状态跟踪（只在第一次调用时）
            if (lastKeyguardLocked == null) {
                val keyguardManager = context.getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
                lastKeyguardLocked = keyguardManager?.isKeyguardLocked ?: true
                Log.d(TAG, "🔄 初始化锁屏状态跟踪: lastKeyguardLocked=$lastKeyguardLocked")
            }

            when (intent.action) {
                Intent.ACTION_SCREEN_OFF -> {
                    // 屏幕关闭（锁屏）- 立即发送锁屏事件
                    Log.d(TAG, "🔒 检测到屏幕关闭事件 (ACTION_SCREEN_OFF)")
                    handler.removeCallbacksAndMessages(null) // 取消之前的延迟检查

                    // 更新状态跟踪
                    lastKeyguardLocked = true

                    sendScreenEvent(false, force = true)
                }

                Intent.ACTION_SCREEN_ON -> {
                    // 屏幕亮起 - 立即进行快速检查，然后连续检查是否已解锁
                    Log.d(TAG, "💡 检测到屏幕亮起事件 (ACTION_SCREEN_ON)")

                    // 立即进行一次快速检查（兼容极快解锁）
                    val keyguardManager = context.getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
                    val currentLocked = keyguardManager?.isKeyguardLocked ?: true
                    val wasLocked = lastKeyguardLocked ?: true

                    Log.d(TAG, "🔍 快速检查: wasLocked=$wasLocked, currentLocked=$currentLocked")

                    // 如果之前是锁屏状态，现在检测到解锁，说明在屏幕亮起的瞬间已经解锁
                    if (wasLocked && !currentLocked) {
                        Log.d(TAG, "⚡ 检测到瞬间解锁 (快速解锁方式如指纹/面部识别)")
                        lastKeyguardLocked = false
                        handler.removeCallbacksAndMessages(null)
                        sendScreenEvent(true)
                        return
                    }

                    // 如果仍然处于锁屏状态，开始连续检查
                    if (currentLocked) {
                        lastKeyguardLocked = true
                        handler.removeCallbacksAndMessages(null)
                        repeatCheckUntilUnlocked(context)
                    } else {
                        // 设备已经解锁，可能是从其他途径解锁的
                        Log.d(TAG, "ℹ️ 屏幕亮起时设备已处于解锁状态")
                        lastKeyguardLocked = false
                        // 这里不发送事件，避免重复
                    }
                }

                Intent.ACTION_USER_PRESENT, Intent.ACTION_USER_UNLOCKED -> {
                    // 用户解锁设备（传统方式：密码/图案）
                    // 立即发送解锁事件
                    Log.d(TAG, "🔓 检测到用户解锁事件 (${intent.action})")

                    // 更新状态跟踪
                    lastKeyguardLocked = false

                    handler.removeCallbacksAndMessages(null) // 取消延迟检查
                    sendScreenEvent(true)
                }

                else -> {
                    logWarning(context, "⚠️ 收到未知的Intent Action: ${intent.action}")
                }
            }
        } catch (e: Exception) {
            logError(context, "❌ 处理屏幕事件时发生异常", mapOf("error" to (e.message ?: "unknown")))
        }
    }
    
    // ================================
    // 🔥 原生层文件日志功能
    // ================================
    
    private fun writeNativeLog(
        context: Context,
        level: String,
        message: String,
        extra: Map<String, Any?>? = null
    ) {
        try {
            // 使用与 Flutter 层相同的日志目录：filesDir/logs（对应 getApplicationSupportDirectory()/logs）
            val logDir = File(context.filesDir, "logs")
            if (!logDir.exists()) {
                logDir.mkdirs()
            }
            
            val dateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH-mm-ss.SSSSSS", Locale.US)
            val now = Date()
            val fileName = "${dateFormat.format(now)}_app.log"
            val logFile = File(logDir, fileName)
            
            val isoFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSSSS", Locale.US)
            val timestamp = isoFormat.format(now)
            
            val logEntry = JSONObject().apply {
                put("timestamp", timestamp)
                put("level", level)
                put("tag", NATIVE_LOG_TAG)
                put("message", message)
                extra?.let {
                    val extraJson = JSONObject()
                    it.forEach { (key, value) ->
                        extraJson.put(key, value ?: JSONObject.NULL)
                    }
                    put("extra", extraJson)
                }
            }
            
            logFile.appendText(logEntry.toString() + "\n")
        } catch (e: Exception) {
            Log.e(TAG, "写入原生日志失败", e)
        }
    }
    
    private fun logInfo(context: Context, message: String, extra: Map<String, Any?>? = null) {
        Log.d(TAG, message)
        writeNativeLog(context, "INFO", message, extra)
    }
    
    private fun logWarning(context: Context, message: String, extra: Map<String, Any?>? = null) {
        Log.w(TAG, message)
        writeNativeLog(context, "WARNING", message, extra)
    }
    
    private fun logError(context: Context, message: String, extra: Map<String, Any?>? = null) {
        Log.e(TAG, message)
        writeNativeLog(context, "ERROR", message, extra)
    }
}
