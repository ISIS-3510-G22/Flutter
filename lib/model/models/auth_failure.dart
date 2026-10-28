enum AuthError {
  invalidCredentials,
  userNotFound,
  invalidEmail,
  emailAlreadyInUse,
  weakPassword,
  network,
  unknown,
}

class AuthFailure implements Exception {
  const AuthFailure(this.error);

  final AuthError error;

  @override
  String toString() => 'AuthFailure(${error.name})';
}
