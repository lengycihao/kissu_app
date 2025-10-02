package com.yuluo.kissu

import android.content.Context
import android.database.ContentObserver
import android.database.Cursor
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.util.Log
import java.util.*

/**
 * 截屏监听器
 * 通过监听媒体库的变化来检测截屏行为
 */
class ScreenshotObserver(
    private val context: Context,
    private val onScreenshotCaptured: (String) -> Unit
) : ContentObserver(Handler(Looper.getMainLooper())) {

    companion object {
        private const val TAG = "ScreenshotObserver"
        
        // 截图关键字
        private val SCREENSHOT_KEYWORDS = arrayOf(
            "screenshot", "screen_shot", "screen-shot", "screen shot",
            "screencapture", "screen_capture", "screen-capture", "screen capture",
            "截屏", "截图"
        )
        
        // 检测时间窗口（10秒内的图片才认为是截屏）
        private const val DETECT_WINDOW_SECONDS = 10
    }

    // 外部存储媒体URI
    private val externalContentUri: Uri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI

    // 最后一次截图的路径，用于去重
    private var lastScreenshotPath: String? = null
    private var lastScreenshotTime: Long = 0

    /**
     * 开始监听
     */
    fun startObserving() {
        try {
            context.contentResolver.registerContentObserver(
                externalContentUri,
                true,
                this
            )
            Log.d(TAG, "截屏监听已启动")
        } catch (e: Exception) {
            Log.e(TAG, "启动截屏监听失败: ${e.message}", e)
        }
    }

    /**
     * 停止监听
     */
    fun stopObserving() {
        try {
            context.contentResolver.unregisterContentObserver(this)
            Log.d(TAG, "截屏监听已停止")
        } catch (e: Exception) {
            Log.e(TAG, "停止截屏监听失败: ${e.message}", e)
        }
    }

    override fun onChange(selfChange: Boolean, uri: Uri?) {
        super.onChange(selfChange, uri)
        
        if (uri == null) return
        
        Log.d(TAG, "媒体库发生变化: $uri")
        
        // 检查是否是截屏
        handleMediaChange(uri)
    }

    /**
     * 处理媒体库变化
     */
    private fun handleMediaChange(uri: Uri) {
        var cursor: Cursor? = null
        try {
            // 【关键修改】无论是否有权限，都先通知Flutter层（让Flutter层请求权限）
            // 通过检查URI路径来判断是否可能是截图
            val uriPath = uri.toString()
            Log.d(TAG, "URI路径: $uriPath")
            
            // 先尝试查询，如果失败可能是权限问题
            cursor = context.contentResolver.query(
                uri,
                arrayOf(
                    MediaStore.Images.Media.DISPLAY_NAME,
                    MediaStore.Images.Media.DATA,
                    MediaStore.Images.Media.DATE_ADDED
                ),
                null,
                null,
                "${MediaStore.Images.Media.DATE_ADDED} DESC"
            )

            if (cursor != null && cursor.moveToFirst()) {
                val displayNameIndex = cursor.getColumnIndex(MediaStore.Images.Media.DISPLAY_NAME)
                val dataIndex = cursor.getColumnIndex(MediaStore.Images.Media.DATA)
                val dateAddedIndex = cursor.getColumnIndex(MediaStore.Images.Media.DATE_ADDED)

                if (displayNameIndex >= 0 && dataIndex >= 0 && dateAddedIndex >= 0) {
                    val displayName = cursor.getString(displayNameIndex) ?: ""
                    val data = cursor.getString(dataIndex) ?: ""
                    val dateAdded = cursor.getLong(dateAddedIndex)

                    Log.d(TAG, "检测到新图片: displayName=$displayName, path=$data")

                    // 检查是否是截屏
                    if (isScreenshot(displayName, data, dateAdded)) {
                        // 去重检查
                        val currentTime = System.currentTimeMillis()
                        if (data != lastScreenshotPath || 
                            currentTime - lastScreenshotTime > 1000) {
                            
                            Log.d(TAG, "✅ 检测到截屏: $data")
                            lastScreenshotPath = data
                            lastScreenshotTime = currentTime
                            
                            // 回调通知Flutter层
                            onScreenshotCaptured(data)
                        } else {
                            Log.d(TAG, "重复的截屏事件，已忽略")
                        }
                    }
                } else {
                    Log.w(TAG, "⚠️ 无法获取列索引")
                }
            } else {
                // 查询失败或无结果，可能是权限问题
                Log.w(TAG, "⚠️ 查询媒体库失败，可能需要权限。URI: $uri")
                Log.w(TAG, "⚠️ Cursor: $cursor, moveToFirst: ${cursor?.moveToFirst()}")
                
                // 即使查询失败，也通知Flutter层（触发权限请求）
                // 使用URI作为临时路径
                val currentTime = System.currentTimeMillis()
                if (uriPath != lastScreenshotPath || 
                    currentTime - lastScreenshotTime > 1000) {
                    
                    Log.d(TAG, "📸 媒体库变化，通知Flutter层请求权限")
                    lastScreenshotPath = uriPath
                    lastScreenshotTime = currentTime
                    
                    // 传递URI字符串
                    onScreenshotCaptured(uriPath)
                }
            }
        } catch (e: SecurityException) {
            Log.e(TAG, "❌ 安全异常（权限不足）: ${e.message}")
            // 权限不足，通知Flutter层请求权限
            val currentTime = System.currentTimeMillis()
            if (uri.toString() != lastScreenshotPath || 
                currentTime - lastScreenshotTime > 1000) {
                
                Log.d(TAG, "📸 权限不足，通知Flutter层请求权限")
                lastScreenshotPath = uri.toString()
                lastScreenshotTime = currentTime
                onScreenshotCaptured(uri.toString())
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ 处理媒体变化异常: ${e.message}", e)
        } finally {
            cursor?.close()
        }
    }

    /**
     * 判断是否是截屏
     */
    private fun isScreenshot(displayName: String, path: String, dateAdded: Long): Boolean {
        // 1. 检查时间（必须是最近10秒内的）
        val currentTime = System.currentTimeMillis() / 1000
        if (currentTime - dateAdded > DETECT_WINDOW_SECONDS) {
            return false
        }

        // 2. 检查文件名和路径是否包含截屏关键字
        val lowerDisplayName = displayName.lowercase()
        val lowerPath = path.lowercase()

        for (keyword in SCREENSHOT_KEYWORDS) {
            if (lowerDisplayName.contains(keyword) || lowerPath.contains(keyword)) {
                return true
            }
        }

        return false
    }
}

