// Ported from `library/std/src/path/tests.rs`:
//
//   * `test_compare`
//   * `test_ord`
//
// Plus doc-comment assertions from `library/std/src/path.rs` for:
//
//   * `Path::starts_with`
//   * `Path::ends_with`
//   * `Path::strip_prefix`

import 'package:pathify/pathify.dart';
import 'package:test/test.dart';

import '_helpers.dart';

void main() {
  // ── test_compare (cross-platform) ───────────────────────────────────────

  group('test_compare (cross-platform)', () {
    usePosix();

    test('"" == ""', () {
      tc(
        path1: '',
        path2: '',
        eq: true,
        startsWith: true,
        endsWith: true,
        relativeFrom: '',
        isWindows: false,
      );
    });

    test('"foo" vs ""', () {
      tc(
        path1: 'foo',
        path2: '',
        eq: false,
        startsWith: true,
        endsWith: true,
        relativeFrom: 'foo',
        isWindows: false,
      );
    });

    test('"" vs "foo"', () {
      tc(
        path1: '',
        path2: 'foo',
        eq: false,
        startsWith: false,
        endsWith: false,
        relativeFromIsNone: true,
        isWindows: false,
      );
    });

    test('"foo" == "foo"', () {
      tc(
        path1: 'foo',
        path2: 'foo',
        eq: true,
        startsWith: true,
        endsWith: true,
        relativeFrom: '',
        isWindows: false,
      );
    });

    test('"foo/" == "foo"', () {
      tc(
        path1: 'foo/',
        path2: 'foo',
        eq: true,
        startsWith: true,
        endsWith: true,
        relativeFrom: '',
        isWindows: false,
      );
    });

    test('"foo//" == "foo"', () {
      tc(
        path1: 'foo//',
        path2: 'foo',
        eq: true,
        startsWith: true,
        endsWith: true,
        relativeFrom: '',
        isWindows: false,
      );
    });

    test('"foo///" == "foo"', () {
      tc(
        path1: 'foo///',
        path2: 'foo',
        eq: true,
        startsWith: true,
        endsWith: true,
        relativeFrom: '',
        isWindows: false,
      );
    });

    test('"foo/." == "foo"', () {
      tc(
        path1: 'foo/.',
        path2: 'foo',
        eq: true,
        startsWith: true,
        endsWith: true,
        relativeFrom: '',
        isWindows: false,
      );
    });

    test('"foo/./bar" == "foo/bar"', () {
      tc(
        path1: 'foo/./bar',
        path2: 'foo/bar',
        eq: true,
        startsWith: true,
        endsWith: true,
        relativeFrom: '',
        isWindows: false,
      );
    });

    test('"foo/.//bar" == "foo/bar"', () {
      tc(
        path1: 'foo/.//bar',
        path2: 'foo/bar',
        eq: true,
        startsWith: true,
        endsWith: true,
        relativeFrom: '',
        isWindows: false,
      );
    });

    test('"foo//./bar" == "foo/bar"', () {
      tc(
        path1: 'foo//./bar',
        path2: 'foo/bar',
        eq: true,
        startsWith: true,
        endsWith: true,
        relativeFrom: '',
        isWindows: false,
      );
    });

    test('"foo/bar" vs "foo"', () {
      tc(
        path1: 'foo/bar',
        path2: 'foo',
        eq: false,
        startsWith: true,
        endsWith: false,
        relativeFrom: 'bar',
        isWindows: false,
      );
    });

    test('"foo/bar" vs "foobar"', () {
      tc(
        path1: 'foo/bar',
        path2: 'foobar',
        eq: false,
        startsWith: false,
        endsWith: false,
        relativeFromIsNone: true,
        isWindows: false,
      );
    });

    test('"foo/bar/baz" vs "foo/bar"', () {
      tc(
        path1: 'foo/bar/baz',
        path2: 'foo/bar',
        eq: false,
        startsWith: true,
        endsWith: false,
        relativeFrom: 'baz',
        isWindows: false,
      );
    });

    test('"foo/bar" vs "foo/bar/baz"', () {
      tc(
        path1: 'foo/bar',
        path2: 'foo/bar/baz',
        eq: false,
        startsWith: false,
        endsWith: false,
        relativeFromIsNone: true,
        isWindows: false,
      );
    });

    test('"./foo/bar/" vs "."', () {
      tc(
        path1: './foo/bar/',
        path2: '.',
        eq: false,
        startsWith: true,
        endsWith: false,
        relativeFrom: 'foo/bar',
        isWindows: false,
      );
    });
  });

  // ── test_compare (Windows) ──────────────────────────────────────────────

  group('test_compare (Windows)', () {
    useWindows();

    test(r'"C:\src\rust\cargo-test\test\Cargo.toml" vs '
    r'"c:\src\rust\cargo-test\test"', () {
      tc(
        path1: r'C:\src\rust\cargo-test\test\Cargo.toml',
        path2: r'c:\src\rust\cargo-test\test',
        eq: false,
        startsWith: true,
        endsWith: false,
        relativeFrom: 'Cargo.toml',
        isWindows: true,
      );
    });

    test(r'"c:\foo" == "C:\foo"', () {
      tc(
        path1: r'c:\foo',
        path2: r'C:\foo',
        eq: true,
        startsWith: true,
        endsWith: true,
        relativeFrom: '',
        isWindows: true,
      );
    });

    test(r'"C:\foo\.\bar.txt" == "C:\foo\bar.txt"', () {
      tc(
        path1: r'C:\foo\.\bar.txt',
        path2: r'C:\foo\bar.txt',
        eq: true,
        startsWith: true,
        endsWith: true,
        relativeFrom: '',
        isWindows: true,
      );
    });

    test(r'"C:\foo\." == "C:\foo"', () {
      tc(
        path1: r'C:\foo\.',
        path2: r'C:\foo',
        eq: true,
        startsWith: true,
        endsWith: true,
        relativeFrom: '',
        isWindows: true,
      );
    });

    test(r'"\\?\C:\foo\.\bar.txt" vs "\\?\C:\foo\bar.txt"', () {
      tc(
        path1: r'\\?\C:\foo\.\bar.txt',
        path2: r'\\?\C:\foo\bar.txt',
        eq: false,
        startsWith: false,
        endsWith: false,
        relativeFromIsNone: true,
        isWindows: true,
      );
    });
  });

  // ── test_ord ─────────────────────────────────────────────────────────────
  //
  // Rust's `ord!` macro asserts cmp::Ordering. pathify lacks ordering, so we
  // assert only the equality-related half: Equal cases must be == AND have
  // matching hashes; non-Equal cases must be !=.

  group('test_ord (cross-platform)', () {
    usePosix();

    test('"1" != "2"', () {
      ordNotEqual(left: '1', right: '2', isWindows: false);
    });
    test('"/foo/bar" != "/foo./bar"', () {
      ordNotEqual(left: '/foo/bar', right: '/foo./bar', isWindows: false);
    });
    test('"foo/bar" != "foo/bar."', () {
      ordNotEqual(left: 'foo/bar', right: 'foo/bar.', isWindows: false);
    });
    test('"foo/./bar" == "foo/bar/"', () {
      ordEqual(left: 'foo/./bar', right: 'foo/bar/', isWindows: false);
    });
    test('"foo/bar" == "foo/bar/"', () {
      ordEqual(left: 'foo/bar', right: 'foo/bar/', isWindows: false);
    });
    test('"foo/bar" == "foo/bar/."', () {
      ordEqual(left: 'foo/bar', right: 'foo/bar/.', isWindows: false);
    });
    test('"foo/bar" == "foo/bar//"', () {
      ordEqual(left: 'foo/bar', right: 'foo/bar//', isWindows: false);
    });
  });

  // ── Path::starts_with doc-asserts ────────────────────────────────────────
  //
  // Rust source (path.rs):
  //
  //   let path = Path::new("/etc/passwd");
  //   assert!(path.starts_with("/etc"));
  //   assert!(path.starts_with("/etc/"));
  //   assert!(path.starts_with("/etc/passwd"));
  //   assert!(path.starts_with("/etc/passwd/"));
  //   assert!(path.starts_with("/etc/passwd///"));
  //   assert!(!path.starts_with("/e"));
  //   assert!(!path.starts_with("/etc/passwd.txt"));
  //   assert!(!Path::new("/etc/foo.rs").starts_with("/etc/foo"));

  group('Path::starts_with doc-asserts (POSIX)', () {
    usePosix();

    test('starts_with /etc', () {
      final p = PathBuf.fromBytes(b('/etc/passwd'));
      expect(p.startsWith(PathBuf.fromBytes(b('/etc'))), isTrue);
    });

    test('starts_with /etc/ (extra slash okay)', () {
      final p = PathBuf.fromBytes(b('/etc/passwd'));
      expect(p.startsWith(PathBuf.fromBytes(b('/etc/'))), isTrue);
    });

    test('starts_with /etc/passwd', () {
      final p = PathBuf.fromBytes(b('/etc/passwd'));
      expect(p.startsWith(PathBuf.fromBytes(b('/etc/passwd'))), isTrue);
    });

    test('starts_with /etc/passwd/ (extra slash okay)', () {
      final p = PathBuf.fromBytes(b('/etc/passwd'));
      expect(p.startsWith(PathBuf.fromBytes(b('/etc/passwd/'))), isTrue);
    });

    test('starts_with /etc/passwd/// (multiple extra slashes okay)', () {
      final p = PathBuf.fromBytes(b('/etc/passwd'));
      expect(p.startsWith(PathBuf.fromBytes(b('/etc/passwd///'))), isTrue);
    });

    test('does not start_with /e', () {
      final p = PathBuf.fromBytes(b('/etc/passwd'));
      expect(p.startsWith(PathBuf.fromBytes(b('/e'))), isFalse);
    });

    test('does not start_with /etc/passwd.txt', () {
      final p = PathBuf.fromBytes(b('/etc/passwd'));
      expect(p.startsWith(PathBuf.fromBytes(b('/etc/passwd.txt'))), isFalse);
    });

    test('/etc/foo.rs does not start_with /etc/foo', () {
      final p = PathBuf.fromBytes(b('/etc/foo.rs'));
      expect(p.startsWith(PathBuf.fromBytes(b('/etc/foo'))), isFalse);
    });
  });

  // ── Path::ends_with doc-asserts ──────────────────────────────────────────
  //
  // Rust source (path.rs):
  //
  //   let path = Path::new("/etc/resolv.conf");
  //   assert!(path.ends_with("resolv.conf"));
  //   assert!(path.ends_with("etc/resolv.conf"));
  //   assert!(path.ends_with("/etc/resolv.conf"));
  //   assert!(!path.ends_with("/resolv.conf"));
  //   assert!(!path.ends_with("conf"));

  group('Path::ends_with doc-asserts (POSIX)', () {
    usePosix();

    test('ends_with resolv.conf', () {
      final p = PathBuf.fromBytes(b('/etc/resolv.conf'));
      expect(p.endsWith(PathBuf.fromBytes(b('resolv.conf'))), isTrue);
    });

    test('ends_with etc/resolv.conf', () {
      final p = PathBuf.fromBytes(b('/etc/resolv.conf'));
      expect(p.endsWith(PathBuf.fromBytes(b('etc/resolv.conf'))), isTrue);
    });

    test('ends_with /etc/resolv.conf', () {
      final p = PathBuf.fromBytes(b('/etc/resolv.conf'));
      expect(p.endsWith(PathBuf.fromBytes(b('/etc/resolv.conf'))), isTrue);
    });

    test('does not end_with /resolv.conf', () {
      final p = PathBuf.fromBytes(b('/etc/resolv.conf'));
      expect(p.endsWith(PathBuf.fromBytes(b('/resolv.conf'))), isFalse);
    });

    test('does not end_with conf (partial component)', () {
      final p = PathBuf.fromBytes(b('/etc/resolv.conf'));
      expect(p.endsWith(PathBuf.fromBytes(b('conf'))), isFalse);
    });
  });

  // ── Path::strip_prefix doc-asserts ───────────────────────────────────────
  //
  // Rust source (path.rs):
  //
  //   let path = Path::new("/test/haha/foo.txt");
  //   assert_eq!(path.strip_prefix("/"),                  Ok(Path::new("test/haha/foo.txt")));
  //   assert_eq!(path.strip_prefix("/test"),              Ok(Path::new("haha/foo.txt")));
  //   assert_eq!(path.strip_prefix("/test/"),             Ok(Path::new("haha/foo.txt")));
  //   assert_eq!(path.strip_prefix("/test/haha/foo.txt"), Ok(Path::new("")));
  //   assert_eq!(path.strip_prefix("/test/haha/foo.txt/"),Ok(Path::new("")));
  //   assert!(path.strip_prefix("test").is_err());
  //   assert!(path.strip_prefix("/te").is_err());
  //   assert!(path.strip_prefix("/haha").is_err());

  group('Path::strip_prefix doc-asserts (POSIX)', () {
    usePosix();

    test('strip /', () {
      final p = PathBuf.fromBytes(b('/test/haha/foo.txt'));
      final out = p.stripPrefix(PathBuf.fromBytes(b('/')));
      expect(out, isNotNull);
      expect(pStr(out!), equals('test/haha/foo.txt'));
    });

    test('strip /test', () {
      final p = PathBuf.fromBytes(b('/test/haha/foo.txt'));
      final out = p.stripPrefix(PathBuf.fromBytes(b('/test')));
      expect(out, isNotNull);
      expect(pStr(out!), equals('haha/foo.txt'));
    });

    test('strip /test/', () {
      final p = PathBuf.fromBytes(b('/test/haha/foo.txt'));
      final out = p.stripPrefix(PathBuf.fromBytes(b('/test/')));
      expect(out, isNotNull);
      expect(pStr(out!), equals('haha/foo.txt'));
    });

    test('strip /test/haha/foo.txt', () {
      final p = PathBuf.fromBytes(b('/test/haha/foo.txt'));
      final out = p.stripPrefix(PathBuf.fromBytes(b('/test/haha/foo.txt')));
      expect(out, isNotNull);
      expect(pStr(out!), equals(''));
    });

    test('strip /test/haha/foo.txt/', () {
      final p = PathBuf.fromBytes(b('/test/haha/foo.txt'));
      final out = p.stripPrefix(PathBuf.fromBytes(b('/test/haha/foo.txt/')));
      expect(out, isNotNull);
      expect(pStr(out!), equals(''));
    });

    test('strip test (relative) returns null', () {
      final p = PathBuf.fromBytes(b('/test/haha/foo.txt'));
      expect(p.stripPrefix(PathBuf.fromBytes(b('test'))), isNull);
    });

    test('strip /te (partial component) returns null', () {
      final p = PathBuf.fromBytes(b('/test/haha/foo.txt'));
      expect(p.stripPrefix(PathBuf.fromBytes(b('/te'))), isNull);
    });

    test('strip /haha (not a prefix) returns null', () {
      final p = PathBuf.fromBytes(b('/test/haha/foo.txt'));
      expect(p.stripPrefix(PathBuf.fromBytes(b('/haha'))), isNull);
    });
  });
}
