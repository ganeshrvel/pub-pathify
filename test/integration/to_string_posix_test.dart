import 'dart:convert';
import 'dart:typed_data';

import 'package:pathify/pathify.dart';
import 'package:test/test.dart';

Uint8List _b(String s) => Uint8List.fromList(utf8.encode(s));

void main() {
  group('toStr / toStringLossy (POSIX)', () {
    setUp(() {
      Pathify.instance.overriddenPlatform = PathifyPlatform.linux;
    });

    tearDown(Pathify.instance.resetForTesting);

    // ─────────────────────────────────────────────
    // ASCII
    // ─────────────────────────────────────────────

    test('simple ascii path', () {
      final p = PathBuf.fromBytes(_b('/tmp/file.txt'));

      expect(p.toStr(), equals('/tmp/file.txt'));
      expect(p.toStringLossy(), equals('/tmp/file.txt'));
    });

    test('ascii with multiple separators', () {
      final p = PathBuf.fromBytes(_b('/usr//bin///bash'));

      expect(p.toStr(), equals('/usr//bin///bash'));
      expect(p.toStringLossy(), equals('/usr//bin///bash'));
    });

    test('relative ascii path', () {
      final p = PathBuf.fromBytes(_b('foo/bar/baz.txt'));

      expect(p.toStr(), equals('foo/bar/baz.txt'));
      expect(p.toStringLossy(), equals('foo/bar/baz.txt'));
    });

    // ─────────────────────────────────────────────
    // Emoji
    // ─────────────────────────────────────────────

    test('single emoji directory', () {
      final p = PathBuf.fromBytes(_b('/tmp/🚀'));

      expect(p.toStr(), equals('/tmp/🚀'));
      expect(p.toStringLossy(), equals('/tmp/🚀'));
    });

    test('emoji inside filename', () {
      final p = PathBuf.fromBytes(_b('/tmp/file🚀.txt'));

      expect(p.toStr(), equals('/tmp/file🚀.txt'));
      expect(p.toStringLossy(), equals('/tmp/file🚀.txt'));
    });

    test('multiple emoji filename', () {
      final p = PathBuf.fromBytes(_b('/tmp/❤️🚀🔥.txt'));

      expect(p.toStr(), equals('/tmp/❤️🚀🔥.txt'));
      expect(p.toStringLossy(), equals('/tmp/❤️🚀🔥.txt'));
    });

    // ─────────────────────────────────────────────
    // Foreign scripts
    // ─────────────────────────────────────────────

    test('cyrillic path', () {
      final p = PathBuf.fromBytes(
        _b('/home/Пользователь/документы/файл.txt'),
      );

      expect(
        p.toStr(),
        equals('/home/Пользователь/документы/файл.txt'),
      );
      expect(
        p.toStringLossy(),
        equals('/home/Пользователь/документы/файл.txt'),
      );
    });

    test('arabic path', () {
      final p = PathBuf.fromBytes(_b('/home/مستخدم/ملف.txt'));

      expect(p.toStr(), equals('/home/مستخدم/ملف.txt'));
      expect(p.toStringLossy(), equals('/home/مستخدم/ملف.txt'));
    });

    test('chinese path', () {
      final p = PathBuf.fromBytes(_b('/home/用户/文件.txt'));

      expect(p.toStr(), equals('/home/用户/文件.txt'));
      expect(p.toStringLossy(), equals('/home/用户/文件.txt'));
    });

    test('mixed language path', () {
      final p = PathBuf.fromBytes(
        _b('/home/用户/документы/ملف🚀.txt'),
      );

      expect(
        p.toStr(),
        equals('/home/用户/документы/ملف🚀.txt'),
      );
      expect(
        p.toStringLossy(),
        equals('/home/用户/документы/ملف🚀.txt'),
      );
    });

    // ─────────────────────────────────────────────
    // Invalid UTF-8
    // ─────────────────────────────────────────────

    test('invalid byte sequence (0xFF)', () {
      final bytes = Uint8List.fromList([0x2F, 0xFF, 0x61]);

      final p = PathBuf.fromBytes(bytes);

      expect(p.toStr(), isNull);
      expect(p.toStringLossy(), isNotEmpty);
    });

    test('invalid continuation byte', () {
      final bytes = Uint8List.fromList([0x2F, 0x80, 0x61]);

      final p = PathBuf.fromBytes(bytes);

      expect(p.toStr(), isNull);
      expect(p.toStringLossy(), isNotEmpty);
    });

    test('overlong encoding', () {
      final bytes = Uint8List.fromList([0x2F, 0xC0, 0xAF]);

      final p = PathBuf.fromBytes(bytes);

      expect(p.toStr(), isNull);
      expect(p.toStringLossy(), isNotEmpty);
    });

    // ─────────────────────────────────────────────
    // Null byte
    // ─────────────────────────────────────────────

    test('null byte only', () {
      final bytes = Uint8List.fromList([0x00]);

      final p = PathBuf.fromBytes(bytes);

      expect(p.toStr(), isNull);
      expect(p.toStringLossy(), isNotEmpty);
    });

    test('null byte inside path', () {
      final bytes = Uint8List.fromList([0x2F, 0x00, 0x61]);

      final p = PathBuf.fromBytes(bytes);

      expect(p.toStr(), isNull);
      expect(p.toStringLossy(), isNotEmpty);
    });

    // ─────────────────────────────────────────────
    // Empty
    // ─────────────────────────────────────────────

    test('empty path', () {
      final p = PathBuf.fromBytes(Uint8List(0));

      expect(p.toStr(), equals(''));
      expect(p.toStringLossy(), equals(''));
    });
  });
}
