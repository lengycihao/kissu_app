package com.yuluo.kissu.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.Rect
import android.util.Log
import android.widget.RemoteViews
import com.yuluo.kissu.MainActivity
import com.yuluo.kissu.R
import java.net.URL
import kotlin.concurrent.thread

/**
 * Kissu 4×2 桌面小组件 Provider
 * 展示: 双方头像、电量、市级位置、距离、相恋天数
 * 数据通过 SharedPreferences 从 Flutter 侧同步
 */
class KissuWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val TAG = "KissuWidget"
        const val PREFS_NAME = "kissu_widget_data"

        // 共用数据
        const val KEY_DISTANCE = "distance"
        const val KEY_DAYS = "together_days"
        const val KEY_LOVE_TIME = "love_time"

        // 另一半数据
        const val KEY_PARTNER_BATTERY = "partner_battery"
        const val KEY_PARTNER_AVATAR = "partner_avatar"

        // 自己数据
        const val KEY_SELF_BATTERY = "self_battery"
        const val KEY_SELF_AVATAR = "self_avatar"

        // VIP / 绑定状态
        const val KEY_IS_VIP = "is_vip"
        const val KEY_IS_BIND = "is_bind"
        const val KEY_IS_SET_LOVER_TIME = "is_set_lover_time"

        // 最后刷新时间（调试用）
        const val KEY_LAST_REFRESH = "last_refresh_time"

        /**
         * 从外部触发更新所有小组件
         */
        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, KissuWidgetProvider::class.java))
            for (id in ids) {
                updateWidget(context, manager, id)
            }
        }

        /**
         * 将 Bitmap 裁剪为圆形
         */
        fun getCircularBitmap(bitmap: Bitmap): Bitmap {
            val size = minOf(bitmap.width, bitmap.height)
            val output = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(output)
            val paint = Paint().apply {
                isAntiAlias = true
            }
            val rect = Rect(0, 0, size, size)
            canvas.drawCircle(size / 2f, size / 2f, size / 2f, paint)
            paint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
            val left = (bitmap.width - size) / 2
            val top = (bitmap.height - size) / 2
            val srcRect = Rect(left, top, left + size, top + size)
            canvas.drawBitmap(bitmap, srcRect, rect, paint)
            return output
        }

        /**
         * 从 URL 下载头像 Bitmap（需在后台线程调用）
         */
        fun downloadBitmap(url: String): Bitmap? {
            return try {
                val connection = URL(url).openConnection()
                connection.connectTimeout = 5000
                connection.readTimeout = 5000
                val inputStream = connection.getInputStream()
                val bitmap = BitmapFactory.decodeStream(inputStream)
                inputStream.close()
                bitmap
            } catch (e: Exception) {
                Log.e(TAG, "下载头像失败: ${e.message}")
                null
            }
        }

        /**
         * 更新单个小组件 UI（静态方法，供 updateAllWidgets 和 onUpdate 共用）
         */
        fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

            val isVip  = prefs.getInt(KEY_IS_VIP,  0) == 1
            val isBind = prefs.getInt(KEY_IS_BIND, 0) == 1
            val days   = prefs.getString(KEY_DAYS, "0") ?: "0"

            val views = RemoteViews(context.packageName, R.layout.widget_kissu_large)

            // 未绑定：显示未绑定覆盖图，隐藏其他内容
            if (!isBind) {
                views.setViewVisibility(R.id.iv_unbound_overlay, android.view.View.VISIBLE)
                views.setViewVisibility(R.id.tv_last_refresh,    android.view.View.GONE)
                appWidgetManager.updateAppWidget(appWidgetId, views)
                return
            }

            views.setViewVisibility(R.id.iv_unbound_overlay, android.view.View.GONE)

            // 已绑定：根据 VIP 状态决定显示内容
            val distance: String
            val selfBattery: String
            val partnerBattery: String

            if (isVip) {
                distance      = prefs.getString(KEY_DISTANCE,        "未知") ?: "未知"
                selfBattery   = prefs.getString(KEY_SELF_BATTERY,    "--%")  ?: "--%"
                partnerBattery = prefs.getString(KEY_PARTNER_BATTERY, "--%") ?: "--%"
            } else {
                distance       = "VIP可见"
                selfBattery    = "--%"
                partnerBattery = "--%"
            }

            val selfAvatarUrl    = prefs.getString(KEY_SELF_AVATAR,    "") ?: ""
            val partnerAvatarUrl = prefs.getString(KEY_PARTNER_AVATAR, "") ?: ""

            views.setTextViewText(R.id.tv_distance,        distance)
            views.setTextViewText(R.id.tv_days,            days)
            views.setTextViewText(R.id.tv_self_battery,    selfBattery.replace("%", "") + "%")
            views.setTextViewText(R.id.tv_partner_battery, partnerBattery.replace("%", "") + "%")

            val lastRefresh = prefs.getString(KEY_LAST_REFRESH, "--:--:--") ?: "--:--:--"
            views.setTextViewText(R.id.tv_last_refresh, "最近刷新 $lastRefresh")
            views.setViewVisibility(R.id.tv_last_refresh, android.view.View.VISIBLE)

            // 点击小组件打开 App → 跳转到定位页面
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("widget_target_page", "location")
            }
            val pendingIntent = PendingIntent.getActivity(
                context, 0, launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            // 点击未绑定覆盖图 → 打开 App 并弹出绑定弹窗
            val bindIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("widget_target_page", "show_bind_dialog")
            }
            val bindPendingIntent = PendingIntent.getActivity(
                context, 1, bindIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.iv_unbound_overlay, bindPendingIntent)

            // 先用文字数据更新一次（头像用默认占位）
            appWidgetManager.updateAppWidget(appWidgetId, views)

            // 异步加载双方头像
            thread {
                try {
                    val updatedViews = RemoteViews(context.packageName, R.layout.widget_kissu_large)
                    var hasUpdate = false

                    // 加载自己头像
                    if (selfAvatarUrl.isNotEmpty()) {
                        val bitmap = downloadBitmap(selfAvatarUrl)
                        if (bitmap != null) {
                            val circularBitmap = getCircularBitmap(bitmap)
                            updatedViews.setImageViewBitmap(R.id.iv_self_avatar, circularBitmap)
                            hasUpdate = true
                         }
                    }

                    // 加载另一半头像
                    if (partnerAvatarUrl.isNotEmpty()) {
                        val bitmap = downloadBitmap(partnerAvatarUrl)
                        if (bitmap != null) {
                            val circularBitmap = getCircularBitmap(bitmap)
                            updatedViews.setImageViewBitmap(R.id.iv_partner_avatar, circularBitmap)
                            hasUpdate = true
                         }
                    }

                    if (hasUpdate) {
                        appWidgetManager.partiallyUpdateAppWidget(appWidgetId, updatedViews)
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "加载头像异常: ${e.message}")
                }
            }

            Log.d(TAG, "小组件已更新: id=$appWidgetId, days=$days, distance=$distance")
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        Log.d(TAG, "onUpdate: 更新 ${appWidgetIds.size} 个小组件")
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
        // 系统触发 onUpdate 时，顺手确保周期任务仍然存在（部分机型/升级场景可能丢失）
        WidgetUpdateWorker.enqueuePeriodicWork(context)
        // 系统触发的 onUpdate → 立即入队一次性 Worker 拉取最新数据
        // 这是最可靠的后台刷新路径，因为由 Android 系统根据 updatePeriodMillis 触发
        WidgetUpdateWorker.enqueueOneTimeWork(context)
        // 🔥 启动 AlarmManager 备份链，防止 WorkManager 被国产ROM冻结
        WidgetUpdateWorker.scheduleAlarmBackup(context)
    }

    override fun onEnabled(context: Context) {
        Log.d(TAG, "onEnabled: 第一个小组件被添加")
        // 注册 WorkManager 周期刷新任务
        WidgetUpdateWorker.enqueuePeriodicWork(context)
        // 🔥 启动 AlarmManager 备份链
        WidgetUpdateWorker.scheduleAlarmBackup(context)
    }

    override fun onDisabled(context: Context) {
        Log.d(TAG, "onDisabled: 最后一个小组件被移除")
        // 仅当 2x2 组件也没有时才取消
        val manager = AppWidgetManager.getInstance(context)
        val daysIds = manager.getAppWidgetIds(ComponentName(context, KissuWidgetDaysProvider::class.java))
        if (daysIds.isEmpty()) {
            WidgetUpdateWorker.cancelPeriodicWork(context)
        }
    }
}
