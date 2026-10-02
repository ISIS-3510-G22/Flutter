import 'package:flutter_test/flutter_test.dart';
import 'package:plansync/utils/debt_simplifier.dart';

Map<String, int> _applyTransfers(
  Map<String, int> balances,
  List<Transfer> transfers,
) {
  final result = Map<String, int>.from(balances);
  for (final t in transfers) {
    result[t.fromId] = result[t.fromId]! + t.amountCents;
    result[t.toId] = result[t.toId]! - t.amountCents;
  }
  return result;
}

void main() {
  group('splitCents', () {
    test('adds up exactly to the total', () {
      final shares = splitCents(1000, 3);
      expect(shares, [334, 333, 333]);
      expect(shares.reduce((a, b) => a + b), 1000);
    });
  });

  group('simplifyDebts', () {
    test('settles everyone to zero', () {
      final balances = {'a': 3000, 'b': -1000, 'c': -1500, 'd': -500};
      final transfers = simplifyDebts(balances);
      final after = _applyTransfers(balances, transfers);
      expect(after.values.every((v) => v == 0), isTrue);
    });

    test('uses at most n - 1 transfers', () {
      final balances = {'a': 5000, 'b': 2000, 'c': -4000, 'd': -3000};
      final transfers = simplifyDebts(balances);
      expect(transfers.length, lessThanOrEqualTo(3));
      final after = _applyTransfers(balances, transfers);
      expect(after.values.every((v) => v == 0), isTrue);
    });

    test('matches equal amounts directly', () {
      final balances = {'a': 1000, 'b': 2500, 'c': -2500, 'd': -1000};
      final transfers = simplifyDebts(balances);
      expect(transfers.length, 2);
    });

    test('chains of debts collapse into one transfer', () {
      // a owes b 10, b owes c 10 -> a pays c directly.
      final balances = {'a': -1000, 'b': 0, 'c': 1000};
      final transfers = simplifyDebts(balances);
      expect(transfers.length, 1);
      expect(transfers.first.fromId, 'a');
      expect(transfers.first.toId, 'c');
    });

    test('nothing to do when everyone is even', () {
      expect(simplifyDebts({'a': 0, 'b': 0}), isEmpty);
    });
  });
}
