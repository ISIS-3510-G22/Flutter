import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plansync/data/local/json_file_store.dart';
import 'package:plansync/models/reimbursement_method.dart';
import 'package:plansync/models/user.dart';

class UserRepository {
  final _users = FirebaseFirestore.instance.collection('users');

  final _files = JsonFileStore();

  String _meFile(String uid) => 'me_$uid.json';

  Future<void> saveLocal(User user) =>
      _files.write(_meFile(user.id), jsonEncode(user.toJson()));

  Future<User?> _readMe(String uid) async {
    final text = await _files.read(_meFile(uid));
    if (text == null) return null;
    try {
      return User.fromJson(jsonDecode(text) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<User?> currentUser(String uid) async {
    try {
      final doc = await _users
          .doc(uid)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 8));
      if (!doc.exists) return null;
      final user = _getUserFromDoc(uid, doc.data()!);
      await saveLocal(user);
      return user;
    } catch (_) {
      final saved = await _readMe(uid);
      if (saved == null) rethrow;
      return saved;
    }
  }

  Future<List<User>> _readPeople(String filename) async {
    final text = await _files.read(filename);
    if (text == null) return [];
    try {
      return [
        for (final data in jsonDecode(text) as List)
          _getUserFromDoc(data['id'] as String, data as Map<String, dynamic>),
      ];
    } catch (_) {
      return [];
    }
  }

  Future<List<User>> planPeople(String planId, List<String> ids) async {
    final file = 'plan_${planId}_people.json';
    try {
      final users = await getUsers(
        ids,
        source: Source.server,
      ).timeout(const Duration(seconds: 8));
      await _files.write(
        file,
        jsonEncode([
          for (final u in users)
            {
              'id': u.id,
              'name': u.name,
              'lastName': u.lastName,
              'photoUrl': u.photoUrl,
            },
        ]),
      );
      return users;
    } catch (_) {
      return _readPeople(file);
    }
  }

  User _getUserFromDoc(String docId, Map<String, dynamic> data) {
    return User(
      id: docId,
      name: data['name'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      username: data['username'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
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

  Future<User?> getUser(String id) async {
    final doc = await _users.doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    return _getUserFromDoc(id, data);
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
          .map((m) => m.toJson())
          .toList(),
    });
  }

  Future<void> updatePhotoUrl(String userId, String photoUrl) {
    return _users.doc(userId).update({'photoUrl': photoUrl});
  }

  Future<List<User>> getUsers(
    List<String> ids, {
    Source source = Source.serverAndCache,
  }) async {
    if (ids.isEmpty) return [];
    final snapshot = await _users
        .where(FieldPath.documentId, whereIn: ids)
        .get(GetOptions(source: source));
    return snapshot.docs
        .map((doc) => _getUserFromDoc(doc.id, doc.data()))
        .toList();
  }

  Future<List<User>> getUsersForSearch({String? excludingId}) async {
    final snapshot = await _users.get();
    return snapshot.docs.where((doc) => doc.id != excludingId).map((doc) {
      return _getUserFromDoc(doc.id, doc.data());
    }).toList();
  }
}
