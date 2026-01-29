package com.klivostudios.flux

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class BalanceWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.balance_widget).apply {
                val balance = widgetData.getString("balance", "$0.00")
                val income = widgetData.getString("income", "$0.00")
                val expenses = widgetData.getString("expenses", "$0.00")
                
                setTextViewText(R.id.widget_balance, balance)
                setTextViewText(R.id.widget_income, income)
                setTextViewText(R.id.widget_expenses, expenses)

                // Create a PendingIntent to launch the app with a specific URI
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("flux://add_transaction")
                )
                setOnClickPendingIntent(R.id.widget_button_add, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
