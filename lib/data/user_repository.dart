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
}
