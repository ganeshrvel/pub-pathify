// Ported from `library/std/src/path/tests.rs`:
//
//   * `test_stem_ext`
//   * `test_prefix_ext`
//
// Plus doc-comment assertions from `library/std/src/path.rs` for:
//
//   * `Path::file_name`
//   * `Path::parent`
//   * `Path::ancestors`
//   * `Path::is_empty`

import 'package:pathify/pathify.dart';
import 'package:test/test.dart';

import '_helpers.dart';

void main() {
  // ── test_stem_ext ────────────────────────────────────────────────────────

  group('test_stem_ext', () {
    usePosix();

    test('foo', () {
      t(
        path: 'foo',
        isWindows: false,
        fileStem: 'foo',
        extensionIsNone: true,
      );
    });

    test('foo.', () {
      t(
        path: 'foo.',
        isWindows: false,
        fileStem: 'foo',
        extension: '',
      );
    });

    test('.foo', () {
      t(
        path: '.foo',
        isWindows: false,
        fileStem: '.foo',
        extensionIsNone: true,
      );
    });

    test('foo.txt', () {
      t(
        path: 'foo.txt',
        isWindows: false,
        fileStem: 'foo',
        extension: 'txt',
      );
    });

    test('foo.bar.txt', () {
      t(
        path: 'foo.bar.txt',
        isWindows: false,
        fileStem: 'foo.bar',
        extension: 'txt',
      );
    });

    test('foo.bar.', () {
      t(
        path: 'foo.bar.',
        isWindows: false,
        fileStem: 'foo.bar',
        extension: '',
      );
    });

    test('. -> stem None ext None', () {
      t(
        path: '.',
        isWindows: false,
        fileStemIsNone: true,
        extensionIsNone: true,
      );
    });

    test('.. -> stem None ext None', () {
      t(
        path: '..',
        isWindows: false,
        fileStemIsNone: true,
        extensionIsNone: true,
      );
    });

    test('.x.y.z -> stem .x.y ext z', () {
      t(
        path: '.x.y.z',
        isWindows: false,
        fileStem: '.x.y',
        extension: 'z',
      );
    });

    test('..x.y.z -> stem ..x.y ext z', () {
      t(
        path: '..x.y.z',
        isWindows: false,
        fileStem: '..x.y',
        extension: 'z',
      );
    });

    test('empty -> stem None ext None', () {
      t(
        path: '',
        isWindows: false,
        fileStemIsNone: true,
        extensionIsNone: true,
      );
    });
  });

  // ── test_prefix_ext ──────────────────────────────────────────────────────

  group('test_prefix_ext', () {
    usePosix();

    test('foo', () {
      t(
        path: 'foo',
        isWindows: false,
        filePrefix: 'foo',
        extensionIsNone: true,
      );
    });

    test('foo.', () {
      t(
        path: 'foo.',
        isWindows: false,
        filePrefix: 'foo',
        extension: '',
      );
    });

    test('.foo', () {
      t(
        path: '.foo',
        isWindows: false,
        filePrefix: '.foo',
        extensionIsNone: true,
      );
    });

    test('foo.txt', () {
      t(
        path: 'foo.txt',
        isWindows: false,
        filePrefix: 'foo',
        extension: 'txt',
      );
    });

    test('foo.bar.txt -> prefix foo', () {
      t(
        path: 'foo.bar.txt',
        isWindows: false,
        filePrefix: 'foo',
        extension: 'txt',
      );
    });

    test('foo.bar. -> prefix foo', () {
      t(
        path: 'foo.bar.',
        isWindows: false,
        filePrefix: 'foo',
        extension: '',
      );
    });

    test('. -> prefix None ext None', () {
      t(
        path: '.',
        isWindows: false,
        filePrefixIsNone: true,
        extensionIsNone: true,
      );
    });

    test('.. -> prefix None ext None', () {
      t(
        path: '..',
        isWindows: false,
        filePrefixIsNone: true,
        extensionIsNone: true,
      );
    });

    test('.x.y.z -> prefix .x ext z', () {
      t(
        path: '.x.y.z',
        isWindows: false,
        filePrefix: '.x',
        extension: 'z',
      );
    });

    test('..x.y.z -> prefix . ext z', () {
      t(
        path: '..x.y.z',
        isWindows: false,
        filePrefix: '.',
        extension: 'z',
      );
    });

    test('empty -> prefix None ext None', () {
      t(
        path: '',
        isWindows: false,
        filePrefixIsNone: true,
        extensionIsNone: true,
      );
    });
  });

  // ── Path::file_name doc-asserts ──────────────────────────────────────────
  //
  // Rust source (path.rs):
  //
  //   assert_eq!(Some(OsStr::new("bin")),     Path::new("/usr/bin/").file_name());
  //   assert_eq!(Some(OsStr::new("foo.txt")), Path::new("tmp/foo.txt").file_name());
  //   assert_eq!(Some(OsStr::new("foo.txt")), Path::new("foo.txt/.").file_name());
  //   assert_eq!(Some(OsStr::new("foo.txt")), Path::new("foo.txt/.//").file_name());
  //   assert_eq!(None, Path::new("foo.txt/..").file_name());
  //   assert_eq!(None, Path::new("/").file_name());

  group('Path::file_name doc-asserts (POSIX)', () {
    usePosix();

    test('/usr/bin/ -> bin', () {
      final p = PathBuf.fromBytes(b('/usr/bin/'));
      final name = p.fileName();
      expect(name, isNotNull);
      expect(cuStr(name!), equals('bin'));
    });

    test('tmp/foo.txt -> foo.txt', () {
      final p = PathBuf.fromBytes(b('tmp/foo.txt'));
      final name = p.fileName();
      expect(name, isNotNull);
      expect(cuStr(name!), equals('foo.txt'));
    });

    test('foo.txt/. -> foo.txt', () {
      final p = PathBuf.fromBytes(b('foo.txt/.'));
      final name = p.fileName();
      expect(name, isNotNull);
      expect(cuStr(name!), equals('foo.txt'));
    });

    test('foo.txt/.// -> foo.txt', () {
      final p = PathBuf.fromBytes(b('foo.txt/.//'));
      final name = p.fileName();
      expect(name, isNotNull);
      expect(cuStr(name!), equals('foo.txt'));
    });

    test('foo.txt/.. -> None', () {
      final p = PathBuf.fromBytes(b('foo.txt/..'));
      expect(p.fileName(), isNull);
    });

    test('/ -> None', () {
      final p = PathBuf.fromBytes(b('/'));
      expect(p.fileName(), isNull);
    });
  });

  // ── Path::parent doc-asserts ─────────────────────────────────────────────
  //
  // Rust source (path.rs):
  //
  //   let path = Path::new("/foo/bar");
  //   let parent = path.parent().unwrap();
  //   assert_eq!(parent, Path::new("/foo"));
  //   let grand_parent = parent.parent().unwrap();
  //   assert_eq!(grand_parent, Path::new("/"));
  //   assert_eq!(grand_parent.parent(), None);
  //
  //   let relative_path = Path::new("foo/bar");
  //   let parent = relative_path.parent();
  //   assert_eq!(parent, Some(Path::new("foo")));
  //   let grand_parent = parent.and_then(Path::parent);
  //   assert_eq!(grand_parent, Some(Path::new("")));
  //   let great_grand_parent = grand_parent.and_then(Path::parent);
  //   assert_eq!(great_grand_parent, None);

  group('Path::parent doc-asserts (POSIX)', () {
    usePosix();

    test('/foo/bar -> /foo -> / -> None', () {
      final p = PathBuf.fromBytes(b('/foo/bar'));

      final parent = p.parent();
      expect(parent, isNotNull);
      expect(parent, equals(PathBuf.fromBytes(b('/foo'))));

      final grand = parent!.parent();
      expect(grand, isNotNull);
      expect(grand, equals(PathBuf.fromBytes(b('/'))));

      expect(grand!.parent(), isNull);
    });

    test('foo/bar -> foo -> "" -> None', () {
      final p = PathBuf.fromBytes(b('foo/bar'));

      final parent = p.parent();
      expect(parent, isNotNull);
      expect(parent, equals(PathBuf.fromBytes(b('foo'))));

      final grand = parent!.parent();
      expect(grand, isNotNull);
      expect(grand, equals(PathBuf.fromBytes(b(''))));

      expect(grand!.parent(), isNull);
    });
  });

  // ── Path::ancestors doc-asserts ──────────────────────────────────────────
  //
  // Rust source (path.rs):
  //
  //   let mut ancestors = Path::new("/foo/bar").ancestors();
  //   assert_eq!(ancestors.next(), Some(Path::new("/foo/bar")));
  //   assert_eq!(ancestors.next(), Some(Path::new("/foo")));
  //   assert_eq!(ancestors.next(), Some(Path::new("/")));
  //   assert_eq!(ancestors.next(), None);
  //
  //   let mut ancestors = Path::new("../foo/bar").ancestors();
  //   assert_eq!(ancestors.next(), Some(Path::new("../foo/bar")));
  //   assert_eq!(ancestors.next(), Some(Path::new("../foo")));
  //   assert_eq!(ancestors.next(), Some(Path::new("..")));
  //   assert_eq!(ancestors.next(), Some(Path::new("")));
  //   assert_eq!(ancestors.next(), None);

  group('Path::ancestors doc-asserts (POSIX)', () {
    usePosix();

    test('/foo/bar walks /foo/bar, /foo, /', () {
      final p = PathBuf.fromBytes(b('/foo/bar'));
      final list = p.ancestors().toList();
      expect(list, hasLength(3));
      expect(list[0], equals(PathBuf.fromBytes(b('/foo/bar'))));
      expect(list[1], equals(PathBuf.fromBytes(b('/foo'))));
      expect(list[2], equals(PathBuf.fromBytes(b('/'))));
    });

    test('../foo/bar walks ../foo/bar, ../foo, .., ""', () {
      final p = PathBuf.fromBytes(b('../foo/bar'));
      final list = p.ancestors().toList();
      expect(list, hasLength(4));
      expect(list[0], equals(PathBuf.fromBytes(b('../foo/bar'))));
      expect(list[1], equals(PathBuf.fromBytes(b('../foo'))));
      expect(list[2], equals(PathBuf.fromBytes(b('..'))));
      expect(list[3], equals(PathBuf.fromBytes(b(''))));
    });
  });

  // ── Path::is_empty doc-asserts ───────────────────────────────────────────
  //
  // Rust source (path.rs):
  //
  //   let path = Path::new("");   assert!(path.is_empty());
  //   let path = Path::new("foo");assert!(!path.is_empty());
  //   let path = Path::new("."); assert!(!path.is_empty());

  group('Path::is_empty doc-asserts (POSIX)', () {
    usePosix();

    test('"" is empty', () {
      expect(PathBuf.fromBytes(b('')).isEmpty, isTrue);
    });

    test('"foo" is not empty', () {
      expect(PathBuf.fromBytes(b('foo')).isEmpty, isFalse);
    });

    test('"." is not empty', () {
      expect(PathBuf.fromBytes(b('.')).isEmpty, isFalse);
    });
  });
}
