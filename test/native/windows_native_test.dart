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
  });
}
