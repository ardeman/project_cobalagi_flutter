import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Checks codes bought on the website, which Dahlunas (Ardeman's payment
/// service) emails to the buyer: `DL1.` and 144 Base32 characters, signed with
/// Ed25519 and checked here without going online. The format is specified in
/// Dahlunas's `docs/code-format.md`; this follows its steps in order.
///
/// Only GitHub builds accept them (`StoreRules.allowsPurchasedCodes`): stores
/// with in-app purchase forbid unlocking with a purchase made elsewhere.
class PurchasedCodes {
  const PurchasedCodes({
    required this.project,
    required this.products,
    required this.publicKeys,
  });

  /// Accepts no code at all.
  const PurchasedCodes.none()
    : project = 0,
      products = const {},
      publicKeys = const {};

  /// Reads `purchased_codes` in `assets/config/donations.json`: the project id
  /// Dahlunas assigned to Coba Lagi, the product ids that unlock the sponsor
  /// plan, and each signing key's 32-byte public key in hex by key id.
  factory PurchasedCodes.fromJson(Map<String, Object?> json) => PurchasedCodes(
    project: json['project']! as int,
    products: {...(json['products']! as List).cast<int>()},
    publicKeys: {
      for (final MapEntry(:key, :value)
          in (json['public_keys']! as Map<String, Object?>).entries)
        int.parse(key): _hex(value! as String),
    },
  );

  final int project;
  final Set<int> products;
  final Map<int, List<int>> publicKeys;

  static const _prefix = 'DL1.';
  static const _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  static const _payloadLength = 26;
  static const _domain = 'Dahlunas/unlock/v1';

  /// The code's canonical text when it is genuine and unlocks one of
  /// [products], else null.
  Future<String?> verify(String input) async {
    final envelope = decode(input);
    if (envelope == null) return null;
    final data = ByteData.sublistView(envelope);
    final version = data.getUint8(0);
    final keyId = data.getUint8(1);
    final codeProject = data.getUint16(2);
    final product = data.getUint16(4);
    final codeId = envelope.sublist(6, 22);
    if (version != 1 ||
        keyId == 0 ||
        codeProject == 0 ||
        codeProject != project ||
        product == 0 ||
        !products.contains(product) ||
        codeId.every((byte) => byte == 0)) {
      return null;
    }
    final key = publicKeys[keyId];
    if (key == null || key.length != 32) return null;
    final payload = envelope.sublist(0, _payloadLength);
    final genuine = await Ed25519().verify(
      [...ascii.encode(_domain), 0, ...payload],
      signature: Signature(
        envelope.sublist(_payloadLength),
        publicKey: SimplePublicKey(key, type: KeyPairType.ed25519),
      ),
    );
    return genuine ? '$_prefix${_encode(envelope)}' : null;
  }

  /// The 90-byte envelope in [input], or null when it isn't written as the
  /// format allows: any case, spaces, line breaks and hyphens between groups.
  static Uint8List? decode(String input) {
    if (utf8.encode(input).length > 512) return null;
    final upper = String.fromCharCodes([
      for (final unit in input.codeUnits)
        if (unit != 0x20 && unit != 0x09 && unit != 0x0D && unit != 0x0A)
          unit >= 0x61 && unit <= 0x7A ? unit - 0x20 : unit,
    ]);
    if (!upper.startsWith(_prefix)) return null;
    final body = upper.substring(_prefix.length).replaceAll('-', '');
    if (body.length != 144) return null;
    final bytes = Uint8List(90);
    var buffer = 0;
    var bits = 0;
    var index = 0;
    for (final char in body.split('')) {
      final value = _alphabet.indexOf(char);
      if (value < 0) return null;
      buffer = (buffer << 5 | value) & 0xFFFF;
      bits += 5;
      if (bits >= 8) {
        bits -= 8;
        bytes[index++] = buffer >> bits & 0xFF;
      }
    }
    // 144 characters carry exactly 90 bytes (720 bits), so no bits are left
    // over and every body that decodes is already canonical.
    return bytes;
  }

  static String _encode(List<int> bytes) {
    final out = StringBuffer();
    var buffer = 0;
    var bits = 0;
    for (final byte in bytes) {
      buffer = (buffer << 8 | byte) & 0xFFFF;
      bits += 8;
      while (bits >= 5) {
        bits -= 5;
        out.write(_alphabet[buffer >> bits & 0x1F]);
      }
    }
    return out.toString();
  }

  static List<int> _hex(String hex) => [
    for (var i = 0; i + 1 < hex.length; i += 2)
      int.parse(hex.substring(i, i + 2), radix: 16),
  ];
}
