/// Format a minute count as "45m", "1h", or "1h 45m".
String fmtMinutes(int m) {
  if (m < 60) return '${m}m';
  final h = m ~/ 60;
  final mm = m % 60;
  return mm == 0 ? '${h}h' : '${h}h ${mm}m';
}

/// Relative time label, e.g. "just now", "5m ago", "3h ago", "2d ago".
String agoLabel(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  return '${d.inDays}d ago';
}

/// Full date label like "Friday, Jun 26".
String dateLabel([DateTime? when]) {
  const wd = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  const mo = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final n = when ?? DateTime.now();
  return '${wd[n.weekday - 1]}, ${mo[n.month - 1]} ${n.day}';
}
