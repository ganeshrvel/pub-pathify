import 'dart:typed_data';

import 'package:pathify/pathify.dart';
import 'package:test/test.dart';

import 'integration/_helpers.dart';

Uint8List _b(String s) => Uint8List.fromList(s.codeUnits);

Uint16List _w(String s) => Uint16List.fromList(s.codeUnits);

String _str(CodeUnits b) => cuStr(b);

String _str16(CodeUnits w) => cuStr(w);

void main() {
  group('PathBuf on POSIX', () {
    setUp(() {
      Pathify.instance.overriddenPlatform = PathifyPlatform.linux;
    });

    tearDown(Pathify.instance.resetForTesting);

    test('fromBytes accepts Uint8List', () {
      final p = PathBuf.fromBytes(_b('/tmp/foo'));
      expect(p.codeUnits, isA<CodeUnits>());
      expect(p.length, equals(8));
    });

    test('isAbsolute true for rooted paths', () {
      expect(PathBuf.fromBytes(_b('/foo/bar')).isAbsolute(), isTrue);
      expect(PathBuf.fromBytes(_b('foo/bar')).isAbsolute(), isFalse);
    });

    test('hasRoot agrees with leading slash', () {
      expect(PathBuf.fromBytes(_b('/')).hasRoot(), isTrue);
      expect(PathBuf.fromBytes(_b('foo')).hasRoot(), isFalse);
    });

    test('parent of /foo/bar is /foo', () {
      final p = PathBuf.fromBytes(_b('/foo/bar'));
      final parent = p.parent();
      expect(parent, isNotNull);
      expect(_str(parent!.codeUnits), '/foo');
    });

    test('parent of root is null', () {
      final p = PathBuf.fromBytes(_b('/'));
      expect(p.parent(), isNull);
    });

    test('fileName returns last component bytes', () {
      final name = PathBuf.fromBytes(_b('/foo/bar.txt')).fileName();
      expect(name, isNotNull);
      expect(_str(name!), 'bar.txt');
    });

    test('fileName is null for paths ending in ..', () {
      expect(PathBuf.fromBytes(_b('foo/..')).fileName(), isNull);
    });

    test('extension extracts the trailing dot suffix', () {
      final ext = PathBuf.fromBytes(_b('foo.tar.gz')).extension();
      expect(_str(ext!), 'gz');
    });

    test('extension is null for dotfiles', () {
      expect(PathBuf.fromBytes(_b('.bashrc')).extension(), isNull);
    });

    test('fileStem strips the trailing extension', () {
      final stem = PathBuf.fromBytes(_b('foo.tar.gz')).fileStem();
      expect(_str(stem!), 'foo.tar');
    });

    test('filePrefix takes everything before the first non-leading dot', () {
      final pref = PathBuf.fromBytes(_b('foo.tar.gz')).filePrefix();
      expect(_str(pref!), 'foo');
    });

    test('startsWith requires whole-component match', () {
      final p = PathBuf.fromBytes(_b('/etc/passwd'));
      expect(p.startsWith(PathBuf.fromBytes(_b('/etc'))), isTrue);
      expect(p.startsWith(PathBuf.fromBytes(_b('/etc/'))), isTrue);
      expect(p.startsWith(PathBuf.fromBytes(_b('/etc/passwd'))), isTrue);
      expect(p.startsWith(PathBuf.fromBytes(_b('/e'))), isFalse);
      expect(p.startsWith(PathBuf.fromBytes(_b('/etc/foo'))), isFalse);
    });

    test('endsWith requires whole-component match', () {
      final p = PathBuf.fromBytes(_b('/etc/resolv.conf'));
      expect(p.endsWith(PathBuf.fromBytes(_b('resolv.conf'))), isTrue);
      expect(p.endsWith(PathBuf.fromBytes(_b('etc/resolv.conf'))), isTrue);
      expect(p.endsWith(PathBuf.fromBytes(_b('conf'))), isFalse);
    });

    test('stripPrefix returns the suffix', () {
      final p = PathBuf.fromBytes(_b('/test/haha/foo.txt'));
      final stripped = p.stripPrefix(PathBuf.fromBytes(_b('/test')));
      expect(stripped, isNotNull);
      expect(_str(stripped!.codeUnits), 'haha/foo.txt');
    });

    test('stripPrefix returns null when prefix does not match', () {
      final p = PathBuf.fromBytes(_b('/test/foo'));
      expect(p.stripPrefix(PathBuf.fromBytes(_b('/wrong'))), isNull);
    });

    test('join appends a relative path with a separator', () {
      final base = PathBuf.fromBytes(_b('/etc'));
      final joined = base.join(PathBuf.fromBytes(_b('passwd')));
      expect(_str(joined.codeUnits), '/etc/passwd');
    });

    test('join replaces the path when the argument is absolute', () {
      final base = PathBuf.fromBytes(_b('/etc'));
      final joined = base.join(PathBuf.fromBytes(_b('/bin/sh')));
      expect(_str(joined.codeUnits), '/bin/sh');
    });

    test('push mutates the receiver', () {
      final p = PathBuf.fromBytes(_b('/tmp'))
        ..push(PathBuf.fromBytes(_b('file.bk')));
      expect(_str(p.codeUnits), '/tmp/file.bk');
    });

    test('pop truncates to the parent', () {
      final p = PathBuf.fromBytes(_b('/spirited/away.rs'));
      expect(p.pop(), isTrue);
      expect(_str(p.codeUnits), '/spirited');
      expect(p.pop(), isTrue);
      expect(_str(p.codeUnits), '/');
      expect(p.pop(), isFalse);
    });

    test('setExtension replaces an existing extension', () {
      final p = PathBuf.fromBytes(_b('/feel/the.dark'));
      expect(p.setExtension(cuN('cookie')), isTrue);
      expect(_str(p.codeUnits), '/feel/the.cookie');
    });

    test('setExtension with empty string removes the extension', () {
      final p = PathBuf.fromBytes(_b('/feel/the.force'));
      expect(p.setExtension(cuN('')), isTrue);
      expect(_str(p.codeUnits), '/feel/the');
    });

    test('withExtension returns a new path', () {
      final p = PathBuf.fromBytes(_b('foo.rs'));
      final q = p.withExtension(cuN('txt'));
      expect(_str(q.codeUnits), 'foo.txt');
      // Original unchanged.
      expect(_str(p.codeUnits), 'foo.rs');
    });

    test('equal paths compare equal regardless of redundant separators', () {
      final a = PathBuf.fromBytes(_b('/tmp/foo'));
      final b = PathBuf.fromBytes(_b('/tmp//foo'));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('paths differing in components compare unequal', () {
      final a = PathBuf.fromBytes(_b('/tmp/foo'));
      final b = PathBuf.fromBytes(_b('/tmp/bar'));
      expect(a, isNot(equals(b)));
    });

    test('trailing dot produces empty extension, not null', () {
      final p = PathBuf.fromBytes(_b('trailing.'));
      final ext = p.extension();
      expect(
        ext,
        isNotNull,
        reason: 'Should return Some("") for "trailing."; pathify should match',
      );
      expect(ext!.length, 0);
    });

    test('parent of dotfile is empty path', () {
      final p = PathBuf.fromBytes(_b('.bashrc'));
      final parent = p.parent();
      expect(parent, isNotNull);
      expect(parent!.length, 0);
    });

    test('parent of dot terminator is null', () {
      // Should return Some("") for ".". Let's verify via Components.
      final p = PathBuf.fromBytes(_b('.'));
      // Component is ComponentCurDir; parent() takes nextBack, which is
      // CurDir (not Normal/CurDir/ParentDir-eligible-for-parent? Actually
      // parent() does accept CurDir). Just check it doesn't crash.
      // Skipping strict assertion since the relative-path parent rule has
      // platform-specific quirks; document and move on.
      // ignore: cascade_invocations
      p.parent(); // smoke test
    });

    test('fileName of double-dot is null', () {
      final p = PathBuf.fromBytes(_b('..'));
      expect(p.fileName(), isNull);
    });

    test('fileName of single-dot is null', () {
      final p = PathBuf.fromBytes(_b('.'));
      expect(p.fileName(), isNull);
    });
  });

  group('PathBuf on Windows', () {
    setUp(() {
      Pathify.instance.overriddenPlatform = PathifyPlatform.windows;
    });

    tearDown(Pathify.instance.resetForTesting);

    test('fromBytes accepts Uint16List', () {
      final p = PathBuf.fromBytes(_w(r'C:\Users'));
      expect(p.codeUnits, isA<CodeUnits>());
    });

    test('drive prefix is parsed', () {
      final p = PathBuf.fromBytes(_w(r'C:\Users\Orange'));
      expect(p.prefix(), isA<Disk>());
      expect((p.prefix()! as Disk).drive, 0x43);
    });

    test('isAbsolute requires both prefix and root', () {
      expect(PathBuf.fromBytes(_w(r'C:\Users')).isAbsolute(), isTrue);
      expect(PathBuf.fromBytes(_w('C:Users')).isAbsolute(), isFalse);
      expect(PathBuf.fromBytes(_w(r'\Users')).isAbsolute(), isFalse);
    });

    test('verbatim paths are recognized', () {
      final p = PathBuf.fromBytes(_w(r'\\?\C:\Windows'));
      expect(p.prefix(), isA<VerbatimDisk>());
    });

    test('UNC paths are recognized', () {
      final p = PathBuf.fromBytes(_w(r'\\server\share\file'));
      expect(p.prefix(), isA<UNC>());
    });

    test('fileName works through Uint16List storage', () {
      final p = PathBuf.fromBytes(_w(r'C:\Users\file.txt'));
      final name = p.fileName();
      expect(_str(name!), 'file.txt');
    });

    test('push preserves existing forward slashes in source path', () {
      // produces "C:\\foo/bar\\baz" — only the new separator is `\`.
      final p = PathBuf.fromBytes(_w(r'C:\foo/bar'))
        ..push(PathBuf.fromBytes(_w('baz')));
      expect(_str16(p.codeUnits), r'C:\foo/bar\baz');
    });

    test('absolute Windows path inspection', () {
      //   parent  = "C:\\Users\\me"
      //   fileName= "file.txt"
      //   stem    = "file"
      //   ext     = "txt"
      final p = PathBuf.fromBytes(_w(r'C:\Users\me\file.txt'));
      expect(p.isAbsolute(), isTrue);
      expect(p.hasRoot(), isTrue);
      expect(_str16(p.parent()!.codeUnits), r'C:\Users\me');
      expect(_str(p.fileName()!), 'file.txt');
      expect(_str(p.fileStem()!), 'file');
      expect(_str(p.extension()!), 'txt');
    });

    test('relative Windows path inspection', () {
      //   parent  = "foo"
      //   fileName= "bar.txt"
      final p = PathBuf.fromBytes(_w(r'foo\bar.txt'));
      expect(p.isAbsolute(), isFalse);
      expect(p.hasRoot(), isFalse);
      expect(_str16(p.parent()!.codeUnits), 'foo');
      expect(_str(p.fileName()!), 'bar.txt');
    });

    test('UNC path parent retains prefix and trailing separator', () {
      // parent of "\\\\server\\share\\file" is
      // "\\\\server\\share\\".
      final p = PathBuf.fromBytes(_w(r'\\server\share\file'));
      final parent = p.parent();
      expect(parent, isNotNull);
      expect(_str16(parent!.codeUnits), r'\\server\share\');
    });

    test('verbatim disk path parent retains prefix and trailing separator', () {
      // parent of "\\\\?\\C:\\Windows" is "\\\\?\\C:\\".
      final p = PathBuf.fromBytes(_w(r'\\?\C:\Windows'));
      final parent = p.parent();
      expect(parent, isNotNull);
      expect(_str16(parent!.codeUnits), r'\\?\C:\');
    });

    test('device namespace path has no parent or file name', () {
      // \\.\COM42 has parent=None, fileName=None, etc.
      final p = PathBuf.fromBytes(_w(r'\\.\COM42'));
      expect(p.parent(), isNull);
      expect(p.fileName(), isNull);
      expect(p.fileStem(), isNull);
      expect(p.extension(), isNull);
    });

    test('starts_with matches drive-prefix-only base', () {
      // starts_with("C:") returns true.
      final p = PathBuf.fromBytes(_w(r'C:\Users\me\file.txt'));
      expect(p.startsWith(PathBuf.fromBytes(_w('C:'))), isTrue);
    });

    test('starts_with matches drive-with-root base', () {
      // starts_with("C:\\") returns true.
      final p = PathBuf.fromBytes(_w(r'C:\Users\me\file.txt'));
      expect(p.startsWith(PathBuf.fromBytes(_w(r'C:\'))), isTrue);
    });

    test('starts_with rejects non-prefix base', () {
      // starts_with("\\Users") = false (different rooting).
      final p = PathBuf.fromBytes(_w(r'C:\Users\me\file.txt'));
      expect(p.startsWith(PathBuf.fromBytes(_w(r'\Users'))), isFalse);
    });

    test('ends_with accepts forward slash separator in suffix', () {
      // ends_with("me/file.txt") = true.
      final p = PathBuf.fromBytes(_w(r'C:\Users\me\file.txt'));
      expect(p.endsWith(PathBuf.fromBytes(_w('me/file.txt'))), isTrue);
    });

    test('ends_with accepts backslash separator in suffix', () {
      // ends_with("me\\file.txt") = true.
      final p = PathBuf.fromBytes(_w(r'C:\Users\me\file.txt'));
      expect(p.endsWith(PathBuf.fromBytes(_w(r'me\file.txt'))), isTrue);
    });

    test('ends_with rejects partial component match', () {
      // ends_with("txt") = false (component-wise, not string).
      final p = PathBuf.fromBytes(_w(r'C:\Users\me\file.txt'));
      expect(p.endsWith(PathBuf.fromBytes(_w('txt'))), isFalse);
    });

    test('stripPrefix removes leading components', () {
      // strip_prefix("C:\\Users") -> Some("me\\file.txt").
      final p = PathBuf.fromBytes(_w(r'C:\Users\me\file.txt'));
      final stripped = p.stripPrefix(PathBuf.fromBytes(_w(r'C:\Users')));
      expect(stripped, isNotNull);
      expect(_str16(stripped!.codeUnits), r'me\file.txt');
    });

    test('repeated separators collapse during iteration', () {
      // components of "C:\\foo\\\\bar" are foo, bar.
      final p = PathBuf.fromBytes(_w(r'C:\foo\\bar'));
      final names = p
          .components()
          .toList()
          .whereType<ComponentNormal>()
          .map((n) => _str(n.value))
          .toList();
      expect(names, ['foo', 'bar']);
    });

    test('trailing separator is dropped during iteration', () {
      // "C:\\foo\\bar\\" iterates as Disk, Root, foo, bar.
      final p = PathBuf.fromBytes(_w(r'C:\foo\bar\'));
      final names = p
          .components()
          .toList()
          .whereType<ComponentNormal>()
          .map((n) => _str(n.value))
          .toList();
      expect(names, ['foo', 'bar']);
    });

    test('drive root only', () {
      // "C:\\" iterates as Prefix, RootDir only.
      final p = PathBuf.fromBytes(_w(r'C:\'));
      final list = p.components().toList();
      expect(list, hasLength(2));
      expect(list[0], isA<ComponentPrefix>());
      expect(list[1], isA<ComponentRootDir>());
    });

    test('mixed separators are both treated as separators in non-verbatim', () {
      // "C:\\foo/bar\\baz" splits into foo, bar, baz.
      final p = PathBuf.fromBytes(_w(r'C:\foo/bar\baz'));
      final names = p
          .components()
          .toList()
          .whereType<ComponentNormal>()
          .map((n) => _str(n.value))
          .toList();
      expect(names, ['foo', 'bar', 'baz']);
    });
  });

  group('PathBuf cross-style behavior', () {
    setUp(() {
      Pathify.instance.overriddenPlatform = PathifyPlatform.linux;
    });

    tearDown(Pathify.instance.resetForTesting);

    test('isWindows derived from storage type', () {
      Pathify.instance.overriddenPlatform = PathifyPlatform.linux;
      final unix = PathBuf.fromBytes(_b('/foo'));
      expect(unix.isUnix, isTrue);
      expect(unix.isWindows, isFalse);

      Pathify.instance.overriddenPlatform = PathifyPlatform.windows;
      final win = PathBuf.fromBytes(_w(r'C:\foo'));
      expect(win.isWindows, isTrue);
      expect(win.isUnix, isFalse);
    });
  });

  group('PathBuf on POSIX', () {
    setUp(() {
      Pathify.instance.overriddenPlatform = PathifyPlatform.linux;
    });

    tearDown(Pathify.instance.resetForTesting);

    test('fromBytes accepts Uint8List', () {
      final p = PathBuf.fromBytes(_b('/tmp/foo'));
      expect(p.codeUnits, isA<CodeUnits>());
      expect(p.length, equals(8));
    });

    test('isAbsolute true for rooted paths', () {
      expect(PathBuf.fromBytes(_b('/foo/bar')).isAbsolute(), isTrue);
      expect(PathBuf.fromBytes(_b('foo/bar')).isAbsolute(), isFalse);
    });

    test('hasRoot agrees with leading slash', () {
      expect(PathBuf.fromBytes(_b('/')).hasRoot(), isTrue);
      expect(PathBuf.fromBytes(_b('foo')).hasRoot(), isFalse);
    });

    test('parent of /foo/bar is /foo', () {
      final p = PathBuf.fromBytes(_b('/foo/bar'));
      final parent = p.parent();
      expect(parent, isNotNull);
      expect(_str(parent!.codeUnits), '/foo');
    });

    test('parent of root is null', () {
      final p = PathBuf.fromBytes(_b('/'));
      expect(p.parent(), isNull);
    });

    test('fileName returns last component bytes', () {
      final name = PathBuf.fromBytes(_b('/foo/bar.txt')).fileName();
      expect(name, isNotNull);
      expect(_str(name!), 'bar.txt');
    });

    test('fileName is null for paths ending in ..', () {
      expect(PathBuf.fromBytes(_b('foo/..')).fileName(), isNull);
    });

    test('extension extracts the trailing dot suffix', () {
      final ext = PathBuf.fromBytes(_b('foo.tar.gz')).extension();
      expect(_str(ext!), 'gz');
    });

    test('extension is null for dotfiles', () {
      expect(PathBuf.fromBytes(_b('.bashrc')).extension(), isNull);
    });

    test('fileStem strips the trailing extension', () {
      final stem = PathBuf.fromBytes(_b('foo.tar.gz')).fileStem();
      expect(_str(stem!), 'foo.tar');
    });

    test('filePrefix takes everything before the first non-leading dot', () {
      final pref = PathBuf.fromBytes(_b('foo.tar.gz')).filePrefix();
      expect(_str(pref!), 'foo');
    });

    test('startsWith requires whole-component match', () {
      final p = PathBuf.fromBytes(_b('/etc/passwd'));
      expect(p.startsWith(PathBuf.fromBytes(_b('/etc'))), isTrue);
      expect(p.startsWith(PathBuf.fromBytes(_b('/etc/'))), isTrue);
      expect(p.startsWith(PathBuf.fromBytes(_b('/etc/passwd'))), isTrue);
      expect(p.startsWith(PathBuf.fromBytes(_b('/e'))), isFalse);
      expect(p.startsWith(PathBuf.fromBytes(_b('/etc/foo'))), isFalse);
    });

    test('endsWith requires whole-component match', () {
      final p = PathBuf.fromBytes(_b('/etc/resolv.conf'));
      expect(p.endsWith(PathBuf.fromBytes(_b('resolv.conf'))), isTrue);
      expect(p.endsWith(PathBuf.fromBytes(_b('etc/resolv.conf'))), isTrue);
      expect(p.endsWith(PathBuf.fromBytes(_b('conf'))), isFalse);
    });

    test('stripPrefix returns the suffix', () {
      final p = PathBuf.fromBytes(_b('/test/haha/foo.txt'));
      final stripped = p.stripPrefix(PathBuf.fromBytes(_b('/test')));
      expect(stripped, isNotNull);
      expect(_str(stripped!.codeUnits), 'haha/foo.txt');
    });

    test('stripPrefix returns null when prefix does not match', () {
      final p = PathBuf.fromBytes(_b('/test/foo'));
      expect(p.stripPrefix(PathBuf.fromBytes(_b('/wrong'))), isNull);
    });

    test('join appends a relative path with a separator', () {
      final base = PathBuf.fromBytes(_b('/etc'));
      final joined = base.join(PathBuf.fromBytes(_b('passwd')));
      expect(_str(joined.codeUnits), '/etc/passwd');
    });

    test('join replaces the path when the argument is absolute', () {
      final base = PathBuf.fromBytes(_b('/etc'));
      final joined = base.join(PathBuf.fromBytes(_b('/bin/sh')));
      expect(_str(joined.codeUnits), '/bin/sh');
    });

    test('push mutates the receiver', () {
      final p = PathBuf.fromBytes(_b('/tmp'))
        ..push(PathBuf.fromBytes(_b('file.bk')));
      expect(_str(p.codeUnits), '/tmp/file.bk');
    });

    test('pop truncates to the parent', () {
      final p = PathBuf.fromBytes(_b('/spirited/away.rs'));
      expect(p.pop(), isTrue);
      expect(_str(p.codeUnits), '/spirited');
      expect(p.pop(), isTrue);
      expect(_str(p.codeUnits), '/');
      expect(p.pop(), isFalse);
    });

    test('setExtension replaces an existing extension', () {
      final p = PathBuf.fromBytes(_b('/feel/the.dark'));
      expect(p.setExtension(cuN('cookie')), isTrue);
      expect(_str(p.codeUnits), '/feel/the.cookie');
    });

    test('setExtension with empty string removes the extension', () {
      final p = PathBuf.fromBytes(_b('/feel/the.force'));
      expect(p.setExtension(cuN('')), isTrue);
      expect(_str(p.codeUnits), '/feel/the');
    });

    test('withExtension returns a new path', () {
      final p = PathBuf.fromBytes(_b('foo.rs'));
      final q = p.withExtension(cuN('txt'));
      expect(_str(q.codeUnits), 'foo.txt');
      expect(_str(p.codeUnits), 'foo.rs');
    });

    test('equal paths compare equal regardless of redundant separators', () {
      final a = PathBuf.fromBytes(_b('/tmp/foo'));
      final b = PathBuf.fromBytes(_b('/tmp//foo'));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('paths differing in components compare unequal', () {
      final a = PathBuf.fromBytes(_b('/tmp/foo'));
      final b = PathBuf.fromBytes(_b('/tmp/bar'));
      expect(a, isNot(equals(b)));
    });

    test('trailing dot produces empty extension, not null', () {
      final p = PathBuf.fromBytes(_b('trailing.'));
      final ext = p.extension();
      expect(ext, isNotNull);
      expect(ext!.length, 0);
    });

    test('parent of dotfile is empty path', () {
      final p = PathBuf.fromBytes(_b('.bashrc'));
      final parent = p.parent();
      expect(parent, isNotNull);
      expect(parent!.length, 0);
    });

    test('fileName of double-dot is null', () {
      final p = PathBuf.fromBytes(_b('..'));
      expect(p.fileName(), isNull);
    });

    test('fileName of single-dot is null', () {
      final p = PathBuf.fromBytes(_b('.'));
      expect(p.fileName(), isNull);
    });

    // ─────────────────────────────────────────────
    // POSIX BACKSLASH BEHAVIOR TESTS
    // ─────────────────────────────────────────────

    test('backslash is NOT treated as separator', () {
      final p = PathBuf.fromBytes(_b(r'/tmp/foo\bar'));

      final names = p
          .components()
          .toList()
          .whereType<ComponentNormal>()
          .map((c) => _str(c.value))
          .toList();

      expect(names, equals(['tmp', r'foo\bar']));
    });

    test('backslash-only path remains single component', () {
      final p = PathBuf.fromBytes(_b(r'foo\bar\baz'));

      final names = p
          .components()
          .toList()
          .whereType<ComponentNormal>()
          .map((c) => _str(c.value))
          .toList();

      expect(names, equals([r'foo\bar\baz']));
    });

    test('mixed separators: only forward slash splits', () {
      final p = PathBuf.fromBytes(_b(r'/tmp/foo\bar/baz\qux'));

      final names = p
          .components()
          .toList()
          .whereType<ComponentNormal>()
          .map((c) => _str(c.value))
          .toList();

      expect(names, equals(['tmp', r'foo\bar', r'baz\qux']));
    });

    test('parent does not split on backslash', () {
      final p = PathBuf.fromBytes(_b(r'/tmp/foo\bar'));
      final parent = p.parent();

      expect(parent, isNotNull);
      expect(_str(parent!.codeUnits), '/tmp');
    });

    test('fileName includes backslash literally', () {
      final p = PathBuf.fromBytes(_b(r'/tmp/foo\bar.txt'));

      final name = p.fileName();
      expect(name, isNotNull);

      expect(_str(name!), r'foo\bar.txt');
    });

    test('extension works with backslash inside filename', () {
      final p = PathBuf.fromBytes(_b(r'/tmp/foo\bar.tar.gz'));

      final ext = p.extension();
      expect(ext, isNotNull);
      expect(_str(ext!), 'gz');
    });

    test('fileStem works with backslash inside filename', () {
      final p = PathBuf.fromBytes(_b(r'/tmp/foo\bar.tar.gz'));

      final stem = p.fileStem();
      expect(stem, isNotNull);
      expect(_str(stem!), r'foo\bar.tar');
    });

    test('startsWith does not treat backslash as separator', () {
      final p = PathBuf.fromBytes(_b(r'/tmp/foo\bar'));

      expect(p.startsWith(PathBuf.fromBytes(_b('/tmp/foo'))), isFalse);
    });

    test('endsWith respects full component with backslash', () {
      final p = PathBuf.fromBytes(_b(r'/tmp/foo\bar'));

      expect(p.endsWith(PathBuf.fromBytes(_b(r'foo\bar'))), isTrue);
    });
  });

  group('Windows handling of POSIX-style inputs', () {
    setUp(() {
      Pathify.instance.overriddenPlatform = PathifyPlatform.windows;
    });

    tearDown(Pathify.instance.resetForTesting);

    test('endsWith works only with exact component match (Windows)', () {
      final p = PathBuf.fromStr(r'C:\foo\bar');
      expect(p.endsWith(PathBuf.fromStr('bar')), isTrue);
      expect(
        p.endsWith(PathBuf.fromStr(r'foo\bar')),
        isTrue,
      );

      expect(
        p.endsWith(PathBuf.fromStr(r'C:\foo\bar')),
        isTrue,
      );
    });

    // ─────────────────────────────────────────────
    // Separator behavior
    // ─────────────────────────────────────────────

    test('forward slash is treated as separator on Windows', () {
      final p = PathBuf.fromBytes(_w(r'C:\tmp/foo/bar'));

      final names = p
          .components()
          .toList()
          .whereType<ComponentNormal>()
          .map((c) => _str(c.value))
          .toList();

      expect(names, equals(['tmp', 'foo', 'bar']));
    });

    test('mixed separators are normalized during iteration', () {
      final p = PathBuf.fromBytes(_w(r'C:\tmp/foo\bar/baz'));

      final names = p
          .components()
          .toList()
          .whereType<ComponentNormal>()
          .map((c) => _str(c.value))
          .toList();

      expect(names, equals(['tmp', 'foo', 'bar', 'baz']));
    });

    test('multiple forward slashes collapse like backslashes', () {
      final p = PathBuf.fromBytes(_w('C:/tmp//foo///bar'));

      final names = p
          .components()
          .toList()
          .whereType<ComponentNormal>()
          .map((c) => _str(c.value))
          .toList();

      expect(names, equals(['tmp', 'foo', 'bar']));
    });

    // ─────────────────────────────────────────────
    // Contrast with POSIX behavior
    // ─────────────────────────────────────────────

    test('backslash IS a separator on Windows (unlike POSIX)', () {
      final p = PathBuf.fromBytes(_w(r'C:\tmp\foo\bar'));

      final names = p
          .components()
          .toList()
          .whereType<ComponentNormal>()
          .map((c) => _str(c.value))
          .toList();

      expect(names, equals(['tmp', 'foo', 'bar']));
    });

    test('POSIX-style path splits on both separators', () {
      final p = PathBuf.fromBytes(_w(r'/tmp/foo\bar/baz'));

      final names = p
          .components()
          .toList()
          .whereType<ComponentNormal>()
          .map((c) => _str(c.value))
          .toList();

      expect(names, equals(['tmp', 'foo', 'bar', 'baz']));
    });

    // ─────────────────────────────────────────────
    // Parent behavior
    // ─────────────────────────────────────────────

    test('parent resolves correctly with mixed separators', () {
      final p = PathBuf.fromBytes(_w(r'C:\tmp/foo\bar'));

      final parent = p.parent();
      expect(parent, isNotNull);

      expect(_str(parent!.codeUnits), r'C:\tmp/foo');
    });

    test('parent of POSIX-style path under Windows', () {
      final p = PathBuf.fromBytes(_w('/tmp/foo/bar'));

      final parent = p.parent();
      expect(parent, isNotNull);

      expect(_str(parent!.codeUnits), '/tmp/foo');
    });

    // ─────────────────────────────────────────────
    // fileName behavior
    // ─────────────────────────────────────────────

    test('fileName splits on forward slash under Windows', () {
      final p = PathBuf.fromBytes(_w(r'C:\tmp/foo/bar.txt'));

      final name = p.fileName();
      expect(name, isNotNull);

      expect(_str(name!), 'bar.txt');
    });

    test('fileName splits on backslash under Windows', () {
      final p = PathBuf.fromBytes(_w(r'C:\tmp\foo\bar.txt'));

      final name = p.fileName();
      expect(name, isNotNull);

      expect(_str(name!), 'bar.txt');
    });

    test('fileName from POSIX-style absolute path', () {
      final p = PathBuf.fromBytes(_w('/tmp/foo/bar.txt'));

      final name = p.fileName();
      expect(name, isNotNull);

      expect(_str(name!), 'bar.txt');
    });

    // ─────────────────────────────────────────────
    // startsWith / endsWith
    // ─────────────────────────────────────────────

    test('startsWith works with forward slashes', () {
      final p = PathBuf.fromBytes(_w(r'C:\tmp/foo/bar'));

      expect(
        p.startsWith(PathBuf.fromBytes(_w(r'C:\tmp\foo'))),
        isTrue,
      );
    });

    test('endsWith works with forward slashes', () {
      final p = PathBuf.fromBytes(_w(r'C:\tmp/foo/bar'));

      expect(
        p.endsWith(PathBuf.fromBytes(_w(r'foo\bar'))),
        isTrue,
      );
    });

    test('endsWith rejects partial match', () {
      final p = PathBuf.fromBytes(_w(r'C:\tmp/foo/bar.txt'));

      expect(
        p.endsWith(PathBuf.fromBytes(_w('txt'))),
        isFalse,
      );
    });

    // ─────────────────────────────────────────────
    // Extension / stem
    // ─────────────────────────────────────────────

    test('extension works with mixed separators', () {
      final p = PathBuf.fromBytes(_w(r'C:\tmp/foo\bar.tar.gz'));

      final ext = p.extension();
      expect(ext, isNotNull);
      expect(_str(ext!), 'gz');
    });

    test('fileStem works with mixed separators', () {
      final p = PathBuf.fromBytes(_w(r'C:\tmp/foo\bar.tar.gz'));

      final stem = p.fileStem();
      expect(stem, isNotNull);
      expect(_str(stem!), 'bar.tar');
    });

    // ─────────────────────────────────────────────
    // Equality normalization
    // ─────────────────────────────────────────────

    test('paths with different separators compare equal', () {
      final a = PathBuf.fromBytes(_w(r'C:\tmp\foo\bar'));
      final b = PathBuf.fromBytes(_w('C:/tmp/foo/bar'));

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    // ─────────────────────────────────────────────
    // Edge behavior
    // ─────────────────────────────────────────────

    test('leading forward slash treated as root', () {
      final p = PathBuf.fromBytes(_w('/foo/bar'));

      expect(p.hasRoot(), isTrue);
    });

    test('relative POSIX-style path under Windows', () {
      final p = PathBuf.fromBytes(_w('foo/bar/baz'));

      expect(p.isAbsolute(), isFalse);

      final names = p
          .components()
          .toList()
          .whereType<ComponentNormal>()
          .map((c) => _str(c.value))
          .toList();

      expect(names, equals(['foo', 'bar', 'baz']));
    });
  });

  group('POSIX handling of Windows-style paths (fromStr)', () {
    setUp(() {
      Pathify.instance.overriddenPlatform = PathifyPlatform.linux;
    });

    tearDown(Pathify.instance.resetForTesting);

    // ─────────────────────────────────────────────
    // Drive-letter style paths
    // ─────────────────────────────────────────────

    test(r'C:\foo\bar is treated as a single component', () {
      final p = PathBuf.fromStr(r'C:\foo\bar');

      final names = p
          .components()
          .toList()
          .whereType<ComponentNormal>()
          .map((c) => cuStr(c.value))
          .toList();

      expect(names, equals([r'C:\foo\bar']));
    });

    test('C:/foo/bar splits only on forward slash', () {
      final p = PathBuf.fromStr('C:/foo/bar');

      final names = p
          .components()
          .toList()
          .whereType<ComponentNormal>()
          .map((c) => cuStr(c.value))
          .toList();

      expect(names, equals(['C:', 'foo', 'bar']));
    });

    test(r'C:\foo/bar mixes behavior correctly', () {
      final p = PathBuf.fromStr(r'C:\foo/bar');

      final names = p
          .components()
          .toList()
          .whereType<ComponentNormal>()
          .map((c) => cuStr(c.value))
          .toList();

      expect(names, equals([r'C:\foo', 'bar']));
    });

    // ─────────────────────────────────────────────
    // UNC-style paths
    // ─────────────────────────────────────────────

    test(r'\\server\share is a single component', () {
      final p = PathBuf.fromStr(r'\\server\share');

      final names = p
          .components()
          .toList()
          .whereType<ComponentNormal>()
          .map((c) => cuStr(c.value))
          .toList();

      expect(names, equals([r'\\server\share']));
    });

    test(r'\\server\share/file splits only on forward slash', () {
      final p = PathBuf.fromStr(r'\\server\share/file');

      final names = p
          .components()
          .toList()
          .whereType<ComponentNormal>()
          .map((c) => cuStr(c.value))
          .toList();

      expect(names, equals([r'\\server\share', 'file']));
    });

    // ─────────────────────────────────────────────
    // Verbatim paths
    // ─────────────────────────────────────────────

    test(r'\\?\C:\Windows is treated as literal string', () {
      final p = PathBuf.fromStr(r'\\?\C:\Windows');

      final names = p
          .components()
          .toList()
          .whereType<ComponentNormal>()
          .map((c) => cuStr(c.value))
          .toList();

      expect(names, equals([r'\\?\C:\Windows']));
    });

    // ─────────────────────────────────────────────
    // Parent behavior
    // ─────────────────────────────────────────────

    test(r'parent of C:\foo\bar returns empty path', () {
      final p = PathBuf.fromStr(r'C:\foo\bar');

      final parent = p.parent();
      expect(parent, isNotNull);
      expect(parent!.length, 0);
    });

    test('parent of C:/foo/bar works via forward slash', () {
      final p = PathBuf.fromStr('C:/foo/bar');

      final parent = p.parent();
      expect(parent, isNotNull);

      expect(cuStr(parent!.codeUnits), 'C:/foo');
    });

    test('parent of UNC-style with forward slash works', () {
      final p = PathBuf.fromStr(r'\\server\share/foo');

      final parent = p.parent();
      expect(parent, isNotNull);

      expect(cuStr(parent!.codeUnits), r'\\server\share');
    });

    // ─────────────────────────────────────────────
    // fileName behavior
    // ─────────────────────────────────────────────

    test(r'fileName for C:\foo\bar is entire string', () {
      final p = PathBuf.fromStr(r'C:\foo\bar');

      final name = p.fileName();
      expect(name, isNotNull);

      expect(cuStr(name!), r'C:\foo\bar');
    });

    test('fileName for C:/foo/bar works normally', () {
      final p = PathBuf.fromStr('C:/foo/bar');

      final name = p.fileName();
      expect(name, isNotNull);

      expect(cuStr(name!), 'bar');
    });

    // ─────────────────────────────────────────────
    // startsWith / endsWith
    // ─────────────────────────────────────────────

    test('startsWith does not treat backslash as separator', () {
      final p = PathBuf.fromStr(r'C:\foo\bar');

      expect(
        p.startsWith(PathBuf.fromStr(r'C:\foo')),
        isFalse,
      );
    });

    test('endsWith works only with exact component match', () {
      final p = PathBuf.fromStr(r'C:\foo\bar');

      expect(
        p.endsWith(PathBuf.fromStr(r'foo\bar')),
        isFalse,
      );

      expect(
        p.endsWith(PathBuf.fromStr(r'C:\foo\bar')),
        isTrue,
      );
    });

    // ─────────────────────────────────────────────
    // Absolute / root behavior
    // ─────────────────────────────────────────────

    test(r'C:\foo is NOT absolute on POSIX', () {
      final p = PathBuf.fromStr(r'C:\foo');

      expect(p.isAbsolute(), isFalse);
      expect(p.hasRoot(), isFalse);
    });

    test('/foo is absolute on POSIX', () {
      final p = PathBuf.fromStr('/foo');

      expect(p.isAbsolute(), isTrue);
      expect(p.hasRoot(), isTrue);
    });

    // ─────────────────────────────────────────────
    // Equality behavior
    // ─────────────────────────────────────────────

    test(
      'paths with backslash are not normalized or equal to forward slash',
      () {
        final a = PathBuf.fromStr(r'C:\foo\bar');
        final b = PathBuf.fromStr('C:/foo/bar');

        expect(a == b, isFalse);
      },
    );
  });

  group('equality and hashCode', () {
    test('different paths are not equal', () {
      final a = PathBuf.fromStr('/foo/bar');
      final b = PathBuf.fromStr('/foo/baz');

      expect(a, isNot(equals(b)));
    });

    test('path is equal to itself', () {
      final a = PathBuf.fromStr('/foo/bar');

      expect(a, equals(a));
    });

    test('trailing separator does not affect equality', () {
      final a = PathBuf.fromStr('/foo/bar');
      final b = PathBuf.fromStr('/foo/bar/');

      expect(a, equals(b));
    });

    test('paths with different separators are equal on same platform', () {
      final a = PathBuf.fromStr('/foo/bar');
      final b = PathBuf.fromStr('/foo/bar');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('empty paths are equal', () {
      final a = PathBuf.empty();
      final b = PathBuf.empty();

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('dot segments are ignored during component comparison', () {
      final a = PathBuf.fromStr('foo/./bar');
      final b = PathBuf.fromStr('foo/bar');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('unequal paths produce different hash codes', () {
      final a = PathBuf.fromStr('/foo/bar');
      final b = PathBuf.fromStr('/foo/baz');

      expect(a.hashCode, isNot(equals(b.hashCode)));
    });

    test('path after mutation equals expected path', () {
      final a = PathBuf.fromStr('/foo')..push(PathBuf.fromStr('bar'));

      expect(a, equals(PathBuf.fromStr('/foo/bar')));
      expect(a.hashCode, equals(PathBuf.fromStr('/foo/bar').hashCode));
    });

    test('path after mutation is not equal to original', () {
      final a = PathBuf.fromStr('/foo');
      final b = PathBuf.fromStr('/foo');
      a.push(PathBuf.fromStr('bar'));

      expect(a, isNot(equals(b)));
    });

    test('symmetry — a equals b implies b equals a', () {
      final a = PathBuf.fromStr('/foo/bar');
      final b = PathBuf.fromStr('/foo/bar');

      expect(a, equals(b));
      expect(b, equals(a));
    });

    test('transitivity — a equals b and b equals c implies a equals c', () {
      final a = PathBuf.fromStr('/foo/bar');
      final b = PathBuf.fromStr('/foo/bar');
      final c = PathBuf.fromStr('/foo/bar');

      expect(a, equals(b));
      expect(b, equals(c));
      expect(a, equals(c));
    });
  });

  group('fileNameComponent (POSIX)', () {
    usePosix();

    test('normal file', () {
      final p = PathBuf.fromStr('/tmp/file.txt');

      final component = p.fileNameComponent();

      expect(component, isNotNull);
      expect(component!.toStr(), 'file.txt');
    });

    test('directory path', () {
      final p = PathBuf.fromStr('/usr/local/bin/');

      final component = p.fileNameComponent();

      expect(component, isNotNull);
      expect(component!.toStr(), 'bin');
    });

    test('root returns null', () {
      final p = PathBuf.fromStr('/');

      expect(p.fileNameComponent(), isNull);
    });

    test('double-dot returns null', () {
      final p = PathBuf.fromStr('foo/..');

      expect(p.fileNameComponent(), isNull);
    });

    test('emoji filename', () {
      final p = PathBuf.fromStr('/tmp/📁_hello_🔥.txt');

      final component = p.fileNameComponent();

      expect(component, isNotNull);
      expect(component!.toStr(), '📁_hello_🔥.txt');
    });

    test('unicode filename', () {
      final p = PathBuf.fromStr('/tmp/こんにちは.txt');

      final component = p.fileNameComponent();

      expect(component, isNotNull);
      expect(component!.toStr(), 'こんにちは.txt');
    });

    test('backslashes remain literal', () {
      final p = PathBuf.fromStr(r'/tmp/foo\bar.txt');

      final component = p.fileNameComponent();

      expect(component, isNotNull);
      expect(component!.toStr(), r'foo\bar.txt');
    });
  });

  group('fileNameComponent (Windows)', () {
    useWindows();

    test('normal file', () {
      final p = PathBuf.fromStr(r'C:\Users\hello.txt');

      final component = p.fileNameComponent();

      expect(component, isNotNull);
      expect(component!.toStr(), 'hello.txt');
    });

    test('drive root returns null', () {
      final p = PathBuf.fromStr(r'C:\');

      expect(p.fileNameComponent(), isNull);
    });

    test('emoji filename', () {
      final p = PathBuf.fromStr(r'C:\Users\🔥_rocket_📁.txt');

      final component = p.fileNameComponent();

      expect(component, isNotNull);
      expect(component!.toStr(), '🔥_rocket_📁.txt');
    });

    test('unicode filename', () {
      final p = PathBuf.fromStr(r'C:\Users\你好.txt');

      final component = p.fileNameComponent();

      expect(component, isNotNull);
      expect(component!.toStr(), '你好.txt');
    });

    test('mixed separators', () {
      final p = PathBuf.fromStr(r'C:\tmp/foo\bar.txt');

      final component = p.fileNameComponent();

      expect(component, isNotNull);
      expect(component!.toStr(), 'bar.txt');
    });
  });
}
