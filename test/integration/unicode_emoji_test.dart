import 'dart:convert';
import 'dart:typed_data';

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

  group('Emoji deep tests (POSIX)', () {
    setUp(() {
      Pathify.instance.overriddenPlatform = PathifyPlatform.linux;
    });

    tearDown(Pathify.instance.resetForTesting);

    test('round trip emoji via fromStr → toStr', () {
      final p = PathBuf.fromStr('/tmp/🚀/file.txt');

      expect(p.toStr(), '/tmp/🚀/file.txt');
      expect(p.toStringLossy(), '/tmp/🚀/file.txt');
    });

    test('round trip emoji via fromBytes → toStr', () {
      final p = PathBuf.fromBytes(_b('/tmp/🚀/file.txt'));

      expect(p.toStr(), '/tmp/🚀/file.txt');
    });

    test('multi emoji directory chain', () {
      final p = PathBuf.fromBytes(_b('/🔥/🚀/❤️/file.txt'));

      final names = p
          .components()
          .toList()
          .whereType<ComponentNormal>()
          .map((c) => cuStr(c.value))
          .toList();

      expect(names, equals(['🔥', '🚀', '❤️', 'file.txt']));
    });

    test('emoji filename extraction', () {
      final p = PathBuf.fromBytes(_b('/tmp/🔥🚀.txt'));

      final name = p.fileName();
      expect(name, isNotNull);
      expect(cuStr(name!), '🔥🚀.txt');
    });

    test('emoji extension extraction', () {
      final p = PathBuf.fromBytes(_b('/tmp/file🔥.tar.gz'));

      final ext = p.extension();
      expect(ext, isNotNull);
      expect(cuStr(ext!), 'gz');
    });

    test('emoji fileStem extraction', () {
      final p = PathBuf.fromBytes(_b('/tmp/🔥🚀.tar.gz'));

      final stem = p.fileStem();
      expect(stem, isNotNull);
      expect(cuStr(stem!), '🔥🚀.tar');
    });

    test('emoji survives parent()', () {
      final p = PathBuf.fromBytes(_b('/tmp/🚀/nested/file.txt'));

      final parent = p.parent();
      expect(parent, isNotNull);
      expect(cuStr(parent!.codeUnits), '/tmp/🚀/nested');
    });

    test('emoji at root level', () {
      final p = PathBuf.fromBytes(_b('/🚀'));

      expect(p.fileName(), isNotNull);
      expect(cuStr(p.fileName()!), '🚀');
    });

    test('emoji only path', () {
      final p = PathBuf.fromBytes(_b('🚀'));

      expect(p.fileName(), isNotNull);
      expect(cuStr(p.fileName()!), '🚀');

      final parent = p.parent();
      expect(parent, isNotNull);
      expect(parent!.length, 0);
    });

    test('invalid UTF-8 with emoji prefix → toStr null', () {
      final bytes = Uint8List.fromList([
        0xF0, 0x9F, 0x9A, 0x80, // 🚀
        0xFF, // invalid
      ]);

      final p = PathBuf.fromBytes(bytes);

      expect(p.toStr(), isNull);
      expect(p.toStringLossy(), isNotEmpty);
    });

    test('lossy decoding preserves valid emoji', () {
      final bytes = Uint8List.fromList([
        0xF0, 0x9F, 0x9A, 0x80, // 🚀
        0xFF,
      ]);

      final p = PathBuf.fromBytes(bytes);

      final s = p.toStringLossy();
      expect(s.contains('🚀'), isTrue);
      expect(s.contains('\uFFFD'), isTrue);
    });

    test('startsWith / endsWith with emoji', () {
      final p = PathBuf.fromBytes(_b('/tmp/🚀/file.txt'));

      expect(
        p.startsWith(PathBuf.fromStr('/tmp/🚀')),
        isTrue,
      );

      expect(
        p.endsWith(PathBuf.fromStr('file.txt')),
        isTrue,
      );

      expect(
        p.endsWith(PathBuf.fromStr('🚀')),
        isFalse,
      );
    });
  });

  group('Emoji deep tests (Windows)', () {
    setUp(() {
      Pathify.instance.overriddenPlatform = PathifyPlatform.windows;
    });

    tearDown(Pathify.instance.resetForTesting);

    test('round trip emoji via fromStr → toStr', () {
      final p = PathBuf.fromStr(r'C:\🚀\file.txt');

      expect(p.toStr(), r'C:\🚀\file.txt');
      expect(p.toStringLossy(), r'C:\🚀\file.txt');
    });

    test('round trip emoji via fromBytes (UTF-16)', () {
      final p = PathBuf.fromBytes(_w(r'C:\🚀\file.txt'));

      expect(p.toStr(), r'C:\🚀\file.txt');
    });

    test('multi emoji directories', () {
      final p = PathBuf.fromBytes(_w(r'C:\🔥\🚀\❤️\file.txt'));

      final names = p
          .components()
          .toList()
          .whereType<ComponentNormal>()
          .map((c) => cuStr(c.value))
          .toList();

      expect(names, equals(['🔥', '🚀', '❤️', 'file.txt']));
    });

    test('emoji filename extraction', () {
      final p = PathBuf.fromBytes(_w(r'C:\tmp\🔥🚀.txt'));

      final name = p.fileName();
      expect(name, isNotNull);
      expect(cuStr(name!), '🔥🚀.txt');
    });

    test('emoji extension extraction', () {
      final p = PathBuf.fromBytes(_w(r'C:\tmp\file🔥.tar.gz'));

      final ext = p.extension();
      expect(ext, isNotNull);
      expect(cuStr(ext!), 'gz');
    });

    test('emoji fileStem extraction', () {
      final p = PathBuf.fromBytes(_w(r'C:\tmp\🔥🚀.tar.gz'));

      final stem = p.fileStem();
      expect(stem, isNotNull);
      expect(cuStr(stem!), '🔥🚀.tar');
    });

    test('emoji survives parent()', () {
      final p = PathBuf.fromBytes(_w(r'C:\🚀\nested\file.txt'));

      final parent = p.parent();
      expect(parent, isNotNull);

      final parentStr = String.fromCharCodes(
        parent!.codeUnits.toTypedData() as Uint16List,
      );

      expect(parentStr, contains('🚀'));
    });

    test('emoji root-level component', () {
      final p = PathBuf.fromBytes(_w(r'C:\🚀'));

      final name = p.fileName();
      expect(name, isNotNull);
      expect(cuStr(name!), '🚀');
    });

    test('unpaired surrogate invalidates toStr', () {
      final wide = Uint16List.fromList([
        0xD83D, // broken high surrogate
      ]);

      final p = PathBuf.fromBytes(wide);

      expect(p.toStr(), isNull);
    });

    test('lossy preserves valid emoji and replaces invalid', () {
      final wide = Uint16List.fromList([
        0xD83D, 0xDE80, // 🚀
        0xD83D, // invalid
      ]);

      final p = PathBuf.fromBytes(wide);

      final s = p.toStringLossy();

      expect(s.contains('🚀'), isTrue);
      expect(s.contains('\uFFFD'), isTrue);
    });

    test('startsWith / endsWith with emoji', () {
      final p = PathBuf.fromBytes(_w(r'C:\🚀\file.txt'));

      expect(
        p.startsWith(PathBuf.fromStr(r'C:\🚀')),
        isTrue,
      );

      expect(
        p.endsWith(PathBuf.fromStr('file.txt')),
        isTrue,
      );

      expect(
        p.endsWith(PathBuf.fromStr('🚀')),
        isFalse,
      );
    });
  });
}
