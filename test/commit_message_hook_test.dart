import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory temporaryDirectory;
  late File messageFile;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'commit_message_',
    );
    messageFile = File('${temporaryDirectory.path}/message');
  });

  tearDown(() async {
    await temporaryDirectory.delete(recursive: true);
  });

  Future<ProcessResult> validate(String message) async {
    await messageFile.writeAsString(message);
    return Process.run('bash', ['.githooks/commit-msg', messageFile.path]);
  }

  test(
    'accepts supported types, scopes, breaking changes and bodies',
    () async {
      for (final type in [
        'feat',
        'fix',
        'docs',
        'style',
        'refactor',
        'perf',
        'test',
        'build',
        'ci',
        'chore',
        'revert',
      ]) {
        expect((await validate('$type: update something\n')).exitCode, 0);
      }
      for (final message in [
        'feat(profiles): add avatars',
        'fix!: change storage\n\nBREAKING CHANGE: new format\n',
        'refactor(engine)!: change instruction format\r\n',
        'docs: explain setup\n\nA free-form body.\n',
      ]) {
        expect((await validate(message)).exitCode, 0, reason: message);
      }
    },
  );

  test('rejects nonstandard or empty subjects with guidance', () async {
    for (final message in [
      '',
      'update files',
      'Feat: add avatars',
      'unknown: change',
      'fix:missing space',
      'fix: ',
      'fix:   ',
      'feat(): add avatars',
      'feat(two words): add avatars',
      'feat(scope: add avatars',
      '\nfeat: valid second line',
      'Merge branch main',
      'fix!!: change',
    ]) {
      final result = await validate(message);
      expect(result.exitCode, 1, reason: message);
      expect(result.stderr, contains('Commit rejected'));
    }
  });
}
