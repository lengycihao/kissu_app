package com.yuluo.kissu

import android.app.*
import android.content.Context
import android.content.Intent
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
import java.text.SimpleDateFormat
import java.util.*

class LockScreenOverlayService : Service() {

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var handler: Handler? = null
    private var checkRunnable: Runnable? = null
    private var prefs: SharedPreferences? = null

    private var isScreenLockMode = false
    private var screenLockEndTime: Long = 0
    private var remainingSeconds: Long = 0
    private var isOverlayShowing = false
    private var isAnsweringQuestion = false // 是否正在答题页面

    // 锁屏UI
    private var timeTextView: TextView? = null
    private var timeUpdateRunnable: Runnable? = null
    
    // 答题页面相关
    private var lockScreenContainer: FrameLayout? = null  // 锁屏主视图容器
    private var questionContainer: FrameLayout? = null    // 答题视图容器
    private var questionText: String = "什么马不能骑？"
    private var answerOptions: List<String> = listOf("海马", "河马", "斑马", "木马")
    private var correctAnswerIndex: Int = 0
    
    // 锁屏界面显示信息
    private var lockText: String = ""           // 锁屏文案
    private var bgImageIndex: Int = 0           // 背景图片索引

    // 保活
    private var wakeLock: PowerManager.WakeLock? = null

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

