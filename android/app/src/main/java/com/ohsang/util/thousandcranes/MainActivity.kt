package com.ohsang.util.thousandcranes

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Color
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.View
import android.webkit.JavascriptInterface
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebView
import android.webkit.WebViewClient
import android.window.OnBackInvokedDispatcher
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.webkit.WebViewAssetLoader

/**
 * 앱 화면은 assets/www/index.html (웹 프로토타입과 같은 접기·유리통 화면)을
 * WebView로 띄우고, 광고·진동·뒤로 가기만 네이티브에서 처리한다.
 * 기록은 WebView의 localStorage(앱 전용 저장소)에 남는다.
 */
class MainActivity : Activity() {

    private lateinit var web: WebView
    private lateinit var ads: RewardedAds

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val dark = (resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
        val bg = if (dark) Color.parseColor("#14151E") else Color.parseColor("#EEF0F4")

        WindowCompat.setDecorFitsSystemWindows(window, false)
        WindowCompat.getInsetsController(window, window.decorView).apply {
            isAppearanceLightStatusBars = !dark
            isAppearanceLightNavigationBars = !dark
        }

        val loader = WebViewAssetLoader.Builder()
            .addPathHandler("/assets/", WebViewAssetLoader.AssetsPathHandler(this))
            .build()

        web = WebView(this).apply {
            setBackgroundColor(bg)
            overScrollMode = View.OVER_SCROLL_NEVER
            settings.javaScriptEnabled = true
            settings.domStorageEnabled = true
            settings.textZoom = 100
            settings.allowFileAccess = false
            settings.allowContentAccess = false
            settings.mediaPlaybackRequiresUserGesture = true
            webViewClient = object : WebViewClient() {
                override fun shouldInterceptRequest(view: WebView, request: WebResourceRequest): WebResourceResponse? =
                    loader.shouldInterceptRequest(request.url)

                override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
                    val url = request.url
                    if (url.host == "appassets.androidplatform.net") return false
                    // 바깥 링크는 브라우저로 연다
                    runCatching { startActivity(Intent(Intent.ACTION_VIEW, url)) }
                    return true
                }
            }
            addJavascriptInterface(Bridge(), "Native")
        }

        // 상태 표시줄·내비게이션 바·카메라 홀만큼 안쪽으로 띄운다
        val root = android.widget.FrameLayout(this).apply { setBackgroundColor(bg) }
        root.addView(web)
        ViewCompat.setOnApplyWindowInsetsListener(root) { v, insets ->
            val bars = insets.getInsets(WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.displayCutout())
            val ime = insets.getInsets(WindowInsetsCompat.Type.ime())
            v.setPadding(bars.left, bars.top, bars.right, maxOf(bars.bottom, ime.bottom))
            WindowInsetsCompat.CONSUMED
        }
        setContentView(root)

        ads = RewardedAds(this) { result -> sendAdResult(result) }
        ads.init()

        if (savedInstanceState != null) web.restoreState(savedInstanceState)
        else web.loadUrl("https://appassets.androidplatform.net/assets/www/index.html")

        if (Build.VERSION.SDK_INT >= 33) {
            onBackInvokedDispatcher.registerOnBackInvokedCallback(OnBackInvokedDispatcher.PRIORITY_DEFAULT) { handleBack() }
        }
    }

    private fun handleBack() {
        web.evaluateJavascript("(window.onBackPressed && window.onBackPressed()) ? 'y' : 'n'") { r ->
            if (r?.contains("y") != true) finish()
        }
    }

    @Deprecated("API 32 이하 뒤로 가기")
    override fun onBackPressed() {
        handleBack()
    }

    private fun sendAdResult(result: String) {
        runOnUiThread { web.evaluateJavascript("window.onAdResult && window.onAdResult('$result')", null) }
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        web.saveState(outState)
    }

    override fun onResume() {
        super.onResume()
        web.onResume()
        // 날짜가 바뀌었으면 페이지가 visibilitychange에서 오늘의 색종이를 지급한다
    }

    override fun onPause() {
        web.onPause()
        super.onPause()
    }

    override fun onDestroy() {
        web.destroy()
        super.onDestroy()
    }

    inner class Bridge {
        @JavascriptInterface
        fun isDebug(): Boolean = BuildConfig.DEBUG

        @JavascriptInterface
        fun showRewardedAd() {
            runOnUiThread { ads.show() }
        }

        @JavascriptInterface
        fun vibrate(ms: Int) {
            val v: Vibrator? = if (Build.VERSION.SDK_INT >= 31) {
                (getSystemService(VIBRATOR_MANAGER_SERVICE) as? VibratorManager)?.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                getSystemService(VIBRATOR_SERVICE) as? Vibrator
            }
            runCatching { v?.vibrate(VibrationEffect.createOneShot(ms.coerceIn(5, 80).toLong(), 60)) }
        }

        @JavascriptInterface
        fun openUrl(url: String) {
            if (!url.startsWith("https://")) return
            runOnUiThread { runCatching { startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url))) } }
        }
    }
}
