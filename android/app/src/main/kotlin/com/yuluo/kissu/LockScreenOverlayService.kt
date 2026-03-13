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
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest
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
    private var bgImageView: ImageView? = null  // 锁屏背景图ImageView
    private var lockScreenContainerTop: FrameLayout? = null  // 锁屏主视图容器上方灰色背景
    private var questionContainer: FrameLayout? = null    // 答题视图容器
    private var questionText: String = "什么马不能骑？"
    private var answerOptions: List<String> = listOf("海马", "河马", "斑马", "木马")
    private var correctAnswerIndex: Int = 0
    private var answerAttempts: Int = 0  // 🔥 答题次数计数器
    private val triedAnswerIndices = mutableSetOf<Int>()  // 🔥 已尝试的答案索引集合
    private var shutdownReceiver: BroadcastReceiver? = null  // 🔥 关机/重启广播接收器
    
    // 锁屏界面显示信息
    private var lockText: String = ""           // 锁屏文案
    private var bgImageIndex: Int = 0           // 背景图片索引
    private var bgImageUrl: String = ""         // 网络背景图片URL
    
    // Intent传递的数据（优先级高于SharedPreferences）
    private var intentLockText: String = ""
    private var intentBgImagePath: String = ""

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
        // 从Intent extras读取lockText和bgImagePath（优先级高于SharedPreferences）
        var hasNewData = false
        intent?.getStringExtra("lock_text")?.let {
            if (it.isNotEmpty()) {
                intentLockText = it
                hasNewData = true
                android.util.Log.d("LockScreenOverlay", "从Intent读取lockText: $it")
            }
        }
        intent?.getStringExtra("bg_image_path")?.let {
            if (it.isNotEmpty()) {
                intentBgImagePath = it
                hasNewData = true
                android.util.Log.d("LockScreenOverlay", "从Intent读取bgImagePath: $it")
            }
        }
        acquireWakeLock()
        scheduleRestartAlarm()
        if (checkRunnable == null || handler == null) {
            handler = Handler(Looper.getMainLooper())
            startMonitoring()
        }
        // 如果overlay已经在显示且收到了新数据，刷新overlay以使用最新的lockText/bgImage
        if (hasNewData && isOverlayShowing) {
            android.util.Log.d("LockScreenOverlay", "收到新数据，刷新overlay: lockText=$intentLockText, bgImagePath=$intentBgImagePath")
            handler?.post { showOverlay() }
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
        bgImageView = null
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
        
        // 锁屏背景图（ImageView，支持 CENTER_CROP 全屏铺满）
        bgImageView = ImageView(context).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
            scaleType = ImageView.ScaleType.CENTER_CROP
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

        // 灰色遮罩层
        try {
            lockScreenContainerTop?.background = ContextCompat.getDrawable(context, R.drawable.kissu_lock_gray_bg)
        } catch (_: Exception) {}

        // 背景图片 - 优先本地文件，其次网络URL，最后预设图
        try {
            if (bgImageUrl.isNotEmpty()) {
                val file = java.io.File(bgImageUrl)
                if (file.exists()) {
                    loadLocalBgImage(file.absolutePath, screenWidth, screenHeight)
                } else if (bgImageUrl.startsWith("http")) {
                    loadNetworkBgImage(bgImageUrl, screenWidth, screenHeight)
                } else {
                    setFallbackBackground(context)
                }
            } else {
                setFallbackBackground(context)
            }
        } catch (e: Exception) {
            android.util.Log.e("LockScreenOverlay", "背景图加载异常: ${e.message}")
            setFallbackBackground(context)
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
        rootContainer.addView(bgImageView)
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
        triedAnswerIndices.clear()  // 🔥 重置已尝试的答案集合
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
    
    private fun setFallbackBackground(context: Context) {
        try {
            val bgResId = when (bgImageIndex) {
                0 -> R.drawable.kissu_lock_bg_1
                1 -> R.drawable.kissu_lock_bg_2
                2 -> R.drawable.kissu_lock_bg_3
                else -> R.drawable.kissu_lock_bg_1
            }
            bgImageView?.setImageResource(bgResId)
        } catch (_: Exception) {}
    }

    /** OOM安全：根据目标尺寸计算 inSampleSize 后再解码本地图片 */
    private fun loadLocalBgImage(filePath: String, reqWidth: Int, reqHeight: Int) {
        try {
            val bitmap = decodeSampledBitmap(filePath, reqWidth, reqHeight)
            if (bitmap != null) {
                bgImageView?.setImageBitmap(bitmap)
                android.util.Log.d("LockScreenOverlay", "本地背景图加载成功: ${bitmap.width}x${bitmap.height}")
            } else {
                setFallbackBackground(this)
            }
        } catch (e: Exception) {
            android.util.Log.e("LockScreenOverlay", "本地背景图加载失败: ${e.message}")
            setFallbackBackground(this)
        }
    }

    /** 异步下载网络图片，解码后设置到 ImageView */
    private fun loadNetworkBgImage(url: String, reqWidth: Int, reqHeight: Int) {
        // 先显示预设图兜底，网络图加载成功后替换
        setFallbackBackground(this)
        Thread {
            var connection: java.net.HttpURLConnection? = null
            try {
                connection = (java.net.URL(url).openConnection() as java.net.HttpURLConnection).apply {
                    connectTimeout = 8000
                    readTimeout = 8000
                    doInput = true
                }
                connection.connect()
                // 读到字节数组以便两次解码（先取尺寸再采样）
                val bytes = connection.inputStream.use { it.readBytes() }
                val bitmap = decodeSampledBitmapFromBytes(bytes, reqWidth, reqHeight)
                if (bitmap != null) {
                    handler?.post {
                        bgImageView?.setImageBitmap(bitmap)
                        android.util.Log.d("LockScreenOverlay", "网络背景图加载成功: ${bitmap.width}x${bitmap.height}")
                    }
                }
            } catch (e: Exception) {
                android.util.Log.e("LockScreenOverlay", "网络背景图加载失败: ${e.message}")
            } finally {
                connection?.disconnect()
            }
        }.start()
    }

    /** 从本地文件路径 OOM安全解码 */
    private fun decodeSampledBitmap(filePath: String, reqWidth: Int, reqHeight: Int): Bitmap? {
        val options = BitmapFactory.Options()
        options.inJustDecodeBounds = true
        BitmapFactory.decodeFile(filePath, options)
        options.inSampleSize = calculateInSampleSize(options, reqWidth, reqHeight)
        options.inJustDecodeBounds = false
        return BitmapFactory.decodeFile(filePath, options)
    }

    /** 从字节数组 OOM安全解码 */
    private fun decodeSampledBitmapFromBytes(bytes: ByteArray, reqWidth: Int, reqHeight: Int): Bitmap? {
        val options = BitmapFactory.Options()
        options.inJustDecodeBounds = true
        BitmapFactory.decodeByteArray(bytes, 0, bytes.size, options)
        options.inSampleSize = calculateInSampleSize(options, reqWidth, reqHeight)
        options.inJustDecodeBounds = false
        return BitmapFactory.decodeByteArray(bytes, 0, bytes.size, options)
    }

    /** 计算合适的 inSampleSize，保证解码后尺寸 >= 目标尺寸 */
    private fun calculateInSampleSize(options: BitmapFactory.Options, reqWidth: Int, reqHeight: Int): Int {
        val (rawW, rawH) = options.outWidth to options.outHeight
        var inSampleSize = 1
        if (rawW > reqWidth || rawH > reqHeight) {
            val halfW = rawW / 2
            val halfH = rawH / 2
            while (halfW / inSampleSize >= reqWidth && halfH / inSampleSize >= reqHeight) {
                inSampleSize *= 2
            }
        }
        return inSampleSize
    }

    private fun loadLockScreenDisplayData() {
        try {
            // 从Flutter SharedPreferences加载锁屏界面显示信息
            // 注意：Flutter的SharedPreferences使用不同的文件名
            val flutterPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            lockText = flutterPrefs.getString("flutter.lock_text", "") ?: ""
            bgImageIndex = flutterPrefs.getLong("flutter.lock_bg_image_index", 0L).toInt()
            // 优先读取本地文件路径（Flutter侧已预下载），兜底读URL
            bgImageUrl = flutterPrefs.getString("flutter.lock_bg_image_local_path", "") ?: ""
            if (bgImageUrl.isEmpty()) {
                bgImageUrl = flutterPrefs.getString("flutter.lock_bg_image_url", "") ?: ""
            }
            // Intent传递的数据优先级最高，覆盖SharedPreferences的值
            if (intentLockText.isNotEmpty()) {
                lockText = intentLockText
                android.util.Log.d("LockScreenOverlay", "使用Intent传递的lockText: $lockText")
            }
            if (intentBgImagePath.isNotEmpty()) {
                bgImageUrl = intentBgImagePath
                android.util.Log.d("LockScreenOverlay", "使用Intent传递的bgImagePath: $bgImageUrl")
            }
            android.util.Log.d("LockScreenOverlay", "加载锁屏显示数据: lockText=$lockText, bgIndex=$bgImageIndex, bgImageUrl=$bgImageUrl")
        } catch (e: Exception) {
            android.util.Log.e("LockScreenOverlay", "加载锁屏显示数据失败: ${e.message}")
            lockText = ""
            bgImageIndex = 0
            bgImageUrl = ""
        }
    }
    
    private fun showQuestionView() {
        bgImageView?.visibility = View.GONE
        lockScreenContainerTop?.visibility = View.GONE
        questionContainer?.visibility = View.VISIBLE
        // 重新创建答题视图内容
        questionContainer?.removeAllViews()
        questionContainer?.addView(createQuestionContent())
    }
    
    private fun showLockScreenView() {
        isAnsweringQuestion = false
        questionContainer?.visibility = View.GONE
        bgImageView?.visibility = View.VISIBLE
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
            setPadding(dp(40), dp(40), dp(40), dp(40))
            setLineSpacing(0f, 1.6f)   // 行高 = 1.4倍
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
        isAnswerLocked = true  // 🔥 锁定
        
        // 🔥 轻微震动反馈
        vibrateLight()
        
        // 记录已尝试的答案索引
        triedAnswerIndices.add(index)
        
        // 🔥 使用本地答案立即判断正误，不等待API返回
        val isCorrect = (index == correctAnswerIndex)
        android.util.Log.d("LockScreenOverlay", "选择答案: $index, 本地正确答案: $correctAnswerIndex, 结果: ${if (isCorrect) "正确" else "错误"}")
        
        // 埋点6: 保存答题事件到FlutterSharedPreferences供Flutter上报
        saveAnswerAnalyticsEvent(if (isCorrect) 1 else 0)
        
        if (isCorrect) {
            // 答对了，立即显示正确状态
            try {
                button.background = resources.getDrawable(R.drawable.kissu_lock_right_bg, null)
            } catch (e: Exception) {
                android.util.Log.e("LockScreenOverlay", "加载正确答案背景图片失败: ${e.message}")
            }
            // 异步调用API（不阻塞UI）
            callUnlockApiWithAnswer(index) { _ -> }
            // 立即显示成功弹窗
            showSuccessDialog()
        } else {
            // 答错了，立即显示错误状态
            try {
                button.background = resources.getDrawable(R.drawable.kissu_lock_wrong_bg, null)
            } catch (e: Exception) {
                android.util.Log.e("LockScreenOverlay", "加载错误答案背景图片失败: ${e.message}")
            }
            button.setTextColor(Color.parseColor("#FF6B6B"))
            answerAttempts++  // 🔥 答错计数
            
            // 异步调用API（不阻塞UI）
            callUnlockApiWithAnswer(index) { _ -> }
            
            // 🔥 检查是否4个答案都尝试过且都错误，自动解锁
            if (triedAnswerIndices.size >= 4) {
                android.util.Log.d("LockScreenOverlay", "4个答案都尝试错误，自动解锁")
                handler?.postDelayed({
                    // 自动解锁：显示成功弹窗并解锁
                    showSuccessDialog()
                }, 800)
                return
            }
            
            // 短暂延迟后重置
            handler?.postDelayed({
                try {
                    button.background = resources.getDrawable(R.drawable.kissu_lock_answer_bg, null)
                } catch (e: Exception) {
                    android.util.Log.e("LockScreenOverlay", "重置答案背景图片失败: ${e.message}")
                }
                button.setTextColor(Color.parseColor("#333333"))
                isAnswerLocked = false  // 🔥 答错后解锁，允许重新选择
            }, 800)
        }
    }
    
    /**
     * 埋点6: 保存答题选择事件到FlutterSharedPreferences
     * Flutter侧会在锁屏解除后读取并上报这些事件
     * @param unlockStatus 1=解锁成功(答对) 0=解锁失败(答错)
     */
    private fun saveAnswerAnalyticsEvent(unlockStatus: Int) {
        try {
            val flutterPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val existingJson = flutterPrefs.getString("flutter.lock_answer_analytics_events", "[]") ?: "[]"
            val arr = org.json.JSONArray(existingJson)
            val event = org.json.JSONObject().apply {
                put("unlock_status", unlockStatus)
                put("click_time", System.currentTimeMillis() / 1000)
            }
            arr.put(event)
            flutterPrefs.edit().putString("flutter.lock_answer_analytics_events", arr.toString()).apply()
            android.util.Log.d("LockScreenOverlay", "埋点6: 保存答题事件 unlockStatus=$unlockStatus, 总计${arr.length()}条")
        } catch (e: Exception) {
            android.util.Log.e("LockScreenOverlay", "保存答题埋点事件失败: ${e.message}")
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
        android.util.Log.d("LockScreenOverlay", "答对问题，解锁屏幕（API已在选择答案时调用）")
        
        // 🔥 发送解锁通知给锁机方（IM兜底，确保锁机方收到通知）
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
     * 🔥 调用解锁API: POST /unlock/user/phone
     * 被动解锁 unlock_type=2, unlock_answer_index=选择的答案索引(0-based: 0,1,2,3)
     * @param answerIndex 选择的答案索引，从0开始
     * @param callback 回调，true=答对（API成功），false=答错（API失败）
     */
    private fun callUnlockApiWithAnswer(answerIndex: Int, callback: (Boolean) -> Unit) {
        Thread {
            var connection: HttpURLConnection? = null
            try {
                val kissuPrefs = getSharedPreferences("kissu_preferences", Context.MODE_PRIVATE)
                val token = kissuPrefs.getString("user_token", null)
                val baseUrl = kissuPrefs.getString("base_api_url", "https://service-api.ikissu.cn")
                
                if (token.isNullOrEmpty()) {
                    android.util.Log.w("LockScreenOverlay", "🔓 无用户token，跳过解锁API调用")
                    callback(false)
                    return@Thread
                }
                
                val apiUrl = "$baseUrl/unlock/user/phone"
                android.util.Log.d("LockScreenOverlay", "🔓 调用解锁API: $apiUrl, answer_index=$answerIndex")
                
                // 准备请求头
                val headers = mutableMapOf(
                    "Content-Type" to "application/json; charset=UTF-8",
                    "Accept" to "application/json",
                    "token" to token,
                    "version" to getAppVersionForApi(),
                    "pkg" to packageName,
                    "deviceid" to getDeviceIdForApi(),
                    "channel" to (getSharedPreferences("kissu_preferences", android.content.Context.MODE_PRIVATE).getString("app_channel", null) ?: "kissu_android"),
                    "os" to "1"
                )
                
                // 准备请求体
                val bodyParams = mapOf(
                    "unlock_type" to "2",
                    "unlock_answer_index" to answerIndex.toString()
                )
                
                // 生成签名
                val sign = generateSignForApi(headers, bodyParams)
                headers["sign"] = sign
                
                // 创建连接
                val url = URL(apiUrl)
                connection = (url.openConnection() as HttpURLConnection).apply {
                    requestMethod = "POST"
                    doOutput = true
                    doInput = true
                    connectTimeout = 10000
                    readTimeout = 10000
                    headers.forEach { (key, value) -> setRequestProperty(key, value) }
                }
                
                // 发送请求体
                val requestBody = JSONObject().apply {
                    put("unlock_type", 2)
                    put("unlock_answer_index", answerIndex)
                }
                OutputStreamWriter(connection.outputStream, Charsets.UTF_8).use { writer ->
                    writer.write(requestBody.toString())
                    writer.flush()
                }
                
                val responseCode = connection.responseCode
                if (responseCode == HttpURLConnection.HTTP_OK) {
                    val response = connection.inputStream.bufferedReader().use { it.readText() }
                    android.util.Log.d("LockScreenOverlay", "🔓 解锁API成功（答对）: $response")
                    // 解析响应判断是否成功
                    val jsonResponse = JSONObject(response)
                    val code = jsonResponse.optInt("code", -1)
                    callback(code == 200 || code == 0)
                } else {
                    val errorResponse = connection.errorStream?.bufferedReader()?.use { it.readText() } ?: ""
                    android.util.Log.d("LockScreenOverlay", "🔓 解锁API返回非200（答错）: $responseCode, $errorResponse")
                    callback(false)
                }
            } catch (e: Exception) {
                android.util.Log.e("LockScreenOverlay", "🔓 解锁API异常: ${e.message}")
                callback(false)
            } finally {
                connection?.disconnect()
            }
        }.start()
    }

    private fun getAppVersionForApi(): String {
        return try {
            val pInfo = packageManager.getPackageInfo(packageName, 0)
            pInfo.versionName ?: "1.0.0"
        } catch (e: Exception) { "1.0.0" }
    }

    private fun getDeviceIdForApi(): String {
        return try {
            android.provider.Settings.Secure.getString(contentResolver, android.provider.Settings.Secure.ANDROID_ID) ?: "unknown"
        } catch (e: Exception) { "unknown" }
    }

    private fun generateSignForApi(headers: Map<String, String>, bodyParams: Map<String, String>): String {
        val secretKey = "TYXHTRrGeP8xy095q0iY"
        val allParams = mutableMapOf<String, String>()
        val businessHeaders = setOf("channel", "version", "deviceid", "pkg", "token", "userid")
        headers.forEach { (key, value) ->
            if (businessHeaders.contains(key.lowercase())) {
                allParams[key.lowercase()] = value
            }
        }
        allParams.putAll(bodyParams)
        val sortedKeys = allParams.keys.sorted()
        val signBuilder = StringBuilder()
        sortedKeys.forEach { key -> signBuilder.append(allParams[key]) }
        signBuilder.append(secretKey)
        val md = MessageDigest.getInstance("MD5")
        val digest = md.digest(signBuilder.toString().toByteArray())
        return digest.joinToString("") { "%02x".format(it) }.uppercase()
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
