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

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'lastName': lastName,
    'username': username,
    'email': email,
    'phone': phone,
    'photoUrl': photoUrl,
    'reimbursementMethods': [for (final m in reimbursementMethods) m.toJson()],
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    name: json['name'] as String,
    lastName: json['lastName'] as String,
    username: json['username'] as String,
    email: json['email'] as String,
    phone: json['phone'] as String,
    photoUrl: json['photoUrl'] as String?,
    reimbursementMethods: [
      for (final m in json['reimbursementMethods'] as List)
        ReimbursementMethod.fromJson(m as Map<String, dynamic>),
    ],
  );
}
