// Ported from `library/std/src/path/tests.rs`:
//
//   * `test_push`
//   * `test_pop`
//   * `test_set_file_name`
//   * `test_set_extension`
//   * `test_add_extension`

import 'package:test/test.dart';

import '_helpers.dart';

void main() {
  group('test_push (POSIX)', () {
    usePosix();

    test('empty + foo', () {
      tp(path: '', push: 'foo', expected: 'foo', isWindows: false);
    });
    test('foo + bar', () {
      tp(path: 'foo', push: 'bar', expected: 'foo/bar', isWindows: false);
    });
    test('foo/ + bar', () {
      tp(path: 'foo/', push: 'bar', expected: 'foo/bar', isWindows: false);
    });
    test('foo// + bar', () {
      tp(path: 'foo//', push: 'bar', expected: 'foo//bar', isWindows: false);
    });
    test('foo/. + bar', () {
      tp(path: 'foo/.', push: 'bar', expected: 'foo/./bar', isWindows: false);
    });
    test('foo./. + bar', () {
      tp(path: 'foo./.', push: 'bar', expected: 'foo././bar', isWindows: false);
    });
    test('foo + empty', () {
      tp(path: 'foo', push: '', expected: 'foo/', isWindows: false);
    });
    test('foo + .', () {
      tp(path: 'foo', push: '.', expected: 'foo/.', isWindows: false);
    });
    test('foo + ..', () {
      tp(path: 'foo', push: '..', expected: 'foo/..', isWindows: false);
    });
    test('foo + /', () {
      tp(path: 'foo', push: '/', expected: '/', isWindows: false);
    });
    test('/foo/bar + /', () {
      tp(path: '/foo/bar', push: '/', expected: '/', isWindows: false);
    });
    test('/foo/bar + /baz', () {
      tp(path: '/foo/bar', push: '/baz', expected: '/baz', isWindows: false);
    });
    test('/foo/bar + ./baz', () {
      tp(
        path: '/foo/bar',
        push: './baz',
        expected: '/foo/bar/./baz',
        isWindows: false,
      );
    });
  });

  group('test_push (Windows)', () {
    useWindows();

    test('empty + foo', () {
      tp(path: '', push: 'foo', expected: 'foo', isWindows: true);
    });
    test('foo + bar', () {
      tp(path: 'foo', push: 'bar', expected: r'foo\bar', isWindows: true);
    });
    test('foo/ + bar', () {
      tp(path: 'foo/', push: 'bar', expected: 'foo/bar', isWindows: true);
    });
    test(r'foo\ + bar', () {
      tp(path: r'foo\', push: 'bar', expected: r'foo\bar', isWindows: true);
    });
    test('foo// + bar', () {
      tp(path: 'foo//', push: 'bar', expected: 'foo//bar', isWindows: true);
    });
    test(r'foo\\ + bar', () {
      tp(path: r'foo\\', push: 'bar', expected: r'foo\\bar', isWindows: true);
    });
    test('foo/. + bar', () {
      tp(path: 'foo/.', push: 'bar', expected: r'foo/.\bar', isWindows: true);
    });
    test('foo./. + bar', () {
      tp(
        path: 'foo./.',
        push: 'bar',
        expected: r'foo./.\bar',
        isWindows: true,
      );
    });
    test(r'foo\. + bar', () {
      tp(path: r'foo\.', push: 'bar', expected: r'foo\.\bar', isWindows: true);
    });
    test(r'foo.\. + bar', () {
      tp(
        path: r'foo.\.',
        push: 'bar',
        expected: r'foo.\.\bar',
        isWindows: true,
      );
    });
    test('foo + empty', () {
      tp(path: 'foo', push: '', expected: r'foo\', isWindows: true);
    });
    test('foo + .', () {
      tp(path: 'foo', push: '.', expected: r'foo\.', isWindows: true);
    });
    test('foo + ..', () {
      tp(path: 'foo', push: '..', expected: r'foo\..', isWindows: true);
    });
    test('foo + /', () {
      tp(path: 'foo', push: '/', expected: '/', isWindows: true);
    });
    test(r'foo + \', () {
      tp(path: 'foo', push: r'\', expected: r'\', isWindows: true);
    });
    test('/foo/bar + /', () {
      tp(path: '/foo/bar', push: '/', expected: '/', isWindows: true);
    });
    test(r'\foo\bar + \', () {
      tp(path: r'\foo\bar', push: r'\', expected: r'\', isWindows: true);
    });
    test('/foo/bar + /baz', () {
      tp(path: '/foo/bar', push: '/baz', expected: '/baz', isWindows: true);
    });
    test(r'/foo/bar + \baz', () {
      tp(path: '/foo/bar', push: r'\baz', expected: r'\baz', isWindows: true);
    });
    test('/foo/bar + ./baz', () {
      tp(
        path: '/foo/bar',
        push: './baz',
        expected: r'/foo/bar\./baz',
        isWindows: true,
      );
    });
    test(r'/foo/bar + .\baz', () {
      tp(
        path: '/foo/bar',
        push: r'.\baz',
        expected: r'/foo/bar\.\baz',
        isWindows: true,
      );
    });

    test(r'c:\ + windows', () {
      tp(
        path: r'c:\',
        push: 'windows',
        expected: r'c:\windows',
        isWindows: true,
      );
    });
    test('c: + windows', () {
      tp(path: 'c:', push: 'windows', expected: 'c:windows', isWindows: true);
    });

    test(r'a\b\c + d', () {
      tp(
        path: r'a\b\c',
        push: 'd',
        expected: r'a\b\c\d',
        isWindows: true,
      );
    });
    test(r'\a\b\c + d', () {
      tp(
        path: r'\a\b\c',
        push: 'd',
        expected: r'\a\b\c\d',
        isWindows: true,
      );
    });
    test(r'a\b + c\d', () {
      tp(
        path: r'a\b',
        push: r'c\d',
        expected: r'a\b\c\d',
        isWindows: true,
      );
    });
    test(r'a\b + \c\d', () {
      tp(
        path: r'a\b',
        push: r'\c\d',
        expected: r'\c\d',
        isWindows: true,
      );
    });
    test(r'a\b + .', () {
      tp(path: r'a\b', push: '.', expected: r'a\b\.', isWindows: true);
    });
    test(r'a\b + ..\c', () {
      tp(
        path: r'a\b',
        push: r'..\c',
        expected: r'a\b\..\c',
        isWindows: true,
      );
    });
    test(r'a\b + C:a.txt', () {
      tp(
        path: r'a\b',
        push: 'C:a.txt',
        expected: 'C:a.txt',
        isWindows: true,
      );
    });
    test(r'a\b + C:\a.txt', () {
      tp(
        path: r'a\b',
        push: r'C:\a.txt',
        expected: r'C:\a.txt',
        isWindows: true,
      );
    });
    test(r'C:\a + C:\b.txt', () {
      tp(
        path: r'C:\a',
        push: r'C:\b.txt',
        expected: r'C:\b.txt',
        isWindows: true,
      );
    });
    test(r'C:\a\b\c + C:d', () {
      tp(
        path: r'C:\a\b\c',
        push: 'C:d',
        expected: 'C:d',
        isWindows: true,
      );
    });
    test(r'C:a\b\c + C:d', () {
      tp(
        path: r'C:a\b\c',
        push: 'C:d',
        expected: 'C:d',
        isWindows: true,
      );
    });
    test(r'C: + a\b\c', () {
      tp(
        path: 'C:',
        push: r'a\b\c',
        expected: r'C:a\b\c',
        isWindows: true,
      );
    });
    test(r'C: + ..\a', () {
      tp(path: 'C:', push: r'..\a', expected: r'C:..\a', isWindows: true);
    });
    test(r'\\server\share\foo + bar', () {
      tp(
        path: r'\\server\share\foo',
        push: 'bar',
        expected: r'\\server\share\foo\bar',
        isWindows: true,
      );
    });
    test(r'\\server\share\foo + C:baz', () {
      tp(
        path: r'\\server\share\foo',
        push: 'C:baz',
        expected: 'C:baz',
        isWindows: true,
      );
    });
    test(r'\\?\C:\a\b + C:c\d', () {
      tp(
        path: r'\\?\C:\a\b',
        push: r'C:c\d',
        expected: r'C:c\d',
        isWindows: true,
      );
    });
    test(r'\\?\C:a\b + C:c\d', () {
      tp(
        path: r'\\?\C:a\b',
        push: r'C:c\d',
        expected: r'C:c\d',
        isWindows: true,
      );
    });
    test(r'\\?\C:\a\b + C:\c\d', () {
      tp(
        path: r'\\?\C:\a\b',
        push: r'C:\c\d',
        expected: r'C:\c\d',
        isWindows: true,
      );
    });
    test(r'\\?\foo\bar + baz', () {
      tp(
        path: r'\\?\foo\bar',
        push: 'baz',
        expected: r'\\?\foo\bar\baz',
        isWindows: true,
      );
    });
    test(r'\\?\UNC\server\share\foo + bar', () {
      tp(
        path: r'\\?\UNC\server\share\foo',
        push: 'bar',
        expected: r'\\?\UNC\server\share\foo\bar',
        isWindows: true,
      );
    });
    test(r'\\?\UNC\server\share + C:\a', () {
      tp(
        path: r'\\?\UNC\server\share',
        push: r'C:\a',
        expected: r'C:\a',
        isWindows: true,
      );
    });
    test(r'\\?\UNC\server\share + C:a', () {
      tp(
        path: r'\\?\UNC\server\share',
        push: 'C:a',
        expected: 'C:a',
        isWindows: true,
      );
    });

    test(r'\\?\UNC\server + foo', () {
      tp(
        path: r'\\?\UNC\server',
        push: 'foo',
        expected: r'\\?\UNC\server\foo',
        isWindows: true,
      );
    });

    test(r'C:\a + \\?\UNC\server\share', () {
      tp(
        path: r'C:\a',
        push: r'\\?\UNC\server\share',
        expected: r'\\?\UNC\server\share',
        isWindows: true,
      );
    });
    test(r'\\.\foo\bar + baz', () {
      tp(
        path: r'\\.\foo\bar',
        push: 'baz',
        expected: r'\\.\foo\bar\baz',
        isWindows: true,
      );
    });
    test(r'\\.\foo\bar + C:a', () {
      tp(
        path: r'\\.\foo\bar',
        push: 'C:a',
        expected: 'C:a',
        isWindows: true,
      );
    });
    test(r'\\.\foo + ..\bar', () {
      tp(
        path: r'\\.\foo',
        push: r'..\bar',
        expected: r'\\.\foo\..\bar',
        isWindows: true,
      );
    });

    test(r'\\?\C: + foo', () {
      tp(
        path: r'\\?\C:',
        push: 'foo',
        expected: r'\\?\C:\foo',
        isWindows: true,
      );
    });

    test(r'\\?\C:\bar + ../foo', () {
      tp(
        path: r'\\?\C:\bar',
        push: '../foo',
        expected: r'\\?\C:\foo',
        isWindows: true,
      );
    });
    test(r'\\?\C:\bar + ../../foo', () {
      tp(
        path: r'\\?\C:\bar',
        push: '../../foo',
        expected: r'\\?\C:\foo',
        isWindows: true,
      );
    });
    test(r'\\?\C:\ + ../foo', () {
      tp(
        path: r'\\?\C:\',
        push: '../foo',
        expected: r'\\?\C:\foo',
        isWindows: true,
      );
    });
    test(r'\\?\C: + D:\foo/./', () {
      tp(
        path: r'\\?\C:',
        push: r'D:\foo/./',
        expected: r'D:\foo/./',
        isWindows: true,
      );
    });
    test(r'\\?\C: + \\?\D:\foo\.\', () {
      tp(
        path: r'\\?\C:',
        push: r'\\?\D:\foo\.\',
        expected: r'\\?\D:\foo\.\',
        isWindows: true,
      );
    });
    test(r'\\?\A:\x\y + /foo', () {
      tp(
        path: r'\\?\A:\x\y',
        push: '/foo',
        expected: r'\\?\A:\foo',
        isWindows: true,
      );
    });
    test(r'\\?\A: + ..\foo\.', () {
      tp(
        path: r'\\?\A:',
        push: r'..\foo\.',
        expected: r'\\?\A:\foo',
        isWindows: true,
      );
    });
    test(r'\\?\A:\x\y + .\foo\.', () {
      tp(
        path: r'\\?\A:\x\y',
        push: r'.\foo\.',
        expected: r'\\?\A:\x\y\foo',
        isWindows: true,
      );
    });
    test(r'\\?\A:\x\y + empty', () {
      tp(
        path: r'\\?\A:\x\y',
        push: '',
        expected: r'\\?\A:\x\y\',
        isWindows: true,
      );
    });
  });

  // ── test_pop ────────────────────────────────────────────────────────────

  group('test_pop (cross-platform)', () {
    usePosix();

    test('empty', () {
      tpop(path: '', expected: '', output: false, isWindows: false);
    });
    test('/', () {
      tpop(path: '/', expected: '/', output: false, isWindows: false);
    });
    test('foo', () {
      tpop(path: 'foo', expected: '', output: true, isWindows: false);
    });
    test('.', () {
      tpop(path: '.', expected: '', output: true, isWindows: false);
    });
    test('/foo', () {
      tpop(path: '/foo', expected: '/', output: true, isWindows: false);
    });
    test('/foo/bar', () {
      tpop(path: '/foo/bar', expected: '/foo', output: true, isWindows: false);
    });
    test('foo/bar', () {
      tpop(path: 'foo/bar', expected: 'foo', output: true, isWindows: false);
    });
    test('foo/.', () {
      tpop(path: 'foo/.', expected: '', output: true, isWindows: false);
    });
    test('foo//bar', () {
      tpop(path: 'foo//bar', expected: 'foo', output: true, isWindows: false);
    });
  });

  group('test_pop (Windows)', () {
    useWindows();

    test(r'a\b\c -> a\b', () {
      tpop(path: r'a\b\c', expected: r'a\b', output: true, isWindows: true);
    });
    test(r'\a -> \', () {
      tpop(path: r'\a', expected: r'\', output: true, isWindows: true);
    });
    test(r'\ -> \ (false)', () {
      tpop(path: r'\', expected: r'\', output: false, isWindows: true);
    });

    test(r'C:\a\b -> C:\a', () {
      tpop(
        path: r'C:\a\b',
        expected: r'C:\a',
        output: true,
        isWindows: true,
      );
    });
    test(r'C:\a -> C:\', () {
      tpop(path: r'C:\a', expected: r'C:\', output: true, isWindows: true);
    });
    test(r'C:\ -> C:\ (false)', () {
      tpop(path: r'C:\', expected: r'C:\', output: false, isWindows: true);
    });
    test(r'C:a\b -> C:a', () {
      tpop(
        path: r'C:a\b',
        expected: 'C:a',
        output: true,
        isWindows: true,
      );
    });
    test('C:a -> C:', () {
      tpop(path: 'C:a', expected: 'C:', output: true, isWindows: true);
    });
    test('C: -> C: (false)', () {
      tpop(path: 'C:', expected: 'C:', output: false, isWindows: true);
    });
    test(r'\\server\share\a\b -> \\server\share\a', () {
      tpop(
        path: r'\\server\share\a\b',
        expected: r'\\server\share\a',
        output: true,
        isWindows: true,
      );
    });
    test(r'\\server\share\a -> \\server\share\', () {
      tpop(
        path: r'\\server\share\a',
        expected: r'\\server\share\',
        output: true,
        isWindows: true,
      );
    });
    test(r'\\server\share -> \\server\share (false)', () {
      tpop(
        path: r'\\server\share',
        expected: r'\\server\share',
        output: false,
        isWindows: true,
      );
    });
    test(r'\\?\a\b\c -> \\?\a\b', () {
      tpop(
        path: r'\\?\a\b\c',
        expected: r'\\?\a\b',
        output: true,
        isWindows: true,
      );
    });
    test(r'\\?\a\b -> \\?\a\', () {
      tpop(
        path: r'\\?\a\b',
        expected: r'\\?\a\',
        output: true,
        isWindows: true,
      );
    });
    test(r'\\?\a -> \\?\a (false)', () {
      tpop(
        path: r'\\?\a',
        expected: r'\\?\a',
        output: false,
        isWindows: true,
      );
    });
    test(r'\\?\C:\a\b -> \\?\C:\a', () {
      tpop(
        path: r'\\?\C:\a\b',
        expected: r'\\?\C:\a',
        output: true,
        isWindows: true,
      );
    });
    test(r'\\?\C:\a -> \\?\C:\', () {
      tpop(
        path: r'\\?\C:\a',
        expected: r'\\?\C:\',
        output: true,
        isWindows: true,
      );
    });
    test(r'\\?\C:\ -> \\?\C:\ (false)', () {
      tpop(
        path: r'\\?\C:\',
        expected: r'\\?\C:\',
        output: false,
        isWindows: true,
      );
    });
    test(r'\\?\UNC\server\share\a\b -> \\?\UNC\server\share\a', () {
      tpop(
        path: r'\\?\UNC\server\share\a\b',
        expected: r'\\?\UNC\server\share\a',
        output: true,
        isWindows: true,
      );
    });
    test(r'\\?\UNC\server\share\a -> \\?\UNC\server\share\', () {
      tpop(
        path: r'\\?\UNC\server\share\a',
        expected: r'\\?\UNC\server\share\',
        output: true,
        isWindows: true,
      );
    });
    test(r'\\?\UNC\server\share -> \\?\UNC\server\share (false)', () {
      tpop(
        path: r'\\?\UNC\server\share',
        expected: r'\\?\UNC\server\share',
        output: false,
        isWindows: true,
      );
    });
    test(r'\\.\a\b\c -> \\.\a\b', () {
      tpop(
        path: r'\\.\a\b\c',
        expected: r'\\.\a\b',
        output: true,
        isWindows: true,
      );
    });
    test(r'\\.\a\b -> \\.\a\', () {
      tpop(
        path: r'\\.\a\b',
        expected: r'\\.\a\',
        output: true,
        isWindows: true,
      );
    });
    test(r'\\.\a -> \\.\a (false)', () {
      tpop(
        path: r'\\.\a',
        expected: r'\\.\a',
        output: false,
        isWindows: true,
      );
    });

    test(r'\\?\a\b\ -> \\?\a\', () {
      tpop(
        path: r'\\?\a\b\',
        expected: r'\\?\a\',
        output: true,
        isWindows: true,
      );
    });
  });

  // ── test_set_file_name ──────────────────────────────────────────────────

  group('test_set_file_name (cross-platform)', () {
    usePosix();

    test('foo -> foo (no change)', () {
      tfn(path: 'foo', file: 'foo', expected: 'foo', isWindows: false);
    });
    test('foo -> bar', () {
      tfn(path: 'foo', file: 'bar', expected: 'bar', isWindows: false);
    });
    test('foo -> empty', () {
      tfn(path: 'foo', file: '', expected: '', isWindows: false);
    });
    test('empty -> foo', () {
      tfn(path: '', file: 'foo', expected: 'foo', isWindows: false);
    });
  });

  group('test_set_file_name (POSIX)', () {
    usePosix();

    test('. -> foo', () {
      tfn(path: '.', file: 'foo', expected: './foo', isWindows: false);
    });
    test('foo/ -> bar', () {
      tfn(path: 'foo/', file: 'bar', expected: 'bar', isWindows: false);
    });
    test('foo/. -> bar', () {
      tfn(path: 'foo/.', file: 'bar', expected: 'bar', isWindows: false);
    });
    test('.. -> foo', () {
      tfn(path: '..', file: 'foo', expected: '../foo', isWindows: false);
    });
    test('foo/.. -> bar', () {
      tfn(
        path: 'foo/..',
        file: 'bar',
        expected: 'foo/../bar',
        isWindows: false,
      );
    });
    test('/ -> foo', () {
      tfn(path: '/', file: 'foo', expected: '/foo', isWindows: false);
    });
  });

  group('test_set_file_name (Windows)', () {
    useWindows();

    test('foo -> foo (no change)', () {
      tfn(path: 'foo', file: 'foo', expected: 'foo', isWindows: true);
    });
    test('foo -> bar', () {
      tfn(path: 'foo', file: 'bar', expected: 'bar', isWindows: true);
    });
    test('foo -> empty', () {
      tfn(path: 'foo', file: '', expected: '', isWindows: true);
    });
    test('empty -> foo', () {
      tfn(path: '', file: 'foo', expected: 'foo', isWindows: true);
    });

    test('. -> foo', () {
      tfn(path: '.', file: 'foo', expected: r'.\foo', isWindows: true);
    });
    test(r'foo\ -> bar', () {
      tfn(path: r'foo\', file: 'bar', expected: 'bar', isWindows: true);
    });
    test(r'foo\. -> bar', () {
      tfn(path: r'foo\.', file: 'bar', expected: 'bar', isWindows: true);
    });
    test('.. -> foo', () {
      tfn(path: '..', file: 'foo', expected: r'..\foo', isWindows: true);
    });
    test(r'foo\.. -> bar', () {
      tfn(
        path: r'foo\..',
        file: 'bar',
        expected: r'foo\..\bar',
        isWindows: true,
      );
    });
    test(r'\ -> foo', () {
      tfn(path: r'\', file: 'foo', expected: r'\foo', isWindows: true);
    });
  });

  // ── test_set_extension ──────────────────────────────────────────────────

  group('test_set_extension', () {
    usePosix();

    test('foo -> txt', () {
      tfe(
        path: 'foo',
        ext: 'txt',
        expected: 'foo.txt',
        output: true,
        isWindows: false,
      );
    });
    test('foo.bar -> txt', () {
      tfe(
        path: 'foo.bar',
        ext: 'txt',
        expected: 'foo.txt',
        output: true,
        isWindows: false,
      );
    });
    test('foo.bar.baz -> txt', () {
      tfe(
        path: 'foo.bar.baz',
        ext: 'txt',
        expected: 'foo.bar.txt',
        output: true,
        isWindows: false,
      );
    });
    test('.test -> txt', () {
      tfe(
        path: '.test',
        ext: 'txt',
        expected: '.test.txt',
        output: true,
        isWindows: false,
      );
    });
    test('foo.txt -> empty', () {
      tfe(
        path: 'foo.txt',
        ext: '',
        expected: 'foo',
        output: true,
        isWindows: false,
      );
    });
    test('foo -> empty', () {
      tfe(
        path: 'foo',
        ext: '',
        expected: 'foo',
        output: true,
        isWindows: false,
      );
    });
    test('empty -> foo', () {
      tfe(
        path: '',
        ext: 'foo',
        expected: '',
        output: false,
        isWindows: false,
      );
    });
    test('. -> foo', () {
      tfe(
        path: '.',
        ext: 'foo',
        expected: '.',
        output: false,
        isWindows: false,
      );
    });
    test('foo/ -> bar', () {
      tfe(
        path: 'foo/',
        ext: 'bar',
        expected: 'foo.bar',
        output: true,
        isWindows: false,
      );
    });
    test('foo/. -> bar', () {
      tfe(
        path: 'foo/.',
        ext: 'bar',
        expected: 'foo.bar',
        output: true,
        isWindows: false,
      );
    });
    test('.. -> foo', () {
      tfe(
        path: '..',
        ext: 'foo',
        expected: '..',
        output: false,
        isWindows: false,
      );
    });
    test('foo/.. -> bar', () {
      tfe(
        path: 'foo/..',
        ext: 'bar',
        expected: 'foo/..',
        output: false,
        isWindows: false,
      );
    });
    test('/ -> foo', () {
      tfe(
        path: '/',
        ext: 'foo',
        expected: '/',
        output: false,
        isWindows: false,
      );
    });
  });

  // ── test_add_extension ──────────────────────────────────────────────────

  group('test_add_extension', () {
    usePosix();

    test('foo -> txt', () {
      tfeAdd(
        path: 'foo',
        ext: 'txt',
        expected: 'foo.txt',
        output: true,
        isWindows: false,
      );
    });
    test('foo.bar -> txt', () {
      tfeAdd(
        path: 'foo.bar',
        ext: 'txt',
        expected: 'foo.bar.txt',
        output: true,
        isWindows: false,
      );
    });
    test('foo.bar.baz -> txt', () {
      tfeAdd(
        path: 'foo.bar.baz',
        ext: 'txt',
        expected: 'foo.bar.baz.txt',
        output: true,
        isWindows: false,
      );
    });
    test('.test -> txt', () {
      tfeAdd(
        path: '.test',
        ext: 'txt',
        expected: '.test.txt',
        output: true,
        isWindows: false,
      );
    });
    test('foo.txt -> empty', () {
      tfeAdd(
        path: 'foo.txt',
        ext: '',
        expected: 'foo.txt',
        output: true,
        isWindows: false,
      );
    });
    test('foo -> empty', () {
      tfeAdd(
        path: 'foo',
        ext: '',
        expected: 'foo',
        output: true,
        isWindows: false,
      );
    });
    test('empty -> foo', () {
      tfeAdd(
        path: '',
        ext: 'foo',
        expected: '',
        output: false,
        isWindows: false,
      );
    });
    test('. -> foo', () {
      tfeAdd(
        path: '.',
        ext: 'foo',
        expected: '.',
        output: false,
        isWindows: false,
      );
    });
    test('foo/ -> bar', () {
      tfeAdd(
        path: 'foo/',
        ext: 'bar',
        expected: 'foo.bar',
        output: true,
        isWindows: false,
      );
    });
    test('foo/. -> bar', () {
      tfeAdd(
        path: 'foo/.',
        ext: 'bar',
        expected: 'foo.bar',
        output: true,
        isWindows: false,
      );
    });
    test('.. -> foo', () {
      tfeAdd(
        path: '..',
        ext: 'foo',
        expected: '..',
        output: false,
        isWindows: false,
      );
    });
    test('foo/.. -> bar', () {
      tfeAdd(
        path: 'foo/..',
        ext: 'bar',
        expected: 'foo/..',
        output: false,
        isWindows: false,
      );
    });
    test('/ -> foo', () {
      tfeAdd(
        path: '/',
        ext: 'foo',
        expected: '/',
        output: false,
        isWindows: false,
      );
    });

    // Edge case from Rust's test_add_extension.
    test('/foo.ext//// -> bar', () {
      tfeAdd(
        path: '/foo.ext////',
        ext: 'bar',
        expected: '/foo.ext.bar',
        output: true,
        isWindows: false,
      );
    });
  });
}
