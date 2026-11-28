package com.klivostudios.flux

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.text.SpannableStringBuilder
import android.text.style.ForegroundColorSpan
import android.view.View
import android.widget.RemoteViews
import androidx.core.graphics.ColorUtils
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

// All numbers are computed in Flutter (lib/core/services/widget_service.dart)
// and stored as strings/ints. These providers only lay them out and draw charts.

abstract class FluxWidget(private val layout: Int) : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (id in appWidgetIds) {
            val o = appWidgetManager.getAppWidgetOptions(id)
            // Portrait size: min width x max height (dp). 0 when the launcher hasn't said.
            size = o.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH) to
                o.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT)
            val views = RemoteViews(context.packageName, layoutFor(size.first, size.second))
            try {
                bind(context, views, widgetData)
            } catch (e: Exception) {
                e.printStackTrace()
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int, newOptions: Bundle
    ) {
        onUpdate(context, appWidgetManager, intArrayOf(appWidgetId), HomeWidgetPlugin.getData(context))
    }

    /** Widget size in dp for the current bind, (0, 0) if unknown. */
    protected var size = 0 to 0

    /** Override to pick a layout by widget size (dp). */
    protected open fun layoutFor(widthDp: Int, heightDp: Int) = layout

    abstract fun bind(c: Context, v: RemoteViews, d: SharedPreferences)

    protected fun link(c: Context, uri: String) =
        HomeWidgetLaunchIntent.getActivity(c, MainActivity::class.java, Uri.parse(uri))

    protected fun SharedPreferences.str(key: String, def: String = "") = getString(key, def) ?: def
    protected fun SharedPreferences.nums(key: String) =
        str(key).split(',').mapNotNull { it.toFloatOrNull() }
}

private object Draw {
    // Chart bitmaps are baked once and don't redraw when the phone switches
    // light/dark, so neutrals are translucent greys that read on both widget
    // backgrounds, and fills are the accent colours (same in both themes).
    private const val TRACK = 0x2E8090A0
    private const val LABEL = 0xFF8A94A6.toInt()
    private const val BLUE = 0xFF1E88E5.toInt()
    private fun soft(color: Int) = ColorUtils.setAlphaComponent(color, 0x59)

