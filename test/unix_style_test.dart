import 'package:pathify/src/path_bytes.dart';
import 'package:pathify/src/sys/path/unix_style.dart';
import 'package:test/test.dart';

void main() {
  group('UnixStyle', () {
    test('separator constants', () {
      expect(UnixStyle.mainSep, PathBytes.slash);
      expect(UnixStyle.mainSepStr, '/');
      expect(UnixStyle.hasPrefixes, isFalse);
    });

    group('isSepByte', () {
      test('only forward slash counts as a separator', () {
        expect(UnixStyle.isSepByte(PathBytes.slash), isTrue);
        expect(UnixStyle.isSepByte(PathBytes.backslash), isFalse);
      });

      test('regular filename bytes are not separators', () {
        expect(UnixStyle.isSepByte(PathBytes.dot), isFalse);
        expect(UnixStyle.isSepByte(PathBytes.colon), isFalse);
        expect(UnixStyle.isSepByte(0x61), isFalse); // 'a'
      });
    });

    test('isVerbatimSep matches isSepByte on POSIX', () {
      for (var b = 0; b < 128; b++) {
        expect(UnixStyle.isVerbatimSep(b), UnixStyle.isSepByte(b));
      }
    });
  });
}
