/// Data holder for an active notification.
class ActiveNotification {
  final String text;
  final String trigger;
  final String audience;
  bool isEnabled;

  ActiveNotification({
    required this.text,
    this.trigger = 'Date anniversaire client',
    this.audience = 'Tous mes clients',
    this.isEnabled = true,
  });
}

