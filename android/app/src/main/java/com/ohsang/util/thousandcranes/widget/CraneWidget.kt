package com.ohsang.util.thousandcranes.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.RemoteViews
import com.ohsang.util.thousandcranes.MainActivity
import com.ohsang.util.thousandcranes.R
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/** 1×1 홈 화면 위젯: 소원 유리병 + 마릿수. 누르면 앱이 열린다. */
class CraneWidget : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        ids.forEach { update(context, manager, it) }
    }

    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, newOptions: Bundle) {
        update(context, manager, id)
    }

    companion object {
        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context) ?: return
            val ids = manager.getAppWidgetIds(ComponentName(context, CraneWidget::class.java))
            ids.forEach { update(context, manager, it) }
        }

        fun update(context: Context, manager: AppWidgetManager, id: Int) {
            val opts = manager.getAppWidgetOptions(id)
            val wDp = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 64)
            val hDp = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 64)
            val density = context.resources.displayMetrics.density
            val px = (max(48, min(wDp.takeIf { it > 0 } ?: 64, hDp.takeIf { it > 0 } ?: 64)) * density).roundToInt().coerceIn(96, 480)

            val state = CraneState.load(context)
            val dark = JarRenderer.isDark(context.resources.configuration.uiMode)
            val views = RemoteViews(context.packageName, R.layout.widget_jar)
            views.setImageViewBitmap(R.id.jar, JarRenderer.render(state, px, dark))
            views.setContentDescription(R.id.jar, "천 마리 학, 학 ${state.count}마리")
            val open = PendingIntent.getActivity(
                context, 0, Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
            views.setOnClickPendingIntent(R.id.jar, open)
            manager.updateAppWidget(id, views)
        }
    }
}
