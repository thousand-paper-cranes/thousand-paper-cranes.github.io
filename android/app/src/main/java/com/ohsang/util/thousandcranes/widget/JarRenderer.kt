package com.ohsang.util.thousandcranes.widget

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.Typeface
import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.min

/**
 * 1×1 위젯 그림: 내가 접은 학이 그 색대로 쌓인 작은 유리병 + 마릿수.
 * 오늘 색종이를 아직 안 받았으면 오른쪽 위에 파란 점.
 */
object JarRenderer {
    val COLORS = mapOf(
        "red" to 0xDE4A3F, "orange" to 0xEF8B2E, "yellow" to 0xF2C531, "lime" to 0x9ACB4C,
        "green" to 0x2F9A60, "sky" to 0x5DB6E4, "blue" to 0x2F6ED4, "navy" to 0x2F3F8E,
        "purple" to 0x7B56C1, "pink" to 0xEC79AE, "blush" to 0xF4B8CD, "mint" to 0x6AD0BD,
        "gold" to 0xD3A73A, "silver" to 0xB9BEC8,
    )

    private class Palette(dark: Boolean) {
        val bg = if (dark) 0xFF1E2030.toInt() else 0xFFF6F7FA.toInt()
        val ink = if (dark) 0xFFE9EAF3.toInt() else 0xFF22253A.toInt()
        val glass = if (dark) 0x14A0B4E6 else 0x1A8CA0C8
        val edge = if (dark) 0x99BEC8F0.toInt() else 0x8C3C4B78.toInt()
        val accent = if (dark) 0xFF8D9CFF.toInt() else 0xFF3E55C4.toInt()
        val lid = if (dark) 0xFF8C6E4E.toInt() else 0xFFB8946A.toInt()
    }

    fun render(state: CraneState, size: Int, dark: Boolean): Bitmap {
        val s = size.toFloat()
        val pal = Palette(dark)
        val bmp = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val c = Canvas(bmp)
        val p = Paint(Paint.ANTI_ALIAS_FLAG)

        // 배경
        p.color = pal.bg
        c.drawRoundRect(RectF(0f, 0f, s, s), s * 0.22f, s * 0.22f, p)

        // 유리병 자리
        val jw = s * 0.50f
        val jx = (s - jw) / 2f
        val top = s * 0.08f
        val jh = s * 0.62f
        val lidH = jh * 0.12f
        val body = RectF(jx, top + lidH + jh * 0.12f, jx + jw, top + jh)
        val jar = jarPath(jx, top + lidH, jw, body)

        // 학
        if (state.cranes.isNotEmpty()) {
            c.save()
            c.clipPath(jar)
            val cell = max(3f, jw * 0.2f)
            val cols = ceil(body.width() / cell).toInt() + 1
            val fill = min(1f, state.count / CraneState.GOAL.toFloat())
            val fillH = max(cell * 0.9f, body.height() * fill)
            val rows = ceil(fillH / (cell * 0.62f)).toInt()
            val total = cols * rows
            val step = max(1.0, state.count / total.toDouble())
            var n = 0
            val stroke = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.STROKE; strokeWidth = s * 0.004f; color = 0x2E000000 }
            for (r in 0 until rows) {
                val y = body.bottom - r * cell * 0.62f - cell * 0.35f
                for (col in 0 until cols) {
                    val idx = min(state.count - 1, (n * step).toInt()); n++
                    val key = state.cranes[state.count - 1 - idx]
                    p.color = (COLORS[key] ?: 0xDE4A3F) or (0xFF shl 24)
                    val x = body.left + col * cell - (if (r % 2 == 0) 0f else cell / 2)
                    val path = crane(x, y, cell, (r + col) % 3 == 0)
                    c.drawPath(path, p)
                    c.drawPath(path, stroke)
                }
            }
            c.restore()
        }

        // 유리, 테두리, 반사광, 뚜껑
        p.style = Paint.Style.FILL; p.color = pal.glass; c.drawPath(jar, p)
        p.style = Paint.Style.STROKE; p.strokeWidth = s * 0.016f; p.color = pal.edge; c.drawPath(jar, p)
        p.style = Paint.Style.FILL; p.color = 0x73FFFFFF
        c.drawRoundRect(RectF(body.left + jw * 0.1f, body.top + jh * 0.06f, body.left + jw * 0.16f, body.top + body.height() * 0.6f), 4f, 4f, p)
        p.color = pal.lid
        c.drawRoundRect(RectF(jx + jw * 0.16f, top, jx + jw * 0.84f, top + lidH * 1.35f), s * 0.02f, s * 0.02f, p)

        // 마릿수
        p.color = pal.ink
        p.textAlign = Paint.Align.CENTER
        p.typeface = Typeface.create(Typeface.SERIF, Typeface.BOLD)
        p.textSize = s * (if (state.count >= 100) 0.19f else 0.21f)
        c.drawText(if (state.wish.isEmpty()) "소원" else state.count.toString(), s / 2, s * 0.90f, p)

        // 오늘의 색종이 도착
        if (state.paperWaiting) {
            p.color = pal.accent
            c.drawCircle(s * 0.83f, s * 0.17f, s * 0.065f, p)
            p.color = pal.bg; p.style = Paint.Style.STROKE; p.strokeWidth = s * 0.02f
            c.drawCircle(s * 0.83f, s * 0.17f, s * 0.065f, p)
            p.style = Paint.Style.FILL
        }
        return bmp
    }

    /** 앱 유리병과 같은 모양: 좁은 입구 → 둥근 어깨 → 몸통 */
    private fun jarPath(x: Float, top: Float, w: Float, body: RectF): Path {
        val neckL = x + w * 0.20f
        val neckR = x + w * 0.80f
        val r = min(w * 0.16f, body.height() * 0.2f)
        return Path().apply {
            moveTo(neckL, top)
            lineTo(neckR, top)
            cubicTo(neckR + w * 0.02f, body.top - w * 0.03f, body.right, body.top - w * 0.02f, body.right, body.top + r * 0.6f)
            lineTo(body.right, body.bottom - r)
            quadTo(body.right, body.bottom, body.right - r, body.bottom)
            lineTo(body.left + r, body.bottom)
            quadTo(body.left, body.bottom, body.left, body.bottom - r)
            lineTo(body.left, body.top + r * 0.6f)
            cubicTo(body.left, body.top - w * 0.02f, neckL - w * 0.02f, body.top - w * 0.03f, neckL, top)
            close()
        }
    }

    /** 아주 작은 종이학 (iOS 위젯과 같은 모양) */
    private fun crane(px: Float, py: Float, s: Float, flip: Boolean): Path {
        val d = if (flip) -1f else 1f
        return Path().apply {
            moveTo(px - 0.5f * s * d, py)
            lineTo(px - 0.62f * s * d, py - 0.42f * s)
            lineTo(px - 0.30f * s * d, py - 0.06f * s)
            lineTo(px + 0.05f * s * d, py - 0.55f * s)
            lineTo(px + 0.22f * s * d, py - 0.06f * s)
            lineTo(px + 0.62f * s * d, py - 0.40f * s)
            lineTo(px + 0.42f * s * d, py)
            lineTo(px, py + 0.16f * s)
            close()
        }
    }

    fun isDark(uiMode: Int) = (uiMode and android.content.res.Configuration.UI_MODE_NIGHT_MASK) ==
        android.content.res.Configuration.UI_MODE_NIGHT_YES

    @Suppress("unused")
    private fun unused() = Color.TRANSPARENT
}
