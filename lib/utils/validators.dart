final _tagPattern = RegExp(r'^[\p{L}\p{N}][\p{L}\p{N} -]*$', unicode: true);
final _alphabeticPattern = RegExp(r'^\p{L}+$', unicode: true);
final _usernamePattern = RegExp(r'^[A-Za-z0-9]+$');
final _phonePattern = RegExp(r'^[0-9]+$');
final _emailPattern = RegExp(
  r'^[^\s@]+@(?:[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?\.)+[A-Za-z]{2,}$',
);
final _passwordPattern = RegExp(r'^[A-Za-z0-9]+$');

String? validateName(String? value) => _validateName(value, 'Name');

String? validateLastName(String? value) => _validateName(value, 'Last name');

String? _validateName(String? value, String label) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) return '$label is required.';
  if (name.length > 20) return '$label can be 20 characters at most.';
  if (!_alphabeticPattern.hasMatch(name)) {
    return '$label can contain letters only.';
  }
  return null;
}

String? validateUsername(String? value) {
  final username = value?.trim() ?? '';
  if (username.isEmpty) return 'Username is required.';
  if (username.length > 20) return 'Username can be 20 characters at most.';
  if (!_usernamePattern.hasMatch(username)) {
    return 'Use only letters and numbers.';
  }
  return null;
}

String? validatePhone(String? value) {
  final phone = value?.trim() ?? '';
  if (phone.isEmpty) return 'Phone number is required.';
  if (!_phonePattern.hasMatch(phone)) {
    return 'Use numbers only, without spaces or symbols.';
  }
  if (phone.length > 15) {
    return 'Phone number can be 15 digits at most.';
  }
  return null;
}

String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Email address is required.';
  if (!_emailPattern.hasMatch(email)) return 'Enter a valid email address.';
  return null;
}

String? validatePassword(String? value) {
  final password = value ?? '';
  if (password.isEmpty) return 'Password is required.';
  if (password.length < 8) return 'Use at least 8 characters.';
  if (!_passwordPattern.hasMatch(password)) {
    return 'Use letters and numbers only.';
  }
  return null;
}

String? validateTag(String tag) {
  if (tag.length > 20) return 'Tags can be 20 characters at most.';
  if (!_tagPattern.hasMatch(tag)) {
    return 'Use only letters, numbers, spaces and hyphens.';
  }
  return null;
}

double? parsePrice(String text) =>
    RegExp(r'^\d{1,9}$').hasMatch(text) ? double.parse(text) : null;
