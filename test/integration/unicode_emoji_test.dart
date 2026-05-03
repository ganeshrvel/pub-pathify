import 'dart:typed_data';
import 'dart:convert';

import 'package:pathify/pathify.dart';
import 'package:test/test.dart';

import '_helpers.dart';

Uint8List _b(String s) => Uint8List.fromList(utf8.encode(s));

Uint16List _w(String s) => Uint16List.fromList(s.codeUnits);

void main() {
  group('Emoji in paths (POSIX, override)', () {
    setUp(() {
      Pathify.instance.overriddenPlatform = PathifyPlatform.linux;
    });

    tearDown(Pathify.instance.resetForTesting);

    test('rocket emoji as a directory component', () {
      final p = PathBuf.fromBytes(_b('/tmp/🚀/file.txt'));
      // file_name should return the bytes for "file.txt"
      expect(p.fileName(), isNotNull);
      // The component containing 🚀 should round-trip through fileName when
      // it is the last component:
      final p2 = PathBuf.fromBytes(_b('/tmp/🚀'));
      final name = p2.fileName();
      expect(name, isNotNull);
      // The bytes must equal the original UTF-8 encoding of 🚀 (4 bytes).
      expect(name!.length, 4);
      expect(name[0], 0xF0);
      expect(name[1], 0x9F);
      expect(name[2], 0x9A);
      expect(name[3], 0x80);
    });

    test('multi-emoji file name', () {
      final p = PathBuf.fromBytes(_b('/share/❤️🚀.txt'));
      final ext = p.extension();
      expect(ext, isNotNull);
      expect(cuStr(ext!), 'txt');
    });
  });

  group('Emoji in paths (Windows, override)', () {
    setUp(() {
      Pathify.instance.overriddenPlatform = PathifyPlatform.windows;
    });

    tearDown(Pathify.instance.resetForTesting);

    test('rocket emoji as a UTF-16 surrogate pair component', () {
      // 🚀 in UTF-16 is the surrogate pair 0xD83D 0xDE80.
      final p = PathBuf.fromBytes(_w(r'C:\🚀\file.txt'));
      final ext = p.extension();
      expect(ext, isNotNull);
      expect(cuStr(ext!), 'txt');
    });

    test('emoji directory survives parent()', () {
      final p = PathBuf.fromBytes(_w(r'C:\🚀\nested\file.txt'));
      final parent = p.parent();
      expect(parent, isNotNull);
      // Parent should contain the emoji intact.
      final parentStr = String.fromCharCodes(
        parent!.codeUnits.toTypedData() as Uint16List,
      );
      expect(parentStr, contains('🚀'));
    });
  });
}
