abstract class AppNotification {
  const AppNotification();

  factory AppNotification.rsvpReminder(DateTime invitedAt) = _RsvpReminder;

  String get message;
}

class _RsvpReminder extends AppNotification {
  const _RsvpReminder(this.invitedAt);

  final DateTime invitedAt;

  @override
  String get message {
    final days = DateTime.now().difference(invitedAt).inDays;
    return 'Invited $days days ago, still no answer';
  }
}
