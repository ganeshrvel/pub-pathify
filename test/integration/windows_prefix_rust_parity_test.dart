import 'dart:typed_data';

import 'package:pathify/pathify.dart';
import 'package:pathify/src/sys/path/windows_prefix.dart';
import 'package:test/test.dart';

import '_helpers.dart';

Uint16List _w(String s) => Uint16List.fromList(s.codeUnits);

void main() {
  group('test_parse_next_component', () {
    test(r'server\share verbatim', () {
      final (a, b) = WindowsPrefix.parseNextComponent(
        cuN(r'server\share'),
        verbatim: true,
      );
      expect(cuStr(a), equals('server'));
      expect(cuStr(b), equals('share'));
    });

    test('server/share verbatim', () {
      final (a, b) = WindowsPrefix.parseNextComponent(
        cuN('server/share'),
        verbatim: true,
      );
      expect(cuStr(a), equals('server/share'));
      expect(cuStr(b), equals(''));
    });

    test('server/share non-verbatim', () {
      final (a, b) = WindowsPrefix.parseNextComponent(
        cuN('server/share'),
        verbatim: false,
      );
      expect(cuStr(a), equals('server'));
      expect(cuStr(b), equals('share'));
    });

    test(r'server\ trailing', () {
      final (a, b) = WindowsPrefix.parseNextComponent(
        cuN(r'server\'),
        verbatim: false,
      );
      expect(cuStr(a), equals('server'));
      expect(cuStr(b), equals(''));
    });

    test(r'\server\ leading', () {
      final (a, b) = WindowsPrefix.parseNextComponent(
        cuN(r'\server\'),
        verbatim: false,
      );
      expect(cuStr(a), equals(''));
      expect(cuStr(b), equals(r'server\'));
    });

    test('servershare', () {
      final (a, b) = WindowsPrefix.parseNextComponent(
        cuN('servershare'),
        verbatim: false,
      );
      expect(cuStr(a), equals('servershare'));
      expect(cuStr(b), equals(''));
    });
  });

  group('verbatim', () {
    setUp(() {
      Pathify.instance.overriddenPlatform = PathifyPlatform.windows;
    });

    tearDown(Pathify.instance.resetForTesting);
    void check(String path, String expected) {
      final p = PathBuf.fromBytes(_w(path));

      // Using observable behavior: toStringLossy()
      final s = p.toStringLossy();

      expect(s, equals(expected), reason: path);
    }

    test('verbatim paths', () {
      check(
        r'\\?\verbatim.\aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb\foo.txt',
        r'\\?\verbatim.\aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb\foo.txt',
      );

      check(r'C:\Program Files\Rust', r'C:\Program Files\Rust');
      check(r'\\server\share', r'\\server\share');
      check(r'\\.\COM1', r'\\.\COM1');

      check('Z:', 'Z:');

      // deterministic invalid case
      final p = PathBuf.fromBytes(_w('\u0000'));
      expect(p.toStr(), isNull);
    });

    test('null byte handling', () {
      final p = PathBuf.fromBytes(_w('\u0000'));

      // strict conversion → invalid
      expect(p.toStr(), isNull);

      // lossy conversion → must NOT fail, must return something
      final lossy = p.toStringLossy();
      expect(lossy, isNotNull);
      expect(lossy.isNotEmpty, isTrue);
    });
  });

  group('test_parse_prefix_verbatim', () {
    test('verbatim disk', () {
      final p = WindowsPrefix.parsePrefix(
        cuN(r'\\?\C:/windows/system32/notepad.exe'),
      );
      expect(p, isA<VerbatimDisk>());
      expect((p! as VerbatimDisk).drive, equals(0x43));
    });

    test('verbatim disk backslash', () {
      final p = WindowsPrefix.parsePrefix(
        cuN(r'\\?\C:\windows\system32\notepad.exe'),
      );
      expect(p, isA<VerbatimDisk>());
      expect((p! as VerbatimDisk).drive, equals(0x43));
    });
  });

  group('test_parse_prefix_verbatim_device', () {
    void check(String path) {
      final p = WindowsPrefix.parsePrefix(cuN(path));
      expect(p, isA<UNC>());
      final u = p! as UNC;
      expect(cuStr(u.server), equals('?'));
      expect(cuStr(u.share), equals('C:'));
    }

    test('verbatim device parses as UNC', () {
      check('//?/C:/windows/system32/notepad.exe');
      check(r'//?/C:\windows\system32\notepad.exe');
      check(r'/\?\C:\windows\system32\notepad.exe');
      check(r'\\?/C:\windows\system32\notepad.exe');
    });
  });

  group('broken_unc_path', () {
    setUp(() {
      Pathify.instance.overriddenPlatform = PathifyPlatform.windows;
    });

    tearDown(Pathify.instance.resetForTesting);

    test(r'\\foo\\bar\\', () {
      final comps = PathBuf.fromBytes(
        _w(r'\\foo\\bar\\'),
      ).components().toList();

      final names = comps
          .whereType<ComponentNormal>()
          .map((c) => cuStr(c.value))
          .toList();

      expect(names, equals(['foo', 'bar']));
    });

    test('//foo//bar//', () {
      final comps = PathBuf.fromBytes(
        _w('//foo//bar//'),
      ).components().toList();

      final names = comps
          .whereType<ComponentNormal>()
          .map((c) => cuStr(c.value))
          .toList();

      expect(names, equals(['foo', 'bar']));
    });
  });
}
