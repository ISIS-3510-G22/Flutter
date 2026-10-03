int? overdueDays(DateTime planDate, DateTime now, {int graceDays = 3}) {
  final days = now.difference(planDate).inDays;
  if (days <= graceDays) return null;
  return days;
}
