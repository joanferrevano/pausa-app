package com.pausa.pausa_app

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.os.Build
import android.os.Bundle
import android.os.CountDownTimer
import android.view.Gravity
import android.view.KeyEvent
import android.view.WindowManager
import android.widget.*

class PausaInterstitialActivity : Activity() {

    private var countDownTimer: CountDownTimer? = null
    private var packageName = ""
    private var appName = ""
    private var waitSeconds = 15
    private var maxMinutes = 20
    private var countdownCompleted = false
    private var countdownView: TextView? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        packageName = intent.getStringExtra("packageName") ?: run { finish(); return }
        appName = intent.getStringExtra("appName") ?: packageName
        waitSeconds = intent.getIntExtra("waitSeconds", 15)
        maxMinutes = intent.getIntExtra("maxMinutes", 20)

        // Disable back gesture on Android 13+
        if (Build.VERSION.SDK_INT >= 33) {
            onBackInvokedDispatcher.registerOnBackInvokedCallback(
                android.window.OnBackInvokedDispatcher.PRIORITY_OVERLAY
            ) { /* do nothing */ }
        }

        // Exclude from recents
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val am = getSystemService(ACTIVITY_SERVICE) as android.app.ActivityManager
            am.appTasks?.firstOrNull()?.setExcludeFromRecents(true)
        }

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#0A0A0A"))
            setPadding(80, 80, 80, 80)
        }

        val logoView = android.widget.ImageView(this).apply {
            setImageResource(R.drawable.splash_logo)
            scaleType = android.widget.ImageView.ScaleType.FIT_CENTER
            layoutParams = LinearLayout.LayoutParams(120, 120).apply {
                gravity = Gravity.CENTER_HORIZONTAL
                bottomMargin = 48
            }
        }

        val titleView = TextView(this).apply {
            text = "Vas a abrir $appName"
            textSize = 22f
            setTextColor(Color.parseColor("#F0F0F0"))
            gravity = Gravity.CENTER
            setTypeface(typeface, Typeface.BOLD)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                gravity = Gravity.CENTER_HORIZONTAL
                bottomMargin = 12
            }
        }

        val subtitleView = TextView(this).apply {
            text = "Tómate un momento antes de entrar."
            textSize = 14f
            setTextColor(Color.parseColor("#888888"))
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                gravity = Gravity.CENTER_HORIZONTAL
                bottomMargin = 64
            }
        }

        countdownView = TextView(this).apply {
            text = waitSeconds.toString()
            textSize = 72f
            setTextColor(Color.parseColor("#E24B4A"))
            gravity = Gravity.CENTER
            setTypeface(typeface, Typeface.BOLD)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                gravity = Gravity.CENTER_HORIZONTAL
                bottomMargin = 8
            }
        }

        val countdownLabel = TextView(this).apply {
            text = "segundos para continuar"
            textSize = 13f
            setTextColor(Color.parseColor("#444444"))
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                gravity = Gravity.CENTER_HORIZONTAL
                bottomMargin = 48
            }
        }

        val motivationText = TextView(this).apply {
            text = "Tómate un momento.\nTu futuro yo te lo agradecerá."
            textSize = 12f
            setTextColor(Color.parseColor("#333333"))
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                gravity = Gravity.CENTER_HORIZONTAL
            }
        }

        root.addView(logoView)
        root.addView(titleView)
        root.addView(subtitleView)
        root.addView(countdownView)
        root.addView(countdownLabel)
        root.addView(motivationText)
        setContentView(root)

        startCountdown()
    }

    private fun startCountdown() {
        countDownTimer?.cancel()
        countdownCompleted = false
        countdownView?.text = waitSeconds.toString()

        countDownTimer = object : CountDownTimer(waitSeconds * 1000L, 1000) {
            override fun onTick(millisUntilFinished: Long) {
                val secondsLeft = (millisUntilFinished / 1000).toInt() + 1
                countdownView?.text = secondsLeft.toString()
            }

            override fun onFinish() {
                countdownCompleted = true
                // Register active session BEFORE finishing
                // so AccessibilityService doesn't re-intercept
                PausaAccessibilityService.startSession(packageName)

                if (maxMinutes > 0) {
                    val timerIntent = Intent(
                        this@PausaInterstitialActivity,
                        PausaTimerService::class.java
                    ).apply {
                        putExtra("packageName", packageName)
                        putExtra("appName", appName)
                        putExtra("maxMinutes", maxMinutes)
                    }
                    startService(timerIntent)
                }
                finish()
            }
        }.start()
    }

    // Back button — completely disabled
    @Deprecated("Deprecated in Java")
    override fun onBackPressed() { /* do nothing */ }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_BACK) return true
        return super.onKeyDown(keyCode, event)
    }

    override fun onPause() {
        super.onPause()
        // Cancel countdown — will restart from beginning on resume
        if (!countdownCompleted) {
            countDownTimer?.cancel()
            countDownTimer = null
        }
    }

    override fun onResume() {
        super.onResume()
        // Always restart from beginning if countdown not completed
        if (!countdownCompleted) {
            startCountdown()
        }
    }

    override fun onStop() {
        super.onStop()
        if (!countdownCompleted) {
            countDownTimer?.cancel()
            countDownTimer = null
            PausaAccessibilityService.endSession(packageName)
            if (!isFinishing) finish()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        countDownTimer?.cancel()
    }
}
