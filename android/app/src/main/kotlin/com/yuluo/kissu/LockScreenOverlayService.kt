package com.yuluo.kissu

import android.app.*
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.SharedPreferences
import android.graphics.*
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.os.*
import android.provider.Settings
import android.util.TypedValue
import android.view.*
import android.widget.*
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import org.json.JSONObject
import com.tencent.imsdk.v2.V2TIMManager
import com.tencent.imsdk.v2.V2TIMMessage
import com.tencent.imsdk.v2.V2TIMSendCallback
import java.text.SimpleDateFormat
import java.util.*

class LockScreenOverlayService : Service() {

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var handler: Handler? = null
    private var checkRunnable: Runnable? = null
    private var prefs: SharedPreferences? = null

    private var isScreenLockMode = false
    private var isOverlayShowing = false
    private var isAnsweringQuestion = false // 是否正在答题页面
    
    // 电话/信息应用检测
    private val phoneAndMessagePackages = setOf(
        "com.android.dialer", "com.google.android.dialer", "com.samsung.android.dialer",
        "com.miui.contacts", "com.huawei.contacts", "com.oppo.dialer", "com.vivo.contacts",
        "com.oneplus.dialer", "com.android.contacts", "com.android.phone",
        "com.android.mms", "com.google.android.apps.messaging", "com.samsung.android.messaging",
        "com.miui.mms", "com.huawei.message", "com.oppo.mms", "com.vivo.mms",
        "com.oneplus.mms", "com.coloros.mms"
    )

    // 锁屏UI
    private var timeTextView: TextView? = null
    private var timeUpdateRunnable: Runnable? = null
    
    // 答题页面相关
    private var lockScreenContainer: FrameLayout? = null  // 锁屏主视图容器
    private var lockScreenContainerTop: FrameLayout? = null  // 锁屏主视图容器上方灰色背景
    private var questionContainer: FrameLayout? = null    // 答题视图容器
    private var questionText: String = "什么马不能骑？"
    private var answerOptions: List<String> = listOf("海马", "河马", "斑马", "木马")
    private var correctAnswerIndex: Int = 0
    private var answerAttempts: Int = 0  // 🔥 答题次数计数器
    private var shutdownReceiver: BroadcastReceiver? = null  // 🔥 关机/重启广播接收器
    
    // 锁屏界面显示信息
    private var lockText: String = ""           // 锁屏文案
    private var bgImageIndex: Int = 0           // 背景图片索引

    // 保活
    private var wakeLock: PowerManager.WakeLock? = null
    
    // 自定义字体
    private var customTypeface: Typeface? = null

    companion object {
        const val CHANNEL_ID = "kissu_lock_overlay_channel"
        const val NOTIFICATION_ID = 2001
        const val CHECK_INTERVAL = 200L
        const val PREFS_NAME = "kissu_lock_prefs"
        const val KEY_SCREEN_LOCK = "screen_lock"
        const val RESTART_INTENT = "com.yuluo.kissu.RESTART_LOCK_SERVICE"
    }

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        handler = Handler(Looper.getMainLooper())
        
        // 加载自定义字体
        loadCustomTypeface()

        // 🔥 恢复关机前保存的答题次数
        answerAttempts = prefs?.getInt("lock_answer_attempts", 0) ?: 0
        if (answerAttempts > 0) {
            android.util.Log.d("LockScreenOverlay", "🔥 恢复答题次数: $answerAttempts")
        }
        
