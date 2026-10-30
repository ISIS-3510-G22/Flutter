int toCents(double amount) => (amount * 100).round();

Map<String, int> customSharesCents(Map<String, double> amounts) => {
  for (final entry in amounts.entries) entry.key: toCents(entry.value),
};

/// Positive: still missing. Negative: over the total. Zero: it adds up.
int remainingCents(double total, Map<String, double> amounts) {
  var assigned = 0;
  for (final cents in customSharesCents(amounts).values) {
    assigned += cents;
  }
  return toCents(total) - assigned;
}
