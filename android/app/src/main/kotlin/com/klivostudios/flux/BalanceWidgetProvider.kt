package com.klivostudios.flux

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class BalanceWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            try {
                val views = RemoteViews(context.packageName, R.layout.balance_widget)

                val balance = widgetData.getString("balance", "\$0.00") ?: "\$0.00"
                val income = widgetData.getString("income", "\$0.00") ?: "\$0.00"
                val expenses = widgetData.getString("expenses", "\$0.00") ?: "\$0.00"

                views.setTextViewText(R.id.widget_balance, balance)
                views.setTextViewText(R.id.widget_income, income)
                views.setTextViewText(R.id.widget_expenses, expenses)

                // Accessibility: describe the live amounts for TalkBack
                views.setContentDescription(
                    R.id.widget_balance,
                    context.getString(R.string.widget_cd_balance, balance)
                )
                views.setContentDescription(
                    R.id.widget_income,
                    context.getString(R.string.widget_cd_income, income)
                )
                views.setContentDescription(
                    R.id.widget_expenses,
                    context.getString(R.string.widget_cd_expenses, expenses)
                )

                // Tap launches the app normally
                val launchIntent = context.packageManager
                    .getLaunchIntentForPackage(context.packageName)
                    ?.apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP }

                if (launchIntent != null) {
                    val pendingIntent = PendingIntent.getActivity(
                        context,
                        appWidgetId,
                        launchIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
                }

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}

