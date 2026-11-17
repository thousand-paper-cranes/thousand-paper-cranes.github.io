package com.ohsang.util.thousandcranes

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.ohsang.util.thousandcranes.widget.CraneState
import com.ohsang.util.thousandcranes.widget.JarRenderer
import java.io.File
import kotlin.random.Random

/**
 * 디버그 빌드 전용. adb shell am broadcast -a com.ohsang.util.thousandcranes.WIDGET_SHOT
 * → /sdcard/Android/data/<패키지>/files/shots/android-widget-*.png
 */
class WidgetShotReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val keys = JarRenderer.COLORS.keys.toList()
        val rnd = Random(7)
        val full = CraneState(
            wish = "우리 가족 모두 건강하게",
            cranes = List(327) { keys[rnd.nextInt(keys.size)] },
            papers = 3,
            lastGrant = CraneState.today(),
        )
        val waiting = full.copy(lastGrant = "2000-01-01")
        val few = full.copy(cranes = full.cranes.take(12))
        val almost = full.copy(cranes = List(940) { keys[rnd.nextInt(keys.size)] })
        val dir = File(context.getExternalFilesDir(null), "shots").apply { mkdirs() }
        val size = (64 * 3)
        listOf(
            Triple("light-327", full, false), Triple("light-waiting", waiting, false),
            Triple("dark-327", full, true), Triple("dark-waiting", waiting, true),
            Triple("light-12", few, false), Triple("light-940", almost, false),
            Triple("light-empty", CraneState(), false),
        ).forEach { (name, state, dark) ->
            File(dir, "android-widget-$name.png").outputStream().use {
                JarRenderer.render(state, size, dark).compress(android.graphics.Bitmap.CompressFormat.PNG, 100, it)
            }
        }
        resultData = "ok"
    }
}
