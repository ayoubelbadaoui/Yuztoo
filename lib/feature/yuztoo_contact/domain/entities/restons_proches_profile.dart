/// Editable "Restons proches" / Pascal contact page content.
///
/// Stored on the YuzToo official merchant document so the owner can update
/// every field shown on [YuztooContactScreen] without a separate CMS.
class RestonsProchesProfile {
  const RestonsProchesProfile({
    required this.merchantId,
    required this.ownerUid,
    required this.personName,
    required this.roleTitle,
    required this.bio,
    required this.email,
    this.photoUrl,
    this.phone = '',
    this.address = '',
    this.website = '',
  });

  static const defaultPersonName = 'Pascal';
  static const defaultRoleTitle = 'Fondateur de Yuztoo';
  static const defaultBio =
      'Une question, une idée, un souci ? Écrivez-moi ou appelez-moi, '
      'je vous réponds personnellement.';
  static const defaultEmail = 'contact@yuztoo.com';

  final String merchantId;
  final String ownerUid;
  final String personName;
  final String roleTitle;
  final String bio;
  final String email;
  final String? photoUrl;
  final String phone;
  final String address;
  final String website;

  RestonsProchesProfile copyWith({
    String? personName,
    String? roleTitle,
    String? bio,
    String? email,
    String? photoUrl,
    String? phone,
    String? address,
    String? website,
    bool clearPhotoUrl = false,
  }) {
    return RestonsProchesProfile(
      merchantId: merchantId,
      ownerUid: ownerUid,
      personName: personName ?? this.personName,
      roleTitle: roleTitle ?? this.roleTitle,
      bio: bio ?? this.bio,
      email: email ?? this.email,
      photoUrl: clearPhotoUrl ? null : (photoUrl ?? this.photoUrl),
      phone: phone ?? this.phone,
      address: address ?? this.address,
      website: website ?? this.website,
    );
  }
}