        acquireWakeLock()
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createNotification())
        scheduleRestartAlarm()
        registerShutdownReceiver()
        startMonitoring()
    }

    private fun acquireWakeLock() {
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "Kissu::LockScreenWakeLock"
            )
            wakeLock?.acquire(10 * 60 * 1000L)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun scheduleRestartAlarm() {
        try {
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(this, LockServiceRestartReceiver::class.java).apply {
                action = RESTART_INTENT
            }
            val pendingIntent = PendingIntent.getBroadcast(
                this, 0, intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
            val triggerTime = System.currentTimeMillis() + 30000
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerTime, pendingIntent)
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerTime, pendingIntent)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            "STOP_SERVICE" -> {
                cancelRestartAlarm()
                stopSelf()
                return START_NOT_STICKY
            }
        }
        acquireWakeLock()
        scheduleRestartAlarm()
        if (checkRunnable == null || handler == null) {
            handler = Handler(Looper.getMainLooper())
            startMonitoring()
        }
        return START_STICKY
    }

    private fun cancelRestartAlarm() {
        try {
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(this, LockServiceRestartReceiver::class.java).apply {
                action = RESTART_INTENT
            }
            val pendingIntent = PendingIntent.getBroadcast(
                this, 0, intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
            alarmManager.cancel(pendingIntent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        scheduleImmediateRestart()
        super.onTaskRemoved(rootIntent)
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        // 🔥 注销关机广播接收器
        unregisterShutdownReceiver()
        
        val screenLock = prefs?.getString(KEY_SCREEN_LOCK, null)
        if (screenLock != null) {
            scheduleImmediateRestart()
        }
        try {
            wakeLock?.let { if (it.isHeld) it.release() }
        } catch (e: Exception) { e.printStackTrace() }
        handler?.removeCallbacksAndMessages(null)
        hideOverlay()
        super.onDestroy()
    }

    private fun scheduleImmediateRestart() {
        try {
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(this, LockServiceRestartReceiver::class.java).apply {
                action = RESTART_INTENT
            }
            val pendingIntent = PendingIntent.getBroadcast(
                this, 1, intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
            val triggerTime = System.currentTimeMillis() + 1000
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerTime, pendingIntent)
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerTime, pendingIntent)
            }
        } catch (e: Exception) { e.printStackTrace() }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Kissu后台服务",
                NotificationManager.IMPORTANCE_MIN  // 最低优先级，不显示在状态栏
            ).apply {
                description = "Kissu后台服务"
                setShowBadge(false)
                setSound(null, null)
                enableVibration(false)
                enableLights(false)
                lockscreenVisibility = Notification.VISIBILITY_SECRET  // 锁屏不显示
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentTitle("Kissu锁机服务")
            .setContentText("对方正在锁定您的手机")
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setVisibility(NotificationCompat.VISIBILITY_SECRET)
            .setSilent(true)
            .setOngoing(false)
            .build()
    }

    private fun startMonitoring() {
        checkRunnable = object : Runnable {
            override fun run() {
                checkScreenLock()
                handler?.postDelayed(this, CHECK_INTERVAL)
            }
        }
        handler?.post(checkRunnable!!)
    }

    private var checkCounter = 0
    
    private fun checkScreenLock() {
        checkCounter++
        val shouldLog = checkCounter % 50 == 1
        
        val screenLockJson = prefs?.getString(KEY_SCREEN_LOCK, null)
        if (screenLockJson == null) {
            if (isScreenLockMode) {
                android.util.Log.d("LockScreenOverlay", "checkScreenLock: screenLockJson为null，隐藏悬浮窗")
                isScreenLockMode = false
                hideOverlayOnly()
            }
            return
        }
        
        try {
            val obj = JSONObject(screenLockJson)
            val endTime = obj.optLong("endTime", 0)
            val currentTime = System.currentTimeMillis()
            
            if (currentTime >= endTime) {
                if (isScreenLockMode) {
                    android.util.Log.d("LockScreenOverlay", "checkScreenLock: 锁屏时间已过，发送解锁通知并停止服务")
                    // 🔥 时间到期，发送解锁通知给锁机方
                    answerAttempts++
                    sendUnlockPhoneReceive(answerAttempts)
                    removeScreenLock()
                    // 清除答题次数
                    prefs?.edit()?.remove("lock_answer_attempts")?.apply()
                    hideOverlay()
                    stopForeground(STOP_FOREGROUND_REMOVE)
                    stopSelf()
                }
                return
            }
            
            // 锁屏仍有效
            isScreenLockMode = true
            
            // 检测前台应用，如果是电话/信息应用则隐藏悬浮窗
            val foregroundPkg = getForegroundPackage()
            val isInPhoneOrMessage = foregroundPkg != null && phoneAndMessagePackages.contains(foregroundPkg)
            
            if (shouldLog) {
                android.util.Log.d("LockScreenOverlay", "checkScreenLock[周期$checkCounter]: foreground=$foregroundPkg isInPhoneOrMessage=$isInPhoneOrMessage isOverlayShowing=$isOverlayShowing")
            }
            
            if (isInPhoneOrMessage) {
                // 用户在电话/信息应用中，隐藏悬浮窗
                if (isOverlayShowing) {
                    android.util.Log.d("LockScreenOverlay", "用户在电话/信息应用($foregroundPkg)，隐藏悬浮窗")
                    hideOverlayOnly()
                }
            } else {
                // 用户不在电话/信息应用，显示悬浮窗
                if (!isOverlayShowing && !isAnsweringQuestion) {
                    android.util.Log.d("LockScreenOverlay", "用户离开电话/信息应用，恢复悬浮窗")
                    showOverlay()
                }
            }
        } catch (e: Exception) { e.printStackTrace() }
    }
    
    private fun getForegroundPackage(): String? {
        try {
            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
                ?: return null
            val endTime = System.currentTimeMillis()
            val beginTime = endTime - 5000
            val usageEvents = usageStatsManager.queryEvents(beginTime, endTime) ?: return null
            
            val foregroundEvents = mutableListOf<Pair<String, Long>>()
            val backgroundEvents = mutableMapOf<String, Long>()
            
            while (usageEvents.hasNextEvent()) {
                val event = UsageEvents.Event()
                usageEvents.getNextEvent(event)
                when (event.eventType) {
                    UsageEvents.Event.ACTIVITY_RESUMED, UsageEvents.Event.MOVE_TO_FOREGROUND -> {
                        foregroundEvents.add(Pair(event.packageName, event.timeStamp))
                    }
                    UsageEvents.Event.ACTIVITY_PAUSED, UsageEvents.Event.MOVE_TO_BACKGROUND -> {
                        backgroundEvents[event.packageName] = event.timeStamp
                    }
                }
            }
            
            foregroundEvents.sortByDescending { it.second }
            for ((pkg, foregroundTime) in foregroundEvents) {
                val backgroundTime = backgroundEvents[pkg] ?: 0L
                if (foregroundTime > backgroundTime) {
                    return pkg
                }
            }
            return foregroundEvents.firstOrNull()?.first
        } catch (e: Exception) {
            return null
        }
    }
    
    // 只隐藏悬浮窗，不清除锁屏状态
    private fun hideOverlayOnly() {
        timeUpdateRunnable?.let { handler?.removeCallbacks(it) }
        overlayView?.let {
            try { windowManager?.removeView(it) } catch (e: Exception) { e.printStackTrace() }
        }
        overlayView = null
        isOverlayShowing = false
        timeTextView = null
        lockScreenContainer = null
        lockScreenContainerTop = null
        questionContainer = null
    }

    private fun removeScreenLock() {
        isScreenLockMode = false
        prefs?.edit()?.remove(KEY_SCREEN_LOCK)?.apply()
    }

    private fun showOverlay() {
        if (!Settings.canDrawOverlays(this)) return

        if (overlayView != null) {
            try { windowManager?.removeView(overlayView) } catch (e: Exception) {}
            overlayView = null
        }

        // 加载锁屏界面显示数据（头像、昵称、文案、背景图片）
        loadLockScreenDisplayData()
        
        overlayView = createScreenLockView()

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                    WindowManager.LayoutParams.FLAG_FULLSCREEN or
                    WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS or
                    WindowManager.LayoutParams.FLAG_TRANSLUCENT_NAVIGATION or
                    WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH or
                    WindowManager.LayoutParams.FLAG_SECURE,
            PixelFormat.TRANSLUCENT
        )
        params.gravity = Gravity.TOP or Gravity.START
        params.x = 0
        params.y = 0
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            params.layoutInDisplayCutoutMode =
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
        }

        try {
            windowManager?.addView(overlayView, params)
            isOverlayShowing = true
        } catch (e: Exception) {
            e.printStackTrace()
            isOverlayShowing = false
        }
    }

    private fun createScreenLockView(): View {
        val context = this
        val screenWidth = resources.displayMetrics.widthPixels
        val screenHeight = resources.displayMetrics.heightPixels

        // 根容器，包含锁屏视图和答题视图
        val rootContainer = FrameLayout(context).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }
        
        // 锁屏主视图容器
        lockScreenContainer = FrameLayout(context).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }

        // 锁屏主视图容器
        lockScreenContainerTop = FrameLayout(context).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }
        
        // 答题视图容器（初始隐藏）
        questionContainer = FrameLayout(context).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
            visibility = View.GONE
        }

        // 背景图片 - 根据bgImageIndex选择对应的背景图片
        try {
            val bgResId = when (bgImageIndex) {
                0 -> R.drawable.kissu_lock_bg_1
                1 -> R.drawable.kissu_lock_bg_2
                2 -> R.drawable.kissu_lock_bg_3
                else -> R.drawable.kissu_lock_bg_1
            }
            val bgResIdTop = R.drawable.kissu_lock_gray_bg
            val bgDrawable = ContextCompat.getDrawable(context, bgResId)
            val bgDrawableTop = ContextCompat.getDrawable(context, bgResIdTop)
            lockScreenContainer?.background = bgDrawable
            lockScreenContainerTop?.background = bgDrawableTop
        } catch (e: Exception) {
            // 如果加载失败，使用默认背景
            try {
                val bgDrawable = ContextCompat.getDrawable(context, R.drawable.kissu_lock_bg)
                lockScreenContainer?.background = bgDrawable
                 val bgDrawableTop = ContextCompat.getDrawable(context, R.drawable.kissu_lock_gray_bg)
                  lockScreenContainerTop?.background = bgDrawableTop
            } catch (e2: Exception) {
                lockScreenContainer?.background = GradientDrawable(
                    GradientDrawable.Orientation.TOP_BOTTOM,
                    intArrayOf(
                        Color.parseColor("#c4a574"),
                        Color.parseColor("#b8956a"),
                        Color.parseColor("#a88560")
                    )
                )
                lockScreenContainerTop?.background = GradientDrawable(
                    GradientDrawable.Orientation.TOP_BOTTOM,
                    intArrayOf(
                        Color.parseColor("#c4a574"),
                        Color.parseColor("#b8956a"),
                        Color.parseColor("#a88560")
                    )
                )
            }
        }

        // 时间模块
        val timeLayout = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
        }
        val timeParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.WRAP_CONTENT,
            FrameLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
            topMargin = dp(80)
        }
        lockScreenContainerTop?.addView(timeLayout, timeParams)

        timeTextView = TextView(context).apply {
            text = SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date())
            textSize = 72f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            typeface = customTypeface ?: Typeface.DEFAULT_BOLD
            setShadowLayer(8f, 2f, 2f, Color.parseColor("#40000000"))
        }
        timeLayout.addView(timeTextView)

        startTimeUpdate()

        val hintText = TextView(context).apply {
            text = "手机已经被Ta锁定"
            textSize = 28f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            typeface = customTypeface ?: Typeface.DEFAULT_BOLD
            setPadding(dp(20), dp(8), dp(20), dp(8))
        }
        val hintTextParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            gravity = Gravity.CENTER_HORIZONTAL
            topMargin = dp(40) // 让文字往下移动，更靠近用户信息模块
        }
        timeLayout.addView(hintText, hintTextParams)
        
        // 用户信息模块（头像、昵称、锁屏文案）- 只有当有锁屏文案时才显示
        if (lockText.isNotEmpty()) {
            // 外层容器：垂直排列（头像昵称行 + 文案）
            val userInfoCard = LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                setPadding(dp(16), dp(12), dp(16), dp(12))
                background = GradientDrawable().apply {
                    setColor(Color.parseColor("#4D000000"))
                    cornerRadius = dp(25).toFloat()
                }
            }
            
            // 第一行：头像 + 昵称（水平排列）
            val headerRow = LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )
            }
            
            // 头像
            val avatarView = ImageView(context).apply {
                layoutParams = LinearLayout.LayoutParams(dp(24), dp(24))
                background = GradientDrawable().apply {
                    shape = GradientDrawable.OVAL
                    setColor(Color.parseColor("#FFE4C4"))
                }
                scaleType = ImageView.ScaleType.CENTER_CROP
                // 加载另一半头像
                loadPartnerAvatar(this)
            }
            headerRow.addView(avatarView)
            
            // 昵称
            val nicknameText = TextView(context).apply {
                text = getPartnerNickname()
                textSize = 14f
                setTextColor(Color.parseColor("#ffffff"))
                 layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    leftMargin = dp(8)
                }
            }
            headerRow.addView(nicknameText)
            
            userInfoCard.addView(headerRow)
            
            // 第二行：锁屏文案
            val lockTextView = TextView(context).apply {
                text = lockText
                textSize = 20f
                setTextColor(Color.parseColor("#ffffff"))
                typeface = Typeface.DEFAULT_BOLD
                maxLines = 2
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    topMargin = dp(8)
                }
            }
            userInfoCard.addView(lockTextView)
            
            // 用户信息模块保持原位置不变
            val userInfoParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                gravity = Gravity.TOP
                topMargin = dp(260)
                leftMargin = dp(24)
                rightMargin = dp(24)
            }
            lockScreenContainerTop?.addView(userInfoCard, userInfoParams)
        }
        // 滑动解锁控件
        val sliderHeight = dp(64)
        val thumbSize = dp(52)
        val sliderContainer = FrameLayout(context).apply {
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#4DFFFFFF"))
                cornerRadius = (sliderHeight / 2).toFloat()
            }
        }

        // 提示文字（在按钮右边10dp）
        val sliderHintText = TextView(context).apply {
            text = "答对问题，解锁手机"
            textSize = 16f
            setTextColor(Color.WHITE)
            typeface = customTypeface ?: Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER_VERTICAL
        }
        sliderContainer.addView(sliderHintText, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.WRAP_CONTENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        ).apply { 
            gravity = Gravity.START or Gravity.CENTER_VERTICAL
            leftMargin = dp(4) + thumbSize + dp(10) // 按钮左边距 + 按钮大小 + 间距10dp
        })

        // 滑块（圆形，左侧）
        val thumb = FrameLayout(context).apply {
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.WHITE)
            }
            elevation = dp(4).toFloat()
        }
        val lockIcon = ImageView(context).apply {
            try {
                setImageResource(R.drawable.kissu_lock_page_icon)
            } catch (e: Exception) {
                setImageResource(android.R.drawable.ic_lock_lock)
            }
            scaleType = ImageView.ScaleType.CENTER_INSIDE
//            setPadding(dp(10), dp(10), dp(10), dp(10))
        }
        thumb.addView(lockIcon, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        ))
        val thumbParams = FrameLayout.LayoutParams(thumbSize, thumbSize).apply {
            gravity = Gravity.START or Gravity.CENTER_VERTICAL
            leftMargin = dp(4)
        }
        sliderContainer.addView(thumb, thumbParams)

        // 触摸监听
        var initialRawX = 0f
        var initialLeftMargin = dp(4)
        thumb.setOnTouchListener { _, event ->
            when (event.action) {
                android.view.MotionEvent.ACTION_DOWN -> {
                    initialRawX = event.rawX
                    initialLeftMargin = (thumb.layoutParams as FrameLayout.LayoutParams).leftMargin
                    true
                }
                android.view.MotionEvent.ACTION_MOVE -> {
                    val containerW = sliderContainer.width
                    val maxMargin = containerW - thumbSize - dp(4)
                    val dx = (event.rawX - initialRawX).toInt()
                    val newMargin = (initialLeftMargin + dx).coerceIn(dp(4), maxMargin)
                    (thumb.layoutParams as FrameLayout.LayoutParams).leftMargin = newMargin
                    thumb.requestLayout()
                    val progress = if (maxMargin > dp(4)) (newMargin - dp(4)).toFloat() / (maxMargin - dp(4)) else 0f
                    sliderHintText.alpha = 1f - progress * 0.8f
                    // 图标顺时针旋转（最多旋转360度）
                    lockIcon.rotation = progress * 360f
                    true
                }
                android.view.MotionEvent.ACTION_UP, android.view.MotionEvent.ACTION_CANCEL -> {
                    val containerW = sliderContainer.width
                    val maxMargin = containerW - thumbSize - dp(4)
                    val currentMargin = (thumb.layoutParams as FrameLayout.LayoutParams).leftMargin
                    if (containerW > 0 && currentMargin >= maxMargin * 0.85f) {
                        // 滑到底后重置位置再跳转（防止返回时位置不对）
                        (thumb.layoutParams as FrameLayout.LayoutParams).leftMargin = dp(4)
                        thumb.requestLayout()
                        lockIcon.rotation = 0f
                        sliderHintText.alpha = 1f
                        openQuestionPage()
                    } else {
                        (thumb.layoutParams as FrameLayout.LayoutParams).leftMargin = dp(4)
                        thumb.requestLayout()
                        lockIcon.rotation = 0f
                        sliderHintText.alpha = 1f
                    }
                    true
                }
                else -> false
            }
        }

        val sliderParams = FrameLayout.LayoutParams(
            dp(240),
            sliderHeight
        ).apply {
            gravity = Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
            bottomMargin = dp(120)
        }
        lockScreenContainerTop?.addView(sliderContainer, sliderParams)

        // 底部图标
        val bottomLayout = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        val bottomParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            dp(60)
        ).apply {
            gravity = Gravity.BOTTOM
            bottomMargin = dp(40)
            leftMargin = dp(40)
            rightMargin = dp(40)
        }
        lockScreenContainerTop?.addView(bottomLayout, bottomParams)

        val messageButton = ImageView(context).apply {
            setImageResource(R.drawable.kissu_lock_message)
            scaleType = ImageView.ScaleType.CENTER_INSIDE

            isClickable = true
            isFocusable = true
            setOnClickListener { openMessagingApp() }
        }

        bottomLayout.addView(messageButton,
            LinearLayout.LayoutParams(dp(50), dp(50))
        )

        val spacer = View(context)
        bottomLayout.addView(spacer, LinearLayout.LayoutParams(0, 1, 1f))

        val phoneButton = ImageView(context).apply {
            setImageResource(R.drawable.kissu_lock_phone)
            scaleType = ImageView.ScaleType.CENTER_INSIDE


            isClickable = true
            isFocusable = true
            setOnClickListener { openPhoneApp() }
        }

        bottomLayout.addView(phoneButton,
            LinearLayout.LayoutParams(dp(50), dp(50))
        )

        // 将两个容器添加到根容器
        rootContainer.addView(lockScreenContainer)
        rootContainer.addView(lockScreenContainerTop)
        rootContainer.addView(questionContainer)

        rootContainer.systemUiVisibility = (View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_FULLSCREEN
                or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY)

        return rootContainer
    }

    private fun startTimeUpdate() {
        timeUpdateRunnable?.let { handler?.removeCallbacks(it) }
        timeUpdateRunnable = object : Runnable {
            override fun run() {
                timeTextView?.text = SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date())
                handler?.postDelayed(this, 1000)
            }
        }
        handler?.post(timeUpdateRunnable!!)
    }

    private fun openQuestionPage() {
        android.util.Log.d("LockScreenOverlay", "openQuestionPage 被点击，在悬浮窗内切换到答题页面")
        isAnsweringQuestion = true
        isAnswerLocked = false  // 🔥 重置答案锁定状态
        // 加载问题数据
        loadQuestionData()
        // 在悬浮窗内切换到答题视图
        showQuestionView()
    }
    
    private fun loadQuestionData() {
        try {
            // Flutter的SharedPreferences存储在FlutterSharedPreferences，key带flutter.前缀
            val flutterPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            questionText = flutterPrefs.getString("flutter.lock_question", "什么马不能骑？") ?: "什么马不能骑？"
            val answersJson = flutterPrefs.getString("flutter.lock_answers", "[\"海马\",\"河马\",\"斑马\",\"木马\"]") ?: "[\"海马\",\"河马\",\"斑马\",\"木马\"]"
            correctAnswerIndex = flutterPrefs.getLong("flutter.lock_correct_index", 0L).toInt()
            
            // 解析答案JSON
            val jsonArray = org.json.JSONArray(answersJson)
            val answers = mutableListOf<String>()
            for (i in 0 until jsonArray.length()) {
                answers.add(jsonArray.getString(i))
            }
            answerOptions = answers
            android.util.Log.d("LockScreenOverlay", "加载问题: $questionText, 答案: $answerOptions, 正确索引: $correctAnswerIndex")
        } catch (e: Exception) {
            android.util.Log.e("LockScreenOverlay", "加载问题数据失败: ${e.message}")
            questionText = "什么马不能骑？"
            answerOptions = listOf("海马", "河马", "斑马", "木马")
            correctAnswerIndex = 0
        }
    }
    
    private fun loadLockScreenDisplayData() {
        try {
            // 从Flutter SharedPreferences加载锁屏界面显示信息
            // 注意：Flutter的SharedPreferences使用不同的文件名
            val flutterPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            lockText = flutterPrefs.getString("flutter.lock_text", "") ?: ""
            bgImageIndex = flutterPrefs.getLong("flutter.lock_bg_image_index", 0L).toInt()
            android.util.Log.d("LockScreenOverlay", "加载锁屏显示数据: lockText=$lockText, bgIndex=$bgImageIndex")
        } catch (e: Exception) {
            android.util.Log.e("LockScreenOverlay", "加载锁屏显示数据失败: ${e.message}")
            lockText = ""
            bgImageIndex = 0
        }
    }
    
    private fun showQuestionView() {
        lockScreenContainer?.visibility = View.GONE
        lockScreenContainerTop?.visibility = View.GONE
        questionContainer?.visibility = View.VISIBLE
        // 重新创建答题视图内容
        questionContainer?.removeAllViews()
        questionContainer?.addView(createQuestionContent())
    }
    
    private fun showLockScreenView() {
        isAnsweringQuestion = false
        questionContainer?.visibility = View.GONE
        lockScreenContainer?.visibility = View.VISIBLE
        lockScreenContainerTop?.visibility = View.VISIBLE
    }
    
    private fun createQuestionContent(): View {
        val context = this
        val container = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
            setBackgroundColor(Color.parseColor("#FFF5E6"))
            setPadding(dp(24), dp(44), dp(24), dp(24))
        }
        
        // 顶部导航栏
        val topBar = FrameLayout(context).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dp(56)
            )
        }
        
        // 返回按钮
        val backButton = ImageView(context).apply {
            setImageResource(android.R.drawable.ic_menu_close_clear_cancel)
            setColorFilter(Color.parseColor("#333333"))
            setPadding(dp(12), dp(12), dp(12), dp(12))
            isClickable = true
            isFocusable = true
            setOnClickListener { showLockScreenView() }
        }
        val backParams = FrameLayout.LayoutParams(dp(44), dp(44)).apply {
            gravity = Gravity.START or Gravity.CENTER_VERTICAL
        }
        topBar.addView(backButton, backParams)
        
        // 标题
        val titleText = TextView(context).apply {
            text = "答对问题，立即解锁手机"
            textSize = 16f
            setTextColor(Color.parseColor("#333333"))
            gravity = Gravity.CENTER
            typeface = customTypeface ?: Typeface.DEFAULT_BOLD
        }
        val titleParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.WRAP_CONTENT,
            FrameLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            gravity = Gravity.CENTER
        }
        topBar.addView(titleText, titleParams)
        container.addView(topBar)
        
        // 间距
        container.addView(View(context).apply {
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dp(20))
        })
        
        // 问题背景区域（使用图片背景，宽度固定高度自适应）
        val questionBgContainer = FrameLayout(context).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }
        
        // 背景图片（宽度固定，高度自适应，保持比例不变形）
        val bgImageView = ImageView(context).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.WRAP_CONTENT
            )
            adjustViewBounds = true // 保持图片宽高比
            scaleType = ImageView.ScaleType.FIT_CENTER
            try {
                setImageResource(R.drawable.kissu_lock_question_bg)
            } catch (e: Exception) {
                android.util.Log.e("LockScreenOverlay", "加载问题背景图片失败: ${e.message}")
            }
        }
        questionBgContainer.addView(bgImageView)
        
        // 问题文字（居中显示）
        val questionTextView = TextView(context).apply {
            text = questionText
            textSize = 22f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            typeface = customTypeface ?: Typeface.DEFAULT_BOLD
            setPadding(dp(24), dp(40), dp(24), dp(40))
        }
        val questionTextParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        ).apply {
            gravity = Gravity.CENTER
        }
        questionBgContainer.addView(questionTextView, questionTextParams)
        container.addView(questionBgContainer)
        
        // 间距
        container.addView(View(context).apply {
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dp(32))
        })
        
        // 答案选项
        for ((index, answer) in answerOptions.withIndex()) {
            val optionButton = TextView(context).apply {
                text = answer
                textSize = 16f
                setTextColor(Color.parseColor("#333333"))
                gravity = Gravity.CENTER
                typeface = customTypeface ?: Typeface.DEFAULT_BOLD
                setPadding(dp(16), dp(16), dp(16), dp(16))
                // 使用背景图片替代边框
                try {
                    background = resources.getDrawable(R.drawable.kissu_lock_answer_bg, null)
                } catch (e: Exception) {
                    android.util.Log.e("LockScreenOverlay", "加载答案背景图片失败: ${e.message}")
                    background = GradientDrawable().apply {
                        setColor(Color.WHITE)
                        cornerRadius = dp(12).toFloat()
                    }
                }
                isClickable = true
                isFocusable = true
                setOnClickListener { onAnswerSelected(index, this) }
            }
            val optionParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dp(56)
            ).apply {
                bottomMargin = dp(12)
            }
            container.addView(optionButton, optionParams)
        }
        
        return container
    }
    
    private var isAnswerLocked = false  // 🔥 选对答案后锁定，防止弹窗期间重复选择
    
    private fun onAnswerSelected(index: Int, button: TextView) {
        if (isAnswerLocked) return  // 🔥 已选对答案，弹窗期间不允许再选
        
        // 🔥 轻微震动反馈
        vibrateLight()
        
        android.util.Log.d("LockScreenOverlay", "选择答案: $index, 正确答案: $correctAnswerIndex")
        
        if (index == correctAnswerIndex) {
            isAnswerLocked = true  // 🔥 锁定答案选择
            // 答对了，使用正确答案背景图片
            try {
                button.background = resources.getDrawable(R.drawable.kissu_lock_right_bg, null)
            } catch (e: Exception) {
                android.util.Log.e("LockScreenOverlay", "加载正确答案背景图片失败: ${e.message}")
            }
            showSuccessDialog()
        } else {
            // 答错了，使用错误答案背景图片
            try {
                button.background = resources.getDrawable(R.drawable.kissu_lock_wrong_bg, null)
            } catch (e: Exception) {
                android.util.Log.e("LockScreenOverlay", "加载错误答案背景图片失败: ${e.message}")
            }
            button.setTextColor(Color.parseColor("#FF6B6B"))
            answerAttempts++  // 🔥 答错计数
            // 短暂延迟后重置
            handler?.postDelayed({
                try {
                    button.background = resources.getDrawable(R.drawable.kissu_lock_answer_bg, null)
                } catch (e: Exception) {
                    android.util.Log.e("LockScreenOverlay", "重置答案背景图片失败: ${e.message}")
                }
                button.setTextColor(Color.parseColor("#333333"))
            }, 800)
        }
    }
    
    private fun showSuccessDialog() {
        android.util.Log.d("LockScreenOverlay", "显示成功弹窗")
        
        // 创建半透明黑色背景遮罩
        val dimBackground = View(this).apply {
            setBackgroundColor(Color.parseColor("#80000000")) // 50%透明度黑色
        }
        val dimParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        )
        questionContainer?.addView(dimBackground, dimParams)
        
        // 创建成功弹窗图片 (313x233)
        val dialogImageView = ImageView(this).apply {
            try {
                setImageResource(R.drawable.kissu_lock_dialog)
            } catch (e: Exception) {
                android.util.Log.e("LockScreenOverlay", "加载成功弹窗图片失败: ${e.message}")
            }
            scaleType = ImageView.ScaleType.FIT_CENTER
        }
        
        val dialogParams = FrameLayout.LayoutParams(
            dp(313),
            dp(233)
        ).apply {
            gravity = Gravity.CENTER
        }
        
        // 添加到问题容器中
        questionContainer?.addView(dialogImageView, dialogParams)
        
        // 1.5秒后移除弹窗和遮罩并解锁
        handler?.postDelayed({
            questionContainer?.removeView(dialogImageView)
            questionContainer?.removeView(dimBackground)
            unlockScreen()
        }, 1500)
    }
    
    /**
     * 🔥 注册关机/重启广播接收器
     * 被锁方关机或重启时，持久化答题次数，锁屏数据保留（重启后快速恢复锁屏）
     */
    private fun registerShutdownReceiver() {
        try {
            shutdownReceiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context?, intent: Intent?) {
                    val action = intent?.action
                    if (action == Intent.ACTION_SHUTDOWN || action == "android.intent.action.QUICKBOOT_POWEROFF") {
                        android.util.Log.d("LockScreenOverlay", "🔥 检测到关机/重启，当前锁屏模式: $isScreenLockMode")
                        if (isScreenLockMode) {
                            // 🔥 持久化答题次数（重启后恢复）
                            val lockPrefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                            lockPrefs.edit()
                                .putInt("lock_answer_attempts", answerAttempts)
                                .commit()  // commit()同步写入，确保关机前写入磁盘
                            android.util.Log.d("LockScreenOverlay", "🔥 关机前已保存答题次数: $answerAttempts，锁屏数据保留")
                            // 🔥 不清除锁屏数据，不发送解锁通知，重启后继续锁屏
                        }
                    }
                }
            }
            val filter = IntentFilter().apply {
                addAction(Intent.ACTION_SHUTDOWN)
                addAction("android.intent.action.QUICKBOOT_POWEROFF")
            }
            registerReceiver(shutdownReceiver, filter)
            android.util.Log.d("LockScreenOverlay", "🔥 关机/重启广播接收器已注册")
        } catch (e: Exception) {
            android.util.Log.e("LockScreenOverlay", "🔥 注册关机广播接收器失败: ${e.message}")
        }
    }
    
    /**
     * 🔥 注销关机/重启广播接收器
     */
    private fun unregisterShutdownReceiver() {
        try {
            shutdownReceiver?.let {
                unregisterReceiver(it)
                android.util.Log.d("LockScreenOverlay", "🔥 关机/重启广播接收器已注销")
            }
            shutdownReceiver = null
        } catch (e: Exception) {
            android.util.Log.e("LockScreenOverlay", "🔥 注销关机广播接收器失败: ${e.message}")
        }
    }
    
    private fun unlockScreen() {
        answerAttempts++  // 🔥 最后一次正确的也算一次
        android.util.Log.d("LockScreenOverlay", "答对问题，解锁屏幕，共答题${answerAttempts}次")
        
        // 🔥 发送解锁通知给锁机方
        sendUnlockPhoneReceive(answerAttempts)
        
        // 清除锁屏数据和答题次数
        prefs?.edit()
            ?.remove(KEY_SCREEN_LOCK)
            ?.remove("lock_answer_attempts")
            ?.apply()
        isScreenLockMode = false
        isAnsweringQuestion = false
        hideOverlay()
        // 停止前台服务并清除通知
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    /**
     * 🔥 发送解锁通知给锁机方（原生V2TIM发送自定义消息）
     */
    private fun sendUnlockPhoneReceive(attempts: Int) {
        try {
            // 从SharedPreferences读取锁机发送者ID
            val flutterPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val senderId = flutterPrefs.getString("flutter.lock_sender_id", null)
            
            if (senderId.isNullOrEmpty()) {
                android.util.Log.w("LockScreenOverlay", "🔓 未找到锁机发送者ID，无法发送解锁通知")
                return
            }
            
            // 构造unlock_phone_receive消息
            val msgData = JSONObject().apply {
                put("type", "unlock_phone_receive")
                put("attempts", attempts)
            }
            val msgBytes = msgData.toString().toByteArray()
            
            // 使用V2TIM SDK发送自定义消息
            val msg = V2TIMManager.getMessageManager().createCustomMessage(msgBytes)
            V2TIMManager.getMessageManager().sendMessage(
                msg, senderId, null,
                V2TIMMessage.V2TIM_PRIORITY_HIGH,
                false, null,
                object : V2TIMSendCallback<V2TIMMessage> {
                    override fun onSuccess(message: V2TIMMessage?) {
                        android.util.Log.d("LockScreenOverlay", "🔓 解锁通知已发送给锁机方: $senderId, 答题次数: $attempts")
                    }
                    override fun onError(code: Int, desc: String?) {
                        android.util.Log.e("LockScreenOverlay", "🔓 发送解锁通知失败: code=$code, desc=$desc")
                    }
                    override fun onProgress(progress: Int) {}
                }
            )
            
            // 清除发送者ID
            flutterPrefs.edit().remove("flutter.lock_sender_id").apply()
        } catch (e: Exception) {
            android.util.Log.e("LockScreenOverlay", "🔓 发送解锁通知异常: ${e.message}")
        }
    }
    
    private fun openMessagingApp() {
        android.util.Log.d("LockScreenOverlay", "openMessagingApp 被点击")
        try {
            val intent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_APP_MESSAGING)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
        } catch (e: Exception) {
            android.util.Log.e("LockScreenOverlay", "启动短信应用失败: ${e.message}")
            try {
                val intent = Intent(Intent.ACTION_VIEW).apply {
                    data = Uri.parse("sms:")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(intent)
            } catch (e2: Exception) { 
                android.util.Log.e("LockScreenOverlay", "备用方式启动短信也失败: ${e2.message}")
            }
        }
    }

    private fun openPhoneApp() {
        android.util.Log.d("LockScreenOverlay", "openPhoneApp 被点击")
        try {
            val intent = Intent(Intent.ACTION_DIAL).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
        } catch (e: Exception) { 
            android.util.Log.e("LockScreenOverlay", "启动电话应用失败: ${e.message}")
        }
    }

    /**
     * 🔥 轻微震动反馈（选择答案时）
     */
    private fun vibrateLight() {
        try {
            val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator ?: return
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator.vibrate(VibrationEffect.createOneShot(30, VibrationEffect.DEFAULT_AMPLITUDE))
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(30)
            }
        } catch (e: Exception) {
            android.util.Log.e("LockScreenOverlay", "震动失败: ${e.message}")
        }
    }

    private fun dp(value: Int): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            value.toFloat(),
            resources.displayMetrics
        ).toInt()
    }
    
    private fun loadCustomTypeface() {
        try {
            // Flutter assets 路径是 flutter_assets/...
            customTypeface = Typeface.createFromAsset(assets, "flutter_assets/assets/font/AlimamaShuHeiTi-Bold.ttf")
            android.util.Log.d("LockScreenOverlay", "自定义字体加载成功")
        } catch (e: Exception) {
            android.util.Log.e("LockScreenOverlay", "自定义字体加载失败: ${e.message}")
            customTypeface = Typeface.DEFAULT_BOLD
        }
    }

    private fun hideOverlay() {
        hideOverlayOnly()
        isScreenLockMode = false
        isAnsweringQuestion = false
    }
    
    private fun getPartnerNickname(): String {
        return try {
            val flutterPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            // 从Flutter存储的锁屏数据中获取另一半昵称
            flutterPrefs.getString("flutter.lock_partner_nickname", null) ?: "Ta"
        } catch (e: Exception) {
            "Ta"
        }
    }
    
    private fun loadPartnerAvatar(imageView: ImageView) {
        try {
            val flutterPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val avatarUrl = flutterPrefs.getString("flutter.lock_partner_avatar", null)
            
            if (!avatarUrl.isNullOrEmpty()) {
                // 在后台线程加载网络图片
                Thread {
                    try {
                        val url = java.net.URL(avatarUrl)
                        val connection = url.openConnection() as java.net.HttpURLConnection
                        connection.doInput = true
                        connection.connect()
                        val input = connection.inputStream
                        val bitmap = BitmapFactory.decodeStream(input)
                        input.close()
                        
                        // 裁剪为圆形
                        val circularBitmap = getCircularBitmap(bitmap)
                        
                        handler?.post {
                            imageView.setImageBitmap(circularBitmap)
                        }
                    } catch (e: Exception) {
                        android.util.Log.e("LockScreenOverlay", "加载头像失败: ${e.message}")
                    }
                }.start()
            }
        } catch (e: Exception) {
            android.util.Log.e("LockScreenOverlay", "获取头像URL失败: ${e.message}")
        }
    }
    
    private fun getCircularBitmap(bitmap: Bitmap): Bitmap {
        val size = minOf(bitmap.width, bitmap.height)
        val output = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)
        
        val paint = Paint().apply {
            isAntiAlias = true
            shader = BitmapShader(bitmap, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP)
        }
        
        canvas.drawCircle(size / 2f, size / 2f, size / 2f, paint)
        return output
    }
}
