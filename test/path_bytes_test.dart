import 'package:pathify/src/path_bytes.dart';
import 'package:test/test.dart';

void main() {
  group('PathBytes', () {
    test('constants have correct ASCII values', () {
      expect(PathBytes.slash, 0x2F);
      expect(PathBytes.backslash, 0x5C);
      expect(PathBytes.colon, 0x3A);
      expect(PathBytes.dot, 0x2E);
      expect(PathBytes.question, 0x3F);
    });

    group('isAsciiAlpha', () {
      test('accepts uppercase ASCII letters', () {
        for (var b = PathBytes.upperA; b <= PathBytes.upperZ; b++) {
          expect(PathBytes.isAsciiAlpha(b), isTrue, reason: 'byte $b');
        }
      });

      test('accepts lowercase ASCII letters', () {
        for (var b = PathBytes.lowerA; b <= PathBytes.lowerZ; b++) {
          expect(PathBytes.isAsciiAlpha(b), isTrue, reason: 'byte $b');
        }
      });

      test('rejects digits and punctuation', () {
        expect(PathBytes.isAsciiAlpha(0x30), isFalse); // '0'
        expect(PathBytes.isAsciiAlpha(0x39), isFalse); // '9'
        expect(PathBytes.isAsciiAlpha(PathBytes.colon), isFalse);
        expect(PathBytes.isAsciiAlpha(PathBytes.slash), isFalse);
      });

      test('rejects bytes outside the ASCII alphabetic range', () {
        expect(PathBytes.isAsciiAlpha(0x40), isFalse); // '@', just before 'A'
        expect(PathBytes.isAsciiAlpha(0x5B), isFalse); // '[', just after 'Z'
        expect(PathBytes.isAsciiAlpha(0x60), isFalse); // '`', just before 'a'
        expect(PathBytes.isAsciiAlpha(0x7B), isFalse); // '{', just after 'z'
      });
    });

    group('asciiToUpper', () {
      test('uppercases lowercase letters', () {
        expect(PathBytes.asciiToUpper(PathBytes.lowerA), PathBytes.upperA);
        expect(PathBytes.asciiToUpper(PathBytes.lowerZ), PathBytes.upperZ);
      });

      test('leaves uppercase letters unchanged', () {
        expect(PathBytes.asciiToUpper(PathBytes.upperA), PathBytes.upperA);
        expect(PathBytes.asciiToUpper(PathBytes.upperZ), PathBytes.upperZ);
      });

      test('leaves non-letters unchanged', () {
        expect(PathBytes.asciiToUpper(PathBytes.colon), PathBytes.colon);
        expect(PathBytes.asciiToUpper(PathBytes.slash), PathBytes.slash);
        expect(PathBytes.asciiToUpper(0x30), 0x30); // '0'
      });
    });
  });
}
