import 'dart:typed_data';

import 'package:pathify/pathify.dart';
import 'package:test/test.dart';

import '_helpers.dart';

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
}