    fun col(c: Context, id: Int) = c.getColor(id)
    private fun px(c: Context, dp: Float) = dp * c.resources.displayMetrics.density
    private fun bmp(c: Context, wDp: Float, hDp: Float) =
        Bitmap.createBitmap(px(c, wDp).toInt(), px(c, hDp).toInt(), Bitmap.Config.ARGB_8888)
    private fun stroke(width: Float, color: Int) = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE; strokeWidth = width; strokeCap = Paint.Cap.ROUND; this.color = color
    }
    private fun fill(color: Int) = Paint(Paint.ANTI_ALIAS_FLAG).apply { this.color = color }

    /** Concentric rings, outermost first. pcts are 0..100. */
    fun rings(c: Context, sizeDp: Float, thickDp: Float, pcts: List<Float>, colors: List<Int>): Bitmap {
        val b = bmp(c, sizeDp, sizeDp); val cv = Canvas(b)
        val t = px(c, thickDp); val gap = t * 0.45f
        val track = TRACK
        colors.forEachIndexed { i, color ->
            val inset = t / 2 + i * (t + gap)
            val r = RectF(inset, inset, b.width - inset, b.height - inset)
            cv.drawArc(r, 0f, 360f, false, stroke(t, track))
            val p = pcts.getOrNull(i) ?: 0f
            if (p > 0) cv.drawArc(r, -90f, 360f * p.coerceAtMost(100f) / 100f, false, stroke(t, color))
        }
        return b
    }

    /** Donut of shares (percent of total), rest drawn as track. */
    fun donut(c: Context, sizeDp: Float, shares: List<Float>, colors: List<Int>): Bitmap {
        val b = bmp(c, sizeDp, sizeDp); val cv = Canvas(b)
        val t = px(c, sizeDp * 0.17f); val r = RectF(t / 2, t / 2, b.width - t / 2, b.height - t / 2)
        val p = stroke(t, TRACK).apply { strokeCap = Paint.Cap.BUTT }
        cv.drawArc(r, 0f, 360f, false, p)
        var start = -90f
        shares.zip(colors).forEach { (s, color) ->
            val sweep = 360f * s / 100f
            if (sweep > 0) cv.drawArc(r, start, sweep, false, p.apply { this.color = color })
            start += sweep
        }
        return b
    }

    fun bars(c: Context, values: List<Float>, today: Int): Bitmap {
        val b = bmp(c, 300f, 84f); val cv = Canvas(b)
        val n = 7; val gap = px(c, 9f); val w = (b.width - gap * (n - 1)) / n
        val max = (values.maxOrNull() ?: 0f).coerceAtLeast(1f)
        val rad = px(c, 6f); val minH = px(c, 6f)
        val labelH = px(c, 20f); val chartH = b.height - labelH
        val text = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            textSize = px(c, 11f); textAlign = Paint.Align.CENTER
        }
        for (i in 0 until n) {
            val v = values.getOrNull(i) ?: 0f
            val h = if (i > today) minH else (chartH * v / max).coerceAtLeast(minH)
            val color = when {
                i == today -> BLUE
                i > today -> TRACK
                else -> soft(BLUE)
            }
            val x = i * (w + gap)
            cv.drawRoundRect(RectF(x, chartH - h, x + w, chartH), rad, rad, fill(color))
            text.color = if (i == today) BLUE else LABEL
            text.isFakeBoldText = i == today
            cv.drawText("MTWTFSS"[i].toString(), x + w / 2, b.height - px(c, 3f), text)
        }
        return b
    }

    fun jar(c: Context, pct: Int): Bitmap {
        val b = bmp(c, 46f, 138f); val cv = Canvas(b)
        val rad = px(c, 14f); val all = RectF(0f, 0f, b.width.toFloat(), b.height.toFloat())
        cv.drawRoundRect(all, rad, rad, fill(TRACK))
        val top = b.height * (1 - pct.coerceIn(0, 100) / 100f)
        cv.save(); cv.clipRect(0f, top, b.width.toFloat(), b.height.toFloat())
        cv.drawRoundRect(all, rad, rad, fill(BLUE))
        cv.restore()
        return b
    }

    /**
     * Month grid as in the mockup: Monday-first, 7 columns, cells stretch to
     * fill the space (5dp gaps, 5dp corners), spend shown as 4 blue levels,
     * today outlined. Size comes from the widget, which is capped in fw_heat_info.xml.
     */
    fun heat(c: Context, wDp: Float, hDp: Float, values: List<Float>, firstWeekday: Int, today: Int): Bitmap {
        val b = bmp(c, wDp, hDp); val cv = Canvas(b)
        val rows = (firstWeekday + values.size + 6) / 7
        val gap = px(c, 5f); val rad = px(c, 5f)
        val cw = (b.width - gap * 6) / 7
        val ch = (b.height - gap * (rows - 1)) / rows
        val max = (values.maxOrNull() ?: 0f).coerceAtLeast(1f)
        values.forEachIndexed { i, v ->
            val pos = firstWeekday + i
            val x = (pos % 7) * (cw + gap); val y = (pos / 7) * (ch + gap)
            val r = RectF(x, y, x + cw, y + ch)
            cv.drawRoundRect(r, rad, rad, fill(heatShade(v, max)))
            if (i + 1 == today) {
                val sw = px(c, 2f); r.inset(sw / 2, sw / 2)
                cv.drawRoundRect(r, rad, rad, stroke(sw, LABEL))
            }
        }
        return b
    }

    /** 0 = no spend, then 4 levels (24/48/72/96% blue) like the mockup. */
    fun heatShade(v: Float, max: Float): Int {
        if (v <= 0f) return TRACK
        val level = 1 + minOf(3, (v / max * 4).toInt())
        return ColorUtils.setAlphaComponent(BLUE, (255 * 0.24f * level).toInt())
    }

    /** "less ■■■ more" legend, squares in increasing blue. */
    fun heatLegend(): CharSequence = SpannableStringBuilder().apply {
        append("less ", ForegroundColorSpan(LABEL), 0)
        for (l in 1..3) append("■", ForegroundColorSpan(ColorUtils.setAlphaComponent(BLUE, (255 * 0.32f * l).toInt())), 0)
        append(" more", ForegroundColorSpan(LABEL), 0)
    }


}

