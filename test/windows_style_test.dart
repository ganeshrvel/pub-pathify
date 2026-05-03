import 'dart:typed_data';

import 'package:pathify/src/path_bytes.dart';
import 'package:pathify/src/sys/path/windows_style.dart';
import 'package:test/test.dart';

Uint8List _b(String s) => Uint8List.fromList(s.codeUnits);

void main() {
  group('WindowsStyle', () {
    test('separator constants', () {
      expect(WindowsStyle.mainSep, PathBytes.backslash);
      expect(WindowsStyle.mainSepStr, r'\');
      expect(WindowsStyle.hasPrefixes, isTrue);
    });

    group('isSepByte', () {
      test('both backslash and forward slash count', () {
        expect(WindowsStyle.isSepByte(PathBytes.backslash), isTrue);
        expect(WindowsStyle.isSepByte(PathBytes.slash), isTrue);
      });

      test('non-separator bytes', () {
        expect(WindowsStyle.isSepByte(PathBytes.dot), isFalse);
        expect(WindowsStyle.isSepByte(PathBytes.colon), isFalse);
      });
    });

    test('isVerbatimSep recognizes only backslash', () {
      expect(WindowsStyle.isVerbatimSep(PathBytes.backslash), isTrue);
      expect(WindowsStyle.isVerbatimSep(PathBytes.slash), isFalse);
    });

    group('isVerbatim', () {
      test('recognizes the standard verbatim prefix', () {
        expect(WindowsStyle.isVerbatim(_b(r'\\?\C:\foo')), isTrue);
        expect(WindowsStyle.isVerbatim(_b(r'\\?\UNC\server\share')), isTrue);
      });

      test('recognizes the NT-form verbatim prefix', () {
        expect(WindowsStyle.isVerbatim(_b(r'\??\C:\foo')), isTrue);
      });

      test('rejects non-verbatim paths', () {
        expect(WindowsStyle.isVerbatim(_b(r'C:\Users')), isFalse);
        expect(WindowsStyle.isVerbatim(_b(r'\\server\share')), isFalse);
        expect(WindowsStyle.isVerbatim(_b(r'\\.\COM42')), isFalse);
      });

      test('rejects paths shorter than four bytes', () {
        expect(WindowsStyle.isVerbatim(_b('')), isFalse);
        expect(WindowsStyle.isVerbatim(_b(r'\')), isFalse);
        expect(WindowsStyle.isVerbatim(_b(r'\\?')), isFalse);
      });
    });

    group('isFileName', () {
      test('true when no separators are present', () {
        expect(WindowsStyle.isFileName(_b('foo.txt')), isTrue);
        expect(WindowsStyle.isFileName(_b('a.b.c')), isTrue);
      });

      test('false when any separator is present', () {
        expect(WindowsStyle.isFileName(_b(r'foo\bar')), isFalse);
        expect(WindowsStyle.isFileName(_b('foo/bar')), isFalse);
      });

      test('empty path counts as a file name', () {
        expect(WindowsStyle.isFileName(_b('')), isTrue);
      });
    });

    group('hasTrailingSlash', () {
      test('trailing backslash is a separator on non-verbatim paths', () {
        expect(WindowsStyle.hasTrailingSlash(_b(r'C:\foo\')), isTrue);
      });

      test('trailing forward slash is a separator on non-verbatim paths', () {
        expect(WindowsStyle.hasTrailingSlash(_b('foo/')), isTrue);
      });

      test('verbatim paths only treat trailing backslash as separator', () {
        expect(
            WindowsStyle.hasTrailingSlash(_b(r'\\?\C:\foo\')), isTrue);
        expect(
            WindowsStyle.hasTrailingSlash(_b(r'\\?\C:\foo/')), isFalse);
      });

      test('false for empty paths', () {
        expect(WindowsStyle.hasTrailingSlash(_b('')), isFalse);
      });

      test('false when path does not end in a separator', () {
        expect(WindowsStyle.hasTrailingSlash(_b(r'C:\foo')), isFalse);
      });
    });
  });
}
