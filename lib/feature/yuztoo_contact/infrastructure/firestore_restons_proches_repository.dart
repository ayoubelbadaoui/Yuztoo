import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/config/yuztoo_official_page.dart';
import '../../../core/domain/core/either.dart';
import '../../../core/domain/core/result.dart';
import '../domain/entities/restons_proches_profile.dart';
import '../domain/repositories/restons_proches_repository.dart';
import '../domain/restons_proches_failure.dart';

/// Reads / writes Restons proches content on the YuzToo official merchant doc.
///
/// Person-facing copy lives under `restons_proches` map; phone / e-mail /
/// address / website / photo reuse the standard merchant contact fields so the
/// storefront stays in sync.
class FirestoreRestonsProchesRepository implements RestonsProchesRepository {
  FirestoreRestonsProchesRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  static const _mapKey = 'restons_proches';

  @override
  Future<Result<RestonsProchesProfile?>> getProfile() async {
    final id = YuztooOfficialPage.merchantId();
    if (id == null) return const Right(null);

    try {
      final snap = await _firestore.collection('merchants').doc(id).get();
      if (!snap.exists || snap.data() == null) {
        return const Left(
          RestonsProchesUnexpectedFailure('Page YuzToo introuvable.'),
        );
      }
      return Right(_fromDoc(id, snap.data()!));
    } catch (e) {
      return Left(
        RestonsProchesUnexpectedFailure(e.toString()),
      );
    }
  }

  @override
  Future<Result<RestonsProchesProfile>> saveProfile(
    RestonsProchesProfile profile,
  ) async {
    final id = YuztooOfficialPage.merchantId();
    if (id == null || id != profile.merchantId) {
      return const Left(RestonsProchesNotConfiguredFailure());
    }

    final personName = profile.personName.trim();
    final roleTitle = profile.roleTitle.trim();
    final bio = profile.bio.trim();
    final email = profile.email.trim();
    if (personName.isEmpty) {
      return const Left(
        RestonsProchesUnexpectedFailure('Le nom est requis.'),
      );
    }
    if (email.isEmpty) {
      return const Left(
        RestonsProchesUnexpectedFailure('L\'e-mail est requis.'),
      );
    }

    try {
      final ref = _firestore.collection('merchants').doc(id);
      await ref.update({
        _mapKey: {
          'person_name': personName,
          'role_title': roleTitle,
          'bio': bio,
        },
        'phone': profile.phone.trim(),
        'email': email,
        'address': profile.address.trim(),
        'website_url': profile.website.trim(),
        if (profile.photoUrl != null) 'logo_url': profile.photoUrl,
        'updated_at': FieldValue.serverTimestamp(),
      });

      final fresh = await ref.get();
      final data = fresh.data();
      if (data == null) {
        return const Left(
          RestonsProchesUnexpectedFailure(
            'Enregistrement impossible — document manquant.',
          ),
        );
      }
      return Right(_fromDoc(id, data));
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return const Left(RestonsProchesPermissionFailure());
      }
      return Left(
        RestonsProchesUnexpectedFailure(e.message ?? 'Erreur Firestore'),
      );
    } catch (e) {
      return Left(
        RestonsProchesUnexpectedFailure(e.toString()),
      );
    }
  }

  RestonsProchesProfile _fromDoc(String id, Map<String, dynamic> data) {
    final map = data[_mapKey];
    final restons = map is Map
        ? Map<String, dynamic>.from(map)
        : const <String, dynamic>{};

    String str(dynamic v) => v is String ? v.trim() : '';

    final personName = str(restons['person_name']);
    final roleTitle = str(restons['role_title']);
    final bio = str(restons['bio']);
    final email = str(data['email']);
    final address = str(data['address']);
    final city = str(data['city']);

    return RestonsProchesProfile(
      merchantId: id,
      ownerUid: str(data['owner_uid']),
      personName: personName.isNotEmpty
          ? personName
          : RestonsProchesProfile.defaultPersonName,
      roleTitle: roleTitle.isNotEmpty
          ? roleTitle
          : RestonsProchesProfile.defaultRoleTitle,
      bio: bio.isNotEmpty ? bio : RestonsProchesProfile.defaultBio,
      email: email.isNotEmpty ? email : RestonsProchesProfile.defaultEmail,
      photoUrl: str(data['logo_url']).isEmpty ? null : str(data['logo_url']),
      phone: str(data['phone']),
      address: address.isNotEmpty ? address : city,
      website: str(data['website_url']),
    );
  }
}
