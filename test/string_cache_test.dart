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

  group('cache invalidation after mutation', () {
    test('toStr cache is cleared after push', () {
      final path = PathBuf.fromStr('/foo')..toStr();

      expect(path.debugCachedStr, isA<Some<String?>>());

      path.push(PathBuf.fromStr('bar'));

      expect(path.debugCachedStr, isA<None<String?>>());
      expect(path.toStr(), equals('/foo/bar'));
    });

    test('toStringLossy cache is cleared after push', () {
      final path = PathBuf.fromStr('/foo')..toStringLossy();

      expect(path.debugCachedStringLossy, isA<Some<String>>());

      path.push(PathBuf.fromStr('bar'));

      expect(path.debugCachedStringLossy, isA<None<String>>());
      expect(path.toStringLossy(), equals('/foo/bar'));
    });

    test('both caches cleared after pop', () {
      final path = PathBuf.fromStr('/foo/bar')
        ..toStr()
        ..toStringLossy()
        ..pop();

      expect(path.debugCachedStr, isA<None<String?>>());
      expect(path.debugCachedStringLossy, isA<None<String>>());
      expect(path.toStr(), equals('/foo'));
    });

    test('both caches cleared after setFileName', () {
      final path = PathBuf.fromStr('/foo/bar.txt')
        ..toStr()
        ..toStringLossy()
        ..setFileName(PathBuf.fromStr('baz.txt').codeUnits);

      expect(path.debugCachedStr, isA<None<String?>>());
      expect(path.debugCachedStringLossy, isA<None<String>>());
      expect(path.toStr(), equals('/foo/baz.txt'));
    });

    test('both caches cleared after setExtension', () {
      final path = PathBuf.fromStr('/foo/bar.txt')
        ..toStr()
        ..toStringLossy()
        ..setExtension(PathBuf.fromStr('md').codeUnits);

      expect(path.debugCachedStr, isA<None<String?>>());
      expect(path.debugCachedStringLossy, isA<None<String>>());
      expect(path.toStr(), equals('/foo/bar.md'));
    });

    test('both caches cleared after addExtension', () {
      final path = PathBuf.fromStr('/foo/bar.txt')
        ..toStr()
        ..toStringLossy()
        ..addExtension(PathBuf.fromStr('gz').codeUnits);

      expect(path.debugCachedStr, isA<None<String?>>());
      expect(path.debugCachedStringLossy, isA<None<String>>());
      expect(path.toStr(), equals('/foo/bar.txt.gz'));
    });

    test('both caches cleared after clear', () {
      final path = PathBuf.fromStr('/foo/bar')
        ..toStr()
        ..toStringLossy()
        ..clear();

      expect(path.debugCachedStr, isA<None<String?>>());
      expect(path.debugCachedStringLossy, isA<None<String>>());
      expect(path.toStr(), equals(''));
    });

    test('cache repopulates correctly after invalidation', () {
      final path = PathBuf.fromStr('/foo')
        ..toStr()
        ..push(PathBuf.fromStr('bar'));

      final result = path.toStr();

      expect(path.debugCachedStr, isA<Some<String?>>());
      expect((path.debugCachedStr as Some<String?>).value, equals(result));
      expect(identical(path.toStr(), result), isTrue);
    });

    test('absolute push replaces path and invalidates cache', () {
      final path = PathBuf.fromStr('/foo/bar')
        ..toStr()
        ..toStringLossy()
        ..push(PathBuf.fromStr('/baz'));

      expect(path.debugCachedStr, isA<None<String?>>());
      expect(path.debugCachedStringLossy, isA<None<String>>());
      expect(path.toStr(), equals('/baz'));
    });
  });

  group('cache invalidation — multiple mutations in sequence', () {
    test('cache reflects each mutation in sequence', () {
      final path = PathBuf.fromStr('/foo')..push(PathBuf.fromStr('bar'));
      expect(path.toStr(), equals('/foo/bar'));

      path.push(PathBuf.fromStr('baz'));
      expect(path.toStr(), equals('/foo/bar/baz'));

      path.pop();
      expect(path.toStr(), equals('/foo/bar'));

      path.pop();
      expect(path.toStr(), equals('/foo'));
    });

    test('cache is fresh after each setExtension call', () {
      final path = PathBuf.fromStr('/foo/bar.txt')
        ..setExtension(PathBuf.fromStr('md').codeUnits);
      expect(path.toStr(), equals('/foo/bar.md'));
      expect(path.debugCachedStr, isA<Some<String?>>());

      path.setExtension(PathBuf.fromStr('rs').codeUnits);
      expect(path.toStr(), equals('/foo/bar.rs'));
    });

    test('toStr and toStringLossy stay consistent across mutations', () {
      final path = PathBuf.fromStr('/foo/bar')
        ..toStr()
        ..toStringLossy()
        ..push(PathBuf.fromStr('baz'));

      expect(path.toStr(), equals(path.toStringLossy()));
    });
  });

  group('cache with invalid unicode bytes after mutation', () {
    test('push of invalid bytes invalidates and recaches as null toStr', () {
      final path = PathBuf.fromStr('/foo')..toStr();

      final invalid = PathBuf.fromBytes(Uint8List.fromList([0xFF, 0xFE]));
      path.push(invalid);

      expect(path.debugCachedStr, isA<None<String?>>());
      expect(path.toStr(), isNull);
      expect(path.debugCachedStr, isA<Some<String?>>());
      expect((path.debugCachedStr as Some<String?>).value, isNull);
    });

    test(
      'toStringLossy after push of invalid bytes returns replacement char',
      () {
        final path = PathBuf.fromStr('/foo');
        final invalid = PathBuf.fromBytes(Uint8List.fromList([0xFF, 0xFE]));
        path.push(invalid);

        final result = path.toStringLossy();

        expect(result, contains('\uFFFD'));
        expect(path.debugCachedStringLossy, isA<Some<String>>());
        expect(identical(path.toStringLossy(), result), isTrue);
      },
    );
  });

  group('cache with empty path', () {
    test('toStr on empty path returns empty string', () {
      final path = PathBuf.empty();

      expect(path.debugCachedStr, isA<None<String?>>());

      final result = path.toStr();

      expect(result, equals(''));
      expect(path.debugCachedStr, isA<Some<String?>>());
      expect(identical(path.toStr(), result), isTrue);
    });

    test('toStringLossy on empty path returns empty string', () {
      final path = PathBuf.empty();
      final result = path.toStringLossy();

      expect(result, equals(''));
      expect(path.debugCachedStringLossy, isA<Some<String>>());
      expect(identical(path.toStringLossy(), result), isTrue);
    });

    test('clear produces same cache state as PathBuf.empty', () {
      final path = PathBuf.fromStr('/foo/bar')
        ..toStr()
        ..toStringLossy()
        ..clear();

      expect(path.debugCachedStr, isA<None<String?>>());
      expect(path.debugCachedStringLossy, isA<None<String>>());
      expect(path.toStr(), equals(''));
      expect(path.toStringLossy(), equals(''));
    });
  });

  group('cache on cloned paths via non-mutating builders', () {
    test('join result starts with empty cache', () {
      final a = PathBuf.fromStr('/foo')..toStr();
      final joined = a.join(PathBuf.fromStr('bar'));

      expect(joined.debugCachedStr, isA<None<String?>>());
      expect(joined.debugCachedStringLossy, isA<None<String>>());
    });

    test('withFileName result starts with empty cache', () {
      final path = PathBuf.fromStr('/foo/bar.txt')..toStr();
      final updated = path.withFileName(PathBuf.fromStr('baz.txt').codeUnits);

      expect(updated.debugCachedStr, isA<None<String?>>());
      expect(updated.debugCachedStringLossy, isA<None<String>>());
    });

    test('withExtension result starts with empty cache', () {
      final path = PathBuf.fromStr('/foo/bar.txt')..toStr();
      final updated = path.withExtension(PathBuf.fromStr('md').codeUnits);

      expect(updated.debugCachedStr, isA<None<String?>>());
      expect(updated.debugCachedStringLossy, isA<None<String>>());
    });

    test('withAddedExtension result starts with empty cache', () {
      final path = PathBuf.fromStr('/foo/bar.txt')..toStr();
      final updated = path.withAddedExtension(PathBuf.fromStr('gz').codeUnits);

      expect(updated.debugCachedStr, isA<None<String?>>());
      expect(updated.debugCachedStringLossy, isA<None<String>>());
    });

    test('original cache unaffected by non-mutating builder', () {
      final path = PathBuf.fromStr('/foo/bar.txt');
      final cached = path.toStr();

      path.withFileName(PathBuf.fromStr('baz.txt').codeUnits);

      expect(path.debugCachedStr, isA<Some<String?>>());
      expect((path.debugCachedStr as Some<String?>).value, equals(cached));
    });
  });

  group('cache on null-byte paths', () {
    test('toStr with null byte returns null and caches it', () {
      final path = PathBuf.fromBytes(Uint8List.fromList([0x2F, 0x00, 0x61]));

      expect(path.toStr(), isNull);
      expect(path.debugCachedStr, isA<Some<String?>>());
      expect((path.debugCachedStr as Some<String?>).value, isNull);
      expect(identical(path.toStr(), path.toStr()), isTrue);
    });

    test('toStringLossy with null byte returns null substitution', () {
      final path = PathBuf.fromBytes(Uint8List.fromList([0x2F, 0x00, 0x61]));
      final result = path.toStringLossy();

      expect(path.debugCachedStringLossy, isA<Some<String>>());
      expect(identical(path.toStringLossy(), result), isTrue);
    });
  });
}
