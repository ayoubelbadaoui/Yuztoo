/// Canonical auto-notification trigger strings.
///
/// Must stay aligned with `functions/src/auto_notification_core.ts`
/// (`AUTO_NOTIFICATION_TRIGGERS`).
class AutoNotificationTriggers {
  AutoNotificationTriggers._();

  static const String birthday = 'Date anniversaire client';
  static const String segmentChange = 'Changement de Statut client';
  static const String newFollower = 'Nouveau client connecté';
  static const String visitDetected = 'Visite client détectée';
  static const String passageValidated = 'Passage fidélité validé';
  static const String inactiveReturn = 'Retour d\'un client inactif';
  static const String rewardAvailable = 'Récompense disponible';
  static const String rewardNear = 'Récompense proche';
  static const String exceptionalClosure = 'Fermeture exceptionnelle';
  static const String newPartner = 'Nouveau partenaire';
  static const String connectionAnniversary = 'Anniversaire de connexion';

  /// Order matches [TriggerGrid] indices.
  static const List<String> triggerLabels = [
    birthday,
    segmentChange,
    newFollower,
    visitDetected,
    passageValidated,
    inactiveReturn,
    rewardAvailable,
    rewardNear,
    exceptionalClosure,
    newPartner,
    connectionAnniversary,
  ];

  /// Triggers backed by a Cloud Function handler in production.
  static const Set<String> wiredInCloud = {
    birthday,
    segmentChange,
    newFollower,
    passageValidated,
    inactiveReturn,
    rewardAvailable,
    rewardNear,
    exceptionalClosure,
    newPartner,
    connectionAnniversary,
  };

  static bool isWiredInCloud(String trigger) => wiredInCloud.contains(trigger);
}