/** Lucide icon per category name (names from lib/core/constants/categories.dart). */
private fun categoryIcon(category: String) = when (category) {
    "Food & Dining" -> R.drawable.fw_ic_utensils
    "Transportation" -> R.drawable.fw_ic_car
    "Entertainment" -> R.drawable.fw_ic_clapperboard
    "Shopping" -> R.drawable.fw_ic_shopping_bag
    "Bills & Utilities" -> R.drawable.fw_ic_zap
    "Healthcare" -> R.drawable.fw_ic_heart_pulse
    "Education" -> R.drawable.fw_ic_graduation_cap
    "Housing" -> R.drawable.fw_ic_house
    "Insurance" -> R.drawable.fw_ic_shield
    "Personal Care" -> R.drawable.fw_ic_sparkles
    "Travel" -> R.drawable.fw_ic_plane
    "Gifts" -> R.drawable.fw_ic_gift
    "Salary" -> R.drawable.fw_ic_wallet
    "Freelance" -> R.drawable.fw_ic_briefcase
    "Investment" -> R.drawable.fw_ic_trending_up
    "Business" -> R.drawable.fw_ic_building_2
    "Other Income" -> R.drawable.fw_ic_banknote
    else -> R.drawable.fw_ic_tag
}

private val levelColors = intArrayOf(R.color.fw_good, R.color.fw_warn, R.color.fw_bad)
private val levelRing = intArrayOf(0xFF1E88E5.toInt(), 0xFFE08A0B.toInt(), 0xFFE5484D.toInt())

/** 01 Safe to spend. Keeps the old class name so placed widgets survive. */
class ActionWidgetProvider : FluxWidget(R.layout.fw_safe) {
    override fun bind(c: Context, v: RemoteViews, d: SharedPreferences) {
        val level = d.getInt("safe_level", 0).coerceIn(0, 2)
        val days = d.getInt("safe_days_left", 0)
        val status = d.str("safe_status", "Open Flux to sync")
        v.setTextViewText(R.id.amount, d.str("safe_amount", "–"))
        v.setTextViewText(R.id.status, SpannableStringBuilder().apply {
            append("● $status", ForegroundColorSpan(Draw.col(c, levelColors[level])), 0)
            if (days > 0) append(" · $days ${if (days == 1) "day" else "days"} left")
        })
        v.setImageViewBitmap(R.id.ring, Draw.rings(c, 26f, 4f,
            listOf(d.getInt("month_progress", 0).toFloat()), listOf(levelRing[level])))
        v.setContentDescription(R.id.root, "Safe to spend today: ${d.str("safe_amount")}. $status")
        v.setOnClickPendingIntent(R.id.root, link(c, "flux://open_home"))
    }
}

/** 02 Quick add. */
class QuickCaptureWidgetProvider : FluxWidget(R.layout.fw_quick) {
    override fun bind(c: Context, v: RemoteViews, d: SharedPreferences) {
        v.setContentDescription(R.id.add_expense, "Add expense")
        v.setContentDescription(R.id.add_income, "Add income")
        v.setOnClickPendingIntent(R.id.add_expense, link(c, "flux://add_transaction?type=expense"))
        v.setOnClickPendingIntent(R.id.add_income, link(c, "flux://add_transaction?type=income"))
        listOf(R.id.cat1 to 1, R.id.cat2 to 2).forEach { (id, n) ->
            val cat = d.str("qa_cat$n", if (n == 1) "Food & Dining" else "Transportation")
            v.setImageViewResource(id, categoryIcon(cat))
            v.setContentDescription(id, "Add $cat expense")
            v.setOnClickPendingIntent(id,
                link(c, "flux://add_transaction?type=expense&category=${Uri.encode(cat)}"))
        }
    }
}

