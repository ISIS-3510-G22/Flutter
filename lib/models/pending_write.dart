class PendingWrite<K extends Enum> {
  final int? id;
  final K kind;
  final String docId;
  final Map<String, dynamic> payload;

  const PendingWrite({
    this.id,
    required this.kind,
    required this.docId,
    required this.payload,
  });
}
