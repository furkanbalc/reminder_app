package com.furkanbalci.su_hatirlatici

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/** Ana ekran widget'ı: günlük ilerleme, sıradaki hatırlatma ve tek dokunuşla bardak ekleme. */
class SuWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val total = widgetData.getInt("total_ml", 0)
        val goal = widgetData.getInt("goal_ml", 2500).coerceAtLeast(1)
        val glass = widgetData.getInt("glass_ml", 330)
        val next = widgetData.getString("next", "") ?: ""
        val pct = (total * 100 / goal).coerceIn(0, 100)

        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.su_widget).apply {
                setTextViewText(R.id.widget_total, liters(total))
                setTextViewText(R.id.widget_goal, "hedef ${liters(goal)} · %$pct")
                setTextViewText(R.id.widget_next, if (next.isEmpty()) "" else "Sıradaki $next")
                setProgressBar(R.id.widget_progress, 100, pct, false)
                setTextViewText(R.id.widget_add, "+ $glass ml")
                setOnClickPendingIntent(
                    R.id.widget_container,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )
                setOnClickPendingIntent(
                    R.id.widget_add,
                    HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse("suhatirlatici://add")),
                )
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    private fun liters(ml: Int): String = "${ml / 1000}.${(ml % 1000) / 100} L"
}
