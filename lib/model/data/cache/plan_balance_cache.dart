import 'package:plansync/model/logic/debt_simplifier.dart';

typedef _Entry = ({int version, List<Transfer> transfers});

class PlanBalanceCache {
  static const probationCapacity = 10;
  static const protectedCapacity = 10;

  final _probation = <String, _Entry>{};
  final _protected = <String, _Entry>{};

  List<Transfer>? get(String planId, int version) {
    final protectedEntry = _protected.remove(planId);
    if (protectedEntry != null) {
      if (protectedEntry.version != version) return null;
      _protected[planId] = protectedEntry;
      return protectedEntry.transfers;
    }
    final probationEntry = _probation.remove(planId);
    if (probationEntry == null || probationEntry.version != version) {
      return null;
    }
    _protected[planId] = probationEntry;
    if (_protected.length > protectedCapacity) {
      final demotedId = _protected.keys.first;
      _probation[demotedId] = _protected.remove(demotedId)!;
      _trimProbation();
    }
    return probationEntry.transfers;
  }

  void put(String planId, int version, List<Transfer> transfers) {
    final entry = (version: version, transfers: transfers);
    if (_protected.remove(planId) != null) {
      _protected[planId] = entry;
      return;
    }
    _probation.remove(planId);
    _probation[planId] = entry;
    _trimProbation();
  }

  void _trimProbation() {
    while (_probation.length > probationCapacity) {
      _probation.remove(_probation.keys.first);
    }
  }

  void clear() {
    _probation.clear();
    _protected.clear();
  }
}
