import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:plansync/data/user_repository.dart';
import 'package:plansync/models/user.dart';

class AuthService {
  final _firebaseAuth = fb.FirebaseAuth.instance;
  final _userRepository = UserRepository();

  Stream<User?> get authStateChanges {
    return _firebaseAuth
        .authStateChanges()
        .withInitialTimeout(const Duration(seconds: 20))
        .asyncMap((fbUser) async {
          if (fbUser == null) return null;
          return _userRepository
              .getUser(fbUser.uid)
              .timeout(const Duration(seconds: 20));
        });
  }

  Future<void> signIn({required String email, required String password}) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<String> signUp({
    required String email,
    required String password,
  }) async {
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

extension _InitialAuthStateTimeout on Stream<fb.User?> {
  Stream<fb.User?> withInitialTimeout(Duration duration) {
    return Stream<fb.User?>.multi((controller) {
      var receivedInitialState = false;
      final timer = Timer(duration, () {
        if (receivedInitialState) return;
        receivedInitialState = true;
        controller.addError(
          TimeoutException(
            'Firebase Authentication did not emit its initial state.',
          ),
        );
      });

      late final StreamSubscription<fb.User?> subscription;
      subscription = listen(
        (user) {
          if (!receivedInitialState) {
            receivedInitialState = true;
            timer.cancel();
          }
          controller.add(user);
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!receivedInitialState) {
            receivedInitialState = true;
            timer.cancel();
          }
          controller.addError(error, stackTrace);
        },
        onDone: controller.close,
      );

      controller.onCancel = () async {
        timer.cancel();
        await subscription.cancel();
      };
    });
  }
}
