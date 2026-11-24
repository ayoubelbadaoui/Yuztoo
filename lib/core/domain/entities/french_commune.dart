/// Administrative data for a French commune returned by geo.api.gouv.fr.
///
/// [size] is an application classification derived from the official
/// population. It is not an administrative category published by the API.
enum FrenchCommuneSize {
  village,
  smallTown,
  city,
  largeCity;

  String get label => switch (this) {
        FrenchCommuneSize.village => 'Village',
        FrenchCommuneSize.smallTown => 'Petite ville',
        FrenchCommuneSize.city => 'Ville',
        FrenchCommuneSize.largeCity => 'Grande ville',
      };
}

class FrenchCommune {
  const FrenchCommune({
    required this.name,
    this.inseeCode,
    this.postalCodes = const <String>[],
    this.population,
    this.departmentCode,
    this.regionCode,
    this.epciCode,
    this.epciName,
    this.longitude,
    this.latitude,
  });

  final String name;
  final String? inseeCode;
  final List<String> postalCodes;
  final int? population;
  final String? departmentCode;
  final String? regionCode;

  /// Official intercommunality (EPCI) linking the commune to its wider area.
  final String? epciCode;
  final String? epciName;

  final double? longitude;
  final double? latitude;

  factory FrenchCommune.fromFirestore(Map<String, dynamic> map) {
    String? stringValue(String key) {
      final value = map[key];
      return value is String && value.trim().isNotEmpty ? value.trim() : null;
    }

    final rawPostalCodes = map['postal_codes'];
    return FrenchCommune(
      name: stringValue('name') ?? '',
      inseeCode: stringValue('insee_code'),
      postalCodes: rawPostalCodes is List
          ? rawPostalCodes.whereType<String>().toList(growable: false)
          : const <String>[],
      population:
          map['population'] is num ? (map['population'] as num).toInt() : null,
      departmentCode: stringValue('department_code'),
      regionCode: stringValue('region_code'),
      epciCode: stringValue('epci_code'),
      epciName: stringValue('epci_name'),
      longitude:
          map['longitude'] is num ? (map['longitude'] as num).toDouble() : null,
      latitude:
          map['latitude'] is num ? (map['latitude'] as num).toDouble() : null,
    );
  }

  FrenchCommuneSize get size {
    final inhabitants = population ?? 0;
    if (inhabitants >= 100000) return FrenchCommuneSize.largeCity;
    if (inhabitants >= 20000) return FrenchCommuneSize.city;
    if (inhabitants >= 2000) return FrenchCommuneSize.smallTown;
    return FrenchCommuneSize.village;
  }

  String get locationLabel {
    final parts = <String>[
      if (postalCodes.isNotEmpty) postalCodes.first,
      if (departmentCode != null && departmentCode!.trim().isNotEmpty)
        'dépt. $departmentCode',
    ];
    return parts.join(' · ');
  }

  FrenchCommune copyWith({
    String? epciName,
  }) =>
      FrenchCommune(
        name: name,
        inseeCode: inseeCode,
        postalCodes: postalCodes,
        population: population,
        departmentCode: departmentCode,
        regionCode: regionCode,
        epciCode: epciCode,
        epciName: epciName ?? this.epciName,
        longitude: longitude,
        latitude: latitude,
      );

  /// Backward-compatible Firestore metadata. The legacy `city` string remains
  /// the source used by existing screens and queries.
  Map<String, dynamic> toFirestore() => <String, dynamic>{
        'name': name,
        if (inseeCode != null) 'insee_code': inseeCode,
        if (postalCodes.isNotEmpty) 'postal_codes': postalCodes,
        if (population != null) 'population': population,
        'size': size.name,
        if (departmentCode != null) 'department_code': departmentCode,
        if (regionCode != null) 'region_code': regionCode,
        if (epciCode != null) 'epci_code': epciCode,
        if (epciName != null) 'epci_name': epciName,
        if (longitude != null) 'longitude': longitude,
        if (latitude != null) 'latitude': latitude,
        'source': 'geo.api.gouv.fr',
      };
}
