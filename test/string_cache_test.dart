import 'dart:typed_data';

import 'package:option_result/option.dart';
import 'package:pathify/pathify.dart';
import 'package:test/test.dart';

void main() {
  group('PathBuf.toStr cache', () {
    test('cache is empty before first call', () {
      final path = PathBuf.fromStr('/foo/bar');

      expect(path.debugCachedStr, isA<None<String?>>());
    });

    test('cache is populated after first call', () {
      final path = PathBuf.fromStr('/foo/bar')..toStr();

      expect(path.debugCachedStr, isA<Some<String?>>());
    });

    test('cached value matches return value', () {
      final path = PathBuf.fromStr('/foo/bar');
      final result = path.toStr();

      expect((path.debugCachedStr as Some<String?>).value, equals(result));
    });

    test('returns same string instance on repeated calls', () {
      final path = PathBuf.fromStr('/foo/bar');
      final first = path.toStr();
      final second = path.toStr();

      expect(identical(first, second), isTrue);
    });

    test('caches null result for invalid unicode bytes', () {
      final bytes = Uint8List.fromList([0xFF, 0xFE, 0x00]);
      final path = PathBuf.fromBytes(bytes);
      final result = path.toStr();

      expect(result, isNull);
      expect(path.debugCachedStr, isA<Some<String?>>());
      expect((path.debugCachedStr as Some<String?>).value, isNull);
    });

    test('null result returned from cache on repeated calls', () {
      final bytes = Uint8List.fromList([0xFF, 0xFE, 0x00]);
      final path = PathBuf.fromBytes(bytes)..toStr();
      final second = path.toStr();

      expect(second, isNull);
    });
  });

  group('PathBuf.toStringLossy cache', () {
    test('cache is empty before first call', () {
      final path = PathBuf.fromStr('/foo/bar');

      expect(path.debugCachedStringLossy, isA<None<String>>());
    });

    test('cache is populated after first call', () {
      final path = PathBuf.fromStr('/foo/bar')..toStringLossy();

      expect(path.debugCachedStringLossy, isA<Some<String>>());
    });

    test('cached value matches return value', () {
      final path = PathBuf.fromStr('/foo/bar');
      final result = path.toStringLossy();

      expect(
        (path.debugCachedStringLossy as Some<String>).value,
        equals(result),
      );
    });

    test('returns same string instance on repeated calls', () {
      final path = PathBuf.fromStr('/foo/bar');
      final first = path.toStringLossy();
      final second = path.toStringLossy();

      expect(identical(first, second), isTrue);
    });

    test('caches substituted result for invalid unicode bytes', () {
      final bytes = Uint8List.fromList([0xFF, 0xFE]);
      final path = PathBuf.fromBytes(bytes);
      final result = path.toStringLossy();

      expect(path.debugCachedStringLossy, isA<Some<String>>());
      expect(
        (path.debugCachedStringLossy as Some<String>).value,
        equals(result),
      );
    });
  });

  group('PathBuf.toStr and toStringLossy cache independence', () {
    test('calling toStr does not populate toStringLossy cache', () {
      final path = PathBuf.fromStr('/foo/bar')..toStr();

      expect(path.debugCachedStringLossy, isA<None<String>>());
    });

    test('calling toStringLossy does not populate toStr cache', () {
      final path = PathBuf.fromStr('/foo/bar')..toStringLossy();

      expect(path.debugCachedStr, isA<None<String?>>());
    });
  });

  group('PathBuf immutability', () {
    test('two paths constructed from same string are equal', () {
      final a = PathBuf.fromStr('/foo/bar');
      final b = PathBuf.fromStr('/foo/bar');

      expect(a, equals(b));
    });

    test('equal paths produce equal hash codes', () {
      final a = PathBuf.fromStr('/foo/bar');
      final b = PathBuf.fromStr('/foo/bar');

      expect(a.hashCode, equals(b.hashCode));
    });

    test('bytes getter returns same content on repeated access', () {
      final path = PathBuf.fromStr('/foo/bar');
      final first = path.bytes;
      final second = path.bytes;

      expect(first, equals(second));
    });

    test('codeUnits length is stable across accesses', () {
      final path = PathBuf.fromStr('/foo/bar');

      expect(path.codeUnits.length, equals(path.codeUnits.length));
    });

    test('join returns new instance, original is unchanged', () {
      final a = PathBuf.fromStr('/foo');
      final b = PathBuf.fromStr('bar');
      final joined = a.join(b);

      expect(a.toStr(), equals('/foo'));
      expect(joined.toStr(), equals('/foo/bar'));
    });

    test('withFileName returns new instance, original is unchanged', () {
      final path = PathBuf.fromStr('/foo/bar.txt');
      final updated = path.withFileName(
        PathBuf.fromStr('baz.txt').codeUnits,
      );

      expect(path.toStr(), equals('/foo/bar.txt'));
      expect(updated.toStr(), equals('/foo/baz.txt'));
    });

    test('withExtension returns new instance, original is unchanged', () {
      final path = PathBuf.fromStr('/foo/bar.txt');
      final updated = path.withExtension(
        PathBuf.fromStr('md').codeUnits,
      );

      expect(path.toStr(), equals('/foo/bar.txt'));
      expect(updated.toStr(), equals('/foo/bar.md'));
    });
  });

  test('toStr computes once and caches result', () {
    final path = PathBuf.fromStr('/foo/bar');

    expect(path.debugCachedStr, isA<None<String?>>());

    final result = path.toStr();

    expect(path.debugCachedStr, isA<Some<String?>>());
    expect((path.debugCachedStr as Some<String?>).value, equals(result));
    expect(identical(path.toStr(), result), isTrue);
  });

  test('toStringLossy computes once and caches result', () {
    final path = PathBuf.fromStr('/foo/bar');

    expect(path.debugCachedStringLossy, isA<None<String>>());

    final result = path.toStringLossy();

    expect(path.debugCachedStringLossy, isA<Some<String>>());
    expect((path.debugCachedStringLossy as Some<String>).value, equals(result));
    expect(identical(path.toStringLossy(), result), isTrue);
  });

  test('toStr and toStringLossy compute once and cache result', () {
    final path = PathBuf.fromStr('/foo/bar');

    expect(path.debugCachedStr, isA<None<String?>>());
    expect(path.debugCachedStringLossy, isA<None<String>>());

    final str = path.toStr();
    final lossy = path.toStringLossy();

    expect(path.debugCachedStr, isA<Some<String?>>());
    expect(path.debugCachedStringLossy, isA<Some<String>>());
    expect((path.debugCachedStr as Some<String?>).value, equals(str));
    expect((path.debugCachedStringLossy as Some<String>).value, equals(lossy));
    expect(identical(path.toStr(), str), isTrue);
    expect(identical(path.toStringLossy(), lossy), isTrue);
  });
}
