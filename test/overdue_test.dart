import 'package:flutter_test/flutter_test.dart';
import 'package:plansync/utils/overdue.dart';

void main() {
  final planDate = DateTime(2026, 10, 1, 18);

  test('not overdue before the plan happens', () {
    expect(overdueDays(planDate, DateTime(2026, 9, 30)), isNull);
  });

  test('not overdue during the 3 grace days', () {
    expect(overdueDays(planDate, DateTime(2026, 10, 4, 17)), isNull);
    expect(overdueDays(planDate, DateTime(2026, 10, 4, 19)), isNull);
  });

  test('overdue after more than 3 days', () {
    expect(overdueDays(planDate, DateTime(2026, 10, 5, 19)), 4);
    expect(overdueDays(planDate, DateTime(2026, 10, 11, 18)), 10);
  });

  test('grace days can change', () {
    expect(overdueDays(planDate, DateTime(2026, 10, 3, 19), graceDays: 1), 2);
  });
}