/** 03 Goal jar. */
class GoalProgressWidgetProvider : FluxWidget(R.layout.fw_goal) {
    override fun bind(c: Context, v: RemoteViews, d: SharedPreferences) {
        val pct = d.getInt("goal_pct", 0)
        val name = d.str("goal_name", "No goal yet")
        v.setTextViewText(R.id.name, name)
        v.setTextViewText(R.id.pct, "$pct%")
        v.setTextViewText(R.id.amounts, d.str("goal_amounts", "Tap to set one"))
        v.setTextViewText(R.id.eta, d.str("goal_eta"))
        v.setImageViewBitmap(R.id.jar, Draw.jar(c, pct))
        v.setContentDescription(R.id.root, "$name, $pct percent saved")
        v.setOnClickPendingIntent(R.id.root, link(c, "flux://open_goals"))
    }
}

/** 04 Month at a glance. */
class BalanceWidgetProvider : FluxWidget(R.layout.fw_glance) {
    override fun bind(c: Context, v: RemoteViews, d: SharedPreferences) {
        v.setTextViewText(R.id.balance, d.str("glance_balance", "–"))
        v.setTextViewText(R.id.income, d.str("glance_in", "–"))
        v.setTextViewText(R.id.expense, d.str("glance_out", "–"))
        v.setContentDescription(R.id.add, "Add transaction")
        v.setOnClickPendingIntent(R.id.root, link(c, "flux://open_home"))
        v.setOnClickPendingIntent(R.id.add, link(c, "flux://add_transaction?type=expense"))
    }
}

/** 05 Spending pulse. */
class SpendingPulseWidgetProvider : FluxWidget(R.layout.fw_pulse) {
    override fun bind(c: Context, v: RemoteViews, d: SharedPreferences) {
        val up = d.getInt("pulse_up", 0) == 1 // spending more is the bad direction
        v.setTextViewText(R.id.total, d.str("pulse_total", "–"))
        v.setTextViewText(R.id.change, d.str("pulse_change", "This week"))
        val chipText = if (up) R.color.fw_bad else R.color.fw_good
        // API 31+ resolves the colour resource at draw time, so it follows light/dark.
        if (Build.VERSION.SDK_INT >= 31) v.setColorStateList(R.id.change, "setTextColor", chipText)
        else v.setTextColor(R.id.change, Draw.col(c, chipText))
        v.setInt(R.id.change, "setBackgroundResource",
            if (up) R.drawable.fw_tile_bad_soft else R.drawable.fw_tile_good_soft)
        v.setImageViewBitmap(R.id.chart, Draw.bars(c, d.nums("pulse_days"), d.getInt("pulse_today", 6)))
        v.setOnClickPendingIntent(R.id.root, link(c, "flux://open_analytics"))
    }
}

/** 06 Budget rings. */
class BudgetRingsWidgetProvider : FluxWidget(R.layout.fw_rings) {
    override fun bind(c: Context, v: RemoteViews, d: SharedPreferences) {
        val colors = listOf(0xFFE76F51, 0xFF1E88E5, 0xFF22A355).map { it.toInt() }
        val names = d.str("ring_names").split('|').filter { it.isNotBlank() }
        val pcts = d.nums("ring_pcts")
        v.setImageViewBitmap(R.id.rings, Draw.rings(c, 112f, 9f, pcts, colors))
        v.setTextViewText(R.id.legend, if (names.isEmpty()) "No budgets yet" else
            SpannableStringBuilder().apply {
                names.forEachIndexed { i, n ->
                    if (i > 0) append("  ")
                    append("●", ForegroundColorSpan(colors[i]), 0); append(" $n")
                }
            })
        v.setContentDescription(R.id.root, names.mapIndexed { i, n ->
            "$n ${pcts.getOrNull(i)?.toInt() ?: 0} percent used" }.joinToString(", ").ifEmpty { "No budgets yet" })
        v.setOnClickPendingIntent(R.id.root, link(c, "flux://open_budgets"))
    }
}

/** 07 Upcoming bills. */
class UpcomingBillsWidgetProvider : FluxWidget(R.layout.fw_bills) {
    private val rows = intArrayOf(R.id.b0, R.id.b1, R.id.b2)
    private val icons = intArrayOf(R.id.b0_icon, R.id.b1_icon, R.id.b2_icon)
    private val names = intArrayOf(R.id.b0_name, R.id.b1_name, R.id.b2_name)
    private val whens = intArrayOf(R.id.b0_when, R.id.b1_when, R.id.b2_when)
    private val amounts = intArrayOf(R.id.b0_amount, R.id.b1_amount, R.id.b2_amount)

