import 'dart:convert';
import 'dart:typed_data';

import 'package:cobalagi/core/entitlement/purchased_code.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

// The fixture in Dahlunas's code format (payment_service.code_format in
// external-projects.json): test data only, its private
// key was thrown away.
const fixturePublicKey =
    '008c7deff2cbf3a7a1a584bcd07688840e98a21e79758af3d14dae5f60c44c1f';
const fixture =
    'DL1.AEAQAAIAAEAQEAYEAUDAOCAJBIFQYDIOB4IAAACRBYIBSQIHQTFDZHGEMZNXGYM42TXYHEJBIKITDDAZYRSQNKCYNM52JLTMUTVMZTGGYJDXMOVISMS4ZJBSFW7E262RZBFJWNGXPJFGC5AI';

List<int> hex(String text) => [
  for (var i = 0; i < text.length; i += 2)
    int.parse(text.substring(i, i + 2), radix: 16),
];

String base32(List<int> bytes) {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  final out = StringBuffer();
  var buffer = 0;
  var bits = 0;
  for (final byte in bytes) {
    buffer = (buffer << 8 | byte) & 0xFFFF;
    bits += 8;
    while (bits >= 5) {
      bits -= 5;
      out.write(alphabet[buffer >> bits & 0x1F]);
    }
  }
  return out.toString();
}

/// [fixture] with byte [index] of its envelope changed.
String flipped(int index) {
  final envelope = PurchasedCodes.decode(fixture)!;
  envelope[index] ^= 1;
  return 'DL1.${base32(envelope)}';
}

final fixtureCodes = PurchasedCodes(
  project: 1,
  products: {1},
  publicKeys: {1: hex(fixturePublicKey)},
);

void main() {
  group('the documented fixture', () {
    test('is accepted and comes back canonical', () async {
      expect(await fixtureCodes.verify(fixture), fixture);
    });

    test('decodes to the documented fields', () {
      final data = ByteData.sublistView(PurchasedCodes.decode(fixture)!);
      expect(data.getUint8(0), 1);
      expect(data.getUint8(1), 1);
      expect(data.getUint16(2), 1);
      expect(data.getUint16(4), 1);
      expect(data.getUint32(22), 20750);
    });

    test('is accepted in lower case, grouped and with line breaks', () async {
      final body = fixture.substring(4);
      final groups = [
        for (var i = 0; i < body.length; i += 8) body.substring(i, i + 8),
      ];
      for (final variant in [
        fixture.toLowerCase(),
        'dl1.${body.toLowerCase()}',
        'DL1.${groups.join('-')}',
        ' DL1.\n${groups.join(' - ')}\t\r\n',
      ]) {
        expect(await fixtureCodes.verify(variant), fixture, reason: variant);
      }
    });

    test('has no expiry, whatever the device clock says', () async {
      // Verification reads no clock at all: the issued day is only metadata.
      expect(await fixtureCodes.verify(fixture), isNotNull);
    });
  });

  test('rejects a changed payload or signature', () async {
    for (final index in [0, 1, 3, 5, 10, 25, 26, 60, 89]) {
      expect(
        await fixtureCodes.verify(flipped(index)),
        isNull,
        reason: '$index',
      );
    }
  });

  test('rejects another project, product or key', () async {
    final key = hex(fixturePublicKey);
    for (final codes in [
      PurchasedCodes(project: 2, products: {1}, publicKeys: {1: key}),
      PurchasedCodes(project: 1, products: {2}, publicKeys: {1: key}),
      PurchasedCodes(project: 1, products: {1}, publicKeys: {2: key}),
      PurchasedCodes(
        project: 1,
        products: {1},
        publicKeys: {1: List.filled(32, 7)},
      ),
      const PurchasedCodes.none(),
    ]) {
      expect(await codes.verify(fixture), isNull);
    }
  });

  test('rejects text that is not written as the format allows', () async {
    final body = fixture.substring(4);
    for (final input in [
      '',
      body,
      'DL2.$body',
      'DL1$body',
      'DL1.${body.substring(1)}',
      'DL1.${body}A',
      'DL1.$body====',
      'DL1.${body.replaceFirst('A', '0')}',
      'DL1.${body.replaceFirst('I', '1')}',
      'DL1.${body.replaceFirst('A', 'Ａ')}', // a full-width lookalike
      'DL1.${body.replaceFirst('A', '_')}',
      'DL1.${body.replaceRange(8, 8, '.')}',
      '$fixture${' ' * 400}',
    ]) {
      expect(await fixtureCodes.verify(input), isNull, reason: input);
    }
  });

  group('signed fields', () {
    late SimpleKeyPair keys;
    late PurchasedCodes codes;

    /// A code signed with a throwaway key, so fields can be checked past the
    /// signature.
    Future<String> sign({
      int version = 1,
      int keyId = 1,
      int project = 1,
      int product = 1,
      List<int>? codeId,
    }) async {
      final payload = ByteData(26)
        ..setUint8(0, version)
        ..setUint8(1, keyId)
        ..setUint16(2, project)
        ..setUint16(4, product)
        ..setUint32(22, 20750);
      final bytes = payload.buffer.asUint8List()
        ..setRange(6, 22, codeId ?? List.generate(16, (i) => i + 1));
      final signature = await Ed25519().sign([
        ...ascii.encode('Dahlunas/unlock/v1'),
        0,
        ...bytes,
      ], keyPair: keys);
      return 'DL1.${base32([...bytes, ...signature.bytes])}';
    }

    setUp(() async {
      keys = await Ed25519().newKeyPair();
      final public = await keys.extractPublicKey();
      codes = PurchasedCodes(
        project: 1,
        products: {1},
        publicKeys: {1: public.bytes, 0: public.bytes},
      );
    });

    test('accepts a well-formed code', () async {
      expect(await codes.verify(await sign()), isNotNull);
    });

    test('rejects other versions and zero reserved fields', () async {
      for (final code in [
        await sign(version: 2),
        await sign(version: 0),
        await sign(keyId: 0),
        await sign(project: 0),
        await sign(product: 0),
        await sign(codeId: List.filled(16, 0)),
      ]) {
        expect(await codes.verify(code), isNull);
      }
    });
  });
}
