package com.ohsang.util.thousandcranes.widget

import android.content.Context
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

/** 화면(localStorage)의 상태 JSON을 앱 SharedPreferences에 복사해 둔 것. 위젯과 기록 백업에 쓴다. */
data class CraneState(
    val wish: String = "",
    val cranes: List<String> = emptyList(),
    val papers: Int = 0,
    val lastGrant: String = "",
    val dayOffset: Int = 0,
) {
    val count get() = cranes.size

    /** 오늘 아직 색종이를 안 받았는지 (앱을 열면 받는다) */
    val paperWaiting get() = wish.isNotEmpty() && lastGrant != today(dayOffset)

    companion object {
        const val PREFS = "crane"
        const val KEY = "state"
        const val GOAL = 1000
        /** 화면 쪽 localStorage 키 */
        const val KEY_LS = "cranejar.v1"

        fun raw(ctx: Context): String? = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, null)

        fun save(ctx: Context, json: String) {
            ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(KEY, json).apply()
        }

        fun load(ctx: Context): CraneState = parse(raw(ctx))

        fun parse(json: String?): CraneState {
            if (json.isNullOrBlank()) return CraneState()
            return runCatching {
                val o = JSONObject(json)
                val arr = o.optJSONArray("cranes")
                val list = if (arr == null) emptyList() else List(arr.length()) { arr.optString(it) }
                CraneState(
                    wish = o.optString("wish", ""),
                    cranes = list,
                    papers = o.optJSONArray("papers")?.length() ?: 0,
                    lastGrant = o.optString("lastGrant", ""),
                    dayOffset = o.optInt("dayOffset", 0),
                )
            }.getOrDefault(CraneState())
        }

        fun today(offset: Int = 0): String {
            val c = Calendar.getInstance()
            c.add(Calendar.DAY_OF_MONTH, offset)
            return SimpleDateFormat("yyyy-MM-dd", Locale.US).format(c.time)
        }
    }
}
