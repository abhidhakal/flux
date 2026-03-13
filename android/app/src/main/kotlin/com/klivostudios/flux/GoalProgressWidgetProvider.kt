package com.klivostudios.flux

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class GoalProgressWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.goal_progress_widget)

            val goalName = widgetData.getString("goal_name", "Start your first goal") ?: "Start your first goal"
            val goalProgress = widgetData.getInt("goal_progress", 0)

            views.setTextViewText(R.id.widget_goal_name, goalName)
            views.setTextViewText(R.id.widget_goal_progress_text, "$goalProgress%")
            views.setProgressBar(R.id.widget_goal_progress_bar, 100, goalProgress, false)
            views.setContentDescription(
                R.id.widget_goal_progress_bar,
                context.getString(R.string.widget_cd_goal_progress, goalProgress.toString(), goalName)
            )

            val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("flux://open_goals")
            )
            views.setOnClickPendingIntent(R.id.widget_goal_container, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
