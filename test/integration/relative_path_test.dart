import 'dart:convert';
import 'dart:typed_data';

import 'package:pathify/pathify.dart';
import 'package:test/test.dart';

Uint8List _b(String s) => Uint8List.fromList(utf8.encode(s));

Uint16List _w(String s) => Uint16List.fromList(s.codeUnits);

void main() {
  // =========================================================
  // POSIX
  // =========================================================

  group('relative paths POSIX', () {
    setUp(() {
      Pathify.instance.overriddenPlatform = PathifyPlatform.linux;
    });

    tearDown(Pathify.instance.resetForTesting);

    // ─────────────────────────────────────────────
    // BASIC RELATIVE
    // ─────────────────────────────────────────────

    test('simple relative', () {
      final p = PathBuf.fromBytes(_b('a/b/c'));
      expect(p.toStringLossy(), 'a/b/c');
    });

    test('./ path', () {
      final p = PathBuf.fromBytes(_b('./a/b'));
      expect(p.toStringLossy(), './a/b');
    });

    test('../ path', () {
      final p = PathBuf.fromBytes(_b('../a/b'));
      expect(p.toStringLossy(), '../a/b');
    });

    test('../../ deep relative', () {
      final p = PathBuf.fromBytes(_b('../../a/b'));
      expect(p.toStringLossy(), '../../a/b');
    });

    test('only ..', () {
      final p = PathBuf.fromBytes(_b('..'));
      expect(p.toStringLossy(), '..');
    });

    test('only .', () {
      final p = PathBuf.fromBytes(_b('.'));
      expect(p.toStringLossy(), '.');
    });

    // ─────────────────────────────────────────────
    // TRAILING
    // ─────────────────────────────────────────────

    test('relative with trailing slash', () {
      final p = PathBuf.fromBytes(_b('a/b/c/'));
      expect(p.toStringLossy(), 'a/b/c/');
    });

    test('./ with trailing', () {
      final p = PathBuf.fromBytes(_b('./a/b/'));
      expect(p.toStringLossy(), './a/b/');
    });

    // ─────────────────────────────────────────────
    // HIDDEN FILES
    // ─────────────────────────────────────────────

    test('hidden file', () {
      final p = PathBuf.fromBytes(_b('.gitignore'));
      expect(p.fileName(), isNotNull);
    });

    test('hidden dir', () {
      final p = PathBuf.fromBytes(_b('.config/app'));
      expect(p.toStringLossy(), '.config/app');
    });

    // ─────────────────────────────────────────────
    // EMOJI
    // ─────────────────────────────────────────────

    test('emoji relative', () {
      final p = PathBuf.fromBytes(_b('🚀/🔥/file.txt'));
      expect(p.toStringLossy(), '🚀/🔥/file.txt');
    });

    test('emoji with ..', () {
      final p = PathBuf.fromBytes(_b('../🚀/file.txt'));
      expect(p.toStringLossy(), '../🚀/file.txt');
    });

    // ─────────────────────────────────────────────
    // FOREIGN
    // ─────────────────────────────────────────────

    test('foreign relative', () {
      final p = PathBuf.fromBytes(_b('用户/данные/ملف.txt'));
      expect(p.toStringLossy(), '用户/данные/ملف.txt');
    });

    test('foreign with ..', () {
      final p = PathBuf.fromBytes(_b('../用户/данные'));
      expect(p.toStringLossy(), '../用户/данные');
    });

    // ─────────────────────────────────────────────
    // MIXED SEPARATORS
    // ─────────────────────────────────────────────

    test('backslash not separator', () {
      final p = PathBuf.fromBytes(_b(r'a\b\c'));
      expect(p.toStringLossy(), r'a\b\c');
    });

    test('mixed separators', () {
      final p = PathBuf.fromBytes(_b(r'a\b/c\d'));
      expect(p.toStringLossy(), r'a\b/c\d');
    });

    // ─────────────────────────────────────────────
    // CROSS WINDOWS STYLE
    // ─────────────────────────────────────────────

    test('windows style relative', () {
      final p = PathBuf.fromBytes(_b(r'C:\foo\bar'));
      expect(p.toStringLossy(), r'C:\foo\bar');
    });

    test('UNC style relative', () {
      final p = PathBuf.fromBytes(_b(r'\\server\share'));
      expect(p.toStringLossy(), r'\\server\share');
    });

    // ─────────────────────────────────────────────
    // COMPLEX MIXED
    // ─────────────────────────────────────────────

    test('complex mixed path', () {
      final p = PathBuf.fromBytes(
        _b(r'../用户\🚀/данные\ملف/./file.txt'),
      );
      expect(
        p.toStringLossy(),
        r'../用户\🚀/данные\ملف/./file.txt',
      );
    });
  });

  // =========================================================
  // WINDOWS
  // =========================================================

  group('relative paths Windows', () {
    setUp(() {
      Pathify.instance.overriddenPlatform = PathifyPlatform.windows;
    });

    tearDown(Pathify.instance.resetForTesting);

    // ─────────────────────────────────────────────
    // BASIC
    // ─────────────────────────────────────────────

    test('simple relative', () {
      final p = PathBuf.fromBytes(_w(r'a\b\c'));
      expect(p.toStringLossy(), r'a\b\c');
    });

    test(r'.\ path', () {
      final p = PathBuf.fromBytes(_w(r'.\a\b'));
      expect(p.toStringLossy(), r'.\a\b');
    });

    test(r'..\ path', () {
      final p = PathBuf.fromBytes(_w(r'..\a\b'));
      expect(p.toStringLossy(), r'..\a\b');
    });

    test(r'..\..\ deep', () {
      final p = PathBuf.fromBytes(_w(r'..\..\a\b'));
      expect(p.toStringLossy(), r'..\..\a\b');
    });

    test('only ..', () {
      final p = PathBuf.fromBytes(_w('..'));
      expect(p.toStringLossy(), '..');
    });

    test('only .', () {
      final p = PathBuf.fromBytes(_w('.'));
      expect(p.toStringLossy(), '.');
    });

    // ─────────────────────────────────────────────
    // TRAILING
    // ─────────────────────────────────────────────

    test('trailing slash', () {
      final p = PathBuf.fromBytes(_w(r'a\b\c\'));
      expect(p.toStringLossy(), r'a\b\c\');
    });

    // ─────────────────────────────────────────────
    // HIDDEN FILES
    // ─────────────────────────────────────────────

    test('hidden file', () {
      final p = PathBuf.fromBytes(_w('.gitignore'));
      expect(p.fileName(), isNotNull);
    });

    // ─────────────────────────────────────────────
    // EMOJI
    // ─────────────────────────────────────────────

    test('emoji relative', () {
      final p = PathBuf.fromBytes(_w(r'🚀\🔥\file.txt'));
      expect(p.toStringLossy(), r'🚀\🔥\file.txt');
    });

    test('emoji with ..', () {
      final p = PathBuf.fromBytes(_w(r'..\🚀\file.txt'));
      expect(p.toStringLossy(), r'..\🚀\file.txt');
    });

    // ─────────────────────────────────────────────
    // FOREIGN
    // ─────────────────────────────────────────────

    test('foreign relative', () {
      final p = PathBuf.fromBytes(_w(r'用户\данные\ملف.txt'));
      expect(p.toStringLossy(), r'用户\данные\ملف.txt');
    });

    // ─────────────────────────────────────────────
    // MIXED SEPARATORS
    // ─────────────────────────────────────────────

    test('mixed separators', () {
      final p = PathBuf.fromBytes(_w(r'a/b\c/d'));
      expect(p.toStringLossy(), r'a/b\c/d');
    });

    // ─────────────────────────────────────────────
    // POSIX STYLE INSIDE WINDOWS
    // ─────────────────────────────────────────────

    test('posix relative inside windows', () {
      final p = PathBuf.fromBytes(_w('a/b/c'));
      expect(p.toStringLossy(), 'a/b/c');
    });

    // ─────────────────────────────────────────────
    // DRIVE RELATIVE
    // ─────────────────────────────────────────────

    test('C: relative path', () {
      final p = PathBuf.fromBytes(_w(r'C:foo\bar'));
      expect(p.toStringLossy(), r'C:foo\bar');
    });

    test('C: with ..', () {
      final p = PathBuf.fromBytes(_w(r'C:..\foo'));
      expect(p.toStringLossy(), r'C:..\foo');
    });

    // ─────────────────────────────────────────────
    // COMPLEX MIXED
    // ─────────────────────────────────────────────

    test('complex mixed path', () {
      final p = PathBuf.fromBytes(
        _w(r'..\用户\🚀/данные\ملف\.\file.txt'),
      );
      expect(
        p.toStringLossy(),
        r'..\用户\🚀/данные\ملف\.\file.txt',
      );
    });
  });
}
