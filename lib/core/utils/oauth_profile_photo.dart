import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// True when [url] looks like a remote profile image from Google / Apple / Firebase.
bool isUsableOAuthProfilePhotoUrl(String? url) {
  if (url == null) return false;
  final trimmed = url.trim();
  if (trimmed.isEmpty) return false;
  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme) return false;
  if (uri.scheme != 'http' && uri.scheme != 'https') return false;
  return true;
}

/// Downloads an OAuth provider photo to a temp file for upload to Firebase Storage.
Future<String?> downloadOAuthProfilePhotoToTempFile(String url) async {
  if (!isUsableOAuthProfilePhotoUrl(url)) return null;
  try {
    final response = await http
        .get(Uri.parse(url.trim()))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
      return null;
    }
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/oauth_profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(response.bodyBytes, flush: true);
    return file.path;
  } catch (_) {
    return null;
  }
}
