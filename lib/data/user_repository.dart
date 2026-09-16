import 'package:cloud_firestore/cloud_firestore.dart';
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
    );
  }
}