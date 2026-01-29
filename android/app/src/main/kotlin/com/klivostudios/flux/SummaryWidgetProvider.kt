package com.klivostudios.flux

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class SummaryWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.summary_widget).apply {
                val balance = widgetData.getString("balance", "$0.00")
                val income = widgetData.getString("income", "$0.00")
                val expenses = widgetData.getString("expenses", "$0.00")
                val count = widgetData.getInt("transactionCount", 0)
                
                setTextViewText(R.id.widget_balance, balance)
                setTextViewText(R.id.widget_income, income)
                setTextViewText(R.id.widget_expenses, expenses)
                setTextViewText(R.id.widget_transaction_count, "$count Transactions")
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
