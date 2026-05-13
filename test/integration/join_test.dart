import 'dart:convert';
import 'dart:typed_data';

import 'package:pathify/pathify.dart';
import 'package:test/test.dart';

Uint8List _b(String s) => Uint8List.fromList(utf8.encode(s));

Uint16List _w(String s) => Uint16List.fromList(s.codeUnits);

void main() {
  group('join() POSIX', () {
    setUp(() {
      Pathify.instance.overriddenPlatform = PathifyPlatform.linux;
    });

    tearDown(Pathify.instance.resetForTesting);

    // ─────────────────────────────────────────────
    // BASIC
    // ─────────────────────────────────────────────

    test('simple join', () {
      final base = PathBuf.fromBytes(_b('/a/b'));
      final joined = base.join(PathBuf.fromBytes(_b('c')));
      expect(joined.toStringLossy(), '/a/b/c');
    });

    test('join multiple levels', () {
      final base = PathBuf.fromBytes(_b('/a'));
      final joined = base.join(PathBuf.fromBytes(_b('b/c/d')));
      expect(joined.toStringLossy(), '/a/b/c/d');
    });

    test('join with trailing slash base', () {
      final base = PathBuf.fromBytes(_b('/a/b/'));
      final joined = base.join(PathBuf.fromBytes(_b('c')));
      expect(joined.toStringLossy(), '/a/b/c');
    });

    // ─────────────────────────────────────────────
    // RELATIVE JOIN
    // ─────────────────────────────────────────────

    test('relative join', () {
      final base = PathBuf.fromBytes(_b('a/b'));
      final joined = base.join(PathBuf.fromBytes(_b('c')));
      expect(joined.toStringLossy(), 'a/b/c');
    });

    test('join with ./', () {
      final base = PathBuf.fromBytes(_b('/a/b'));
      final joined = base.join(PathBuf.fromBytes(_b('./c')));
      expect(joined.toStringLossy(), '/a/b/./c');
    });

    test('join with ../', () {
      final base = PathBuf.fromBytes(_b('/a/b'));
      final joined = base.join(PathBuf.fromBytes(_b('../c')));
      expect(joined.toStringLossy(), '/a/b/../c');
    });

    // ─────────────────────────────────────────────
    // EMOJI
    // ─────────────────────────────────────────────

    test('emoji join', () {
      final base = PathBuf.fromBytes(_b('/🚀/🔥'));
      final joined = base.join(PathBuf.fromBytes(_b('file.txt')));
      expect(joined.toStringLossy(), '/🚀/🔥/file.txt');
    });

    test('emoji in both sides', () {
      final base = PathBuf.fromBytes(_b('/🚀'));
      final joined = base.join(PathBuf.fromBytes(_b('🔥/file')));
      expect(joined.toStringLossy(), '/🚀/🔥/file');
    });

    // ─────────────────────────────────────────────
    // FOREIGN
    // ─────────────────────────────────────────────

    test('foreign join', () {
      final base = PathBuf.fromBytes(_b('/用户/данные'));
      final joined = base.join(PathBuf.fromBytes(_b('ملف.txt')));
      expect(joined.toStringLossy(), '/用户/данные/ملف.txt');
    });

    test('mixed foreign + emoji', () {
      final base = PathBuf.fromBytes(_b('/用户/🚀'));
      final joined = base.join(PathBuf.fromBytes(_b('данные/🔥')));
      expect(joined.toStringLossy(), '/用户/🚀/данные/🔥');
    });

    // ─────────────────────────────────────────────
    // MIXED SEPARATORS (POSIX RULE)
    // ─────────────────────────────────────────────

    test('mixed separators join', () {
      final base = PathBuf.fromBytes(_b(r'/a\b'));
      final joined = base.join(PathBuf.fromBytes(_b(r'c\d')));
      expect(joined.toStringLossy(), r'/a\b/c\d');
    });

    // ─────────────────────────────────────────────
    // WINDOWS STYLE INSIDE POSIX
    // ─────────────────────────────────────────────

    test('windows style path join POSIX', () {
      final base = PathBuf.fromBytes(_b(r'C:\foo'));
      final joined = base.join(PathBuf.fromBytes(_b('bar')));
      expect(joined.toStringLossy(), r'C:\foo/bar');
    });

    test('UNC style join POSIX', () {
      final base = PathBuf.fromBytes(_b(r'\\server\share'));
      final joined = base.join(PathBuf.fromBytes(_b('file')));
      expect(joined.toStringLossy(), r'\\server\share/file');
    });

    test('relative base join simple', () {
      final base = PathBuf.fromBytes(_b('a/b'));
      final joined = base.join(PathBuf.fromBytes(_b('c/d')));

      expect(joined.toStringLossy(), 'a/b/c/d');
    });

    test('relative base starting with ./', () {
      final base = PathBuf.fromBytes(_b('./a/b'));
      final joined = base.join(PathBuf.fromBytes(_b('c')));

      expect(joined.toStringLossy(), './a/b/c');
    });

    test('relative base starting with ../', () {
      final base = PathBuf.fromBytes(_b('../a/b'));
      final joined = base.join(PathBuf.fromBytes(_b('c')));

      expect(joined.toStringLossy(), '../a/b/c');
    });

    test('deep relative base ../../ join', () {
      final base = PathBuf.fromBytes(_b('../../a/b'));
      final joined = base.join(PathBuf.fromBytes(_b('c/d')));

      expect(joined.toStringLossy(), '../../a/b/c/d');
    });

    test('relative base with emoji', () {
      final base = PathBuf.fromBytes(_b('🚀/🔥'));
      final joined = base.join(PathBuf.fromBytes(_b('file.txt')));

      expect(joined.toStringLossy(), '🚀/🔥/file.txt');
    });

    test('relative base with foreign scripts', () {
      final base = PathBuf.fromBytes(_b('用户/данные'));
      final joined = base.join(PathBuf.fromBytes(_b('ملف.txt')));

      expect(joined.toStringLossy(), '用户/данные/ملف.txt');
    });

    test('relative base with mixed separators', () {
      final base = PathBuf.fromBytes(_b(r'a\b'));
      final joined = base.join(PathBuf.fromBytes(_b(r'c\d')));

      expect(joined.toStringLossy(), r'a\b/c\d');
    });

    test('relative windows-style base inside POSIX', () {
      final base = PathBuf.fromBytes(_b(r'C:\foo'));
      final joined = base.join(PathBuf.fromBytes(_b('bar/baz')));

      expect(joined.toStringLossy(), r'C:\foo/bar/baz');
    });

    test(r'mixed relative slashes: ./a\b + c\d', () {
      final base = PathBuf.fromBytes(_b(r'./a\b'));
      final joined = base.join(PathBuf.fromBytes(_b(r'c\d')));

      expect(joined.toStringLossy(), r'./a\b/c\d');
    });

    test(r'mixed relative slashes: ../a\b + c/d', () {
      final base = PathBuf.fromBytes(_b(r'../a\b'));
      final joined = base.join(PathBuf.fromBytes(_b('c/d')));

      expect(joined.toStringLossy(), r'../a\b/c/d');
    });

    test(r'starts with \ ends with /: \a\b/ + c', () {
      final base = PathBuf.fromBytes(_b(r'\a\b/'));
      final joined = base.join(PathBuf.fromBytes(_b('c')));

      expect(joined.toStringLossy(), r'\a\b/c');
    });

    test(r'starts with \ ends with / mixed: \a\b/ + c\d', () {
      final base = PathBuf.fromBytes(_b(r'\a\b/'));
      final joined = base.join(PathBuf.fromBytes(_b(r'c\d')));

      expect(joined.toStringLossy(), r'\a\b/c\d');
    });

    test('drive-like literal in POSIX: C: + a/b', () {
      final base = PathBuf.fromBytes(_b('C:'));
      final joined = base.join(PathBuf.fromBytes(_b('a/b')));

      expect(joined.toStringLossy(), 'C:/a/b');
    });

    test('drive-like literal Z: join', () {
      final base = PathBuf.fromBytes(_b('Z:'));
      final joined = base.join(PathBuf.fromBytes(_b('file.txt')));

      expect(joined.toStringLossy(), 'Z:/file.txt');
    });

    test('root join: / + a', () {
      final base = PathBuf.fromBytes(_b('/'));
      final joined = base.join(PathBuf.fromBytes(_b('a')));

      expect(joined.toStringLossy(), '/a');
    });

    test('root join absolute: / + /a/b', () {
      final base = PathBuf.fromBytes(_b('/'));
      final joined = base.join(PathBuf.fromBytes(_b('/a/b')));

      expect(joined.toStringLossy(), '/a/b');
    });

    test('join / with /', () {
      final base = PathBuf.fromBytes(_b('/'));
      final joined = base.join(PathBuf.fromBytes(_b('/')));

      expect(joined.toStringLossy(), '/');
    });
  });

  // =========================================================
  // WINDOWS
  // =========================================================

  group('join() Windows', () {
    setUp(() {
      Pathify.instance.overriddenPlatform = PathifyPlatform.windows;
    });

    tearDown(Pathify.instance.resetForTesting);

    // ─────────────────────────────────────────────
    // BASIC
    // ─────────────────────────────────────────────

    test('simple join', () {
      final base = PathBuf.fromBytes(_w(r'C:\a\b'));
      final joined = base.join(PathBuf.fromBytes(_w('c')));
      expect(joined.toStringLossy(), r'C:\a\b\c');
    });

    test('join multiple levels', () {
      final base = PathBuf.fromBytes(_w(r'C:\a'));
      final joined = base.join(PathBuf.fromBytes(_w(r'b\c\d')));
      expect(joined.toStringLossy(), r'C:\a\b\c\d');
    });

    test('join with trailing slash base', () {
      final base = PathBuf.fromBytes(_w(r'C:\a\b\'));
      final joined = base.join(PathBuf.fromBytes(_w('c')));
      expect(joined.toStringLossy(), r'C:\a\b\c');
    });

    // ─────────────────────────────────────────────
    // RELATIVE
    // ─────────────────────────────────────────────

    test('relative join', () {
      final base = PathBuf.fromBytes(_w(r'a\b'));
      final joined = base.join(PathBuf.fromBytes(_w('c')));
      expect(joined.toStringLossy(), r'a\b\c');
    });

    test('join with ./', () {
      final base = PathBuf.fromBytes(_w(r'C:\a\b'));
      final joined = base.join(PathBuf.fromBytes(_w(r'.\c')));
      expect(joined.toStringLossy(), r'C:\a\b\.\c');
    });

    test('join with ../', () {
      final base = PathBuf.fromBytes(_w(r'C:\a\b'));
      final joined = base.join(PathBuf.fromBytes(_w(r'..\c')));
      expect(joined.toStringLossy(), r'C:\a\b\..\c');
    });

    // ─────────────────────────────────────────────
    // EMOJI
    // ─────────────────────────────────────────────

    test('emoji join', () {
      final base = PathBuf.fromBytes(_w(r'C:\🚀\🔥'));
      final joined = base.join(PathBuf.fromBytes(_w('file.txt')));
      expect(joined.toStringLossy(), r'C:\🚀\🔥\file.txt');
    });

    test('emoji both sides', () {
      final base = PathBuf.fromBytes(_w(r'C:\🚀'));
      final joined = base.join(PathBuf.fromBytes(_w(r'🔥\file')));
      expect(joined.toStringLossy(), r'C:\🚀\🔥\file');
    });

    // ─────────────────────────────────────────────
    // FOREIGN
    // ─────────────────────────────────────────────

    test('foreign join', () {
      final base = PathBuf.fromBytes(_w(r'C:\用户\данные'));
      final joined = base.join(PathBuf.fromBytes(_w('ملف.txt')));
      expect(joined.toStringLossy(), r'C:\用户\данные\ملف.txt');
    });

    test('mixed foreign + emoji', () {
      final base = PathBuf.fromBytes(_w(r'C:\用户\🚀'));
      final joined = base.join(PathBuf.fromBytes(_w(r'данные\🔥')));
      expect(joined.toStringLossy(), r'C:\用户\🚀\данные\🔥');
    });

    // ─────────────────────────────────────────────
    // MIXED SEPARATORS
    // ─────────────────────────────────────────────

    test('mixed separators join', () {
      final base = PathBuf.fromBytes(_w(r'C:\a/b'));
      final joined = base.join(PathBuf.fromBytes(_w(r'c\d')));
      expect(joined.toStringLossy(), r'C:\a/b\c\d');
    });

    // ─────────────────────────────────────────────
    // POSIX STYLE INSIDE WINDOWS
    // ─────────────────────────────────────────────

    test('posix path join windows', () {
      final base = PathBuf.fromBytes(_w('/a/b'));
      final joined = base.join(PathBuf.fromBytes(_w('c')));
      expect(joined.toStringLossy(), r'/a/b\c');
    });

    test('UNC join', () {
      final base = PathBuf.fromBytes(_w(r'\\server\share'));
      final joined = base.join(PathBuf.fromBytes(_w('file')));
      expect(joined.toStringLossy(), r'\\server\share\file');
    });

    test('relative base join simple', () {
      final base = PathBuf.fromBytes(_w(r'a\b'));
      final joined = base.join(PathBuf.fromBytes(_w(r'c\d')));

      expect(joined.toStringLossy(), r'a\b\c\d');
    });

    test('relative base starting with ./', () {
      final base = PathBuf.fromBytes(_w(r'.\a\b'));
      final joined = base.join(PathBuf.fromBytes(_w('c')));

      expect(joined.toStringLossy(), r'.\a\b\c');
    });

    test('relative base starting with ../', () {
      final base = PathBuf.fromBytes(_w(r'..\a\b'));
      final joined = base.join(PathBuf.fromBytes(_w('c')));

      expect(joined.toStringLossy(), r'..\a\b\c');
    });

    test('deep relative base ../../ join', () {
      final base = PathBuf.fromBytes(_w(r'..\..\a\b'));
      final joined = base.join(PathBuf.fromBytes(_w(r'c\d')));

      expect(joined.toStringLossy(), r'..\..\a\b\c\d');
    });

    test('relative base with emoji', () {
      final base = PathBuf.fromBytes(_w(r'🚀\🔥'));
      final joined = base.join(PathBuf.fromBytes(_w('file.txt')));

      expect(joined.toStringLossy(), r'🚀\🔥\file.txt');
    });

    test('relative base with foreign scripts', () {
      final base = PathBuf.fromBytes(_w(r'用户\данные'));
      final joined = base.join(PathBuf.fromBytes(_w('ملف.txt')));

      expect(joined.toStringLossy(), r'用户\данные\ملف.txt');
    });

    test('relative base with mixed separators', () {
      final base = PathBuf.fromBytes(_w('a/b'));
      final joined = base.join(PathBuf.fromBytes(_w(r'c\d')));

      expect(joined.toStringLossy(), r'a/b\c\d');
    });

    test('relative POSIX-style base inside Windows', () {
      final base = PathBuf.fromBytes(_w('a/b'));
      final joined = base.join(PathBuf.fromBytes(_w('c')));

      expect(joined.toStringLossy(), r'a/b\c');
    });

    test(r'mixed relative slashes: .\a/b + c\d', () {
      final base = PathBuf.fromBytes(_w(r'.\a/b'));
      final joined = base.join(PathBuf.fromBytes(_w(r'c\d')));

      expect(joined.toStringLossy(), r'.\a/b\c\d');
    });

    test(r'mixed relative slashes: ..\a/b + c/d', () {
      final base = PathBuf.fromBytes(_w(r'..\a/b'));
      final joined = base.join(PathBuf.fromBytes(_w('c/d')));

      expect(joined.toStringLossy(), r'..\a/b\c/d');
    });

    test(r'starts with \ ends with /: \a\b/ + c', () {
      final base = PathBuf.fromBytes(_w(r'\a\b/'));
      final joined = base.join(PathBuf.fromBytes(_w('c')));

      expect(joined.toStringLossy(), r'\a\b/c');
    });

    test(r'starts with \ ends with / mixed: \a\b/ + c\d', () {
      final base = PathBuf.fromBytes(_w(r'\a\b/'));
      final joined = base.join(PathBuf.fromBytes(_w(r'c\d')));

      expect(joined.toStringLossy(), r'\a\b/c\d');
    });

    test('drive C: relative join', () {
      final base = PathBuf.fromBytes(_w('C:'));
      final joined = base.join(PathBuf.fromBytes(_w(r'foo\bar')));

      expect(joined.toStringLossy(), r'C:foo\bar');
    });

    test('drive Z: relative join', () {
      final base = PathBuf.fromBytes(_w('Z:'));
      final joined = base.join(PathBuf.fromBytes(_w('file.txt')));

      expect(joined.toStringLossy(), 'Z:file.txt');
    });

    test(r'root join: \ + a', () {
      final base = PathBuf.fromBytes(_w(r'\'));
      final joined = base.join(PathBuf.fromBytes(_w('a')));

      expect(joined.toStringLossy(), r'\a');
    });

    test(r'root join absolute: \ + \a\b', () {
      final base = PathBuf.fromBytes(_w(r'\'));
      final joined = base.join(PathBuf.fromBytes(_w(r'\a\b')));

      expect(joined.toStringLossy(), r'\a\b');
    });

    test(r'join \ with \', () {
      final base = PathBuf.fromBytes(_w(r'\'));
      final joined = base.join(PathBuf.fromBytes(_w(r'\')));

      expect(joined.toStringLossy(), r'\');
    });
  });

  group('join() POSIX - prefixes treated as raw', () {
    setUp(() {
      Pathify.instance.overriddenPlatform = PathifyPlatform.linux;
    });

    tearDown(Pathify.instance.resetForTesting);

    test('UNC treated as literal', () {
      final base = PathBuf.fromBytes(_b(r'\\server\share'));
      final joined = base.join(PathBuf.fromBytes(_b('file')));

      expect(joined.toStringLossy(), r'\\server\share/file');
    });

    test('Disk prefix treated as literal', () {
      final base = PathBuf.fromBytes(_b(r'C:\foo'));
      final joined = base.join(PathBuf.fromBytes(_b('bar')));

      expect(joined.toStringLossy(), r'C:\foo/bar');
    });

    test('Device namespace literal', () {
      final base = PathBuf.fromBytes(_b(r'\\.\COM1'));
      final joined = base.join(PathBuf.fromBytes(_b('file')));

      expect(joined.toStringLossy(), r'\\.\COM1/file');
    });

    test('Verbatim path literal', () {
      final base = PathBuf.fromBytes(_b(r'\\?\C:\foo'));
      final joined = base.join(PathBuf.fromBytes(_b('bar')));

      expect(joined.toStringLossy(), r'\\?\C:\foo/bar');
    });

    test('UNC + absolute RHS (still append)', () {
      final base = PathBuf.fromBytes(_b(r'\\server\share'));
      final joined = base.join(PathBuf.fromBytes(_b('/a/b')));

      expect(joined.toStringLossy(), '/a/b');
    });

    test('Verbatim UNC + emoji', () {
      final base = PathBuf.fromBytes(_b(r'\\?\UNC\server\share'));
      final joined = base.join(PathBuf.fromBytes(_b('🚀/file.txt')));

      expect(joined.toStringLossy(), r'\\?\UNC\server\share/🚀/file.txt');
    });

    test('prefix + foreign scripts', () {
      final base = PathBuf.fromBytes(_b(r'C:\用户'));
      final joined = base.join(PathBuf.fromBytes(_b('данные/ملف.txt')));

      expect(joined.toStringLossy(), r'C:\用户/данные/ملف.txt');
    });
  });

  group('join() Windows - prefix semantics', () {
    setUp(() {
      Pathify.instance.overriddenPlatform = PathifyPlatform.windows;
    });

    tearDown(Pathify.instance.resetForTesting);

    // ─────────────────────────────────────────────
    // DISK
    // ─────────────────────────────────────────────

    test('Disk + relative', () {
      final base = PathBuf.fromBytes(_w(r'C:\foo'));
      final joined = base.join(PathBuf.fromBytes(_w('bar')));

      expect(joined.toStringLossy(), r'C:\foo\bar');
    });

    test('Disk + rooted RHS', () {
      final base = PathBuf.fromBytes(_w(r'C:\foo'));
      final joined = base.join(PathBuf.fromBytes(_w(r'\bar')));

      expect(joined.toStringLossy(), r'C:\bar');
    });

    test('Disk + disk RHS replaces', () {
      final base = PathBuf.fromBytes(_w(r'C:\foo'));
      final joined = base.join(PathBuf.fromBytes(_w(r'D:\bar')));

      expect(joined.toStringLossy(), r'D:\bar');
    });

    // ─────────────────────────────────────────────
    // UNC
    // ─────────────────────────────────────────────

    test('UNC + relative', () {
      final base = PathBuf.fromBytes(_w(r'\\server\share\foo'));
      final joined = base.join(PathBuf.fromBytes(_w('bar')));

      expect(joined.toStringLossy(), r'\\server\share\foo\bar');
    });

    test('UNC + rooted RHS', () {
      final base = PathBuf.fromBytes(_w(r'\\server\share\foo'));
      final joined = base.join(PathBuf.fromBytes(_w(r'\bar')));

      expect(joined.toStringLossy(), r'\\server\share\bar');
    });

    test('UNC + UNC RHS replaces', () {
      final base = PathBuf.fromBytes(_w(r'\\server\share\foo'));
      final joined = base.join(
        PathBuf.fromBytes(_w(r'\\other\share\bar')),
      );

      expect(joined.toStringLossy(), r'\\other\share\bar');
    });

    // ─────────────────────────────────────────────
    // DEVICE NAMESPACE
    // ─────────────────────────────────────────────

    test('Device namespace + relative', () {
      final base = PathBuf.fromBytes(_w(r'\\.\COM1'));
      final joined = base.join(PathBuf.fromBytes(_w('file')));

      expect(joined.toStringLossy(), r'\\.\COM1\file');
    });

    test('Device namespace + rooted RHS', () {
      final base = PathBuf.fromBytes(_w(r'\\.\COM1'));
      final joined = base.join(PathBuf.fromBytes(_w(r'\file')));

      expect(joined.toStringLossy(), r'\\.\COM1\file');
    });

    // ─────────────────────────────────────────────
    // VERBATIM
    // ─────────────────────────────────────────────

    test('Verbatim disk + relative', () {
      final base = PathBuf.fromBytes(_w(r'\\?\C:\foo'));
      final joined = base.join(PathBuf.fromBytes(_w('bar')));

      expect(joined.toStringLossy(), r'\\?\C:\foo\bar');
    });

    test('Verbatim disk + rooted RHS', () {
      final base = PathBuf.fromBytes(_w(r'\\?\C:\foo'));
      final joined = base.join(PathBuf.fromBytes(_w(r'\bar')));

      expect(joined.toStringLossy(), r'\\?\C:\bar');
    });

    test('Verbatim UNC + relative', () {
      final base = PathBuf.fromBytes(
        _w(r'\\?\UNC\server\share\foo'),
      );
      final joined = base.join(PathBuf.fromBytes(_w('bar')));

      expect(
        joined.toStringLossy(),
        r'\\?\UNC\server\share\foo\bar',
      );
    });

    // ─────────────────────────────────────────────
    // MIXED + UNICODE
    // ─────────────────────────────────────────────

    test('UNC + emoji', () {
      final base = PathBuf.fromBytes(_w(r'\\server\share\🚀'));
      final joined = base.join(PathBuf.fromBytes(_w('🔥.txt')));

      expect(joined.toStringLossy(), r'\\server\share\🚀\🔥.txt');
    });

    test('Disk + foreign scripts', () {
      final base = PathBuf.fromBytes(_w(r'C:\用户'));
      final joined = base.join(
        PathBuf.fromBytes(_w(r'данные\ملف.txt')),
      );

      expect(joined.toStringLossy(), r'C:\用户\данные\ملف.txt');
    });
  });

  group('join() root edge cases POSIX', () {
    setUp(() {
      Pathify.instance.overriddenPlatform = PathifyPlatform.linux;
    });

    tearDown(Pathify.instance.resetForTesting);

    test('root / joined with normal segment', () {
      final base = PathBuf.fromBytes(_b('/'));
      final joined = base.join(PathBuf.fromBytes(_b('something')));

      expect(joined.toStringLossy(), '/something');
    });

    test('root / joined with nested path', () {
      final base = PathBuf.fromBytes(_b('/'));
      final joined = base.join(PathBuf.fromBytes(_b('a/b/c')));

      expect(joined.toStringLossy(), '/a/b/c');
    });

    test('root / joined with emoji path', () {
      final base = PathBuf.fromBytes(_b('/'));
      final joined = base.join(PathBuf.fromBytes(_b('🚀/🔥/file.txt')));

      expect(joined.toStringLossy(), '/🚀/🔥/file.txt');
    });

    test('root / joined with foreign scripts', () {
      final base = PathBuf.fromBytes(_b('/'));
      final joined = base.join(
        PathBuf.fromBytes(_b('用户/данные/ملف.txt')),
      );

      expect(joined.toStringLossy(), '/用户/данные/ملف.txt');
    });

    test('root / joined with windows-style path', () {
      final base = PathBuf.fromBytes(_b('/'));
      final joined = base.join(
        PathBuf.fromBytes(_b(r'C:\foo\bar')),
      );

      expect(joined.toStringLossy(), r'/C:\foo\bar');
    });

    test('root / joined with UNC-style path', () {
      final base = PathBuf.fromBytes(_b('/'));
      final joined = base.join(
        PathBuf.fromBytes(_b(r'\\server\share')),
      );

      expect(joined.toStringLossy(), r'/\\server\share');
    });
  });

  group('join() root edge cases Windows', () {
    setUp(() {
      Pathify.instance.overriddenPlatform = PathifyPlatform.windows;
    });

    tearDown(Pathify.instance.resetForTesting);

    test(r'root \ joined with normal segment', () {
      final base = PathBuf.fromBytes(_w(r'\'));
      final joined = base.join(PathBuf.fromBytes(_w('something')));

      expect(joined.toStringLossy(), r'\something');
    });

    test(r'root \ joined with nested path', () {
      final base = PathBuf.fromBytes(_w(r'\'));
      final joined = base.join(PathBuf.fromBytes(_w(r'a\b\c')));

      expect(joined.toStringLossy(), r'\a\b\c');
    });

    test(r'root \ joined with emoji path', () {
      final base = PathBuf.fromBytes(_w(r'\'));
      final joined = base.join(
        PathBuf.fromBytes(_w(r'🚀\🔥\file.txt')),
      );

      expect(joined.toStringLossy(), r'\🚀\🔥\file.txt');
    });

    test(r'root \ joined with foreign scripts', () {
      final base = PathBuf.fromBytes(_w(r'\'));
      final joined = base.join(
        PathBuf.fromBytes(_w(r'用户\данные\ملف.txt')),
      );

      expect(joined.toStringLossy(), r'\用户\данные\ملف.txt');
    });

    test(r'root \ joined with POSIX path', () {
      final base = PathBuf.fromBytes(_w(r'\'));
      final joined = base.join(
        PathBuf.fromBytes(_w('/a/b/c')),
      );

      expect(joined.toStringLossy(), '/a/b/c');
    });
  });

  group('join() Windows prefix roots POSIX behavior', () {
    setUp(() {
      Pathify.instance.overriddenPlatform = PathifyPlatform.linux;
    });

    tearDown(Pathify.instance.resetForTesting);

    test('Disk root literal', () {
      final base = PathBuf.fromBytes(_b('C:'));
      final joined = base.join(PathBuf.fromBytes(_b('foo')));

      expect(joined.toStringLossy(), 'C:/foo');
    });

    test('UNC root literal', () {
      final base = PathBuf.fromBytes(_b(r'\\server\share'));
      final joined = base.join(PathBuf.fromBytes(_b('foo')));

      expect(joined.toStringLossy(), r'\\server\share/foo');
    });

    test('DeviceNS root literal', () {
      final base = PathBuf.fromBytes(_b(r'\\.\COM1'));
      final joined = base.join(PathBuf.fromBytes(_b('foo')));

      expect(joined.toStringLossy(), r'\\.\COM1/foo');
    });

    test('Verbatim root literal', () {
      final base = PathBuf.fromBytes(_b(r'\\?\'));
      final joined = base.join(PathBuf.fromBytes(_b('foo')));

      expect(joined.toStringLossy(), r'\\?\/foo');
    });

    test('VerbatimUNC root literal', () {
      final base = PathBuf.fromBytes(
        _b(r'\\?\UNC\server\share'),
      );
      final joined = base.join(PathBuf.fromBytes(_b('foo')));

      expect(
        joined.toStringLossy(),
        r'\\?\UNC\server\share/foo',
      );
    });

    test('VerbatimDisk root literal', () {
      final base = PathBuf.fromBytes(_b(r'\\?\C:\'));
      final joined = base.join(PathBuf.fromBytes(_b('foo')));

      expect(joined.toStringLossy(), r'\\?\C:\/foo');
    });
  });

  group('join() Windows prefix roots Windows behavior', () {
    setUp(() {
      Pathify.instance.overriddenPlatform = PathifyPlatform.windows;
    });

    tearDown(Pathify.instance.resetForTesting);

    test('Disk root', () {
      final base = PathBuf.fromBytes(_w(r'C:\'));
      final joined = base.join(PathBuf.fromBytes(_w('foo')));

      expect(joined.toStringLossy(), r'C:\foo');
    });

    test('Disk drive-relative root', () {
      final base = PathBuf.fromBytes(_w('C:'));
      final joined = base.join(PathBuf.fromBytes(_w(r'foo\bar')));

      expect(joined.toStringLossy(), r'C:foo\bar');
    });

    test('UNC root', () {
      final base = PathBuf.fromBytes(
        _w(r'\\server\share'),
      );
      final joined = base.join(PathBuf.fromBytes(_w('foo')));

      expect(joined.toStringLossy(), r'\\server\share\foo');
    });

    test('DeviceNS root', () {
      final base = PathBuf.fromBytes(_w(r'\\.\COM1'));
      final joined = base.join(PathBuf.fromBytes(_w('foo')));

      expect(joined.toStringLossy(), r'\\.\COM1\foo');
    });

    test('Verbatim root', () {
      final base = PathBuf.fromBytes(_w(r'\\?\'));
      final joined = base.join(PathBuf.fromBytes(_w('foo')));

      expect(joined.toStringLossy(), r'\\?\\foo');
    });

    test('VerbatimUNC root', () {
      final base = PathBuf.fromBytes(
        _w(r'\\?\UNC\server\share'),
      );
      final joined = base.join(PathBuf.fromBytes(_w('foo')));

      expect(
        joined.toStringLossy(),
        r'\\?\UNC\server\share\foo',
      );
    });

    test('VerbatimDisk root', () {
      final base = PathBuf.fromBytes(_w(r'\\?\C:\'));
      final joined = base.join(PathBuf.fromBytes(_w('foo')));

      expect(joined.toStringLossy(), r'\\?\C:\foo');
    });
  });
}
