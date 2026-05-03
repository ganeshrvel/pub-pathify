import 'package:pathify/src/prefix.dart';
import 'package:pathify/src/sys/path/windows_prefix.dart';
import 'package:test/test.dart';

import 'integration/_helpers.dart';

void main() {
  group('WindowsPrefix.parsePrefix', () {
    test('plain disk', () {
      final p = WindowsPrefix.parsePrefix(cuN(r'C:\Users\Orange\Pictures'));
      expect(p, isA<Disk>());
      expect((p! as Disk).drive, 0x43); // 'C'
    });

    test('disk letter is normalized to uppercase', () {
      final p = WindowsPrefix.parsePrefix(cuN(r'c:\Users'));
      expect((p! as Disk).drive, 0x43); // 'C', not 'c'
    });

    test('disk requires a colon', () {
      expect(WindowsPrefix.parsePrefix(cuN(r'C\foo')), isNull);
    });

    test('disk requires an alphabetic letter', () {
      expect(WindowsPrefix.parsePrefix(cuN(r'1:\foo')), isNull);
    });

    test('UNC', () {
      final p = WindowsPrefix.parsePrefix(cuN(r'\\server\share\file'));
      expect(p, isA<UNC>());
      final unc = p! as UNC;
      expect(cuStr(unc.server), 'server');
      expect(cuStr(unc.share), 'share');
    });

    test('UNC with forward slashes is recognized in the prefix window', () {
      final p = WindowsPrefix.parsePrefix(cuN('//server/share/file'));
      expect(p, isA<UNC>());
    });

    test('verbatim prefix with arbitrary component', () {
      final p = WindowsPrefix.parsePrefix(cuN(r'\\?\pictures\kittens'));
      expect(p, isA<Verbatim>());
      expect(cuStr((p! as Verbatim).component), 'pictures');
    });

    test('verbatim disk', () {
      final p = WindowsPrefix.parsePrefix(cuN(r'\\?\C:\Windows'));
      expect(p, isA<VerbatimDisk>());
      expect((p! as VerbatimDisk).drive, 0x43);
    });

    test('verbatim disk requires exact form', () {
      // \\?\Cfoo  - no colon, not a verbatim disk
      final p = WindowsPrefix.parsePrefix(cuN(r'\\?\Cfoo\bar'));
      expect(p, isA<Verbatim>());
    });

    test('verbatim UNC', () {
      final p = WindowsPrefix.parsePrefix(cuN(r'\\?\UNC\server\share'));
      expect(p, isA<VerbatimUNC>());
      final unc = p! as VerbatimUNC;
      expect(cuStr(unc.server), 'server');
      expect(cuStr(unc.share), 'share');
    });

    test('device namespace', () {
      final p = WindowsPrefix.parsePrefix(cuN(r'\\.\COM42'));
      expect(p, isA<DeviceNS>());
      expect(cuStr((p! as DeviceNS).device), 'COM42');
    });

    test('device namespace with brain interface', () {
      final p = WindowsPrefix.parsePrefix(cuN(r'\\.\BrainInterface'));
      expect(p, isA<DeviceNS>());
      expect(cuStr((p! as DeviceNS).device), 'BrainInterface');
    });

    test('relative path returns null', () {
      expect(WindowsPrefix.parsePrefix(cuN(r'foo\bar')), isNull);
      expect(WindowsPrefix.parsePrefix(cuN(r'.\foo')), isNull);
    });

    test('empty path returns null', () {
      expect(WindowsPrefix.parsePrefix(cuN('')), isNull);
    });

    test('lone double-backslash returns null', () {
      expect(WindowsPrefix.parsePrefix(cuN(r'\\')), isNull);
    });

    test('UNC requires both server and share to be non-empty', () {
      expect(WindowsPrefix.parsePrefix(cuN(r'\\server')), isNull);
      expect(WindowsPrefix.parsePrefix(cuN(r'\\server\')), isNull);
    });
  });

  group('WindowsPrefix.parseNextComponent', () {
    test('splits on first separator (non-verbatim)', () {
      final (a, b2) = WindowsPrefix.parseNextComponent(
        cuN(r'foo\bar\baz'),
        verbatim: false,
      );
      expect(cuStr(a), 'foo');
      expect(cuStr(b2), r'bar\baz');
    });

    test('forward slash counts in non-verbatim mode', () {
      final (a, b2) = WindowsPrefix.parseNextComponent(
        cuN('foo/bar'),
        verbatim: false,
      );
      expect(cuStr(a), 'foo');
      expect(cuStr(b2), 'bar');
    });

    test('forward slash is a filename byte in verbatim mode', () {
      final (a, b2) = WindowsPrefix.parseNextComponent(
        cuN(r'foo/bar\baz'),
        verbatim: true,
      );
      expect(cuStr(a), 'foo/bar');
      expect(cuStr(b2), 'baz');
    });

    test('returns whole input when no separator is present', () {
      final (a, b2) = WindowsPrefix.parseNextComponent(
        cuN('only'),
        verbatim: false,
      );
      expect(cuStr(a), 'only');
      expect(b2.isEmpty, isTrue);
    });
  });
}
