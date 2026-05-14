import 'dart:typed_data';

import 'package:pathify/pathify.dart';
import 'package:test/test.dart';

Uint16List _w(String s) => Uint16List.fromList(s.codeUnits);

void main() {
  group('parent() Windows deep tests', () {
    setUp(() {
      Pathify.instance.overriddenPlatform = PathifyPlatform.windows;
    });

    tearDown(Pathify.instance.resetForTesting);

    // ─────────────────────────────────────────────
    // GETPARENTPATH PARITY CASES
    // ─────────────────────────────────────────────

    test('dot returns non-null empty parent', () {
      final p = PathBuf.fromBytes(_w('.'));
      final parent = p.parent();
      expect(parent, isNotNull);
      expect(parent!.isEmpty, isTrue);
    });

    test('double dot returns non-null empty parent', () {
      final p = PathBuf.fromBytes(_w('..'));
      final parent = p.parent();
      expect(parent, isNotNull);
      expect(parent!.isEmpty, isTrue);
    });

    test('single file component returns non-null empty parent', () {
      final p = PathBuf.fromBytes(_w('file.txt'));
      final parent = p.parent();
      expect(parent, isNotNull);
      expect(parent!.isEmpty, isTrue);
    });

    test('single folder component returns non-null empty parent', () {
      final p = PathBuf.fromBytes(_w('folder'));
      final parent = p.parent();
      expect(parent, isNotNull);
      expect(parent!.isEmpty, isTrue);
    });

    test('../file.txt parent is ..', () {
      final p = PathBuf.fromBytes(_w('../file.txt'));
      final parent = p.parent();
      expect(parent, isNotNull);
      expect(parent!.toStringLossy(), '..');
    });

    test('./file.txt parent is .', () {
      final p = PathBuf.fromBytes(_w('./file.txt'));
      final parent = p.parent();
      expect(parent, isNotNull);
      expect(parent!.toStringLossy(), '.');
    });

    test('../../parent/folder/file.txt parent preserves forward slashes', () {
      final p = PathBuf.fromBytes(_w('../../parent/folder/file.txt'));
      final parent = p.parent();
      expect(parent, isNotNull);
      expect(parent!.toStringLossy(), '../../parent/folder');
    });

    test(r'folder\..\other\file.txt parent is folder\..\other', () {
      final p = PathBuf.fromBytes(_w(r'folder\..\other\file.txt'));
      final parent = p.parent();
      expect(parent, isNotNull);
      expect(parent!.toStringLossy(), r'folder\..\other');
    });

    // ─────────────────────────────────────────────
    // DISK ROOTS
    // ─────────────────────────────────────────────

    test(r'C:\ returns null', () {
      final p = PathBuf.fromBytes(_w(r'C:\'));
      expect(p.parent(), isNull);
    });

    test(r'D:\ returns null', () {
      final p = PathBuf.fromBytes(_w(r'D:\'));
      expect(p.parent(), isNull);
    });

    test('C: returns null', () {
      final p = PathBuf.fromBytes(_w('C:'));
      expect(p.parent(), isNull);
    });

    test(r'C:\Windows parent is C:\', () {
      final p = PathBuf.fromBytes(_w(r'C:\Windows'));
      expect(p.parent()!.toStringLossy(), r'C:\');
    });

    test(r'C:\Windows\System32 parent is C:\Windows', () {
      final p = PathBuf.fromBytes(_w(r'C:\Windows\System32'));
      expect(p.parent()!.toStringLossy(), r'C:\Windows');
    });

    test(
      r'C:\Users\Name\Documents\file.txt parent is C:\Users\Name\Documents',
      () {
        final p = PathBuf.fromBytes(_w(r'C:\Users\Name\Documents\file.txt'));
        expect(p.parent()!.toStringLossy(), r'C:\Users\Name\Documents');
      },
    );

    test(
      r'D:\Projects\MyApp\src\main.dart parent is D:\Projects\MyApp\src',
      () {
        final p = PathBuf.fromBytes(_w(r'D:\Projects\MyApp\src\main.dart'));
        expect(p.parent()!.toStringLossy(), r'D:\Projects\MyApp\src');
      },
    );

    test(
      r'C:\Program Files\MyApp\bin\app.exe parent is C:\Program Files\MyApp\bin',
      () {
        final p = PathBuf.fromBytes(_w(r'C:\Program Files\MyApp\bin\app.exe'));
        expect(p.parent()!.toStringLossy(), r'C:\Program Files\MyApp\bin');
      },
    );

    test(r'D:\Data\backup.zip parent is D:\Data', () {
      final p = PathBuf.fromBytes(_w(r'D:\Data\backup.zip'));
      expect(p.parent()!.toStringLossy(), r'D:\Data');
    });

    // ─────────────────────────────────────────────
    // UNC PATHS
    // ─────────────────────────────────────────────

    test(r'\\server\share returns null', () {
      final p = PathBuf.fromBytes(_w(r'\\server\share'));
      expect(p.parent(), isNull);
    });

    test(r'\\server\share\ returns null', () {
      final p = PathBuf.fromBytes(_w(r'\\server\share\'));
      expect(p.parent(), isNull);
    });

    test(r'\\server\share\data parent is \\server\share\', () {
      final p = PathBuf.fromBytes(_w(r'\\server\share\data'));
      expect(p.parent()!.toStringLossy(), r'\\server\share\');
    });

    test(r'\\server\share\folder\file.txt parent is \\server\share\folder', () {
      final p = PathBuf.fromBytes(_w(r'\\server\share\folder\file.txt'));
      expect(p.parent()!.toStringLossy(), r'\\server\share\folder');
    });

    test(
      r'\\localhost\c$\Users\Name\file.pdf parent is \\localhost\c$\Users\Name',
      () {
        final p = PathBuf.fromBytes(_w(r'\\localhost\c$\Users\Name\file.pdf'));
        expect(p.parent()!.toStringLossy(), r'\\localhost\c$\Users\Name');
      },
    );

    test(
      r'\\server\share\folder\subfolder parent is \\server\share\folder',
      () {
        final p = PathBuf.fromBytes(_w(r'\\server\share\folder\subfolder'));
        expect(p.parent()!.toStringLossy(), r'\\server\share\folder');
      },
    );

    // ─────────────────────────────────────────────
    // VERBATIM PATHS
    // ─────────────────────────────────────────────

    test(r'\\?\C:\ returns null', () {
      final p = PathBuf.fromBytes(_w(r'\\?\C:\'));
      expect(p.parent(), isNull);
    });

    test(r'\\?\C:\folder\file.txt parent is \\?\C:\folder', () {
      final p = PathBuf.fromBytes(_w(r'\\?\C:\folder\file.txt'));
      expect(p.parent()!.toStringLossy(), r'\\?\C:\folder');
    });

    test(r'\\?\C:\Windows\System32 parent is \\?\C:\Windows', () {
      final p = PathBuf.fromBytes(_w(r'\\?\C:\Windows\System32'));
      expect(p.parent()!.toStringLossy(), r'\\?\C:\Windows');
    });

    test(r'\\?\UNC\server\share returns null', () {
      final p = PathBuf.fromBytes(_w(r'\\?\UNC\server\share'));
      expect(p.parent(), isNull);
    });

    test(r'\\?\UNC\server\share\folder parent is \\?\UNC\server\share\', () {
      final p = PathBuf.fromBytes(_w(r'\\?\UNC\server\share\folder'));
      expect(p.parent()!.toStringLossy(), r'\\?\UNC\server\share\');
    });

    // ─────────────────────────────────────────────
    // DEVICE NAMESPACE
    // ─────────────────────────────────────────────

    test(r'\\.\C:\ returns null', () {
      final p = PathBuf.fromBytes(_w(r'\\.\C:\'));
      expect(p.parent(), isNull);
    });

    test(r'\\.\C:\folder\file.txt parent is \\.\C:\folder', () {
      final p = PathBuf.fromBytes(_w(r'\\.\C:\folder\file.txt'));
      expect(p.parent()!.toStringLossy(), r'\\.\C:\folder');
    });

    test(r'\\.\C:\Windows\System32 parent is \\.\C:\Windows', () {
      final p = PathBuf.fromBytes(_w(r'\\.\C:\Windows\System32'));
      expect(p.parent()!.toStringLossy(), r'\\.\C:\Windows');
    });

    // ─────────────────────────────────────────────
    // MIXED SEPARATORS
    // ─────────────────────────────────────────────

    test(r'C:\foo/bar parent is C:\foo', () {
      final p = PathBuf.fromBytes(_w(r'C:\foo/bar'));
      expect(p.parent()!.toStringLossy(), r'C:\foo');
    });

    test(r'C:\foo/bar\something parent preserves forward slash', () {
      final p = PathBuf.fromBytes(_w(r'C:\foo/bar\something'));
      expect(p.parent()!.toStringLossy(), r'C:\foo/bar');
    });

    test(r'C:\Users/docs\file.txt parent preserves forward slash', () {
      final p = PathBuf.fromBytes(_w(r'C:\Users/docs\file.txt'));
      expect(p.parent()!.toStringLossy(), r'C:\Users/docs');
    });

    test(r'C:\foo/bar\something/t\a parent preserves forward slash', () {
      final p = PathBuf.fromBytes(_w(r'C:\foo/bar\something/t\a'));
      expect(p.parent()!.toStringLossy(), r'C:\foo/bar\something/t');
    });

    // ─────────────────────────────────────────────
    // RELATIVE PATHS
    // ─────────────────────────────────────────────

    test(r'folder\subfolder\file.txt parent is folder\subfolder', () {
      final p = PathBuf.fromBytes(_w(r'folder\subfolder\file.txt'));
      expect(p.parent()!.toStringLossy(), r'folder\subfolder');
    });

    test(r'documents\reports\annual.pdf parent is documents\reports', () {
      final p = PathBuf.fromBytes(_w(r'documents\reports\annual.pdf'));
      expect(p.parent()!.toStringLossy(), r'documents\reports');
    });

    test(r'project\file.txt parent is project', () {
      final p = PathBuf.fromBytes(_w(r'project\file.txt'));
      expect(p.parent()!.toStringLossy(), 'project');
    });

    test(r'folder\subfolder parent is folder', () {
      final p = PathBuf.fromBytes(_w(r'folder\subfolder'));
      expect(p.parent()!.toStringLossy(), 'folder');
    });

    // ─────────────────────────────────────────────
    // TRAILING SEPARATORS
    // ─────────────────────────────────────────────

    test(r'C:\Windows\System32\ parent is C:\Windows', () {
      final p = PathBuf.fromBytes(_w(r'C:\Windows\System32\'));
      expect(p.parent()!.toStringLossy(), r'C:\Windows');
    });

    test(r'C:\Windows\ parent is C:\', () {
      final p = PathBuf.fromBytes(_w(r'C:\Windows\'));
      expect(p.parent()!.toStringLossy(), r'C:\');
    });

    // ─────────────────────────────────────────────
    // EMPTY PATH
    // ─────────────────────────────────────────────

    test('empty path returns null', () {
      final p = PathBuf.fromBytes(_w(''));
      expect(p.parent(), isNull);
    });

    // ─────────────────────────────────────────────
    // EMOJI PATHS
    // ─────────────────────────────────────────────

    test(r'C:\🚀\🔥\file.txt parent is C:\🚀\🔥', () {
      final p = PathBuf.fromBytes(_w(r'C:\🚀\🔥\file.txt'));
      expect(p.parent()!.toStringLossy(), r'C:\🚀\🔥');
    });

    test(r'C:\temp\🚀\build parent is C:\temp\🚀', () {
      final p = PathBuf.fromBytes(_w(r'C:\temp\🚀\build'));
      expect(p.parent()!.toStringLossy(), r'C:\temp\🚀');
    });

    // ─────────────────────────────────────────────
    // FOREIGN SCRIPTS
    // ─────────────────────────────────────────────

    test(r'C:\用户\数据\文件.txt parent is C:\用户\数据', () {
      final p = PathBuf.fromBytes(_w(r'C:\用户\数据\文件.txt'));
      expect(p.parent()!.toStringLossy(), r'C:\用户\数据');
    });

    test(r'C:\данные\файл.txt parent is C:\данные', () {
      final p = PathBuf.fromBytes(_w(r'C:\данные\файл.txt'));
      expect(p.parent()!.toStringLossy(), r'C:\данные');
    });

    test(r'C:\مستخدم\ملفات\ملف.txt parent is C:\مستخدم\ملفات', () {
      final p = PathBuf.fromBytes(_w(r'C:\مستخدم\ملفات\ملف.txt'));
      expect(p.parent()!.toStringLossy(), r'C:\مستخدم\ملفات');
    });
  });
}
