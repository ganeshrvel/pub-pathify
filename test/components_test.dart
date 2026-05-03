import 'dart:typed_data';

import 'package:pathify/pathify.dart';
import 'package:pathify/src/sys/path/windows_prefix.dart';
import 'package:test/test.dart';

Uint8List _b(String s) => Uint8List.fromList(s.codeUnits);

String _str(Uint8List b) => String.fromCharCodes(b);

Components _unixComponents(String path) {
  final bytes = _b(path);
  return Components.start(
    pathBytes: bytes,
    prefix: null,
    isWindows: false,
  );
}

Components _windowsComponents(String path) {
  final bytes = _b(path);
  return Components.start(
    pathBytes: bytes,
    prefix: WindowsPrefix.parsePrefix(bytes),
    isWindows: true,
  );
}

void main() {
  group('Components on POSIX paths', () {
    test('absolute path with two segments', () {
      final c = _unixComponents('/tmp/foo.txt');
      final list = c.toList();
      expect(list, hasLength(3));
      expect(list[0], isA<ComponentRootDir>());
      expect((list[1] as ComponentNormal).value.let(_str), 'tmp');
      expect((list[2] as ComponentNormal).value.let(_str), 'foo.txt');
    });

    test('relative path with leading dot is preserved as CurDir', () {
      final c = _unixComponents('./tmp/foo');
      final list = c.toList();
      expect(list[0], isA<ComponentCurDir>());
      expect((list[1] as ComponentNormal).value.let(_str), 'tmp');
      expect((list[2] as ComponentNormal).value.let(_str), 'foo');
    });

    test('repeated separators are collapsed', () {
      final c = _unixComponents('/tmp//foo///bar');
      final names = c
          .toList()
          .whereType<ComponentNormal>()
          .map((n) => _str(n.value))
          .toList();
      expect(names, ['tmp', 'foo', 'bar']);
    });

    test('trailing separator is dropped', () {
      final c = _unixComponents('/tmp/foo/');
      final list = c.toList();
      expect(list.last, isA<ComponentNormal>());
      expect((list.last as ComponentNormal).value.let(_str), 'foo');
    });

    test('parent directory is preserved', () {
      final c = _unixComponents('a/../b');
      final list = c.toList();
      expect(list[0], isA<ComponentNormal>());
      expect(list[1], isA<ComponentParentDir>());
      expect(list[2], isA<ComponentNormal>());
    });

    test('empty path yields no components', () {
      final c = _unixComponents('');
      expect(c.toList(), isEmpty);
    });

    test('root only', () {
      final c = _unixComponents('/');
      final list = c.toList();
      expect(list, hasLength(1));
      expect(list[0], isA<ComponentRootDir>());
    });
  });

  group('Components on Windows paths', () {
    test('drive plus body', () {
      final c = _windowsComponents(r'C:\Users\Orange');
      final list = c.toList();
      expect(list[0], isA<ComponentPrefix>());
      expect(list[1], isA<ComponentRootDir>());
      expect((list[2] as ComponentNormal).value.let(_str), 'Users');
      expect((list[3] as ComponentNormal).value.let(_str), 'Orange');
    });

    test('drive without root is relative', () {
      final c = _windowsComponents('C:Users');
      final list = c.toList();
      expect(list[0], isA<ComponentPrefix>());
      // No RootDir between prefix and body for `C:foo`.
      expect(list[1], isA<ComponentNormal>());
    });

    test('UNC path produces prefix + implicit root', () {
      final c = _windowsComponents(r'\\server\share\file');
      final list = c.toList();
      expect(list[0], isA<ComponentPrefix>());
      expect(list[1], isA<ComponentRootDir>());
      expect((list[2] as ComponentNormal).value.let(_str), 'file');
    });

    test('verbatim disk path', () {
      final c = _windowsComponents(r'\\?\C:\Windows');
      final list = c.toList();
      expect(list[0], isA<ComponentPrefix>());
      // Verbatim disk has a physical root after the prefix.
      expect(list[1], isA<ComponentRootDir>());
      expect((list[2] as ComponentNormal).value.let(_str), 'Windows');
    });

    test(
      'verbatim prefix without disk consumes the whole tail as one component',
      () {
        // `\\?\foo/bar` has no drive letter and no UNC marker, so the entire
        // sequence after `\\?\` becomes the Verbatim prefix's single component.
        // `/` does not split it because verbatim paths treat `/` as a filename
        // byte, not a separator.
        final c = _windowsComponents(r'\\?\foo/bar');
        final list = c.toList();
        expect(list, hasLength(1));
        expect(list[0], isA<ComponentPrefix>());
        final pfx = (list[0] as ComponentPrefix).parsed;
        expect(pfx, isA<Verbatim>());
        expect(_str((pfx as Verbatim).component), 'foo/bar');
      },
    );

    test(
      'verbatim path with body keeps forward slashes inside body components',
      () {
        // `\\?\C:\foo/bar\baz`:
        //   prefix:  \\?\C:    (VerbatimDisk)
        //   root:    \          (physical root after the prefix)
        //   body:    foo/bar    (one component; `/` is not a separator)
        //            baz        (split off by `\`, which is a verbatim separator)
        final c = _windowsComponents(r'\\?\C:\foo/bar\baz');
        final list = c.toList();
        expect(list[0], isA<ComponentPrefix>());
        expect(list[1], isA<ComponentRootDir>());
        final body = list
            .whereType<ComponentNormal>()
            .map((n) => _str(n.value))
            .toList();
        expect(body, ['foo/bar', 'baz']);
      },
    );

    test('forward slashes in non-verbatim paths are separators', () {
      final c = _windowsComponents('C:/Users/Orange');
      final names = c
          .toList()
          .whereType<ComponentNormal>()
          .map((n) => _str(n.value))
          .toList();
      expect(names, ['Users', 'Orange']);
    });
  });

  group('Components double-ended iteration', () {
    test('nextBack yields components in reverse', () {
      final c = _unixComponents('/tmp/foo/bar.txt');
      final reversed = c.toListReversed();
      final names = reversed
          .whereType<ComponentNormal>()
          .map((n) => _str(n.value))
          .toList();
      expect(names, ['bar.txt', 'foo', 'tmp']);
    });

    test('mixing next and nextBack consumes from both ends', () {
      final c = _unixComponents('/a/b/c/d');
      expect(c.next(), isA<ComponentRootDir>());
      expect((c.next()! as ComponentNormal).value.let(_str), 'a');
      expect((c.nextBack()! as ComponentNormal).value.let(_str), 'd');
      expect((c.nextBack()! as ComponentNormal).value.let(_str), 'c');
      expect((c.next()! as ComponentNormal).value.let(_str), 'b');
      expect(c.next(), isNull);
      expect(c.nextBack(), isNull);
    });
  });
}

extension on Uint8List {
  T let<T>(T Function(Uint8List) fn) => fn(this);
}
