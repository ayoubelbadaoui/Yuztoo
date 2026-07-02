import '../../../core/infrastructure/nfc_service.dart';
import '../../loyalty/application/use_cases/process_vitrine_scan_visit.dart';
import '../../loyalty/domain/entities/client_merchant_loyalty_progress.dart';

/// Hardware read outcomes emulated without a physical NTAG213.
enum NfcTagReadScenario {
  successValidTag,
  emptyTag,
  invalidTag,
  nfcUnavailable,
  readCancelled,
  readError,
}

/// Merchant-side write outcomes emulated without programming a sticker.
enum NfcTagWriteScenario {
  writeSuccess,
  notNdef,
  readOnly,
  capacityInsufficient,
  nfcUnavailable,
  writeCancelled,
  writeError,
}

/// Post-read vitrine funnel branches ([ProcessVitrineScanVisit]).
enum NfcVitrineFunnelScenario {
  guestConnectSheet,
  followFirstSheet,
  loyaltyInactiveStorefront,
  automaticVisitCelebration,
  manualAwaitingMerchant,
  cooldownSnackbar,
  genericErrorSnackbar,
}

/// Canonical French copy + metadata for the NFC debug emulator UI.
abstract final class NfcDebugScenarioCatalog {
  static const String placeholderMerchantId = 'debug-merchant-id';

  static List<({String title, String subtitle})> tagReadOptions() => [
        (
          title: 'Tag valide',
          subtitle:
              'Badge NDEF avec https://yuztoo.app/vitrine/{id} → ouvre la vitrine.',
        ),
        (
          title: 'Badge vide',
          subtitle: 'NDEF sans enregistrement — message « badge vide ».',
        ),
        (
          title: 'Badge non Yuztoo',
          subtitle: 'URL tierce — message « ne pointe pas vers une vitrine ».',
        ),
        (
          title: 'NFC indisponible',
          subtitle: 'Matériel absent ou NFC désactivé dans les réglages.',
        ),
        (
          title: 'Lecture annulée',
          subtitle: 'L’utilisateur ferme la feuille iOS/Android sans tag.',
        ),
        (
          title: 'Erreur de lecture',
          subtitle: 'Échec matériel ou tag retiré trop tôt.',
        ),
      ];

  static List<({String title, String subtitle})> tagWriteOptions() => [
        (
          title: 'Écriture réussie',
          subtitle: 'URL vitrine écrite — toast vert « Badge programmé ».',
        ),
        (
          title: 'Badge non NDEF',
          subtitle: 'NTAG213 non formaté — message format NDEF requis.',
        ),
        (
          title: 'Badge verrouillé',
          subtitle: 'Tag en lecture seule — impossible de reprogrammer.',
        ),
        (
          title: 'Capacité insuffisante',
          subtitle: 'URL trop longue pour la mémoire user du tag.',
        ),
        (
          title: 'NFC indisponible',
          subtitle: 'Même message que côté client.',
        ),
        (
          title: 'Programmation annulée',
          subtitle: 'Session NFC fermée avant écriture.',
        ),
        (
          title: 'Erreur d’écriture',
          subtitle: 'Échec générique avec message d’erreur.',
        ),
      ];

  static List<({String title, String subtitle, String precondition})>
      funnelOptions() => [
        (
          title: 'Invité — connexion',
          subtitle: 'Sheet « Se connecter pour suivre » + continuer sans compte.',
          precondition: 'Force l’UI invité (ignore l’état auth réel).',
        ),
        (
          title: 'Connecté — suivre d’abord',
          subtitle: 'Sheet « Suivre ce commerce » puis cadeau de bienvenue.',
          precondition: 'Force l’UI non-suiveur.',
        ),
        (
          title: 'Fidélité inactive',
          subtitle: 'Vitrine seule, aucun passage ni modal.',
          precondition: 'Force vitrine sans action fidélité.',
        ),
        (
          title: 'Passage auto enregistré',
          subtitle: 'Overlay célébration or (mode automatique).',
          precondition: 'Force la célébration sans écrire Firestore.',
        ),
        (
          title: 'Validation commerçant',
          subtitle: 'Bannière « validation en cours » (mode manuel).',
          precondition:
              'Force l’état UI ; la session Firestore peut ne pas exister.',
        ),
        (
          title: 'Cooldown 1 h',
          subtitle: 'SnackBar or « Patientez 1 heure ».',
          precondition: 'Force le message cooldown.',
        ),
        (
          title: 'Erreur passage',
          subtitle: 'SnackBar rouge avec message d’erreur.',
          precondition: 'Force une erreur générique.',
        ),
      ];

