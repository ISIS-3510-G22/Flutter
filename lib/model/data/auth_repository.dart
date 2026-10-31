import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:plansync/model/data/connectivity_repository.dart';
import 'package:plansync/model/data/user_repository.dart';
import 'package:plansync/model/models/auth_failure.dart';
import 'package:plansync/model/models/user.dart';
import 'package:plansync/model/services/auth_service.dart';

class AuthRepository {
  final _authService = AuthService();
  final _userRepository = UserRepository();

  Stream<User?> get authStateChanges {
    return _authService.authStateChanges.asyncMap((fbUser) async {
      if (fbUser == null) return null;
      return _userRepository.currentUser(fbUser.uid);
    });
  }

  Future<void> signIn({required String email, required String password}) {
    return _translate(
      () => _authService.signIn(email: email, password: password),
    );
  }

  Future<String> signUp({required String email, required String password}) {
    return _translate(
      () => _authService.signUp(email: email, password: password),
    );
  }

  Future<void> sendPasswordResetEmail({required String email}) {
    return _translate(() {
      ConnectivityRepository.instance.ensureOnline();
      return _authService
          .sendPasswordResetEmail(email: email)
          .timeout(const Duration(seconds: 8));
    });
  }

  Future<void> signOut() => _translate(_authService.signOut);

  Future<T> _translate<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_errorFor(e.code));
    }
  }

  AuthError _errorFor(String code) {
    return switch (code) {
      'wrong-password' || 'invalid-credential' => AuthError.invalidCredentials,
      'user-not-found' => AuthError.userNotFound,
      'invalid-email' => AuthError.invalidEmail,
      'email-already-in-use' => AuthError.emailAlreadyInUse,
      'weak-password' => AuthError.weakPassword,
      'network-request-failed' => AuthError.network,
      _ => AuthError.unknown,
    };
  }
}
