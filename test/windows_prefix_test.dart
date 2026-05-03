import 'dart:typed_data';

import 'package:pathify/src/prefix.dart';
import 'package:pathify/src/sys/path/windows_prefix.dart';
import 'package:test/test.dart';

Uint8List _b(String s) => Uint8List.fromList(s.codeUnits);

String _str(Uint8List b) => String.fromCharCodes(b);

void main() {
  group('WindowsPrefix.parsePrefix', () {
    test('plain disk', () {
      final p = WindowsPrefix.parsePrefix(_b(r'C:\Users\Orange\Pictures'));
      expect(p, isA<Disk>());
      expect((p! as Disk).drive, 0x43); // 'C'
    });

    test('disk letter is normalized to uppercase', () {
      final p = WindowsPrefix.parsePrefix(_b(r'c:\Users'));
      expect((p! as Disk).drive, 0x43); // 'C', not 'c'
    });

    test('disk requires a colon', () {
      expect(WindowsPrefix.parsePrefix(_b(r'C\foo')), isNull);
    });

    test('disk requires an alphabetic letter', () {
      expect(WindowsPrefix.parsePrefix(_b(r'1:\foo')), isNull);
    });

    test('UNC', () {
      final p = WindowsPrefix.parsePrefix(_b(r'\\server\share\file'));
      expect(p, isA<UNC>());
      final unc = p! as UNC;
      expect(_str(unc.server), 'server');
      expect(_str(unc.share), 'share');
    });

    test('UNC with forward slashes is recognized in the prefix window', () {
      final p = WindowsPrefix.parsePrefix(_b('//server/share/file'));
      expect(p, isA<UNC>());
    });

    test('verbatim prefix with arbitrary component', () {
      final p = WindowsPrefix.parsePrefix(_b(r'\\?\pictures\kittens'));
      expect(p, isA<Verbatim>());
      expect(_str((p! as Verbatim).component), 'pictures');
    });

    test('verbatim disk', () {
      final p = WindowsPrefix.parsePrefix(_b(r'\\?\C:\Windows'));
      expect(p, isA<VerbatimDisk>());
      expect((p! as VerbatimDisk).drive, 0x43);
    });

    test('verbatim disk requires exact form', () {
      // \\?\Cfoo  - no colon, not a verbatim disk
      final p = WindowsPrefix.parsePrefix(_b(r'\\?\Cfoo\bar'));
      expect(p, isA<Verbatim>());
    });

    test('verbatim UNC', () {
      final p = WindowsPrefix.parsePrefix(_b(r'\\?\UNC\server\share'));
      expect(p, isA<VerbatimUNC>());
      final unc = p! as VerbatimUNC;
      expect(_str(unc.server), 'server');
      expect(_str(unc.share), 'share');
    });

    test('device namespace', () {
      final p = WindowsPrefix.parsePrefix(_b(r'\\.\COM42'));
      expect(p, isA<DeviceNS>());
      expect(_str((p! as DeviceNS).device), 'COM42');
    });

    test('device namespace with brain interface', () {
      final p = WindowsPrefix.parsePrefix(_b(r'\\.\BrainInterface'));
      expect(p, isA<DeviceNS>());
      expect(_str((p! as DeviceNS).device), 'BrainInterface');
    });

    test('relative path returns null', () {
      expect(WindowsPrefix.parsePrefix(_b(r'foo\bar')), isNull);
      expect(WindowsPrefix.parsePrefix(_b(r'.\foo')), isNull);
    });

    test('empty path returns null', () {
      expect(WindowsPrefix.parsePrefix(Uint8List(0)), isNull);
    });

    test('lone double-backslash returns null', () {
      expect(WindowsPrefix.parsePrefix(_b(r'\\')), isNull);
    });

    test('UNC requires both server and share to be non-empty', () {
      expect(WindowsPrefix.parsePrefix(_b(r'\\server')), isNull);
      expect(WindowsPrefix.parsePrefix(_b(r'\\server\')), isNull);
    });
  });

  group('WindowsPrefix.parseNextComponent', () {
    test('splits on first separator (non-verbatim)', () {
      final (a, b) = WindowsPrefix.parseNextComponent(
        _b(r'foo\bar\baz'),
        verbatim: false,
      );
      expect(_str(a), 'foo');
      expect(_str(b), r'bar\baz');
    });

    test('forward slash counts in non-verbatim mode', () {
      final (a, b) = WindowsPrefix.parseNextComponent(
        _b('foo/bar'),
        verbatim: false,
      );
      expect(_str(a), 'foo');
      expect(_str(b), 'bar');
    });

    test('forward slash is a filename byte in verbatim mode', () {
      final (a, b) = WindowsPrefix.parseNextComponent(
        _b(r'foo/bar\baz'),
        verbatim: true,
      );
      expect(_str(a), 'foo/bar');
      expect(_str(b), 'baz');
    });

    test('returns whole input when no separator is present', () {
      final (a, b) = WindowsPrefix.parseNextComponent(
        _b('only'),
        verbatim: false,
      );
      expect(_str(a), 'only');
      expect(b, isEmpty);
    });
  });
}
