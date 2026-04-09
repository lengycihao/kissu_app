package com.yuluo.kissu.widget

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * 小组件 AlarmManager 备份接收器
 * 当 WorkManager 被系统省电策略冻结时，AlarmManager 作为可靠备份触发小组件刷新
 * 使用自我续命链：每次触发后自动调度下一次闹钟
 */
class WidgetAlarmReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "WidgetAlarmReceiver"
    }

    override fun onReceive(context: Context, intent: Intent?) {
        Log.d(TAG, "⏰ AlarmManager 备份触发小组件刷新")

        // 1. 立即入队一次性 Worker 拉取最新数据
        try {
            WidgetUpdateWorker.enqueueOneTimeWork(context)
        } catch (e: Exception) {
            Log.e(TAG, "入队 OneTimeWork 失败: ${e.message}")
        }

        // 2. 确保 WorkManager 周期任务仍然存在（可能被系统杀掉）
        try {
            WidgetUpdateWorker.enqueuePeriodicWork(context)
        } catch (e: Exception) {
            Log.e(TAG, "恢复 PeriodicWork 失败: ${e.message}")
        }

        // 3. 调度下一次闹钟（自我续命）
        try {
            WidgetUpdateWorker.scheduleAlarmBackup(context)
        } catch (e: Exception) {
            Log.e(TAG, "调度下一次闹钟失败: ${e.message}")
        }
    }
}
