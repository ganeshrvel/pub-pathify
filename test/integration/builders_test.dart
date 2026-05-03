// Ported from `library/std/src/path/tests.rs`:
//
//   * `test_with_extension`
//   * `test_with_added_extension`
//
// Plus doc-comment assertions from `library/std/src/path.rs` for:
//
//   * `Path::with_file_name`
//   * `Path::join`

import 'package:pathify/pathify.dart';
import 'package:test/test.dart';

import '_helpers.dart';

void main() {
  // ── test_with_extension ─────────────────────────────────────────────────

  group('test_with_extension', () {
    usePosix();

    test('foo -> txt', () {
      twe(input: 'foo', ext: 'txt', expected: 'foo.txt', isWindows: false);
    });
    test('foo.bar -> txt', () {
      twe(
        input: 'foo.bar',
        ext: 'txt',
        expected: 'foo.txt',
        isWindows: false,
      );
    });
    test('foo.bar.baz -> txt', () {
      twe(
        input: 'foo.bar.baz',
        ext: 'txt',
        expected: 'foo.bar.txt',
        isWindows: false,
      );
    });
    test('.test -> txt', () {
      twe(
        input: '.test',
        ext: 'txt',
        expected: '.test.txt',
        isWindows: false,
      );
    });
    test('foo.txt -> empty', () {
      twe(input: 'foo.txt', ext: '', expected: 'foo', isWindows: false);
    });
    test('foo -> empty', () {
      twe(input: 'foo', ext: '', expected: 'foo', isWindows: false);
    });
    test('empty -> foo', () {
      twe(input: '', ext: 'foo', expected: '', isWindows: false);
    });
    test('. -> foo', () {
      twe(input: '.', ext: 'foo', expected: '.', isWindows: false);
    });
    test('foo/ -> bar', () {
      twe(input: 'foo/', ext: 'bar', expected: 'foo.bar', isWindows: false);
    });
    test('foo/. -> bar', () {
      twe(input: 'foo/.', ext: 'bar', expected: 'foo.bar', isWindows: false);
    });
    test('.. -> foo', () {
      twe(input: '..', ext: 'foo', expected: '..', isWindows: false);
    });
    test('foo/.. -> bar', () {
      twe(input: 'foo/..', ext: 'bar', expected: 'foo/..', isWindows: false);
    });
    test('/ -> foo', () {
      twe(input: '/', ext: 'foo', expected: '/', isWindows: false);
    });

    // New extension is smaller than file name
    test('aaa_aaa_aaa -> bbb_bbb', () {
      twe(
        input: 'aaa_aaa_aaa',
        ext: 'bbb_bbb',
        expected: 'aaa_aaa_aaa.bbb_bbb',
        isWindows: false,
      );
    });
    // New extension is greater than file name
    test('bbb_bbb -> aaa_aaa_aaa', () {
      twe(
        input: 'bbb_bbb',
        ext: 'aaa_aaa_aaa',
        expected: 'bbb_bbb.aaa_aaa_aaa',
        isWindows: false,
      );
    });

    // New extension is smaller than previous extension
    test('ccc.aaa_aaa_aaa -> bbb_bbb', () {
      twe(
        input: 'ccc.aaa_aaa_aaa',
        ext: 'bbb_bbb',
        expected: 'ccc.bbb_bbb',
        isWindows: false,
      );
    });
    // New extension is greater than previous extension
    test('ccc.bbb_bbb -> aaa_aaa_aaa', () {
      twe(
        input: 'ccc.bbb_bbb',
        ext: 'aaa_aaa_aaa',
        expected: 'ccc.aaa_aaa_aaa',
        isWindows: false,
      );
    });
  });

  // ── test_with_added_extension ───────────────────────────────────────────

  group('test_with_added_extension', () {
    usePosix();

    test('foo -> txt', () {
      tweAdd(input: 'foo', ext: 'txt', expected: 'foo.txt', isWindows: false);
    });
    test('foo.bar -> txt', () {
      tweAdd(
        input: 'foo.bar',
        ext: 'txt',
        expected: 'foo.bar.txt',
        isWindows: false,
      );
    });
    test('foo.bar.baz -> txt', () {
      tweAdd(
        input: 'foo.bar.baz',
        ext: 'txt',
        expected: 'foo.bar.baz.txt',
        isWindows: false,
      );
    });
    test('.test -> txt', () {
      tweAdd(
        input: '.test',
        ext: 'txt',
        expected: '.test.txt',
        isWindows: false,
      );
    });
    test('foo.txt -> empty', () {
      tweAdd(
        input: 'foo.txt',
        ext: '',
        expected: 'foo.txt',
        isWindows: false,
      );
    });
    test('foo -> empty', () {
      tweAdd(input: 'foo', ext: '', expected: 'foo', isWindows: false);
    });
    test('empty -> foo', () {
      tweAdd(input: '', ext: 'foo', expected: '', isWindows: false);
    });
    test('. -> foo', () {
      tweAdd(input: '.', ext: 'foo', expected: '.', isWindows: false);
    });
    test('foo/ -> bar', () {
      tweAdd(
        input: 'foo/',
        ext: 'bar',
        expected: 'foo.bar',
        isWindows: false,
      );
    });
    test('foo/. -> bar', () {
      tweAdd(
        input: 'foo/.',
        ext: 'bar',
        expected: 'foo.bar',
        isWindows: false,
      );
    });
    test('.. -> foo', () {
      tweAdd(input: '..', ext: 'foo', expected: '..', isWindows: false);
    });
    test('foo/.. -> bar', () {
      tweAdd(
        input: 'foo/..',
        ext: 'bar',
        expected: 'foo/..',
        isWindows: false,
      );
    });
    test('/ -> foo', () {
      tweAdd(input: '/', ext: 'foo', expected: '/', isWindows: false);
    });

    // edge case
    test('/foo.ext//// -> bar', () {
      tweAdd(
        input: '/foo.ext////',
        ext: 'bar',
        expected: '/foo.ext.bar',
        isWindows: false,
      );
    });

    // New extension is smaller than file name
    test('aaa_aaa_aaa -> bbb_bbb', () {
      tweAdd(
        input: 'aaa_aaa_aaa',
        ext: 'bbb_bbb',
        expected: 'aaa_aaa_aaa.bbb_bbb',
        isWindows: false,
      );
    });
    // New extension is greater than file name
    test('bbb_bbb -> aaa_aaa_aaa', () {
      tweAdd(
        input: 'bbb_bbb',
        ext: 'aaa_aaa_aaa',
        expected: 'bbb_bbb.aaa_aaa_aaa',
        isWindows: false,
      );
    });

    // New extension is smaller than previous extension
    test('ccc.aaa_aaa_aaa -> bbb_bbb', () {
      tweAdd(
        input: 'ccc.aaa_aaa_aaa',
        ext: 'bbb_bbb',
        expected: 'ccc.aaa_aaa_aaa.bbb_bbb',
        isWindows: false,
      );
    });
    // New extension is greater than previous extension
    test('ccc.bbb_bbb -> aaa_aaa_aaa', () {
      tweAdd(
        input: 'ccc.bbb_bbb',
        ext: 'aaa_aaa_aaa',
        expected: 'ccc.bbb_bbb.aaa_aaa_aaa',
        isWindows: false,
      );
    });
  });

  // ── Path::with_file_name doc-asserts ─────────────────────────────────────
  //
  // Rust source (path.rs):
  //
  //   let path = Path::new("/tmp/foo.png");
  //   assert_eq!(path.with_file_name("bar"),    PathBuf::from("/tmp/bar"));
  //   assert_eq!(path.with_file_name("bar.txt"),PathBuf::from("/tmp/bar.txt"));
  //
  //   let path = Path::new("/tmp");
  //   assert_eq!(path.with_file_name("var"),    PathBuf::from("/var"));

  group('Path::with_file_name doc-asserts (POSIX)', () {
    usePosix();

    test('/tmp/foo.png -> bar', () {
      final p = PathBuf.fromBytes(b('/tmp/foo.png'));
      final out = p.withFileName(cuN('bar'));
      expect(pStr(out), equals('/tmp/bar'));
    });

    test('/tmp/foo.png -> bar.txt', () {
      final p = PathBuf.fromBytes(b('/tmp/foo.png'));
      final out = p.withFileName(cuN('bar.txt'));
      expect(pStr(out), equals('/tmp/bar.txt'));
    });

    test('/tmp -> var', () {
      final p = PathBuf.fromBytes(b('/tmp'));
      final out = p.withFileName(cuN('var'));
      expect(pStr(out), equals('/var'));
    });
  });

  // ── Path::join doc-asserts ───────────────────────────────────────────────
  //
  // Rust source (path.rs):
  //
  //   assert_eq!(Path::new("/etc").join("passwd"), PathBuf::from("/etc/passwd"));
  //   assert_eq!(Path::new("/etc").join("/bin/sh"), PathBuf::from("/bin/sh"));

  group('Path::join doc-asserts (POSIX)', () {
    usePosix();

    test('/etc + passwd', () {
      final base = PathBuf.fromBytes(b('/etc'));
      final out = base.join(PathBuf.fromBytes(b('passwd')));
      expect(pStr(out), equals('/etc/passwd'));
    });

    test('/etc + /bin/sh', () {
      final base = PathBuf.fromBytes(b('/etc'));
      final out = base.join(PathBuf.fromBytes(b('/bin/sh')));
      expect(pStr(out), equals('/bin/sh'));
    });
  });
}
