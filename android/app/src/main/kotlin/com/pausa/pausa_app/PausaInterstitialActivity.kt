package com.pausa.pausa_app

import android.app.Activity
import android.content.Intent
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
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

        // PAUSA logo drawn with Canvas (two rounded bars)
        val pausaLogoView = object : android.view.View(this) {
            override fun onDraw(canvas: Canvas) {
                super.onDraw(canvas)
                val paint = Paint().apply {
                    color = Color.parseColor("#F0F0F0")
                    style = Paint.Style.FILL
                    isAntiAlias = true
                }
                val w = width.toFloat()
                val h = height.toFloat()
                val barW = w * 0.28f
                val barH = h * 0.65f
                val barTop = h * 0.175f
                val radius = barW * 0.4f
                // Left bar
                canvas.drawRoundRect(
                    w * 0.12f, barTop,
                    w * 0.12f + barW, barTop + barH,
                    radius, radius, paint
                )
                // Right bar
                canvas.drawRoundRect(
                    w * 0.60f, barTop,
                    w * 0.60f + barW, barTop + barH,
                    radius, radius, paint
                )
            }
        }.apply {
            setBackgroundColor(Color.parseColor("#161616"))
            layoutParams = LinearLayout.LayoutParams(120, 120).apply {
                gravity = Gravity.CENTER_HORIZONTAL
                bottomMargin = 40
            }
        }

        val titleView = TextView(this).apply {
            text = if (timeUp) "Tiempo agotado en $appName" else "Vas a abrir $appName"
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
            text = if (timeUp) "Has alcanzado tu límite de tiempo."
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

        root.addView(pausaLogoView)
        root.addView(titleView)
        root.addView(subtitleView)

        if (timeUp) {
            val homeButton = Button(this).apply {
                text = "Volver al inicio"
                textSize = 14f
                setTextColor(Color.parseColor("#F0F0F0"))
                setBackgroundColor(Color.parseColor("#1A1A1A"))
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )
            }
            root.addView(homeButton)
            homeButton.setOnClickListener { goHome() }
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
                    // User waited — allow entry, remove from backgrounded set
                    // so AccessibilityService won't re-intercept immediately
                    val service = getAccessibilityService()
                    service?.allowPackage(blockedPackageName)

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

    private fun getAccessibilityService(): PausaAccessibilityService? {
        // Best-effort: service instance is not directly accessible across processes
        // but since they run in the same process we can use a singleton holder
        return PausaAccessibilityService.instance
    }

    private fun goHome() {
        countDownTimer?.cancel()
        // Keep blockedPackageName in backgroundedPausedApps — force re-intercept next open
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
