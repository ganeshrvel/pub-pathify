import 'dart:typed_data';

import 'package:option_result/option.dart';
import 'package:pathify/pathify.dart';
import 'package:test/test.dart';

void main() {
  // ── Helpers ────────────────────────────────────────────────────────────────

  void expectStrCachePopulated(PathBuf path) {
    expect(path.debugCachedStr, isA<Some<String?>>());
  }

  void expectLossyCachePopulated(PathBuf path) {
    expect(path.debugCachedStringLossy, isA<Some<String>>());
  }

  void expectCachePopulated(PathBuf path) {
    expectStrCachePopulated(path);
    expectLossyCachePopulated(path);
  }

  void expectCacheEmpty(PathBuf path) {
    expect(path.debugCachedStr, isA<None<String?>>());
    expect(path.debugCachedStringLossy, isA<None<String>>());
  }

  void populateCache(PathBuf path) {
    path.toStr();

    //ignore: cascade_invocations
    path.toStringLossy();
  }

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
  group('cache invalidation — push (relative)', () {
    test('push invalidates and reflects new path', () {
      final path = PathBuf.fromStr('/foo');
      populateCache(path);
      expectCachePopulated(path);

      path.push(PathBuf.fromStr('bar'));

      expectCacheEmpty(path);
      expect(path.toStr(), equals('/foo/bar'));
      expectStrCachePopulated(path);
      expect(path.toStringLossy(), equals('/foo/bar'));
      expectCachePopulated(path);
    });

    test('push with trailing sep on receiver', () {
      final path = PathBuf.fromStr('/foo/');
      populateCache(path);
      expectCachePopulated(path);

      path.push(PathBuf.fromStr('bar'));

      expectCacheEmpty(path);
      expect(path.toStr(), equals('/foo/bar'));
      expectStrCachePopulated(path);
      expect(path.toStringLossy(), equals('/foo/bar'));
      expectCachePopulated(path);
    });

    test('push multiple times invalidates each time', () {
      final path = PathBuf.fromStr('/foo');

      populateCache(path);
      expectCachePopulated(path);
      path.push(PathBuf.fromStr('bar'));
      expectCacheEmpty(path);
      expect(path.toStr(), equals('/foo/bar'));
      expectStrCachePopulated(path);
      expect(path.toStringLossy(), equals('/foo/bar'));
      expectCachePopulated(path);

      populateCache(path);
      expectCachePopulated(path);
      path.push(PathBuf.fromStr('baz'));
      expectCacheEmpty(path);
      expect(path.toStr(), equals('/foo/bar/baz'));
      expectStrCachePopulated(path);
      expect(path.toStringLossy(), equals('/foo/bar/baz'));
      expectCachePopulated(path);
    });
  });

  group('cache invalidation — push (absolute replace)', () {
    test('absolute push replaces path and invalidates cache', () {
      final path = PathBuf.fromStr('/foo/bar');
      populateCache(path);
      expectCachePopulated(path);

      path.push(PathBuf.fromStr('/baz'));

      expectCacheEmpty(path);
      expect(path.toStr(), equals('/baz'));
      expectStrCachePopulated(path);
      expect(path.toStringLossy(), equals('/baz'));
      expectCachePopulated(path);
    });

    test('absolute push over cached null-toStr path', () {
      final path = PathBuf.fromBytes(Uint8List.fromList([0xFF, 0xFE]));
      populateCache(path);
      expectCachePopulated(path);

      path.push(PathBuf.fromStr('/valid'));

      expectCacheEmpty(path);
      expect(path.toStr(), equals('/valid'));
      expectStrCachePopulated(path);
      expect(path.toStringLossy(), equals('/valid'));
      expectCachePopulated(path);
    });
  });

  group('cache invalidation — pop', () {
    test('pop invalidates and reflects parent path', () {
      final path = PathBuf.fromStr('/foo/bar');
      populateCache(path);
      expectCachePopulated(path);

      path.pop();

      expectCacheEmpty(path);
      expect(path.toStr(), equals('/foo'));
      expectStrCachePopulated(path);
      expect(path.toStringLossy(), equals('/foo'));
      expectCachePopulated(path);
    });

    test('pop on single component path', () {
      final path = PathBuf.fromStr('/foo');
      populateCache(path);
      expectCachePopulated(path);

      path.pop();

      expectCacheEmpty(path);
      expect(path.toStr(), equals('/'));
      expectStrCachePopulated(path);
      expect(path.toStringLossy(), equals('/'));
      expectCachePopulated(path);
    });

    test('pop returns false on root and does not invalidate cache', () {
      final path = PathBuf.fromStr('/');
      populateCache(path);
      expectCachePopulated(path);

      final result = path.pop();

      expect(result, isFalse);
      expectCachePopulated(path);
    });

    test('pop multiple times invalidates each time', () {
      final path = PathBuf.fromStr('/foo/bar/baz');

      populateCache(path);
      expectCachePopulated(path);
      path.pop();
      expectCacheEmpty(path);
      expect(path.toStr(), equals('/foo/bar'));
      expectStrCachePopulated(path);
      expect(path.toStringLossy(), equals('/foo/bar'));
      expectCachePopulated(path);

      populateCache(path);
      expectCachePopulated(path);
      path.pop();
      expectCacheEmpty(path);
      expect(path.toStr(), equals('/foo'));
      expectStrCachePopulated(path);
      expect(path.toStringLossy(), equals('/foo'));
      expectCachePopulated(path);
    });
  });

  group('cache invalidation — setFileName', () {
    test('setFileName invalidates and reflects new name', () {
      final path = PathBuf.fromStr('/foo/bar.txt');
      populateCache(path);
      expectCachePopulated(path);

      path.setFileName(PathBuf.fromStr('baz.txt').codeUnits);

      expectCacheEmpty(path);
      expect(path.toStr(), equals('/foo/baz.txt'));
      expectStrCachePopulated(path);
      expect(path.toStringLossy(), equals('/foo/baz.txt'));
      expectCachePopulated(path);
    });

    test('setFileName on path ending in separator', () {
      final path = PathBuf.fromStr('/foo/');
      populateCache(path);
      expectCachePopulated(path);

      path.setFileName(PathBuf.fromStr('bar.txt').codeUnits);

      expectCacheEmpty(path);
      expect(path.toStr(), equals('/bar.txt'));
      expectStrCachePopulated(path);
      expect(path.toStringLossy(), equals('/bar.txt'));
      expectCachePopulated(path);
    });

    test('setFileName called twice invalidates each time', () {
      final path = PathBuf.fromStr('/foo/bar.txt');

      populateCache(path);
      expectCachePopulated(path);
      path.setFileName(PathBuf.fromStr('baz.txt').codeUnits);
      expectCacheEmpty(path);
      expect(path.toStr(), equals('/foo/baz.txt'));
      expectStrCachePopulated(path);
      expect(path.toStringLossy(), equals('/foo/baz.txt'));
      expectCachePopulated(path);

      populateCache(path);
      expectCachePopulated(path);
      path.setFileName(PathBuf.fromStr('qux.txt').codeUnits);
      expectCacheEmpty(path);
      expect(path.toStr(), equals('/foo/qux.txt'));
      expectStrCachePopulated(path);
      expect(path.toStringLossy(), equals('/foo/qux.txt'));
      expectCachePopulated(path);
    });
  });

  group('cache invalidation — setExtension', () {
    test('setExtension invalidates and reflects new extension', () {
      final path = PathBuf.fromStr('/foo/bar.txt');
      populateCache(path);
      expectCachePopulated(path);

      path.setExtension(PathBuf.fromStr('md').codeUnits);

      expectCacheEmpty(path);
      expect(path.toStr(), equals('/foo/bar.md'));
      expectStrCachePopulated(path);
      expect(path.toStringLossy(), equals('/foo/bar.md'));
      expectCachePopulated(path);
    });

    test('setExtension with empty extension removes extension', () {
      final path = PathBuf.fromStr('/foo/bar.txt');
      populateCache(path);
      expectCachePopulated(path);

      path.setExtension(PathBuf.empty().codeUnits);

      expectCacheEmpty(path);
      expect(path.toStr(), equals('/foo/bar'));
      expectStrCachePopulated(path);
      expect(path.toStringLossy(), equals('/foo/bar'));
      expectCachePopulated(path);
    });

    test('setExtension called twice invalidates each time', () {
      final path = PathBuf.fromStr('/foo/bar.txt');

      populateCache(path);
      expectCachePopulated(path);
      path.setExtension(PathBuf.fromStr('md').codeUnits);
      expectCacheEmpty(path);
      expect(path.toStr(), equals('/foo/bar.md'));
      expectStrCachePopulated(path);
      expect(path.toStringLossy(), equals('/foo/bar.md'));
      expectCachePopulated(path);

      populateCache(path);
      expectCachePopulated(path);
      path.setExtension(PathBuf.fromStr('rs').codeUnits);
      expectCacheEmpty(path);
      expect(path.toStr(), equals('/foo/bar.rs'));
      expectStrCachePopulated(path);
      expect(path.toStringLossy(), equals('/foo/bar.rs'));
      expectCachePopulated(path);
    });

    test(
      'setExtension returns false on path with no fileName, cache unchanged',
      () {
        final path = PathBuf.fromStr('/');
        populateCache(path);
        expectCachePopulated(path);

        final result = path.setExtension(PathBuf.fromStr('md').codeUnits);

        expect(result, isFalse);
        expectCachePopulated(path);
      },
    );
  });

  group('cache invalidation — addExtension', () {
    test('addExtension invalidates and reflects appended extension', () {
      final path = PathBuf.fromStr('/foo/bar.txt');
      populateCache(path);
      expectCachePopulated(path);

      path.addExtension(PathBuf.fromStr('gz').codeUnits);

      expectCacheEmpty(path);
      expect(path.toStr(), equals('/foo/bar.txt.gz'));
      expectStrCachePopulated(path);
      expect(path.toStringLossy(), equals('/foo/bar.txt.gz'));
      expectCachePopulated(path);
    });

    test('addExtension called twice invalidates each time', () {
      final path = PathBuf.fromStr('/foo/bar');

      populateCache(path);
      expectCachePopulated(path);
      path.addExtension(PathBuf.fromStr('txt').codeUnits);
      expectCacheEmpty(path);
      expect(path.toStr(), equals('/foo/bar.txt'));
      expectStrCachePopulated(path);
      expect(path.toStringLossy(), equals('/foo/bar.txt'));
      expectCachePopulated(path);

      populateCache(path);
      expectCachePopulated(path);
      path.addExtension(PathBuf.fromStr('gz').codeUnits);
      expectCacheEmpty(path);
      expect(path.toStr(), equals('/foo/bar.txt.gz'));
      expectStrCachePopulated(path);
      expect(path.toStringLossy(), equals('/foo/bar.txt.gz'));
      expectCachePopulated(path);
    });

    test(
      'addExtension returns false on path with no fileName, cache unchanged',
      () {
        final path = PathBuf.fromStr('/');
        populateCache(path);
        expectCachePopulated(path);

        final result = path.addExtension(PathBuf.fromStr('gz').codeUnits);

        expect(result, isFalse);
        expectCachePopulated(path);
      },
    );
  });

  group('cache invalidation — clear', () {
    test('clear invalidates and path becomes empty', () {
      final path = PathBuf.fromStr('/foo/bar');
      populateCache(path);
      expectCachePopulated(path);

      path.clear();

      expectCacheEmpty(path);
      expect(path.toStr(), equals(''));
      expectStrCachePopulated(path);
      expect(path.toStringLossy(), equals(''));
      expectCachePopulated(path);
    });

    test('clear on already empty path invalidates cache', () {
      final path = PathBuf.empty();
      populateCache(path);
      expectCachePopulated(path);

      path.clear();

      expectCacheEmpty(path);
      expect(path.toStr(), equals(''));
      expectStrCachePopulated(path);
      expect(path.toStringLossy(), equals(''));
      expectCachePopulated(path);
    });
  });

  group('cache invalidation — combined mutation sequences', () {
    test('push then pop restores original path with fresh cache', () {
      final path = PathBuf.fromStr('/foo');
      populateCache(path);
      expectCachePopulated(path);

      path.push(PathBuf.fromStr('bar'));
      expectCacheEmpty(path);
      expect(path.toStr(), equals('/foo/bar'));
      expectStrCachePopulated(path);
      expect(path.toStringLossy(), equals('/foo/bar'));
      expectCachePopulated(path);

      populateCache(path);
      expectCachePopulated(path);
      path.pop();
      expectCacheEmpty(path);
      expect(path.toStr(), equals('/foo'));
      expectStrCachePopulated(path);
      expect(path.toStringLossy(), equals('/foo'));
      expectCachePopulated(path);
    });

    test('setFileName then setExtension invalidates each time', () {
      final path = PathBuf.fromStr('/foo/bar.txt');

      populateCache(path);
      expectCachePopulated(path);
      path.setFileName(PathBuf.fromStr('baz.txt').codeUnits);
      expectCacheEmpty(path);
      expect(path.toStr(), equals('/foo/baz.txt'));
      expectStrCachePopulated(path);
      expect(path.toStringLossy(), equals('/foo/baz.txt'));
      expectCachePopulated(path);

      populateCache(path);
      expectCachePopulated(path);
      path.setExtension(PathBuf.fromStr('md').codeUnits);
      expectCacheEmpty(path);
      expect(path.toStr(), equals('/foo/baz.md'));
      expectStrCachePopulated(path);
      expect(path.toStringLossy(), equals('/foo/baz.md'));
      expectCachePopulated(path);
    });

    test('push then clear invalidates each time', () {
      final path = PathBuf.fromStr('/foo');

      populateCache(path);
      expectCachePopulated(path);
      path.push(PathBuf.fromStr('bar'));
      expectCacheEmpty(path);
      expect(path.toStr(), equals('/foo/bar'));
      expectStrCachePopulated(path);
      expect(path.toStringLossy(), equals('/foo/bar'));
      expectCachePopulated(path);

      populateCache(path);
      expectCachePopulated(path);
      path.clear();
      expectCacheEmpty(path);
      expect(path.toStr(), equals(''));
      expectStrCachePopulated(path);
      expect(path.toStringLossy(), equals(''));
      expectCachePopulated(path);
    });

    test(
      'toStr and toStringLossy stay consistent through mutation sequence',
      () {
        final path = PathBuf.fromStr('/foo')..push(PathBuf.fromStr('bar'));
        expect(path.toStr(), equals(path.toStringLossy()));

        path.push(PathBuf.fromStr('baz'));
        expect(path.toStr(), equals(path.toStringLossy()));

        path.pop();
        expect(path.toStr(), equals(path.toStringLossy()));

        path.setExtension(PathBuf.fromStr('txt').codeUnits);
        expect(path.toStr(), equals(path.toStringLossy()));
      },
    );

    test('addExtension then setExtension invalidates each time', () {
      final path = PathBuf.fromStr('/foo/bar');

      populateCache(path);
      expectCachePopulated(path);
      path.addExtension(PathBuf.fromStr('txt').codeUnits);
      expectCacheEmpty(path);
      expect(path.toStr(), equals('/foo/bar.txt'));
      expectStrCachePopulated(path);
      expect(path.toStringLossy(), equals('/foo/bar.txt'));
      expectCachePopulated(path);

      populateCache(path);
      expectCachePopulated(path);
      path.setExtension(PathBuf.fromStr('md').codeUnits);
      expectCacheEmpty(path);
      expect(path.toStr(), equals('/foo/bar.md'));
      expectStrCachePopulated(path);
      expect(path.toStringLossy(), equals('/foo/bar.md'));
      expectCachePopulated(path);
    });

    test('clear then push starts fresh', () {
      final path = PathBuf.fromStr('/foo/bar');

      populateCache(path);
      expectCachePopulated(path);
      path.clear();
      expectCacheEmpty(path);

      path.push(PathBuf.fromStr('/new/path'));
      expectCacheEmpty(path);
      expect(path.toStr(), equals('/new/path'));
      expectStrCachePopulated(path);
      expect(path.toStringLossy(), equals('/new/path'));
      expectCachePopulated(path);
    });
  });
}