        acquireWakeLock()
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createNotification())
        scheduleRestartAlarm()
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
        // 创建一个静默的、最小化的通知（用户几乎看不到）
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setPriority(NotificationCompat.PRIORITY_MIN)  // 最低优先级
            .setVisibility(NotificationCompat.VISIBILITY_SECRET)  // 锁屏不显示
            .setSilent(true)
            .setOngoing(true)
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

    private fun checkScreenLock() {
        val screenLockJson = prefs?.getString(KEY_SCREEN_LOCK, null)
        if (screenLockJson != null) {
            try {
                val obj = JSONObject(screenLockJson)
                val endTime = obj.optLong("endTime", 0)
                val currentTime = System.currentTimeMillis()
                if (currentTime < endTime) {
                    screenLockEndTime = endTime
                    remainingSeconds = (endTime - currentTime) / 1000
                    // 如果正在答题，不要重新显示悬浮窗
                    if (!isScreenLockMode || (!isOverlayShowing && !isAnsweringQuestion)) {
                        isScreenLockMode = true
                        showOverlay()
                    }
                } else {
                    if (isScreenLockMode) {
                        removeScreenLock()
                        hideOverlay()
                    }
                }
            } catch (e: Exception) { e.printStackTrace() }
        } else {
            if (isScreenLockMode) {
                isScreenLockMode = false
                hideOverlay()
            }
        }
    }

    private fun removeScreenLock() {
        isScreenLockMode = false
        screenLockEndTime = 0
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
            val bgDrawable = ContextCompat.getDrawable(context, bgResId)
            lockScreenContainer?.background = bgDrawable
        } catch (e: Exception) {
            // 如果加载失败，使用默认背景
            try {
                val bgDrawable = ContextCompat.getDrawable(context, R.drawable.kissu_lock_bg)
                lockScreenContainer?.background = bgDrawable
            } catch (e2: Exception) {
                lockScreenContainer?.background = GradientDrawable(
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
        lockScreenContainer?.addView(timeLayout, timeParams)

        timeTextView = TextView(context).apply {
            text = SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date())
            textSize = 72f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            typeface = Typeface.DEFAULT_BOLD
            setShadowLayer(8f, 2f, 2f, Color.parseColor("#40000000"))
        }
        timeLayout.addView(timeTextView)

        startTimeUpdate()

        val hintText = TextView(context).apply {
            text = "手机已经被Ta锁定"
            textSize = 28f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding(dp(20), dp(8), dp(20), dp(8))
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#40000000"))
                cornerRadius = dp(20).toFloat()
            }
        }
        timeLayout.addView(hintText)
        
        // 用户信息模块（头像、昵称、锁屏文案）- 只有当有锁屏文案时才显示
        if (lockText.isNotEmpty()) {
            // 外层容器：垂直排列（头像昵称行 + 文案）
            val userInfoCard = LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                setPadding(dp(16), dp(12), dp(16), dp(12))
                background = GradientDrawable().apply {
                    setColor(Color.parseColor("#4D000000"))
                    cornerRadius = dp(12).toFloat()
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
                textSize = 14f
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
            
            val userInfoParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                gravity = Gravity.TOP
                topMargin = dp(260)
                leftMargin = dp(24)
                rightMargin = dp(24)
            }
            lockScreenContainer?.addView(userInfoCard, userInfoParams)
        }

        // 答对问题解锁按钮
        val unlockButton = TextView(context).apply {
            text = "答对问题，解锁手机"
            textSize = 16f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding(dp(24), dp(14), dp(24), dp(14))
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#4DFFFFFF"))
                cornerRadius = dp(28).toFloat()
            }
            isClickable = true
            isFocusable = true
            setOnClickListener { openQuestionPage() }
        }
        val unlockParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.WRAP_CONTENT,
            dp(56)
        ).apply {
            gravity = Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
            bottomMargin = dp(120)
        }
        lockScreenContainer?.addView(unlockButton, unlockParams)

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
            leftMargin = dp(24)
            rightMargin = dp(24)
        }
        lockScreenContainer?.addView(bottomLayout, bottomParams)

        val messageButton = TextView(context).apply {
            text = "💬"
            textSize = 28f
            gravity = Gravity.CENTER
            setPadding(dp(16), dp(12), dp(16), dp(12))
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#4dffffff"))
                cornerRadius = dp(25).toFloat()
            }
            isClickable = true
            isFocusable = true
            setOnClickListener { openMessagingApp() }
        }
        bottomLayout.addView(messageButton)

        val spacer = View(context)
        bottomLayout.addView(spacer, LinearLayout.LayoutParams(0, 1, 1f))

        val phoneButton = TextView(context).apply {
            text = "📞"
            textSize = 28f
            gravity = Gravity.CENTER
            setPadding(dp(16), dp(12), dp(16), dp(12))
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#4dffffff"))
                cornerRadius = dp(25).toFloat()
            }
            isClickable = true
            isFocusable = true
            setOnClickListener { openPhoneApp() }
        }
        bottomLayout.addView(phoneButton)

        // 将两个容器添加到根容器
        rootContainer.addView(lockScreenContainer)
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
        // 加载问题数据
        loadQuestionData()
        // 在悬浮窗内切换到答题视图
        showQuestionView()
    }
    
    private fun loadQuestionData() {
        try {
            questionText = prefs?.getString("lock_question", "什么马不能骑？") ?: "什么马不能骑？"
            val answersJson = prefs?.getString("lock_answers", "[\"海马\",\"河马\",\"斑马\",\"木马\"]") ?: "[\"海马\",\"河马\",\"斑马\",\"木马\"]"
            correctAnswerIndex = prefs?.getInt("lock_correct_index", 0) ?: 0
            
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
        questionContainer?.visibility = View.VISIBLE
        // 重新创建答题视图内容
        questionContainer?.removeAllViews()
        questionContainer?.addView(createQuestionContent())
    }
    
    private fun showLockScreenView() {
        isAnsweringQuestion = false
        questionContainer?.visibility = View.GONE
        lockScreenContainer?.visibility = View.VISIBLE
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
            typeface = Typeface.DEFAULT_BOLD
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
        
        // 黑板区域（问题显示）
        val blackboard = FrameLayout(context).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#D4903C"))
                cornerRadius = dp(16).toFloat()
            }
            setPadding(dp(4), dp(4), dp(4), dp(4))
        }
        
        val innerBoard = FrameLayout(context).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.WRAP_CONTENT
            )
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#2D7D4F"))
                cornerRadius = dp(12).toFloat()
            }
            setPadding(dp(24), dp(40), dp(24), dp(40))
        }
        
        val questionTextView = TextView(context).apply {
            text = questionText
            textSize = 22f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            typeface = Typeface.DEFAULT_BOLD
        }
        innerBoard.addView(questionTextView)
        blackboard.addView(innerBoard)
        container.addView(blackboard)
        
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
                setPadding(dp(16), dp(16), dp(16), dp(16))
                background = GradientDrawable().apply {
                    setColor(Color.WHITE)
                    cornerRadius = dp(12).toFloat()
                    setStroke(dp(1), Color.parseColor("#EEEEEE"))
                }
                isClickable = true
                isFocusable = true
                setOnClickListener { onAnswerSelected(index, this) }
            }
            val optionParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = dp(12)
            }
            container.addView(optionButton, optionParams)
        }
        
        return container
    }
    
    private fun onAnswerSelected(index: Int, button: TextView) {
        android.util.Log.d("LockScreenOverlay", "选择答案: $index, 正确答案: $correctAnswerIndex")
        if (index == correctAnswerIndex) {
            // 答对了，解锁
            button.background = GradientDrawable().apply {
                setColor(Color.WHITE)
                cornerRadius = dp(12).toFloat()
                setStroke(dp(2), Color.parseColor("#FF7ECE"))
            }
            handler?.postDelayed({
                unlockScreen()
            }, 300)
        } else {
            // 答错了，显示错误状态
            button.background = GradientDrawable().apply {
                setColor(Color.parseColor("#FFF0F0"))
                cornerRadius = dp(12).toFloat()
                setStroke(dp(2), Color.parseColor("#FF6B6B"))
            }
            button.setTextColor(Color.parseColor("#FF6B6B"))
            // 短暂延迟后重置
            handler?.postDelayed({
                button.background = GradientDrawable().apply {
                    setColor(Color.WHITE)
                    cornerRadius = dp(12).toFloat()
                    setStroke(dp(1), Color.parseColor("#EEEEEE"))
                }
                button.setTextColor(Color.parseColor("#333333"))
            }, 800)
        }
    }
    
    private fun unlockScreen() {
        android.util.Log.d("LockScreenOverlay", "答对问题，解锁屏幕")
        // 清除锁屏数据
        prefs?.edit()?.remove(KEY_SCREEN_LOCK)?.apply()
        isScreenLockMode = false
        isAnsweringQuestion = false
        hideOverlay()
    }

    private fun openMessagingApp() {
        android.util.Log.d("LockScreenOverlay", "openMessagingApp 被点击")
        try {
            val intent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_APP_MESSAGING)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            android.util.Log.d("LockScreenOverlay", "短信应用已启动")
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
            android.util.Log.d("LockScreenOverlay", "电话应用已启动")
        } catch (e: Exception) { 
            android.util.Log.e("LockScreenOverlay", "启动电话应用失败: ${e.message}")
        }
    }

    private fun dp(value: Int): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            value.toFloat(),
            resources.displayMetrics
        ).toInt()
    }

    private fun hideOverlay() {
        timeUpdateRunnable?.let { handler?.removeCallbacks(it) }
        overlayView?.let {
            try { windowManager?.removeView(it) } catch (e: Exception) { e.printStackTrace() }
        }
        overlayView = null
        isOverlayShowing = false
        isScreenLockMode = false
        isAnsweringQuestion = false
        timeTextView = null
        lockScreenContainer = null
        questionContainer = null
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
