/// Formats a date as `d/M/yyyy`, e.g. "5/3/2026".
String formatShortDate(DateTime date) =>
    '${date.day}/${date.month}/${date.year}';