    override fun bind(c: Context, v: RemoteViews, d: SharedPreferences) {
        val count = d.getInt("bills_count", 0)
        v.setTextViewText(R.id.week, if (count > 0) d.str("bills_week_total") else "")
        v.setViewVisibility(R.id.empty, if (count == 0) View.VISIBLE else View.GONE)
        for (i in 0 until 3) {
            v.setViewVisibility(rows[i], if (i < count) View.VISIBLE else View.GONE)
            v.setImageViewResource(icons[i], categoryIcon(d.str("bill${i}_category")))
            v.setTextViewText(names[i], d.str("bill${i}_name"))
            v.setTextViewText(whens[i], d.str("bill${i}_when"))
            v.setTextViewText(amounts[i], d.str("bill${i}_amount"))
        }
        v.setOnClickPendingIntent(R.id.root, link(c, "flux://open_recurring"))
    }
}

/** 08 Month heatmap. */
class HeatmapWidgetProvider : FluxWidget(R.layout.fw_heat) {
    override fun bind(c: Context, v: RemoteViews, d: SharedPreferences) {
        v.setTextViewText(R.id.month, d.str("heat_month"))
        v.setTextViewText(R.id.l, Draw.heatLegend())
        // ponytail: whole widget opens transactions; per-day taps need a
        // RemoteViews collection + a day filter on the transactions screen.
        // Space left for the grid after 16dp padding and the header row.
        val (w, h) = size
        val gw = if (w > 0) (w - 32).toFloat() else 300f
        val gh = if (h > 0) (h - 32 - 26).toFloat() else 180f
        v.setImageViewBitmap(R.id.grid, Draw.heat(c, gw, gh.coerceAtLeast(60f),
            d.nums("heat_values"), d.getInt("heat_first_weekday", 0), d.getInt("heat_today", 0)))
        v.setOnClickPendingIntent(R.id.root, link(c, "flux://open_transactions"))
    }
}

/** 09 No-spend streak. */
class StreakWidgetProvider : FluxWidget(R.layout.fw_streak) {
    override fun bind(c: Context, v: RemoteViews, d: SharedPreferences) {
        val n = d.getInt("streak_days", 0)
        v.setTextViewText(R.id.days, if (n == 1) "1 day" else "$n days")
        v.setOnClickPendingIntent(R.id.root, link(c, "flux://open_home"))
    }
}

/** 10 Top category. */
class TopCategoryWidgetProvider : FluxWidget(R.layout.fw_top) {
    override fun bind(c: Context, v: RemoteViews, d: SharedPreferences) {
        val colors = listOf(0xFFE76F51, 0xFF1E88E5, 0xFFE08A0B).map { it.toInt() }
        v.setTextViewText(R.id.pct, d.str("top_pct", "–"))
        v.setTextViewText(R.id.cat, "on ${d.str("top_cat", "nothing yet")}")
        v.setTextViewText(R.id.detail, d.str("top_detail"))
        v.setImageViewBitmap(R.id.donut, Draw.donut(c, 64f, d.nums("top_shares"), colors))
        v.setOnClickPendingIntent(R.id.root, link(c, "flux://open_analytics"))
    }
}

/**
 * 11 Add. No money shown. Shape follows the size it's given:
 * 1x1 plus tile, 2x1 labelled button, 4x1+ "Add a transaction…" bar.
 */
class AddWidgetProvider : FluxWidget(R.layout.fw_add_s) {
    override fun layoutFor(widthDp: Int, heightDp: Int) = when {
        widthDp >= 220 -> R.layout.fw_add_l
        widthDp >= 100 -> R.layout.fw_add_m
        else -> R.layout.fw_add_s
    }

    override fun bind(c: Context, v: RemoteViews, d: SharedPreferences) {
        v.setContentDescription(R.id.root, "Add transaction")
        v.setOnClickPendingIntent(R.id.root, link(c, "flux://add_transaction?type=expense"))
    }
}