  static NfcResult tagReadResult(
    NfcTagReadScenario scenario, {
    String merchantId = placeholderMerchantId,
  }) {
    return switch (scenario) {
      NfcTagReadScenario.successValidTag =>
        NfcSuccess(merchantId: merchantId.trim()),
      NfcTagReadScenario.emptyTag => const NfcError(
          'Ce badge NFC est vide — il doit être programmé par le commerçant.',
        ),
      NfcTagReadScenario.invalidTag => const NfcError(
          'Ce badge ne pointe pas vers une vitrine Yuztoo.',
        ),
      NfcTagReadScenario.nfcUnavailable => const NfcUnavailable(),
      NfcTagReadScenario.readCancelled => const NfcError('Lecture annulée.'),
      NfcTagReadScenario.readError => const NfcError(
          'Impossible de lire le tag NFC : timeout matériel simulé.',
        ),
    };
  }

  static NfcResult tagWriteResult(NfcTagWriteScenario scenario) {
    return switch (scenario) {
      NfcTagWriteScenario.writeSuccess => const NfcSuccess(),
      NfcTagWriteScenario.notNdef => const NfcError(
          'Ce badge n\'est pas compatible NDEF — utilisez un sticker '
          'NTAG213 ou équivalent.',
        ),
      NfcTagWriteScenario.readOnly => const NfcError(
          'Ce badge NFC est en lecture seule et ne peut pas être programmé.',
        ),
      NfcTagWriteScenario.capacityInsufficient => const NfcError(
          'Capacité du badge insuffisante (137 octets disponibles '
          'pour 200 requis).',
        ),
      NfcTagWriteScenario.nfcUnavailable => const NfcUnavailable(),
      NfcTagWriteScenario.writeCancelled =>
        const NfcError('Programmation annulée.'),
      NfcTagWriteScenario.writeError => const NfcError(
          'Impossible de programmer le badge NFC : erreur simulée.',
        ),
    };
  }

  static ScanVisitResult funnelResult(NfcVitrineFunnelScenario scenario) {
    return switch (scenario) {
      NfcVitrineFunnelScenario.guestConnectSheet => const ScanVisitGuest(),
      NfcVitrineFunnelScenario.followFirstSheet =>
        const ScanVisitNotFollowing(),
      NfcVitrineFunnelScenario.loyaltyInactiveStorefront =>
        const ScanVisitLoyaltyInactive(),
      NfcVitrineFunnelScenario.automaticVisitCelebration =>
        const ScanVisitVisitRecorded(ClientMerchantLoyaltyProgress.empty()),
      NfcVitrineFunnelScenario.manualAwaitingMerchant =>
        const ScanVisitAwaitingMerchant(),
      NfcVitrineFunnelScenario.cooldownSnackbar => const ScanVisitCooldownBlocked(
          'Votre passage vient d’être enregistré. Patientez 1 heure avant un nouveau passage chez ce commerçant.',
        ),
      NfcVitrineFunnelScenario.genericErrorSnackbar =>
        const ScanVisitError(
          'Impossible d’enregistrer le passage (erreur simulée).',
        ),
    };
  }

  static NfcTagReadScenario tagReadScenarioAt(int index) =>
      NfcTagReadScenario.values[index];

  static NfcTagWriteScenario tagWriteScenarioAt(int index) =>
      NfcTagWriteScenario.values[index];

  static NfcVitrineFunnelScenario funnelScenarioAt(int index) =>
      NfcVitrineFunnelScenario.values[index];
}
