import 'dart:typed_data';

import 'package:pathify/pathify.dart';
import 'package:test/test.dart';

Uint16List _w(String s) => Uint16List.fromList(s.codeUnits);

void main() {
  group('toStr / toStringLossy (Windows)', () {
    setUp(() {
      Pathify.instance.overriddenPlatform = PathifyPlatform.windows;
    });

    tearDown(Pathify.instance.resetForTesting);

    // ─────────────────────────────────────────────
    // ASCII
    // ─────────────────────────────────────────────

    test('simple ascii path', () {
      final p = PathBuf.fromBytes(_w(r'C:\Temp\file.txt'));

      expect(p.toStr(), equals(r'C:\Temp\file.txt'));
      expect(p.toStringLossy(), equals(r'C:\Temp\file.txt'));
    });

    test('UNC path', () {
      final p = PathBuf.fromBytes(_w(r'\\server\share\file.txt'));

      expect(p.toStr(), equals(r'\\server\share\file.txt'));
      expect(p.toStringLossy(), equals(r'\\server\share\file.txt'));
    });

    // ─────────────────────────────────────────────
    // Emoji
    // ─────────────────────────────────────────────

    test('emoji directory', () {
      final p = PathBuf.fromBytes(_w(r'C:\🚀\file.txt'));

      expect(p.toStr(), equals(r'C:\🚀\file.txt'));
      expect(p.toStringLossy(), equals(r'C:\🚀\file.txt'));
    });

    test('multiple emoji', () {
      final p = PathBuf.fromBytes(_w(r'C:\❤️🚀🔥.txt'));

      expect(p.toStr(), equals(r'C:\❤️🚀🔥.txt'));
      expect(p.toStringLossy(), equals(r'C:\❤️🚀🔥.txt'));
    });

    // ─────────────────────────────────────────────
    // Foreign scripts
    // ─────────────────────────────────────────────

    test('cyrillic path', () {
      final p = PathBuf.fromBytes(
        _w(r'C:\Пользователь\документы\файл.txt'),
      );

      expect(
        p.toStr(),
        equals(r'C:\Пользователь\документы\файл.txt'),
      );
      expect(
        p.toStringLossy(),
        equals(r'C:\Пользователь\документы\файл.txt'),
      );
    });

    test('arabic path', () {
      final p = PathBuf.fromBytes(_w(r'C:\مستخدم\ملف.txt'));

      expect(p.toStr(), equals(r'C:\مستخدم\ملف.txt'));
      expect(p.toStringLossy(), equals(r'C:\مستخدم\ملف.txt'));
    });

    test('chinese path', () {
      final p = PathBuf.fromBytes(_w(r'C:\用户\文件.txt'));

      expect(p.toStr(), equals(r'C:\用户\文件.txt'));
      expect(p.toStringLossy(), equals(r'C:\用户\文件.txt'));
    });

    // ─────────────────────────────────────────────
    // Invalid UTF-16
    // ─────────────────────────────────────────────

    test('unpaired high surrogate', () {
      final wide = Uint16List.fromList([0xD83D]);

      final p = PathBuf.fromBytes(wide);

      expect(p.toStr(), isNull);
      expect(p.toStringLossy(), isNotEmpty);
    });

    test('unpaired low surrogate', () {
      final wide = Uint16List.fromList([0xDC00]);

      final p = PathBuf.fromBytes(wide);

      expect(p.toStr(), isNull);
      expect(p.toStringLossy(), isNotEmpty);
    });

    test('reversed surrogate pair', () {
      final wide = Uint16List.fromList([0xDC00, 0xD83D]);

      final p = PathBuf.fromBytes(wide);

      expect(p.toStr(), isNull);
      expect(p.toStringLossy(), isNotEmpty);
    });

    // ─────────────────────────────────────────────
    // Null byte
    // ─────────────────────────────────────────────

    test('null byte only', () {
      final p = PathBuf.fromBytes(_w('\u0000'));

      expect(p.toStr(), isNull);
      expect(p.toStringLossy(), isNotEmpty);
    });

    test('null inside path', () {
      final wide = Uint16List.fromList([0x43, 0x3A, 0x5C, 0x0000]);

      final p = PathBuf.fromBytes(wide);

      expect(p.toStr(), isNull);
      expect(p.toStringLossy(), isNotEmpty);
    });

    // ─────────────────────────────────────────────
    // Empty
    // ─────────────────────────────────────────────

    test('empty path', () {
      final p = PathBuf.fromBytes(Uint16List(0));

      expect(p.toStr(), equals(''));
      expect(p.toStringLossy(), equals(''));
    });
  });
}
