import 'dart:io';
import 'dart:typed_data';

import 'package:cobalagi/core/audio/voice_clips.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/voice_files.dart';

void main() {
  test('voice output format names a sample rate and a bitrate', () {
    final format = VoiceFormat.parse('mp3_22050_32');
    expect(format.sampleRate, 22050);
    expect(format.bitrateKbps, 32);
    expect(() => VoiceFormat.parse('wav_22050'), throwsFormatException);
  });

  test('bundled voice clips are mono at the configured MP3 format', () {
    final format = VoiceFormat.load();
    expect(format.name, 'mp3_22050_32');
    final languages = bundledVoiceLanguages();
    expect(languages, ['en', 'id', 'jv', 'su']);

    final bad = <String>[];
    var clips = 0;
    for (final language in languages) {
      for (final entity in Directory('assets/audio/$language').listSync()) {
        if (entity is! File || !entity.path.endsWith('.mp3')) continue;
        clips++;
        try {
          final clip = Mp3Clip.read(entity.readAsBytesSync());
          if (clip.sampleRate != format.sampleRate ||
              clip.bitrateKbps != format.bitrateKbps ||
              !clip.mono) {
            bad.add(
              '${entity.path}: ${clip.channels} ch, '
              '${clip.sampleRate} Hz, ${clip.bitrateKbps} kbps',
            );
          }
        } on FormatException catch (error) {
          bad.add('${entity.path}: $error');
        }
      }
    }
    expect(clips, VoiceClips.all.length * languages.length);
    expect(bad, isEmpty);
  });
}

/// One constant-bitrate Layer III file, read from its frame headers.
class Mp3Clip {
  const Mp3Clip({
    required this.sampleRate,
    required this.bitrateKbps,
    required this.channels,
    required this.frames,
  });

  final int sampleRate;
  final int bitrateKbps;
  final int channels;
  final int frames;

  bool get mono => channels == 1;

  static Mp3Clip read(Uint8List bytes) {
    var offset = _skipId3v2(bytes);
    int? sampleRate;
    int? bitrateKbps;
    int? channels;
    var frames = 0;
    var first = true;
    int? infoRate;
    while (offset + 4 <= bytes.length) {
      if (_isId3v1(bytes, offset)) break;
      final frame = _Frame.tryParse(bytes, offset);
      if (frame == null) {
        throw FormatException('not an MP3 frame at byte $offset');
      }
      // ffmpeg's first frame is the gapless Info tag. Its header bitrate is
      // only big enough to hold that tag; the speech frames follow it.
      final infoTag =
          first &&
          _containsAscii(bytes, offset, frame.size, const ['Xing', 'Info']);
      first = false;
      if (!infoTag) {
        sampleRate ??= frame.sampleRate;
        bitrateKbps ??= frame.bitrateKbps;
        channels ??= frame.channels;
        if (frame.sampleRate != sampleRate ||
            frame.bitrateKbps != bitrateKbps ||
            frame.channels != channels) {
          throw FormatException('mixed MP3 frames at byte $offset');
        }
        frames++;
      } else if (frame.channels != 1) {
        throw FormatException('info tag is not mono');
      } else {
        infoRate = frame.sampleRate;
      }
      offset += frame.size;
    }
    if (frames == 0 || sampleRate == null) {
      throw const FormatException('no MP3 frames');
    }
    if (infoRate != null && infoRate != sampleRate) {
      throw FormatException('info tag is $infoRate Hz');
    }
    final trailing = bytes.length - offset;
    if (trailing != 0 && !_isId3v1(bytes, offset)) {
      throw FormatException('$trailing trailing bytes');
    }
    return Mp3Clip(
      sampleRate: sampleRate,
      bitrateKbps: bitrateKbps!,
      channels: channels!,
      frames: frames,
    );
  }
}

bool _containsAscii(Uint8List bytes, int offset, int size, List<String> words) {
  final end = offset + size;
  final text = String.fromCharCodes(
    bytes,
    offset,
    end > bytes.length ? bytes.length : end,
  );
  return words.any(text.contains);
}

int _skipId3v2(Uint8List bytes) {
  if (bytes.length < 10 ||
      bytes[0] != 0x49 ||
      bytes[1] != 0x44 ||
      bytes[2] != 0x33) {
    return 0;
  }
  final size = _synchsafe(bytes, 6);
  final footer = (bytes[5] & 0x10) != 0 ? 10 : 0;
  return 10 + size + footer;
}

int _synchsafe(Uint8List bytes, int offset) {
  var size = 0;
  for (var i = 0; i < 4; i++) {
    size = (size << 7) | (bytes[offset + i] & 0x7f);
  }
  return size;
}

bool _isId3v1(Uint8List bytes, int offset) =>
    bytes.length - offset == 128 &&
    bytes[offset] == 0x54 &&
    bytes[offset + 1] == 0x41 &&
    bytes[offset + 2] == 0x47;

class _Frame {
  const _Frame({
    required this.sampleRate,
    required this.bitrateKbps,
    required this.channels,
    required this.size,
  });

  final int sampleRate;
  final int bitrateKbps;
  final int channels;
  final int size;

  static _Frame? tryParse(Uint8List bytes, int offset) {
    if (offset + 4 > bytes.length) return null;
    final b0 = bytes[offset];
    final b1 = bytes[offset + 1];
    final b2 = bytes[offset + 2];
    final b3 = bytes[offset + 3];
    if (b0 != 0xff || (b1 & 0xe0) != 0xe0) return null;
    final version = (b1 >> 3) & 0x3;
    final layer = (b1 >> 1) & 0x3;
    // Layer III only. Reserved version and reserved layer are rejected.
    if (version == 1 || layer != 1) return null;
    final bitrateIndex = (b2 >> 4) & 0xf;
    final sampleIndex = (b2 >> 2) & 0x3;
    if (bitrateIndex == 0 || bitrateIndex == 15 || sampleIndex == 3) {
      return null;
    }
    final bitrateKbps = version == 3
        ? _mpeg1Layer3Bitrate[bitrateIndex]
        : _mpeg2Layer3Bitrate[bitrateIndex];
    final sampleRate = switch (version) {
      3 => _mpeg1Rate[sampleIndex],
      2 => _mpeg2Rate[sampleIndex],
      _ => _mpeg25Rate[sampleIndex],
    };
    final padding = (b2 >> 1) & 0x1;
    final channels = ((b3 >> 6) & 0x3) == 3 ? 1 : 2;
    // MPEG1 Layer III is 144 bytes per kilobit; MPEG2 and 2.5 are 72.
    final factor = version == 3 ? 144 : 72;
    final size = (factor * bitrateKbps * 1000) ~/ sampleRate + padding;
    if (size < 4 || offset + size > bytes.length) return null;
    return _Frame(
      sampleRate: sampleRate,
      bitrateKbps: bitrateKbps,
      channels: channels,
      size: size,
    );
  }
}

const _mpeg1Layer3Bitrate = [
  0,
  32,
  40,
  48,
  56,
  64,
  80,
  96,
  112,
  128,
  160,
  192,
  224,
  256,
  320,
  0,
];
const _mpeg2Layer3Bitrate = [
  0,
  8,
  16,
  24,
  32,
  40,
  48,
  56,
  64,
  80,
  96,
  112,
  128,
  144,
  160,
  0,
];
const _mpeg1Rate = [44100, 48000, 32000];
const _mpeg2Rate = [22050, 24000, 16000];
const _mpeg25Rate = [11025, 12000, 8000];
