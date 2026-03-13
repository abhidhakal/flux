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
            try {
                val views = RemoteViews(context.packageName, R.layout.balance_widget)

                val balance = widgetData.getString("balance", "\$0.00") ?: "\$0.00"
                val income = widgetData.getString("income", "\$0.00") ?: "\$0.00"
                val expenses = widgetData.getString("expenses", "\$0.00") ?: "\$0.00"
                val transactionCount = widgetData.getInt("transactionCount", 0)

                views.setTextViewText(R.id.widget_balance, balance)
                views.setTextViewText(R.id.widget_income, income)
                views.setTextViewText(R.id.widget_expenses, expenses)
                views.setTextViewText(R.id.widget_transaction_count, "$transactionCount tx")

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

                val homeIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("flux://open_home")
                )
                val transactionsIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("flux://open_transactions")
                )
                views.setOnClickPendingIntent(R.id.widget_container, homeIntent)
                views.setOnClickPendingIntent(R.id.widget_income_card, transactionsIntent)
                views.setOnClickPendingIntent(R.id.widget_expense_card, transactionsIntent)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}
