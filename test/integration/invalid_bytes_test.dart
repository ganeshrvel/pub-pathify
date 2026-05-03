import 'dart:convert';
import 'dart:typed_data';

import 'package:pathify/pathify.dart';
import 'package:test/test.dart';

import '_helpers.dart';

Uint8List _b(String s) => Uint8List.fromList(utf8.encode(s));

void main() {
  group('Invalid UTF-8 sequences (POSIX override)', () {
    setUp(() {
      Pathify.instance.overriddenPlatform = PathifyPlatform.linux;
    });

    tearDown(Pathify.instance.resetForTesting);

    test('lone continuation byte in file name', () {
      // 0x80 is a UTF-8 continuation byte that cannot appear standalone.
      final bytes = Uint8List.fromList([
        0x2F, 0x74, 0x6D, 0x70, 0x2F, // "/tmp/"
        0xFF, 0x80, // invalid bytes
        0x2E, 0x74, 0x78, 0x74, // ".txt"
      ]);
      final p = PathBuf.fromBytes(bytes);
      // Operations must not throw.
      expect(p.parent(), isNotNull);
      expect(p.fileName(), isNotNull);
      expect(
        p.fileName()!.length,
        6,
      ); // 0xFF 0x80 0x2E... length includes ".txt"
    });

    test('overlong encoding bytes in component', () {
      // 0xC0 0xAF would be an overlong-encoded "/" — invalid UTF-8.
      final bytes = Uint8List.fromList([
        0x2F, // "/"
        0xC0, 0xAF, // invalid overlong (NOT actually a separator)
        0x66, 0x6F, 0x6F, // "foo"
      ]);
      final p = PathBuf.fromBytes(bytes);
      // 0xC0 is NOT 0x2F so it should not split a component.
      final names = p
          .components()
          .toList()
          .whereType<ComponentNormal>()
          .map((c) => c.value.length)
          .toList();
      expect(names.length, 1);
    });

    test('toStr returns null for invalid UTF-8', () {
      final bytes = Uint8List.fromList([0x2F, 0xFF, 0xFE]);
      final p = PathBuf.fromBytes(bytes);
      expect(p.toStr(), isNull);
    });

    test('toStringLossy never throws', () {
      final bytes = Uint8List.fromList([0x2F, 0xFF, 0xFE, 0xC0]);
      final p = PathBuf.fromBytes(bytes);
      final s = p.toStringLossy();
      expect(s, isNotEmpty);
      expect(s, contains('\uFFFD')); // replacement character
    });

    test('null byte does not terminate path parsing', () {
      // POSIX paths cannot legally contain null bytes, but pathify should
      // not crash on them — null is just another byte to the parser.
      final bytes = Uint8List.fromList([0x2F, 0x66, 0x00, 0x6F, 0x6F]);
      final p = PathBuf.fromBytes(bytes);
      expect(() => p.components().toList(), returnsNormally);
    });
  });

  group('Invalid UTF-16 sequences (Windows override)', () {
    setUp(() {
      Pathify.instance.overriddenPlatform = PathifyPlatform.windows;
    });

    tearDown(Pathify.instance.resetForTesting);

    test('unpaired high surrogate in component', () {
      // 0xD83D is a high surrogate; alone it is invalid UTF-16 but valid
      // as raw Windows path bytes.
      final wide = Uint16List.fromList([
        0x43, 0x3A, 0x5C, // "C:\"
        0xD83D, // unpaired high surrogate
        0x2E, 0x74, 0x78, 0x74, // ".txt"
      ]);
      final p = PathBuf.fromBytes(wide);
      expect(p.prefix(), isA<Disk>());
      expect(p.extension(), isNotNull);
      expect(cuStr(p.extension()!), 'txt');
    });

    test('toStr returns null for unpaired surrogate', () {
      final wide = Uint16List.fromList([0x43, 0x3A, 0x5C, 0xDC00]);
      final p = PathBuf.fromBytes(wide);
      expect(p.toStr(), isNull);
    });

    test('toStringLossy replaces unpaired surrogates', () {
      final wide = Uint16List.fromList([0x43, 0x3A, 0x5C, 0xDC00]);
      final p = PathBuf.fromBytes(wide);
      final s = p.toStringLossy();
      expect(s.codeUnits, contains(0xFFFD));
    });

    test('reversed surrogate pair (low before high)', () {
      // 0xDC00 0xD83D is malformed (low before high).
      final wide = Uint16List.fromList([
        0x43, 0x3A, 0x5C, // "C:\"
        0xDC00, 0xD83D, // malformed
        0x66, 0x6F, 0x6F, // "foo"
      ]);
      final p = PathBuf.fromBytes(wide);
      expect(() => p.components().toList(), returnsNormally);
    });
  });

  group('Invalid UTF-8 deep tests (POSIX)', () {
    setUp(() {
      Pathify.instance.overriddenPlatform = PathifyPlatform.linux;
    });

    tearDown(Pathify.instance.resetForTesting);

    test('truncated 2-byte sequence', () {
      final bytes = Uint8List.fromList([
        0x2F, // '/'
        0xC3, // start of 2-byte sequence but missing continuation
      ]);

      final p = PathBuf.fromBytes(bytes);

      expect(p.toStr(), isNull);
      expect(p.toStringLossy(), isNotEmpty);
    });

    test('truncated 3-byte sequence', () {
      final bytes = Uint8List.fromList([
        0x2F,
        0xE2, 0x82, // missing third byte
      ]);

      final p = PathBuf.fromBytes(bytes);

      expect(p.toStr(), isNull);
      expect(p.toStringLossy(), isNotEmpty);
    });

    test('truncated 4-byte sequence (emoji broken)', () {
      final bytes = Uint8List.fromList([
        0x2F,
        0xF0, 0x9F, 0x9A, // missing last byte of 🚀
      ]);

      final p = PathBuf.fromBytes(bytes);

      expect(p.toStr(), isNull);
      expect(p.toStringLossy(), contains('\uFFFD'));
    });

    test('valid UTF-8 prefix + invalid tail', () {
      final bytes = Uint8List.fromList([
        ..._b('/tmp/valid'),
        0xFF,
        0xFE,
      ]);

      final p = PathBuf.fromBytes(bytes);

      expect(p.toStr(), isNull);

      final lossy = p.toStringLossy();
      expect(lossy.contains('valid'), isTrue);
      expect(lossy.contains('\uFFFD'), isTrue);
    });

    test('invalid bytes inside filename component', () {
      final bytes = Uint8List.fromList([
        0x2F, 0x74, 0x6D, 0x70, 0x2F, // "/tmp/"
        0x66, 0x6F, // "fo"
        0xFF, // invalid
        0x6F, // "o"
      ]);

      final p = PathBuf.fromBytes(bytes);

      final name = p.fileName();
      expect(name, isNotNull);
      expect(name!.length, 4); // f o [invalid] o
    });

    test('invalid byte does not split components', () {
      final bytes = Uint8List.fromList([
        0x2F,
        0xFF,
        0x66, 0x6F, 0x6F, // "foo"
      ]);

      final p = PathBuf.fromBytes(bytes);

      final names = p
          .components()
          .toList()
          .whereType<ComponentNormal>()
          .toList();

      expect(names.length, 1);
    });

    test('multiple invalid sequences in path', () {
      final bytes = Uint8List.fromList([
        0x2F,
        0xFF,
        0xFE,
        0x2F,
        0xC0,
        0xAF,
        0x2F,
        0x80,
      ]);

      final p = PathBuf.fromBytes(bytes);

      expect(() => p.components().toList(), returnsNormally);

      final lossy = p.toStringLossy();
      expect(lossy.contains('\uFFFD'), isTrue);
    });

    test('invalid UTF-8 in extension still extracts extension', () {
      final bytes = Uint8List.fromList([
        0x2F,
        0x74,
        0x6D,
        0x70,
        0x2F,
        0x66,
        0x6F,
        0x6F,
        0xFF,
        0x2E,
        0x74,
        0x78,
        0x74,
      ]);

      final p = PathBuf.fromBytes(bytes);

      final ext = p.extension();
      expect(ext, isNotNull);
      expect(cuStr(ext!), 'txt');
    });

    test('null byte inside invalid sequence does not crash', () {
      final bytes = Uint8List.fromList([
        0x2F,
        0xFF,
        0x00,
        0xFE,
      ]);

      final p = PathBuf.fromBytes(bytes);

      expect(p.toStringLossy, returnsNormally);
    });

    test('path with only invalid bytes', () {
      final bytes = Uint8List.fromList([0xFF, 0xFE, 0xC0, 0x80]);

      final p = PathBuf.fromBytes(bytes);

      expect(p.toStr(), isNull);

      final lossy = p.toStringLossy();
      expect(lossy.isNotEmpty, isTrue);
    });
  });

  group('Invalid UTF-16 deep tests (Windows)', () {
    setUp(() {
      Pathify.instance.overriddenPlatform = PathifyPlatform.windows;
    });

    tearDown(Pathify.instance.resetForTesting);

    test('lone high surrogate', () {
      final wide = Uint16List.fromList([0xD83D]);
      final p = PathBuf.fromBytes(wide);

      expect(p.toStr(), isNull);
      expect(p.toStringLossy(), isNotEmpty);
    });

    test('lone low surrogate', () {
      final wide = Uint16List.fromList([0xDE80]);
      final p = PathBuf.fromBytes(wide);

      expect(p.toStr(), isNull);
    });

    test('reversed surrogate pair', () {
      final wide = Uint16List.fromList([0xDE80, 0xD83D]);
      final p = PathBuf.fromBytes(wide);

      expect(p.toStr(), isNull);
    });

    test('high surrogate not followed by low', () {
      final wide = Uint16List.fromList([0xD83D, 0x0041]);
      final p = PathBuf.fromBytes(wide);

      expect(p.toStr(), isNull);
    });

    test('valid surrogate pair (emoji)', () {
      final wide = Uint16List.fromList([0xD83D, 0xDE80]);
      final p = PathBuf.fromBytes(wide);

      expect(p.toStr(), '🚀');
    });

    test('mixed valid + invalid sequence', () {
      final wide = Uint16List.fromList([
        0xD83D, 0xDE80, // 🚀
        0xD83D, // invalid
      ]);

      final p = PathBuf.fromBytes(wide);

      expect(p.toStr(), isNull);

      final lossy = p.toStringLossy();
      expect(lossy.contains('🚀'), isTrue);
      expect(lossy.contains('\uFFFD'), isTrue);
    });

    test('invalid sequence inside path does not break parsing', () {
      final wide = Uint16List.fromList([
        0x43, 0x3A, 0x5C, // C:\
        0xD83D, // invalid
        0x5C, 0x66, 0x6F, 0x6F, // \foo
      ]);

      final p = PathBuf.fromBytes(wide);

      expect(() => p.components().toList(), returnsNormally);
    });

    test('null code unit invalidates toStr', () {
      final wide = Uint16List.fromList([0x0000]);

      final p = PathBuf.fromBytes(wide);

      expect(p.toStr(), isNull);
    });
  });
}
