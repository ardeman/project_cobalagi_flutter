import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Checks codes that unlock the supporter plan without a donation, e.g. for
/// Google Play reviewers. Only SHA-256 hashes ship with the app (the repo is
/// public); the codes themselves are kept outside it.
class UnlockCodes {
  const UnlockCodes(this.sha256Hashes);

  /// Lowercase hex SHA-256 of each normalized code.
  final Set<String> sha256Hashes;

  /// Case, spaces and dashes are ignored, so `abcd-efgh` matches `ABCDEFGH`.
  static String normalize(String code) =>
      code.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');

  bool accepts(String code) {
    final normalized = normalize(code);
    if (normalized.isEmpty) return false;
    return sha256Hashes.contains(
      sha256.convert(utf8.encode(normalized)).toString(),
    );
  }
}
