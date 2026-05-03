@TestOn('vm && !windows')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:pathify/pathify.dart';
import 'package:test/test.dart';

Uint8List _b(String s) => Uint8List.fromList(s.codeUnits);

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
  });
}
