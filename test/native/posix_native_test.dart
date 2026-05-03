@TestOn('vm && !windows')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:pathify/pathify.dart';
import 'package:test/test.dart';

Uint8List _b(String s) => Uint8List.fromList(utf8.encode(s));

void main() {
  group('Native POSIX behavior', () {
    setUp(Pathify.instance.resetForTesting);

    test('host platform reports as non-Windows', () {
      expect(Pathify.instance.isWindows(), isFalse);
      expect(Pathify.instance.isUnix(), isTrue);
    });

    test('PathBuf.fromBytes accepts Uint8List on the real host', () {
      final p = PathBuf.fromBytes(_b('/etc/hosts'));
      expect(p.bytes, isA<Uint8List>());
      expect(p.isUnix, isTrue);
    });

    test('PathBuf.fromBytes asserts on Uint16List on the real POSIX host', () {
      // In debug mode the assertion fires; in release the wrong storage is
      // accepted silently. We exercise the debug-mode behavior.
      expect(
        () => PathBuf.fromBytes(Uint16List.fromList('/etc'.codeUnits)),
        throwsA(isA<AssertionError>()),
      );
    });

    test('current working directory components iterate correctly', () {
      final cwdString = Directory.current.path;
      final p = PathBuf.fromBytes(_b(cwdString));
      // Should at least produce some components without throwing.
      final list = p.components().toList();
      expect(list, isNotEmpty);
    });

    test('round trip string → bytes → string (ASCII)', () {
      const original = '/usr/bin/bash';
      final p = PathBuf.fromBytes(_b(original));

      expect(p.toStringLossy(), equals(original));
      expect(p.toStr(), equals(original));
    });

    test('round trip with emoji path', () {
      const original = '/tmp/🚀/file.txt';
      final p = PathBuf.fromBytes(_b(original));

      expect(p.toStringLossy(), equals(original));
      expect(p.toStr(), equals(original));
    });

    test('round trip with foreign scripts', () {
      const original = '/home/用户/Пользователь/ملف.txt';
      final p = PathBuf.fromBytes(_b(original));

      expect(p.toStringLossy(), equals(original));
      expect(p.toStr(), equals(original));
    });

    test('invalid UTF-8 returns null in toStr', () {
      final bytes = Uint8List.fromList([0x2F, 0xFF, 0x61]);

      final p = PathBuf.fromBytes(bytes);

      expect(p.toStr(), isNull);
      expect(p.toStringLossy(), isNotEmpty);
    });

    test('overlong UTF-8 sequence invalid', () {
      final bytes = Uint8List.fromList([0x2F, 0xC0, 0xAF]);

      final p = PathBuf.fromBytes(bytes);

      expect(p.toStr(), isNull);
      expect(p.toStringLossy(), isNotEmpty);
    });

    test('null byte invalidates toStr (OS rule)', () {
      final bytes = Uint8List.fromList([0x2F, 0x00, 0x61]);

      final p = PathBuf.fromBytes(bytes);

      expect(p.toStr(), isNull);
      expect(p.toStringLossy(), isNotEmpty);
    });

    test('empty path behavior', () {
      final p = PathBuf.fromBytes(Uint8List(0));

      expect(p.toStr(), equals(''));
      expect(p.toStringLossy(), equals(''));
    });

    test('components iterate safely on complex path', () {
      final p = PathBuf.fromBytes(_b('/a/b/c/../d/./file.txt'));

      expect(() => p.components().toList(), returnsNormally);
    });

    test('multiple separators preserved', () {
      final p = PathBuf.fromBytes(_b('/usr//local///bin'));

      expect(p.toStr(), equals('/usr//local///bin'));
    });
  });
}
