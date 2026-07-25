import 'package:flutter/material.dart';

enum TimelineFilter { lastWeek, lastMonth, last3Months, custom }

/// Resolves a [TimelineFilter] to a concrete [DateTimeRange], anchored to
/// today. Falls back to the last-month range for [TimelineFilter.custom]
/// when no [customRange] has been picked yet.
DateTimeRange activeRangeFor(TimelineFilter filter, {DateTimeRange? customRange}) {
  if (filter == TimelineFilter.custom && customRange != null) {
    return customRange;
  }
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day, 23, 59, 59);
  switch (filter) {
    case TimelineFilter.lastWeek:
      return DateTimeRange(start: today.subtract(const Duration(days: 6)), end: today);
    case TimelineFilter.lastMonth:
      return DateTimeRange(start: DateTime(now.year, now.month - 1, now.day), end: today);
    case TimelineFilter.last3Months:
      return DateTimeRange(start: DateTime(now.year, now.month - 3, now.day), end: today);
    case TimelineFilter.custom:
      return DateTimeRange(start: DateTime(now.year, now.month - 1, now.day), end: today);
  }
}
