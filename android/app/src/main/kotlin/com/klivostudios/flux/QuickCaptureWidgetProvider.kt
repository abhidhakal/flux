package com.klivostudios.flux

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class QuickCaptureWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.quick_capture_widget).apply {
                setOnClickPendingIntent(
                    R.id.action_add_expense,
                    launchIntent(context, Uri.parse("flux://add_transaction?type=expense"))
                )
                setOnClickPendingIntent(
                    R.id.action_add_income,
                    launchIntent(context, Uri.parse("flux://add_transaction?type=income"))
                )
                setOnClickPendingIntent(
                    R.id.action_open_budgets,
                    launchIntent(context, Uri.parse("flux://open_budgets"))
                )
                setOnClickPendingIntent(
                    R.id.action_open_goals,
                    launchIntent(context, Uri.parse("flux://open_goals"))
                )
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private fun launchIntent(context: Context, uri: Uri) =
        HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, uri)
}
