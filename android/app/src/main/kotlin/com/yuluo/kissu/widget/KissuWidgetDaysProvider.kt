package com.yuluo.kissu.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.RemoteViews
import com.yuluo.kissu.MainActivity
import com.yuluo.kissu.R

/**
 * Kissu 2×2 相伴天数小组件 Provider
 * 展示: 在一起天数
 */
class KissuWidgetDaysProvider : AppWidgetProvider() {

    companion object {
        private const val TAG = "KissuWidgetDays"

        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, KissuWidgetDaysProvider::class.java))
            for (id in ids) {
                updateWidget(context, manager, id)
            }
        }

        /**
         * 更新单个天数小组件 UI（静态方法，供 updateAllWidgets 和 onUpdate 共用）
         */
        fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val prefs = context.getSharedPreferences(KissuWidgetProvider.PREFS_NAME, Context.MODE_PRIVATE)

            val days = prefs.getString(KissuWidgetProvider.KEY_DAYS, "0") ?: "0"
            val bindDate = prefs.getString(KissuWidgetProvider.KEY_BIND_DATE, "") ?: ""

            val views = RemoteViews(context.packageName, R.layout.widget_kissu_days)

            views.setTextViewText(R.id.tv_days, days)
            if (bindDate.isNotEmpty()) {
                views.setTextViewText(R.id.tv_bind_date, bindDate)
            }

            // 点击小组件打开 App → 跳转到恋爱信息页面
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("widget_target_page", "love_info")
            }
            val pendingIntent = PendingIntent.getActivity(
                context, 2, launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
            Log.d(TAG, "天数小组件已更新: id=$appWidgetId, days=$days, bindDate=$bindDate")
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        Log.d(TAG, "onUpdate: 更新 ${appWidgetIds.size} 个天数小组件")
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
        // 系统触发 onUpdate 时，顺手确保周期任务仍然存在（部分机型/升级场景可能丢失）
        WidgetUpdateWorker.enqueuePeriodicWork(context)
        // 系统触发的 onUpdate → 立即入队一次性 Worker 拉取最新数据
        WidgetUpdateWorker.enqueueOneTimeWork(context)
    }

    override fun onEnabled(context: Context) {
        Log.d(TAG, "onEnabled: 第一个天数小组件被添加")
        WidgetUpdateWorker.enqueuePeriodicWork(context)
    }

    override fun onDisabled(context: Context) {
        Log.d(TAG, "onDisabled: 最后一个天数小组件被移除")
        // 仅当 4x2 组件也没有时才取消
        val manager = AppWidgetManager.getInstance(context)
        val largeIds = manager.getAppWidgetIds(ComponentName(context, KissuWidgetProvider::class.java))
        if (largeIds.isEmpty()) {
            WidgetUpdateWorker.cancelPeriodicWork(context)
        }
    }
}
