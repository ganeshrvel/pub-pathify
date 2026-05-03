@TestOn('vm && windows')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:pathify/pathify.dart';
import 'package:test/test.dart';

Uint16List _w(String s) => Uint16List.fromList(s.codeUnits);

void main() {
  group('Native Windows behavior', () {
    setUp(Pathify.instance.resetForTesting);

    test('host platform reports as Windows', () {
      expect(Pathify.instance.isWindows(), isTrue);
    });

    test('PathBuf.fromBytes accepts Uint16List on the real host', () {
      final p = PathBuf.fromBytes(_w(r'C:\Users'));
      expect(p.bytes, isA<Uint16List>());
      expect(p.isWindows, isTrue);
    });

    test('PathBuf.fromBytes asserts on Uint8List on the real Windows host', () {
      expect(
        () => PathBuf.fromBytes(Uint8List.fromList(r'C:\Users'.codeUnits)),
        throwsA(isA<AssertionError>()),
      );
    });

    test('current working directory parses with a Windows prefix', () {
      final cwdString = Directory.current.path;
      final p = PathBuf.fromBytes(_w(cwdString));
      // The CWD should have a recognized Windows prefix.
      expect(p.prefix(), isNotNull);
    });

    test('round trip string → bytes → string (ASCII)', () {
      const original = r'C:\Windows\System32\cmd.exe';
      final p = PathBuf.fromBytes(_w(original));

      expect(p.toStringLossy(), equals(original));
      expect(p.toStr(), equals(original));
    });

    test('round trip with emoji path', () {
      const original = r'C:\Temp\🚀\file.txt';
      final p = PathBuf.fromBytes(_w(original));

      expect(p.toStringLossy(), equals(original));
      expect(p.toStr(), equals(original));
    });

    test('round trip with foreign scripts', () {
      const original = r'C:\用户\Пользователь\ملف.txt';
      final p = PathBuf.fromBytes(_w(original));

      expect(p.toStringLossy(), equals(original));
      expect(p.toStr(), equals(original));
    });

    test('null byte makes toStr return null (OS invalid)', () {
      final wide = Uint16List.fromList([0x43, 0x3A, 0x5C, 0x0000]);
      final p = PathBuf.fromBytes(wide);

      expect(p.toStr(), isNull);
      expect(p.toStringLossy(), isNotEmpty);
    });

    test('unpaired surrogate invalidates toStr', () {
      final wide = Uint16List.fromList([
        0x43, 0x3A, 0x5C,
        0xD83D, // high surrogate only
      ]);

      final p = PathBuf.fromBytes(wide);

      expect(p.toStr(), isNull);
      expect(p.toStringLossy(), isNotEmpty);
    });

    test('valid surrogate pair is preserved', () {
      const original = r'C:\🚀';
      final p = PathBuf.fromBytes(_w(original));

      expect(p.toStr(), equals(original));
    });

    test('UNC path round trip', () {
      const original = r'\\server\share\folder\file.txt';
      final p = PathBuf.fromBytes(_w(original));

      expect(p.toStringLossy(), equals(original));
      expect(p.toStr(), equals(original));
    });

    test('empty path behavior', () {
      final p = PathBuf.fromBytes(Uint16List(0));

      expect(p.toStr(), equals(''));
      expect(p.toStringLossy(), equals(''));
    });

    test('components do not throw on complex path', () {
      final p = PathBuf.fromBytes(_w(r'C:\a\b\c\..\d\.\file.txt'));

      expect(() => p.components().toList(), returnsNormally);
    });
  });
}
