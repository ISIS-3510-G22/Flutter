import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plansync/model/data/connectivity_repository.dart';
import 'package:plansync/model/services/local/crew_local_store.dart';
import 'package:plansync/model/services/local/json_file_store.dart';
import 'package:plansync/model/services/local/upload_store.dart';
import 'package:plansync/model/data/pending_write_repository.dart';
import 'package:plansync/model/models/pending_write.dart';
import 'package:plansync/model/models/reimbursement_method.dart';
import 'package:plansync/model/models/user.dart';

class UserCache {
  UserCache({
    this.capacity = 50,
    this.timeToLive = const Duration(minutes: 10),
  });

  final int capacity;
  final Duration timeToLive;
  final _entries = <String, _CachedUser>{};

  User? get(String id, {bool allowStale = false}) {
    final entry = _entries.remove(id);
    if (entry == null) return null;
    _entries[id] = entry;
    if (!allowStale && DateTime.now().difference(entry.savedAt) >= timeToLive) {
      return null;
    }
    return entry.user;
  }

  void put(User user) {
    _entries.remove(user.id);
    _entries[user.id] = _CachedUser(user, DateTime.now());
    while (_entries.length > capacity) {
      _entries.remove(_entries.keys.first);
    }
  }

  void invalidate(String id) => _entries.remove(id);
}

class _CachedUser {
  const _CachedUser(this.user, this.savedAt);

  final User user;
  final DateTime savedAt;
}

class UserRepository {
  final _users = FirebaseFirestore.instance.collection('users');

  final _files = JsonFileStore();
  final _uploads = UploadStore();
  final _crewLocalStore = CrewLocalStore();
  static final _userCache = UserCache();

  PendingWriteRepository get _queue => PendingWriteRepository.instance;

  final _connectivity = ConnectivityRepository.instance;

  bool get isOnline => _connectivity.isOnline;

  User? cachedUser(String id, {bool allowStale = false}) =>
      _userCache.get(id, allowStale: allowStale);
  
  Future<String?> pendingPhoto(String uid) =>
      _uploads.pending('profile_$uid.jpg');

  Future<bool> saveProfile(User user) async {
    _userCache.put(user);
    await _saveLocal(user);
    return _queue.submit(
      PendingWrite(
        kind: WriteKind.profileUpdate,
        docId: user.id,
        payload: user.toJson(),
      ),
    );
  }

  Future<bool> savePhoto(String uid, String pickedPath) async {
    final path = await _uploads.save('profile_$uid.jpg', pickedPath);
    return _queue.submit(
      PendingWrite(
        kind: WriteKind.profilePhoto,
        docId: uid,
        payload: {'path': path},
      ),
    );
  }

  String _meFile(String uid) => 'me_$uid.json';

  Future<void> _saveLocal(User user) =>
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
      _connectivity.ensureOnline();
      final doc = await _users
          .doc(uid)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 8));
      if (!doc.exists) return null;
      final user = _getUserFromDoc(uid, doc.data()!);
      _userCache.put(user);
      await _saveLocal(user);
      return user;
    } catch (_) {
      final saved = await _readMe(uid);
      if (saved == null) rethrow;
      _userCache.put(saved);
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
      _connectivity.ensureOnline();
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
    final online = _connectivity.isOnline;
    final cached = _userCache.get(id, allowStale: !online);
    if (cached != null) return cached;
    if (!online) return null;

    try {
      _connectivity.ensureOnline();
      final doc = await _users
          .doc(id)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 8));
      if (!doc.exists) {
        _userCache.invalidate(id);
        return null;
      }
      final user = _getUserFromDoc(id, doc.data()!);
      _userCache.put(user);
      return user;
    } catch (_) {
      if (!_connectivity.isOnline) {
        return _userCache.get(id, allowStale: true);
      }
      rethrow;
    }
  }

  Future<void> createUser(User user) async {
    await _users.doc(user.id).set({
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
    _userCache.put(user);
  }

  Future<void> updateProfile(User user) async {
    _userCache.invalidate(user.id);
    await _users.doc(user.id).update({
      'name': user.name,
      'lastName': user.lastName,
      'phone': user.phone,
      'reimbursementMethods': user.reimbursementMethods
          .map((m) => m.toJson())
          .toList(),
    });
  }

  Future<void> updatePhotoUrl(String userId, String photoUrl) async {
    _userCache.invalidate(userId);
    await _users.doc(userId).update({'photoUrl': photoUrl});
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
    ConnectivityRepository.instance.ensureOnline();
    final snapshot = await _users
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 8));
    final users = snapshot.docs
        .where((doc) => doc.id != excludingId)
        .map((doc) => _getUserFromDoc(doc.id, doc.data()))
        .toList();
    await _crewLocalStore.saveDirectory(users);
    return users;
  }

  Future<bool> hasSavedSearchDirectory() => _crewLocalStore.hasSavedDirectory();

  Future<List<User>> storedSearchDirectory() => _crewLocalStore.directory();

  Future<List<User>> cachedUsersByIds(List<String> ids) =>
      _crewLocalStore.peopleByIds(ids);
}
