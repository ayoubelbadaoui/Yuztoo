import 'package:firebase_core/firebase_core.dart';

/// The YuzToo company storefront (Pascal's photo, phone, e-mail, address),
/// opened from the Yuztoo cards in the client app.
abstract final class YuztooOfficialPage {
  /// `merchants/{id}` of the YuzToo page, per Firebase project.
  static const Map<String, String> _merchantIdByProject = {
    'yuztoo': 'hIBHZoC70wPLA6OqBP44KbbxSVA2',
    'yuztoo-dev': 'p5YvllnO1NRu97JAu0p1JYfSrpR2',
  };

  /// Null when the current project has no YuzToo page.
  static String? merchantId() {
    try {
      return _merchantIdByProject[Firebase.app().options.projectId];
    } on Object {
      return null;
    }
  }
}
