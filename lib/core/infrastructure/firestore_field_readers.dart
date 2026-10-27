import 'package:cloud_firestore/cloud_firestore.dart';

// Type-tolerant reads for Firestore fields. A field written with the wrong
// type (console edit, older app version, Cloud Function bug) reads as null
// instead of throwing a TypeError that would fail the whole document.

String? fsString(Object? v) => v is String ? v : null;

bool? fsBool(Object? v) => v is bool ? v : null;

/// Finite numbers only: NaN / infinity would throw on `toInt()`.
num? fsNum(Object? v) => v is num && v.isFinite ? v : null;

Timestamp? fsTimestamp(Object? v) => v is Timestamp ? v : null;

List<String> fsStringList(Object? v) =>
    v is List ? v.whereType<String>().toList() : const <String>[];

Map<String, dynamic>? fsMap(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : null;
