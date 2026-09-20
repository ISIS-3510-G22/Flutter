import 'package:plansync/models/reimbursement_method.dart';

class User {
  final String id;
  final String name;
  final String lastName;
  final String username;
  final String email;
  final String phone;
  final String? photoUrl;
  final List<ReimbursementMethod> reimbursementMethods;

  const User({
    required this.id,
    required this.name,
    required this.lastName,
    required this.username,
    required this.email,
    required this.phone,
    this.photoUrl,
    this.reimbursementMethods = const [],
  });
}
