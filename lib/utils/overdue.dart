/// Days a debt has stayed unpaid after the plan happened, or null while it is
/// still within the [graceDays] the group gives to pay.
int? overdueDays(DateTime planDate, DateTime now, {int graceDays = 3}) {
  final days = now.difference(planDate).inDays;
  if (days <= graceDays) return null;
  return days;
}
