import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plansync/model/data/connectivity_repository.dart';
import 'package:plansync/model/services/local/split_local_store.dart';
import 'package:plansync/model/data/split_outbox_repository.dart';
import 'package:plansync/model/data/user_repository.dart';
import 'package:plansync/model/models/pending_write.dart';
import 'package:plansync/model/models/user.dart';

class PlanPaymentRepository {
  CollectionReference<Map<String, dynamic>> _choices(String planId) =>
      FirebaseFirestore.instance
          .collection('plans')
          .doc(planId)
          .collection('paymentMethods');

  final _local = SplitLocalStore();
  final _userRepository = UserRepository();
  final _connectivity = ConnectivityRepository.instance;

  // A getter, never a field: the queue's constructor creates this repository.
  SplitOutboxRepository get _queue => SplitOutboxRepository.instance;

  /// Saved choices first, then each server answer, saved before it's emitted.
  Stream<Map<String, String>> choicesForPlan(String planId) async* {
    yield await _local.choices(planId);
    yield* _choices(planId)
        .snapshots(includeMetadataChanges: true)
        .where((snapshot) => !snapshot.metadata.isFromCache)
        .asyncMap((snapshot) async {
          final choices = {
            for (final d in snapshot.docs) d.id: d.data()['methodId'] as String,
          };
          if (_queue.hasPendingFor(planId)) return _local.choices(planId);
          for (final entry in choices.entries) {
            await _local.saveChoice(planId, entry.key, entry.value);
          }
          return choices;
        });
  }

  /// The plan's people with their reimbursement methods: from the server
  /// (saved to `plan_people`), or offline the saved ones among [ids].
  Future<List<User>> participants(String planId, List<String> ids) async {
    try {
      _connectivity.ensureOnline();
      final users = await _userRepository
          .getUsers(ids, source: Source.server)
          .timeout(const Duration(seconds: 8));
      await _local.savePeople(planId, users);
      return users;
    } catch (_) {
      final saved = await _local.people(planId);
      return saved.where((u) => ids.contains(u.id)).toList();
    }
  }

  Future<Map<String, String>> savedChoices(String planId) =>
      _local.choices(planId);

  Future<bool> chooseMethod(
    String planId,
    String userId,
    String methodId,
  ) async {
    await _local.saveChoice(planId, userId, methodId);
    return _queue.submit(
      PendingWrite(
        kind: SplitWriteKind.paymentChoose,
        docId: SplitOutboxRepository.docId(planId, userId),
        payload: {'planId': planId, 'userId': userId, 'methodId': methodId},
      ),
    );
  }

  // Server method, called by the queue's `send`.

  Future<void> choose(String planId, String userId, String methodId) {
    return _choices(planId).doc(userId).set({'methodId': methodId});
  }
}
