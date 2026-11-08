package com.ohsang.util.thousandcranes

import android.app.Activity
import com.google.android.gms.ads.AdError
import com.google.android.gms.ads.AdRequest
import com.google.android.gms.ads.FullScreenContentCallback
import com.google.android.gms.ads.LoadAdError
import com.google.android.gms.ads.MobileAds
import com.google.android.gms.ads.rewarded.RewardedAd
import com.google.android.gms.ads.rewarded.RewardedAdLoadCallback

/**
 * "광고 보고 색종이 5장 더 받기"용 보상형 광고.
 * 결과는 페이지의 window.onAdResult로 넘긴다: reward / closed / unavailable
 * 광고 단위 ID는 빌드 때 ADMOB_REWARDED_ID로 넣고, 없으면 Google 테스트 광고가 나온다.
 */
class RewardedAds(
    private val activity: Activity,
    private val onResult: (String) -> Unit,
) {
    private var ad: RewardedAd? = null
    private var loading = false
    private var showWhenLoaded = false

    fun init() {
        Thread {
            MobileAds.initialize(activity) {}
            activity.runOnUiThread { load() }
        }.start()
    }

    private fun load() {
        if (ad != null || loading) return
        loading = true
        RewardedAd.load(
            activity,
            BuildConfig.ADMOB_REWARDED_ID,
            AdRequest.Builder().build(),
            object : RewardedAdLoadCallback() {
                override fun onAdLoaded(loaded: RewardedAd) {
                    loading = false
                    ad = loaded
                    if (showWhenLoaded) {
                        showWhenLoaded = false
                        show()
                    }
                }

                override fun onAdFailedToLoad(error: LoadAdError) {
                    loading = false
                    ad = null
                    if (showWhenLoaded) {
                        showWhenLoaded = false
                        onResult("unavailable")
                    }
                }
            },
        )
    }

    fun show() {
        val current = ad
        if (current == null) {
            // 아직 안 불러왔으면 불러온 뒤 바로 보여준다
            showWhenLoaded = true
            if (!loading) load()
            return
        }
        ad = null
        var rewarded = false
        current.fullScreenContentCallback = object : FullScreenContentCallback() {
            override fun onAdDismissedFullScreenContent() {
                onResult(if (rewarded) "reward" else "closed")
                load()
            }

            override fun onAdFailedToShowFullScreenContent(error: AdError) {
                onResult("unavailable")
                load()
            }
        }
        current.show(activity) { rewarded = true }
    }
}
