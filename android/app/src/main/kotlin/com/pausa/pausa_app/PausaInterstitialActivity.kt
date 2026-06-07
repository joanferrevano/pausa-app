package com.pausa.pausa_app

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.os.Bundle
import android.os.CountDownTimer
import android.view.Gravity
import android.view.WindowManager
import android.widget.*

class PausaInterstitialActivity : Activity() {

    private var countDownTimer: CountDownTimer? = null
    private var blockedPackageName = ""

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        blockedPackageName = intent.getStringExtra("packageName") ?: run { finish(); return }
        val appName = intent.getStringExtra("appName") ?: blockedPackageName
        val waitSeconds = intent.getIntExtra("waitSeconds", 15)
        val maxMinutes = intent.getIntExtra("maxMinutes", 20)
        val timeUp = intent.getBooleanExtra("timeUp", false)

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
            ).apply {
                gravity = Gravity.CENTER_HORIZONTAL
                bottomMargin = 16
            }
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
            ).apply {
                gravity = Gravity.CENTER_HORIZONTAL
                bottomMargin = 60
            }
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
            setContentView(root)
        } else {
            val countdownView = TextView(this).apply {
                text = waitSeconds.toString()
                textSize = 64f
                setTextColor(Color.parseColor("#E24B4A"))
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
                    bottomMargin = 60
                }
            }

            val cancelButton = Button(this).apply {
                text = "No, mejor no"
                textSize = 14f
                setTextColor(Color.parseColor("#888888"))
                setBackgroundColor(Color.TRANSPARENT)
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply { bottomMargin = 16 }
            }

            root.addView(countdownView)
            root.addView(countdownLabel)
            root.addView(cancelButton)
            setContentView(root)

            cancelButton.setOnClickListener {
                countDownTimer?.cancel()
                goHome()
            }

            countDownTimer = object : CountDownTimer(waitSeconds * 1000L, 1000) {
                override fun onTick(millisUntilFinished: Long) {
                    val secondsLeft = (millisUntilFinished / 1000).toInt() + 1
                    countdownView.text = secondsLeft.toString()
                }

                override fun onFinish() {
                    // 3-second whitelist — just enough for the app to open
                    PausaAccessibilityService.allowApp(blockedPackageName)
                    // Register active timer so service won't re-intercept while inside
                    PausaAccessibilityService.addActiveTimer(blockedPackageName)

                    if (maxMinutes > 0) {
                        val timerIntent = Intent(
                            this@PausaInterstitialActivity,
                            PausaTimerService::class.java
                        ).apply {
                            putExtra("packageName", blockedPackageName)
                            putExtra("appName", appName)
                            putExtra("maxMinutes", maxMinutes)
                        }
                        startService(timerIntent)
                    }
                    finish()
                }
            }.start()
        }
    }

    private fun goHome() {
        countDownTimer?.cancel()
        // Do NOT whitelist — force re-intercept next time user opens the app
        val homeIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(homeIntent)
        finish()
    }

    override fun onDestroy() {
        super.onDestroy()
        countDownTimer?.cancel()
    }
}
