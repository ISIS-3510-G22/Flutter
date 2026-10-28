class ReimbursementMethod {
  final String id;
  final String type;
  final String account;

  const ReimbursementMethod({
    required this.id,
    required this.type,
    required this.account,
  });

  Map<String, dynamic> toJson() => {'id': id, 'type': type, 'account': account};

  factory ReimbursementMethod.fromJson(Map<String, dynamic> json) =>
      ReimbursementMethod(
        id: json['id'] as String,
        type: json['type'] as String,
        account: json['account'] as String,
      );
}
