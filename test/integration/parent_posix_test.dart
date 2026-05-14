import 'dart:convert';
import 'dart:typed_data';

import 'package:pathify/pathify.dart';
import 'package:test/test.dart';

Uint8List _b(String s) => Uint8List.fromList(utf8.encode(s));

void main() {
  group('parent() POSIX deep tests', () {
    setUp(() {
      Pathify.instance.overriddenPlatform = PathifyPlatform.linux;
    });

    tearDown(Pathify.instance.resetForTesting);

    // ─────────────────────────────────────────────
    // NORMAL POSIX PATHS
    // ─────────────────────────────────────────────

    test('simple absolute path', () {
      final p = PathBuf.fromBytes(_b('/a/b/c'));
      expect(p.parent()!.toStringLossy(), '/a/b');
    });

    test('single component absolute', () {
      final p = PathBuf.fromBytes(_b('/a'));
      expect(p.parent()!.toStringLossy(), '/');
    });

    test('relative path', () {
      final p = PathBuf.fromBytes(_b('a/b/c'));
      expect(p.parent()!.toStringLossy(), 'a/b');
    });

    test('single relative component', () {
      final p = PathBuf.fromBytes(_b('a'));
      final parent = p.parent();
      expect(parent, isNotNull);
      expect(parent!.length, 0);
    });

    // ─────────────────────────────────────────────
    // MIXED SLASHES (CRITICAL)
    // ─────────────────────────────────────────────

    test('backslash is NOT separator', () {
      final p = PathBuf.fromBytes(_b(r'/a\b/c'));
      expect(p.parent()!.toStringLossy(), r'/a\b');
    });

    test('multiple mixed slashes', () {
      final p = PathBuf.fromBytes(_b(r'/a\b/c\d/e'));
      expect(p.parent()!.toStringLossy(), r'/a\b/c\d');
    });

    test('only backslashes (no split)', () {
      final p = PathBuf.fromBytes(_b(r'a\b\c'));
      final parent = p.parent();
      expect(parent, isNotNull);
      expect(parent!.length, 0);
    });

    test(r'mixed separators with trailing slash: C:\foo/bar\something/', () {
      final p = PathBuf.fromBytes(_b(r'C:\foo/bar\something/'));

      // components = ["C:\foo", "bar\something"]
      // trailing '/' should NOT create an extra component

      expect(
        p.parent()!.toStringLossy(),
        r'C:\foo',
      );
    });

    test(
      r'mixed separators deeper with trailing slash: C:\foo/bar\something/t\a/',
      () {
        final p = PathBuf.fromBytes(_b(r'C:\foo/bar\something/t\a/'));

        // components = ["C:\foo", "bar\something", "t\a"]

        expect(
          p.parent()!.toStringLossy(),
          r'C:\foo/bar\something',
        );
      },
    );

    test('absolute path with trailing slash', () {
      final p = PathBuf.fromBytes(_b('/a/b/c/'));

      // components = ["a", "b", "c"]
      // trailing '/' ignored

      expect(p.parent()!.toStringLossy(), '/a/b');
    });

    test('absolute single component with trailing slash', () {
      final p = PathBuf.fromBytes(_b('/a/'));

      // components = ["a"]

      expect(p.parent()!.toStringLossy(), '/');
    });

    test('root only with trailing slash', () {
      final p = PathBuf.fromBytes(_b('/'));

      // root stays root

      final parent = p.parent();
      expect(parent, isNull);
    });

    test('relative path with trailing slash', () {
      final p = PathBuf.fromBytes(_b('a/b/c/'));

      expect(p.parent()!.toStringLossy(), 'a/b');
    });

    test('single relative component with trailing slash', () {
      final p = PathBuf.fromBytes(_b('a/'));

      final parent = p.parent();
      expect(parent, isNotNull);
      expect(parent!.length, 0);
    });

    test('multiple trailing slashes', () {
      final p = PathBuf.fromBytes(_b('/a/b/c///'));

      expect(p.parent()!.toStringLossy(), '/a/b');
    });

    // ─────────────────────────────────────────────
    // EMOJI PATHS
    // ─────────────────────────────────────────────

    test('emoji path basic', () {
      final p = PathBuf.fromBytes(_b('/🚀/🔥/file.txt'));
      expect(p.parent()!.toStringLossy(), '/🚀/🔥');
    });

    test('emoji mixed with ascii', () {
      final p = PathBuf.fromBytes(_b('/tmp/🚀file/test.txt'));
      expect(p.parent()!.toStringLossy(), '/tmp/🚀file');
    });

    test('emoji only component', () {
      final p = PathBuf.fromBytes(_b('🚀'));
      final parent = p.parent();
      expect(parent, isNotNull);
      expect(parent!.length, 0);
    });

    test('emoji + mixed slash', () {
      final p = PathBuf.fromBytes(_b(r'/🚀\🔥/file'));
      expect(p.parent()!.toStringLossy(), r'/🚀\🔥');
    });

    test('emoji + mixed slash 2', () {
      final p = PathBuf.fromBytes(_b(r'/🚀\🔥/ملفات/🚀\🔥'));
      expect(p.parent()!.toStringLossy(), r'/🚀\🔥/ملفات');
    });

    // ─────────────────────────────────────────────
    // FOREIGN SCRIPTS
    // ─────────────────────────────────────────────

    test('chinese path', () {
      final p = PathBuf.fromBytes(_b('/用户/数据/文件.txt'));
      expect(p.parent()!.toStringLossy(), '/用户/数据');
    });

    test('arabic rtl path', () {
      final p = PathBuf.fromBytes(_b('/مستخدم/ملفات/ملف.txt'));
      expect(p.parent()!.toStringLossy(), '/مستخدم/ملفات');
    });

    test('cyrillic path', () {
      final p = PathBuf.fromBytes(_b('/данные/файл.txt'));
      expect(p.parent()!.toStringLossy(), '/данные');
    });

    test('mixed foreign + emoji', () {
      final p = PathBuf.fromBytes(_b('/用户/🚀/данные/file.txt'));
      expect(p.parent()!.toStringLossy(), '/用户/🚀/данные');
    });

    // ─────────────────────────────────────────────
    // WINDOWS PATHS INSIDE POSIX
    // ─────────────────────────────────────────────

    test('windows path treated as single component', () {
      final p = PathBuf.fromBytes(_b(r'C:\foo\bar'));
      final parent = p.parent();
      expect(parent, isNotNull);
      expect(parent!.length, 0);
    });

    test('windows path mixed with POSIX separator', () {
      final p = PathBuf.fromBytes(_b(r'C:\foo/bar'));
      expect(p.parent()!.toStringLossy(), r'C:\foo');
    });

    test(r'mixed separators: C:\foo/bar\something', () {
      final p = PathBuf.fromBytes(_b(r'C:\foo/bar\something'));

      // split ONLY on '/'
      // components = ["C:\foo", "bar\something"]

      expect(
        p.parent()!.toStringLossy(),
        r'C:\foo',
      );
    });

    test(r'mixed separators deeper: C:\foo/bar\something/t\a', () {
      final p = PathBuf.fromBytes(_b(r'C:\foo/bar\something/t\a'));

      // components = ["C:\foo", "bar\something", "t\a"]

      expect(
        p.parent()!.toStringLossy(),
        r'C:\foo/bar\something',
      );
    });

    test(r'mixed separators with trailing slash: C:\foo/bar\something/', () {
      final p = PathBuf.fromBytes(_b(r'C:\foo/bar\something/'));

      // components = ["C:\foo", "bar\something"]
      // trailing '/' should NOT create an extra component

      expect(
        p.parent()!.toStringLossy(),
        r'C:\foo',
      );
    });

    test(
      r'mixed separators deeper with trailing slash: C:\foo/bar\something/t\a/',
      () {
        final p = PathBuf.fromBytes(_b(r'C:\foo/bar\something/t\a/'));

        // components = ["C:\foo", "bar\something", "t\a"]

        expect(
          p.parent()!.toStringLossy(),
          r'C:\foo/bar\something',
        );
      },
    );

    test('UNC path treated as literal', () {
      final p = PathBuf.fromBytes(_b(r'\\server\share\file'));
      final parent = p.parent();
      expect(parent, isNotNull);
      expect(parent!.length, 0);
    });

    // ─────────────────────────────────────────────
    // INVALID UTF-8
    // ─────────────────────────────────────────────

    test('invalid bytes inside path', () {
      final bytes = Uint8List.fromList([0x2F, 0x61, 0x2F, 0xFF, 0x62]);
      final p = PathBuf.fromBytes(bytes);

      expect(p.parent, returnsNormally);
    });

    test('invalid bytes with separators', () {
      final bytes = Uint8List.fromList([0x2F, 0xFF, 0x2F, 0x61]);
      final p = PathBuf.fromBytes(bytes);

      expect(p.parent(), isNotNull);
    });

    // ─────────────────────────────────────────────
    // MIXED EVERYTHING
    // ─────────────────────────────────────────────

    test('emoji + foreign + mixed slash', () {
      final p = PathBuf.fromBytes(
        _b(r'/用户\🚀/данные\ملف/file.txt'),
      );

      expect(
        p.parent()!.toStringLossy(),
        r'/用户\🚀/данные\ملف',
      );
    });

    test('foreign + windows + emoji mixed', () {
      final p = PathBuf.fromBytes(
        _b(r'用户\🚀\C:\data/file.txt'),
      );

      expect(
        p.parent()!.toStringLossy(),
        r'用户\🚀\C:\data',
      );
    });

    test('deep mixed corruption case', () {
      final bytes = Uint8List.fromList([
        ..._b('/用户/'),
        0xFF,
        ..._b('/🚀/'),
        0xFE,
        ..._b('file.txt'),
      ]);

      final p = PathBuf.fromBytes(bytes);

      expect(p.parent, returnsNormally);
    });

    // ─────────────────────────────────────────────
    // GETPARENTPATH PARITY CASES
    // ─────────────────────────────────────────────

    test('dot returns non-null empty parent', () {
      final p = PathBuf.fromBytes(_b('.'));
      final parent = p.parent();
      expect(parent, isNotNull);
      expect(parent!.isEmpty, isTrue);
    });

    test('double dot returns non-null empty parent', () {
      final p = PathBuf.fromBytes(_b('..'));
      final parent = p.parent();
      expect(parent, isNotNull);
      expect(parent!.isEmpty, isTrue);
    });

    test('single file component returns non-null empty parent', () {
      final p = PathBuf.fromBytes(_b('file.txt'));
      final parent = p.parent();
      expect(parent, isNotNull);
      expect(parent!.isEmpty, isTrue);
    });

    test('single folder component returns non-null empty parent', () {
      final p = PathBuf.fromBytes(_b('folder'));
      final parent = p.parent();
      expect(parent, isNotNull);
      expect(parent!.isEmpty, isTrue);
    });

    test('../file.txt parent is ..', () {
      final p = PathBuf.fromBytes(_b('../file.txt'));
      final parent = p.parent();
      expect(parent, isNotNull);
      expect(parent!.toStringLossy(), '..');
    });

    test('./file.txt parent is .', () {
      final p = PathBuf.fromBytes(_b('./file.txt'));
      final parent = p.parent();
      expect(parent, isNotNull);
      expect(parent!.toStringLossy(), '.');
    });

    test('../../parent/folder/file.txt parent is ../../parent/folder', () {
      final p = PathBuf.fromBytes(_b('../../parent/folder/file.txt'));
      final parent = p.parent();
      expect(parent, isNotNull);
      expect(parent!.toStringLossy(), '../../parent/folder');
    });

    test('folder/../other/file.txt parent is folder/../other', () {
      final p = PathBuf.fromBytes(_b('folder/../other/file.txt'));
      final parent = p.parent();
      expect(parent, isNotNull);
      expect(parent!.toStringLossy(), 'folder/../other');
    });

    test('root / returns null', () {
      final p = PathBuf.fromBytes(_b('/'));
      expect(p.parent(), isNull);
    });

    test('empty path returns null', () {
      final p = PathBuf.fromBytes(_b(''));
      expect(p.parent(), isNull);
    });

    // ─────────────────────────────────────────────
    // MIXED SLASHES CORRECTIONS
    // ─────────────────────────────────────────────

    test(r'C:\foo/bar\something parent is C:\foo on Unix', () {
      final p = PathBuf.fromBytes(_b(r'C:\foo/bar\something'));
      expect(p.parent()!.toStringLossy(), r'C:\foo');
    });

    test(
      r'C:\foo/bar\something/t\a parent is C:\foo/bar\something on Unix',
      () {
        final p = PathBuf.fromBytes(_b(r'C:\foo/bar\something/t\a'));
        expect(p.parent()!.toStringLossy(), r'C:\foo/bar\something');
      },
    );
  });
}
