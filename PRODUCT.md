# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Users

Anyone, anywhere, managing their own money on their phone, in any of the 15 supported currencies. NPR is the developer's own default, but nothing in the product is region-specific. They open Flux in short bursts: right after spending, to log it; at a glance from the home screen, to see if they're still okay this month; and occasionally to plan a goal.

## Product Purpose

Flux is a personal budgeting app: log income and expenses, set monthly budgets, save toward goals, and get plain-language guidance on what to do next. Success means the user logs consistently, stays inside their budgets more often, and reaches their goals.

## Positioning

What Flux should be known for, in priority order the user chose:
1. **Fastest logging.** Adding a transaction takes seconds: home-screen widgets, quick add, category shortcuts and recurring entries.
2. **Tells you what to do.** Forecasts, a financial health score and insights turn numbers into a next step ("pause non-essential housing spending").
3. **Goals and motivation.** Savings goals, streaks and milestones bring people back.

## Operating Context

- Flutter app on Android (Play Store) and iOS; Firebase Auth and Firestore back the data, with a local cache.
- Ten Android home-screen widgets (safe to spend, quick add, goal jar, month at a glance, spending pulse, budget rings, upcoming bills, month heatmap, no-spend streak, top category); one more add-only widget is pending selection.
- Light and dark mode, following the system setting or the user's own choice.
- Free and premium tiers (subscriptions behind a feature flag).

## Capabilities and Constraints

- Transactions (expense and income) with categories, optional budget link, essential flag and recurring schedules.
- Budgets: daily, weekly, monthly or yearly, per category, with rollover, weekly targets and temporary adjustments; forecasts and adaptive weekly plans.
- Goals with templates, contributions and milestones.
- Insights: financial health score, savings rate and needs/wants split, run on the device.
- Notifications: budget alerts, goal milestones, spending patterns, daily reminder, morning greeting.
- Currency is per account (synced to Firestore); amounts must always go through the currency formatter and never hardcode a symbol.
- Data export to CSV or PDF.

## Brand Commitments

- Name: Flux. Logo: a stacked "F" of three rounded bars with a blue → teal → green gradient (`assets/brand/flux_logo.svg`, `assets/images/flux_logo.png`).
- App font: Geist (bundled).
- Icons: Lucide line icons. No emoji anywhere in the UI, and no dollar-sign icons (the app is multi-currency).

## Evidence on Hand

- Real account data viewed in the emulator (developer's own): 126 transactions, 29 active days, monthly Housing budget of Rs 50,000, health score 49. Use only for mockups; never present it as other users' data.
- No testimonials, ratings, press or user counts exist. Do not invent them.

## Product Principles

1. Logging comes first: any screen should get a person to "add" in one tap.
2. Every number earns a next step: show what it means and what to do, not just the figure.
3. Honest about money: overspending is shown plainly, without shaming.
4. Feel native on each OS while staying recognisably Flux.
5. Never assume a currency or a region.
