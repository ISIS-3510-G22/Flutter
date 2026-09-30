import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plansync/models/reimbursement_method.dart';
import 'package:plansync/models/user.dart';

class UserRepository {
  final _users = FirebaseFirestore.instance.collection('users');

  Future<User?> getUser(String id) async {
    final doc = await _users.doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    return User(
      id: id,
      name: data['name'] as String,
      lastName: data['lastName'] as String,
      username: data['username'] as String,
      email: data['email'] as String,
      phone: data['phone'] as String,
      photoUrl: data['photoUrl'] as String?,
      reimbursementMethods:
          (data['reimbursementMethods'] as List<dynamic>? ?? [])
              .map(
                (m) => ReimbursementMethod(
                  id: m['id'] as String,
                  type: m['type'] as String,
                  account: m['account'] as String,
                ),
              )
              .toList(),
    );
  }

  Future<void> createUser(User user) {
    return _users.doc(user.id).set({
      'name': user.name,
      'lastName': user.lastName,
      'username': user.username,
      'email': user.email,
      'phone': user.phone,
      'photoUrl': user.photoUrl,
      'reimbursementMethods': user.reimbursementMethods
          .map((m) => {'id': m.id, 'type': m.type, 'account': m.account})
          .toList(),
    });
  }

  Future<void> updateProfile(
    String userId, {
    required String name,
    required String lastName,
    required String phone,
    required List<ReimbursementMethod> reimbursementMethods,
  }) {
    return _users.doc(userId).update({
      'name': name,
      'lastName': lastName,
      'phone': phone,
      'reimbursementMethods': reimbursementMethods
          .map((m) => {'id': m.id, 'type': m.type, 'account': m.account})
          .toList(),
    });
  }

  Future<void> updatePhotoUrl(String userId, String photoUrl) {
    return _users.doc(userId).update({'photoUrl': photoUrl});
  }

  Future<List<User>> getUsers(List<String> ids) async {
    if (ids.isEmpty) return [];
    final snapshot = await _users
        .where(FieldPath.documentId, whereIn: ids)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return User(
        id: doc.id,
        name: data['name'] as String,
        lastName: data['lastName'] as String,
        username: data['username'] as String,
        email: data['email'] as String,
        phone: data['phone'] as String,
      );
    }).toList();
  }

  Future<List<User>> searchUsers(String prefix, {String? excludingId}) async {
    final query = prefix.trim();
    if (query.isEmpty) return [];

    final terms = query.split(RegExp(r'\s+'));
    final firstNamePrefix = terms.first;
    final lastNamePrefix = terms.length > 1 ? terms.last : query;
    final end = '$query\uf8ff';
    final firstNameEnd = '$firstNamePrefix\uf8ff';
    final lastNameEnd = '$lastNamePrefix\uf8ff';
    final snapshots = await Future.wait([
      _users.orderBy('username').startAt([query]).endAt([end]).limit(20).get(),
      _users
          .orderBy('name')
          .startAt([firstNamePrefix])
          .endAt([firstNameEnd])
          .limit(20)
          .get(),
      _users
          .orderBy('lastName')
          .startAt([lastNamePrefix])
          .endAt([lastNameEnd])
          .limit(20)
          .get(),
    ]);
    final uniqueDocs = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final snapshot in snapshots) {
      for (final doc in snapshot.docs) {
        if (doc.id != excludingId) uniqueDocs[doc.id] = doc;
      }
    }

    return uniqueDocs.values
        .map((doc) {
          final data = doc.data();
          return User(
            id: doc.id,
            name: data['name'] as String? ?? '',
            lastName: data['lastName'] as String? ?? '',
            username: data['username'] as String? ?? '',
            email: data['email'] as String? ?? '',
            phone: data['phone'] as String? ?? '',
            photoUrl: data['photoUrl'] as String?,
          );
        })
        .where((user) {
          final normalized = query.toLowerCase();
          final fullName = '${user.name} ${user.lastName}'.trim().toLowerCase();
          return user.username.toLowerCase().startsWith(normalized) ||
              fullName.startsWith(normalized) ||
              (terms.length == 1 &&
                  (user.name.toLowerCase().startsWith(normalized) ||
                      user.lastName.toLowerCase().startsWith(normalized))) ||
              (terms.length > 1 &&
                  user.name.toLowerCase().startsWith(
                    firstNamePrefix.toLowerCase(),
                  ) &&
                  user.lastName.toLowerCase().startsWith(
                    lastNamePrefix.toLowerCase(),
                  ));
        })
        .toList();
  }
}
