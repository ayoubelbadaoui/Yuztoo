import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// google_fonts only picks up bundled files named `Family-Weight.ttf`; a
/// missing or renamed file silently falls back to a network download, which
/// fails on an offline first launch.
const _weightNames = {
  100: 'Thin',
  200: 'ExtraLight',
  300: 'Light',
  400: 'Regular',
  500: 'Medium',
  600: 'SemiBold',
  700: 'Bold',
  800: 'ExtraBold',
  900: 'Black',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final expected = <String, List<int>>{
    'Outfit': _weightNames.keys.toList(),
    'Inter': [300, 400, 500, 600, 700],
  };

  test('every bundled font file exists under assets/google_fonts', () {
    for (final entry in expected.entries) {
      for (final weight in entry.value) {
        final file =
            File('assets/google_fonts/${entry.key}-${_weightNames[weight]}.ttf');
        expect(file.existsSync(), isTrue, reason: '${file.path} missing');
        expect(file.lengthSync(), greaterThan(10000), reason: file.path);
      }
    }
  });

  test('pubspec bundles the google_fonts asset folder', () {
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('- assets/google_fonts/'),
    );
  });

  test('fonts load with runtime fetching disabled', () async {
    GoogleFonts.config.allowRuntimeFetching = false;
    addTearDown(() => GoogleFonts.config.allowRuntimeFetching = true);
    for (final weight in expected['Outfit']!) {
      GoogleFonts.outfit(fontWeight: FontWeight.values[weight ~/ 100 - 1]);
    }
    for (final weight in expected['Inter']!) {
      GoogleFonts.inter(fontWeight: FontWeight.values[weight ~/ 100 - 1]);
    }
    await expectLater(GoogleFonts.pendingFonts(), completes);
  });
}
