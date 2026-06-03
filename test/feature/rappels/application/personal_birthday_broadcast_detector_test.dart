import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/rappels/application/personal_birthday_broadcast_detector.dart';

void main() {
  group('isLikelyPersonalBirthdayBroadcast', () {
    test('returns false when audience is segment-targeted', () {
      expect(
        isLikelyPersonalBirthdayBroadcast(
          text: 'Joyeux anniversaire 🎂',
          isBroadcastAudience: false,
        ),
        isFalse,
      );
    });

    test('returns false when text is empty or whitespace', () {
      expect(
        isLikelyPersonalBirthdayBroadcast(
          text: '',
          isBroadcastAudience: true,
        ),
        isFalse,
      );
      expect(
        isLikelyPersonalBirthdayBroadcast(
          text: '   ',
          isBroadcastAudience: true,
        ),
        isFalse,
      );
    });

    test('returns true on "joyeux anniversaire" broadcast', () {
      expect(
        isLikelyPersonalBirthdayBroadcast(
          text: 'Joyeux anniversaire 🎂 profitez de -20% en boutique !',
          isBroadcastAudience: true,
        ),
        isTrue,
      );
    });

    test('returns true on "bon anniversaire" broadcast (case-insensitive)', () {
      expect(
        isLikelyPersonalBirthdayBroadcast(
          text: 'BON ANNIVERSAIRE de notre part 💛',
          isBroadcastAudience: true,
        ),
        isTrue,
      );
    });

    test('returns true on English "happy birthday" broadcast', () {
      expect(
        isLikelyPersonalBirthdayBroadcast(
          text: 'Happy birthday from the team',
          isBroadcastAudience: true,
        ),
        isTrue,
      );
    });

    test('returns false on neutral broadcast that mentions anniversaire only without cue', () {
      // "anniversaire" alone (e.g. anniversary of the shop) is not flagged —
      // we only catch personalised wishes ("joyeux/bon anniversaire").
      expect(
        isLikelyPersonalBirthdayBroadcast(
          text:
              "C'est l'anniversaire de notre commerce — passez nous voir !",
          isBroadcastAudience: true,
        ),
        isFalse,
      );
    });

    test('returns false on completely unrelated promo broadcast', () {
      expect(
        isLikelyPersonalBirthdayBroadcast(
          text: 'Nouveau menu cette semaine, venez nombreux !',
          isBroadcastAudience: true,
        ),
        isFalse,
      );
    });
  });
}
