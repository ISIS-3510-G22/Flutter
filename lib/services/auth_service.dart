import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:plansync/data/user_repository.dart';
import 'package:plansync/models/user.dart';

class AuthService {
  final _firebaseAuth = fb.FirebaseAuth.instance;
  final _userRepository = UserRepository();

  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((fbUser) {
      if (fbUser == null) return null;
      return _userRepository.getUser(fbUser.uid);
    });
  }

  Future<void> signIn({required String email, required String password}) {
    return _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<String> signUp({required String email, required String password}) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user!.uid;
  }

  Future<void> sendPasswordResetEmail({required String email}) {
    return _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() => _firebaseAuth.signOut();
}
