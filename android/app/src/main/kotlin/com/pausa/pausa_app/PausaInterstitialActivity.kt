package com.pausa.pausa_app

import android.app.Activity
import android.app.ActivityManager
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
    private var blockedPackageName = ""
    private var appName = ""
    private var waitSeconds = 15
    private var maxMinutes = 20
    private var timeUp = false
    private var countdownCompleted = false
    private var countdownView: TextView? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        // Disable back gesture on Android 13+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            onBackInvokedDispatcher.registerOnBackInvokedCallback(
                android.window.OnBackInvokedDispatcher.PRIORITY_OVERLAY
            ) { /* back is disabled */ }
        }

        blockedPackageName = intent.getStringExtra("packageName") ?: run { finish(); return }
        appName = intent.getStringExtra("appName") ?: blockedPackageName
        waitSeconds = intent.getIntExtra("waitSeconds", 15)
        maxMinutes = intent.getIntExtra("maxMinutes", 20)
        timeUp = intent.getBooleanExtra("timeUp", false)

        // Exclude from recents
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val am = getSystemService(ACTIVITY_SERVICE) as ActivityManager
            am.appTasks?.firstOrNull()?.setExcludeFromRecents(true)
        }

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#0A0A0A"))
            setPadding(80, 80, 80, 80)
        }

        val logoView = ImageView(this).apply {
            setImageResource(R.drawable.splash_logo)
            scaleType = ImageView.ScaleType.FIT_CENTER
            layoutParams = LinearLayout.LayoutParams(120, 120).apply {
                gravity = Gravity.CENTER_HORIZONTAL
                bottomMargin = 40
            }
        }

        val titleView = TextView(this).apply {
            text = if (timeUp) "Tiempo agotado" else "Vas a abrir $appName"
            textSize = 22f
            setTextColor(Color.parseColor("#F0F0F0"))
            gravity = Gravity.CENTER
            setTypeface(typeface, Typeface.BOLD)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { gravity = Gravity.CENTER_HORIZONTAL; bottomMargin = 16 }
        }

        val subtitleView = TextView(this).apply {
            text = if (timeUp) "Has llegado al límite en $appName."
                   else "Tómate un momento antes de entrar."
            textSize = 15f
            setTextColor(Color.parseColor("#888888"))
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { gravity = Gravity.CENTER_HORIZONTAL; bottomMargin = 60 }
        }

        root.addView(logoView)
        root.addView(titleView)
        root.addView(subtitleView)

        if (timeUp) {
            val closeButton = Button(this).apply {
                text = "Cerrar"
                textSize = 14f
                setTextColor(Color.parseColor("#F0F0F0"))
                setBackgroundColor(Color.parseColor("#1A1A1A"))
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )
            }
            root.addView(closeButton)
            closeButton.setOnClickListener { goHome() }
        } else {
            val cdView = TextView(this).apply {
                text = waitSeconds.toString()
                textSize = 64f
                setTextColor(Color.parseColor("#E24B4A"))
                gravity = Gravity.CENTER
                setTypeface(typeface, Typeface.BOLD)
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply { gravity = Gravity.CENTER_HORIZONTAL; bottomMargin = 12 }
            }
            countdownView = cdView

            val countdownLabel = TextView(this).apply {
                text = "segundos para continuar"
                textSize = 13f
                setTextColor(Color.parseColor("#444444"))
                gravity = Gravity.CENTER
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply { gravity = Gravity.CENTER_HORIZONTAL; bottomMargin = 40 }
            }

            val motivationText = TextView(this).apply {
                text = "Tómate un momento. Tu futuro yo te lo agradecerá."
                textSize = 12f
                setTextColor(Color.parseColor("#444444"))
                gravity = Gravity.CENTER
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply { gravity = Gravity.CENTER_HORIZONTAL; topMargin = 40 }
            }

            root.addView(cdView)
            root.addView(countdownLabel)
            root.addView(motivationText)
        }

        setContentView(root)
    }

    // ── Back button disabled — all three methods ──────────────────────────────

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() { /* disabled */ }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_BACK) return true
        return super.onKeyDown(keyCode, event)
    }

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    override fun onResume() {
        super.onResume()
        if (!timeUp && !countdownCompleted) {
            countdownView?.text = waitSeconds.toString()
            startCountdown()
        }
    }

    override fun onPause() {
        super.onPause()
        if (!countdownCompleted) {
            countDownTimer?.cancel()
            countDownTimer = null
        }
    }

    override fun onStop() {
        super.onStop()
        if (!countdownCompleted) {
            countDownTimer?.cancel()
            countDownTimer = null
            PausaAccessibilityService.allowedApps.remove(blockedPackageName)
            PausaAccessibilityService.removeActiveTimer(blockedPackageName)
            if (!isFinishing) finish()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        countDownTimer?.cancel()
        if (!countdownCompleted) {
            PausaAccessibilityService.allowedApps.remove(blockedPackageName)
            PausaAccessibilityService.removeActiveTimer(blockedPackageName)
        }
    }

    // ── Countdown ─────────────────────────────────────────────────────────────

    private fun startCountdown() {
        countDownTimer?.cancel()
        countDownTimer = object : CountDownTimer(waitSeconds * 1000L, 1000) {
            override fun onTick(millisUntilFinished: Long) {
                countdownView?.text = ((millisUntilFinished / 1000).toInt() + 1).toString()
            }
            override fun onFinish() {
                countdownCompleted = true
                PausaAccessibilityService.allowApp(blockedPackageName)
                PausaAccessibilityService.addActiveTimer(blockedPackageName)
                if (maxMinutes > 0) {
                    startService(Intent(this@PausaInterstitialActivity, PausaTimerService::class.java).apply {
                        putExtra("packageName", blockedPackageName)
                        putExtra("appName", appName)
                        putExtra("maxMinutes", maxMinutes)
                    })
                }
                finish()
            }
        }.start()
    }

    private fun goHome() {
        startActivity(Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        })
        finish()
    }
}
