// Ported from `library/std/src/path/tests.rs`:
//
//   * `test_decompositions_unix`
//   * `test_decompositions_windows`
//
// Cygwin tests are intentionally not ported — pathify does not model Cygwin.

import 'package:test/test.dart';

import '_helpers.dart';

void main() {
  group('test_decompositions_unix', () {
    usePosix();

    test('empty path', () {
      t(
        path: '',
        isWindows: false,
        iter: const [],
        hasRoot: false,
        isAbsolute: false,
        parentIsNone: true,
        fileNameIsNone: true,
        fileStemIsNone: true,
        extensionIsNone: true,
        filePrefixIsNone: true,
      );
    });

    test('foo', () {
      t(
        path: 'foo',
        isWindows: false,
        iter: const ['foo'],
        hasRoot: false,
        isAbsolute: false,
        parent: '',
        fileName: 'foo',
        fileStem: 'foo',
        extensionIsNone: true,
        filePrefix: 'foo',
      );
    });

    test('/', () {
      t(
        path: '/',
        isWindows: false,
        iter: const ['/'],
        hasRoot: true,
        isAbsolute: true,
        parentIsNone: true,
        fileNameIsNone: true,
        fileStemIsNone: true,
        extensionIsNone: true,
        filePrefixIsNone: true,
      );
    });

    test('/foo', () {
      t(
        path: '/foo',
        isWindows: false,
        iter: const ['/', 'foo'],
        hasRoot: true,
        isAbsolute: true,
        parent: '/',
        fileName: 'foo',
        fileStem: 'foo',
        extensionIsNone: true,
        filePrefix: 'foo',
      );
    });

    test('foo/', () {
      t(
        path: 'foo/',
        isWindows: false,
        iter: const ['foo'],
        hasRoot: false,
        isAbsolute: false,
        parent: '',
        fileName: 'foo',
        fileStem: 'foo',
        extensionIsNone: true,
        filePrefix: 'foo',
      );
    });

    test('/foo/', () {
      t(
        path: '/foo/',
        isWindows: false,
        iter: const ['/', 'foo'],
        hasRoot: true,
        isAbsolute: true,
        parent: '/',
        fileName: 'foo',
        fileStem: 'foo',
        extensionIsNone: true,
        filePrefix: 'foo',
      );
    });

    test('foo/bar', () {
      t(
        path: 'foo/bar',
        isWindows: false,
        iter: const ['foo', 'bar'],
        hasRoot: false,
        isAbsolute: false,
        parent: 'foo',
        fileName: 'bar',
        fileStem: 'bar',
        extensionIsNone: true,
        filePrefix: 'bar',
      );
    });

    test('/foo/bar', () {
      t(
        path: '/foo/bar',
        isWindows: false,
        iter: const ['/', 'foo', 'bar'],
        hasRoot: true,
        isAbsolute: true,
        parent: '/foo',
        fileName: 'bar',
        fileStem: 'bar',
        extensionIsNone: true,
        filePrefix: 'bar',
      );
    });

    test('///foo///', () {
      t(
        path: '///foo///',
        isWindows: false,
        iter: const ['/', 'foo'],
        hasRoot: true,
        isAbsolute: true,
        parent: '/',
        fileName: 'foo',
        fileStem: 'foo',
        extensionIsNone: true,
        filePrefix: 'foo',
      );
    });

    test('///foo///bar', () {
      t(
        path: '///foo///bar',
        isWindows: false,
        iter: const ['/', 'foo', 'bar'],
        hasRoot: true,
        isAbsolute: true,
        parent: '///foo',
        fileName: 'bar',
        fileStem: 'bar',
        extensionIsNone: true,
        filePrefix: 'bar',
      );
    });

    test('./.', () {
      t(
        path: './.',
        isWindows: false,
        iter: const ['.'],
        hasRoot: false,
        isAbsolute: false,
        parent: '',
        fileNameIsNone: true,
        fileStemIsNone: true,
        extensionIsNone: true,
        filePrefixIsNone: true,
      );
    });

    test('/..', () {
      t(
        path: '/..',
        isWindows: false,
        iter: const ['/', '..'],
        hasRoot: true,
        isAbsolute: true,
        parent: '/',
        fileNameIsNone: true,
        fileStemIsNone: true,
        extensionIsNone: true,
        filePrefixIsNone: true,
      );
    });

    test('../', () {
      t(
        path: '../',
        isWindows: false,
        iter: const ['..'],
        hasRoot: false,
        isAbsolute: false,
        parent: '',
        fileNameIsNone: true,
        fileStemIsNone: true,
        extensionIsNone: true,
        filePrefixIsNone: true,
      );
    });

    test('foo/.', () {
      t(
        path: 'foo/.',
        isWindows: false,
        iter: const ['foo'],
        hasRoot: false,
        isAbsolute: false,
        parent: '',
        fileName: 'foo',
        fileStem: 'foo',
        extensionIsNone: true,
        filePrefix: 'foo',
      );
    });

    test('foo/..', () {
      t(
        path: 'foo/..',
        isWindows: false,
        iter: const ['foo', '..'],
        hasRoot: false,
        isAbsolute: false,
        parent: 'foo',
        fileNameIsNone: true,
        fileStemIsNone: true,
        extensionIsNone: true,
        filePrefixIsNone: true,
      );
    });

    test('foo/./', () {
      t(
        path: 'foo/./',
        isWindows: false,
        iter: const ['foo'],
        hasRoot: false,
        isAbsolute: false,
        parent: '',
        fileName: 'foo',
        fileStem: 'foo',
        extensionIsNone: true,
        filePrefix: 'foo',
      );
    });

    test('foo/./bar', () {
      t(
        path: 'foo/./bar',
        isWindows: false,
        iter: const ['foo', 'bar'],
        hasRoot: false,
        isAbsolute: false,
        parent: 'foo',
        fileName: 'bar',
        fileStem: 'bar',
        extensionIsNone: true,
        filePrefix: 'bar',
      );
    });

    test('foo/../', () {
      t(
        path: 'foo/../',
        isWindows: false,
        iter: const ['foo', '..'],
        hasRoot: false,
        isAbsolute: false,
        parent: 'foo',
        fileNameIsNone: true,
        fileStemIsNone: true,
        extensionIsNone: true,
        filePrefixIsNone: true,
      );
    });

    test('foo/../bar', () {
      t(
        path: 'foo/../bar',
        isWindows: false,
        iter: const ['foo', '..', 'bar'],
        hasRoot: false,
        isAbsolute: false,
        parent: 'foo/..',
        fileName: 'bar',
        fileStem: 'bar',
        extensionIsNone: true,
        filePrefix: 'bar',
      );
    });

    test('./a', () {
      t(
        path: './a',
        isWindows: false,
        iter: const ['.', 'a'],
        hasRoot: false,
        isAbsolute: false,
        parent: '.',
        fileName: 'a',
        fileStem: 'a',
        extensionIsNone: true,
        filePrefix: 'a',
      );
    });

    test('.', () {
      t(
        path: '.',
        isWindows: false,
        iter: const ['.'],
        hasRoot: false,
        isAbsolute: false,
        parent: '',
        fileNameIsNone: true,
        fileStemIsNone: true,
        extensionIsNone: true,
        filePrefixIsNone: true,
      );
    });

    test('./', () {
      t(
        path: './',
        isWindows: false,
        iter: const ['.'],
        hasRoot: false,
        isAbsolute: false,
        parent: '',
        fileNameIsNone: true,
        fileStemIsNone: true,
        extensionIsNone: true,
        filePrefixIsNone: true,
      );
    });

    test('a/b', () {
      t(
        path: 'a/b',
        isWindows: false,
        iter: const ['a', 'b'],
        hasRoot: false,
        isAbsolute: false,
        parent: 'a',
        fileName: 'b',
        fileStem: 'b',
        extensionIsNone: true,
        filePrefix: 'b',
      );
    });

    test('a//b', () {
      t(
        path: 'a//b',
        isWindows: false,
        iter: const ['a', 'b'],
        hasRoot: false,
        isAbsolute: false,
        parent: 'a',
        fileName: 'b',
        fileStem: 'b',
        extensionIsNone: true,
        filePrefix: 'b',
      );
    });

    test('a/./b', () {
      t(
        path: 'a/./b',
        isWindows: false,
        iter: const ['a', 'b'],
        hasRoot: false,
        isAbsolute: false,
        parent: 'a',
        fileName: 'b',
        fileStem: 'b',
        extensionIsNone: true,
        filePrefix: 'b',
      );
    });

    test('a/b/c', () {
      t(
        path: 'a/b/c',
        isWindows: false,
        iter: const ['a', 'b', 'c'],
        hasRoot: false,
        isAbsolute: false,
        parent: 'a/b',
        fileName: 'c',
        fileStem: 'c',
        extensionIsNone: true,
        filePrefix: 'c',
      );
    });

    test('.foo', () {
      t(
        path: '.foo',
        isWindows: false,
        iter: const ['.foo'],
        hasRoot: false,
        isAbsolute: false,
        parent: '',
        fileName: '.foo',
        fileStem: '.foo',
        extensionIsNone: true,
        filePrefix: '.foo',
      );
    });

    test('a/.foo', () {
      t(
        path: 'a/.foo',
        isWindows: false,
        iter: const ['a', '.foo'],
        hasRoot: false,
        isAbsolute: false,
        parent: 'a',
        fileName: '.foo',
        fileStem: '.foo',
        extensionIsNone: true,
        filePrefix: '.foo',
      );
    });

    test('a/.rustfmt.toml', () {
      t(
        path: 'a/.rustfmt.toml',
        isWindows: false,
        iter: const ['a', '.rustfmt.toml'],
        hasRoot: false,
        isAbsolute: false,
        parent: 'a',
        fileName: '.rustfmt.toml',
        fileStem: '.rustfmt',
        extension: 'toml',
        filePrefix: '.rustfmt',
      );
    });

    test('a/.x.y.z', () {
      t(
        path: 'a/.x.y.z',
        isWindows: false,
        iter: const ['a', '.x.y.z'],
        hasRoot: false,
        isAbsolute: false,
        parent: 'a',
        fileName: '.x.y.z',
        fileStem: '.x.y',
        extension: 'z',
        filePrefix: '.x',
      );
    });
  });

  group('test_decompositions_windows', () {
    useWindows();

    test('empty path', () {
      t(
        path: '',
        isWindows: true,
        iter: const [],
        hasRoot: false,
        isAbsolute: false,
        parentIsNone: true,
        fileNameIsNone: true,
        fileStemIsNone: true,
        extensionIsNone: true,
        filePrefixIsNone: true,
      );
    });

    test('foo', () {
      t(
        path: 'foo',
        isWindows: true,
        iter: const ['foo'],
        hasRoot: false,
        isAbsolute: false,
        parent: '',
        fileName: 'foo',
        fileStem: 'foo',
        extensionIsNone: true,
        filePrefix: 'foo',
      );
    });

    test('/', () {
      t(
        path: '/',
        isWindows: true,
        iter: const [r'\'],
        hasRoot: true,
        isAbsolute: false,
        parentIsNone: true,
        fileNameIsNone: true,
        fileStemIsNone: true,
        extensionIsNone: true,
        filePrefixIsNone: true,
      );
    });

    test(r'\', () {
      t(
        path: r'\',
        isWindows: true,
        iter: const [r'\'],
        hasRoot: true,
        isAbsolute: false,
        parentIsNone: true,
        fileNameIsNone: true,
        fileStemIsNone: true,
        extensionIsNone: true,
        filePrefixIsNone: true,
      );
    });

    test('c:', () {
      t(
        path: 'c:',
        isWindows: true,
        iter: const ['c:'],
        hasRoot: false,
        isAbsolute: false,
        parentIsNone: true,
        fileNameIsNone: true,
        fileStemIsNone: true,
        extensionIsNone: true,
        filePrefixIsNone: true,
      );
    });

    test(r'c:\', () {
      t(
        path: r'c:\',
        isWindows: true,
        iter: const ['c:', r'\'],
        hasRoot: true,
        isAbsolute: true,
        parentIsNone: true,
        fileNameIsNone: true,
        fileStemIsNone: true,
        extensionIsNone: true,
        filePrefixIsNone: true,
      );
    });

    test('c:/', () {
      t(
        path: 'c:/',
        isWindows: true,
        iter: const ['c:', r'\'],
        hasRoot: true,
        isAbsolute: true,
        parentIsNone: true,
        fileNameIsNone: true,
        fileStemIsNone: true,
        extensionIsNone: true,
        filePrefixIsNone: true,
      );
    });

    test('/foo', () {
      t(
        path: '/foo',
        isWindows: true,
        iter: const [r'\', 'foo'],
        hasRoot: true,
        isAbsolute: false,
        parent: '/',
        fileName: 'foo',
        fileStem: 'foo',
        extensionIsNone: true,
        filePrefix: 'foo',
      );
    });

    test('foo/', () {
      t(
        path: 'foo/',
        isWindows: true,
        iter: const ['foo'],
        hasRoot: false,
        isAbsolute: false,
        parent: '',
        fileName: 'foo',
        fileStem: 'foo',
        extensionIsNone: true,
        filePrefix: 'foo',
      );
    });

    test('/foo/', () {
      t(
        path: '/foo/',
        isWindows: true,
        iter: const [r'\', 'foo'],
        hasRoot: true,
        isAbsolute: false,
        parent: '/',
        fileName: 'foo',
        fileStem: 'foo',
        extensionIsNone: true,
        filePrefix: 'foo',
      );
    });

    test('foo/bar', () {
      t(
        path: 'foo/bar',
        isWindows: true,
        iter: const ['foo', 'bar'],
        hasRoot: false,
        isAbsolute: false,
        parent: 'foo',
        fileName: 'bar',
        fileStem: 'bar',
        extensionIsNone: true,
        filePrefix: 'bar',
      );
    });

    test('/foo/bar', () {
      t(
        path: '/foo/bar',
        isWindows: true,
        iter: const [r'\', 'foo', 'bar'],
        hasRoot: true,
        isAbsolute: false,
        parent: '/foo',
        fileName: 'bar',
        fileStem: 'bar',
        extensionIsNone: true,
        filePrefix: 'bar',
      );
    });

    test('///foo///', () {
      t(
        path: '///foo///',
        isWindows: true,
        iter: const [r'\', 'foo'],
        hasRoot: true,
        isAbsolute: false,
        parent: '/',
        fileName: 'foo',
        fileStem: 'foo',
        extensionIsNone: true,
        filePrefix: 'foo',
      );
    });

    test('///foo///bar', () {
      t(
        path: '///foo///bar',
        isWindows: true,
        iter: const [r'\', 'foo', 'bar'],
        hasRoot: true,
        isAbsolute: false,
        parent: '///foo',
        fileName: 'bar',
        fileStem: 'bar',
        extensionIsNone: true,
        filePrefix: 'bar',
      );
    });

    test('./.', () {
      t(
        path: './.',
        isWindows: true,
        iter: const ['.'],
        hasRoot: false,
        isAbsolute: false,
        parent: '',
        fileNameIsNone: true,
        fileStemIsNone: true,
        extensionIsNone: true,
        filePrefixIsNone: true,
      );
    });

    test('/..', () {
      t(
        path: '/..',
        isWindows: true,
        iter: const [r'\', '..'],
        hasRoot: true,
        isAbsolute: false,
        parent: '/',
        fileNameIsNone: true,
        fileStemIsNone: true,
        extensionIsNone: true,
        filePrefixIsNone: true,
      );
    });

    test('../', () {
      t(
        path: '../',
        isWindows: true,
        iter: const ['..'],
        hasRoot: false,
        isAbsolute: false,
        parent: '',
        fileNameIsNone: true,
        fileStemIsNone: true,
        extensionIsNone: true,
        filePrefixIsNone: true,
      );
    });

    test('foo/.', () {
      t(
        path: 'foo/.',
        isWindows: true,
        iter: const ['foo'],
        hasRoot: false,
        isAbsolute: false,
        parent: '',
        fileName: 'foo',
        fileStem: 'foo',
        extensionIsNone: true,
        filePrefix: 'foo',
      );
    });

    test('foo/..', () {
      t(
        path: 'foo/..',
        isWindows: true,
        iter: const ['foo', '..'],
        hasRoot: false,
        isAbsolute: false,
        parent: 'foo',
        fileNameIsNone: true,
        fileStemIsNone: true,
        extensionIsNone: true,
        filePrefixIsNone: true,
      );
    });

    test('foo/./', () {
      t(
        path: 'foo/./',
        isWindows: true,
        iter: const ['foo'],
        hasRoot: false,
        isAbsolute: false,
        parent: '',
        fileName: 'foo',
        fileStem: 'foo',
        extensionIsNone: true,
        filePrefix: 'foo',
      );
    });

    test('foo/./bar', () {
      t(
        path: 'foo/./bar',
        isWindows: true,
        iter: const ['foo', 'bar'],
        hasRoot: false,
        isAbsolute: false,
        parent: 'foo',
        fileName: 'bar',
        fileStem: 'bar',
        extensionIsNone: true,
        filePrefix: 'bar',
      );
    });

    test('foo/../', () {
      t(
        path: 'foo/../',
        isWindows: true,
        iter: const ['foo', '..'],
        hasRoot: false,
        isAbsolute: false,
        parent: 'foo',
        fileNameIsNone: true,
        fileStemIsNone: true,
        extensionIsNone: true,
        filePrefixIsNone: true,
      );
    });

    test('foo/../bar', () {
      t(
        path: 'foo/../bar',
        isWindows: true,
        iter: const ['foo', '..', 'bar'],
        hasRoot: false,
        isAbsolute: false,
        parent: 'foo/..',
        fileName: 'bar',
        fileStem: 'bar',
        extensionIsNone: true,
        filePrefix: 'bar',
      );
    });

    test('./a', () {
      t(
        path: './a',
        isWindows: true,
        iter: const ['.', 'a'],
        hasRoot: false,
        isAbsolute: false,
        parent: '.',
        fileName: 'a',
        fileStem: 'a',
        extensionIsNone: true,
        filePrefix: 'a',
      );
    });

    test('.', () {
      t(
        path: '.',
        isWindows: true,
        iter: const ['.'],
        hasRoot: false,
        isAbsolute: false,
        parent: '',
        fileNameIsNone: true,
        fileStemIsNone: true,
        extensionIsNone: true,
        filePrefixIsNone: true,
      );
    });

    test('./', () {
      t(
        path: './',
        isWindows: true,
        iter: const ['.'],
        hasRoot: false,
        isAbsolute: false,
        parent: '',
        fileNameIsNone: true,
        fileStemIsNone: true,
        extensionIsNone: true,
        filePrefixIsNone: true,
      );
    });

    test('a/b', () {
      t(
        path: 'a/b',
        isWindows: true,
        iter: const ['a', 'b'],
        hasRoot: false,
        isAbsolute: false,
        parent: 'a',
        fileName: 'b',
        fileStem: 'b',
        extensionIsNone: true,
        filePrefix: 'b',
      );
    });

    test('a//b', () {
      t(
        path: 'a//b',
        isWindows: true,
        iter: const ['a', 'b'],
        hasRoot: false,
        isAbsolute: false,
        parent: 'a',
        fileName: 'b',
        fileStem: 'b',
        extensionIsNone: true,
        filePrefix: 'b',
      );
    });

    test('a/./b', () {
      t(
        path: 'a/./b',
        isWindows: true,
        iter: const ['a', 'b'],
        hasRoot: false,
        isAbsolute: false,
        parent: 'a',
        fileName: 'b',
        fileStem: 'b',
        extensionIsNone: true,
        filePrefix: 'b',
      );
    });

    test('a/b/c (forward slashes)', () {
      t(
        path: 'a/b/c',
        isWindows: true,
        iter: const ['a', 'b', 'c'],
        hasRoot: false,
        isAbsolute: false,
        parent: 'a/b',
        fileName: 'c',
        fileStem: 'c',
        extensionIsNone: true,
        filePrefix: 'c',
      );
    });

    test(r'a\b\c', () {
      t(
        path: r'a\b\c',
        isWindows: true,
        iter: const ['a', 'b', 'c'],
        hasRoot: false,
        isAbsolute: false,
        parent: r'a\b',
        fileName: 'c',
        fileStem: 'c',
        extensionIsNone: true,
        filePrefix: 'c',
      );
    });

    test(r'\a', () {
      t(
        path: r'\a',
        isWindows: true,
        iter: const [r'\', 'a'],
        hasRoot: true,
        isAbsolute: false,
        parent: r'\',
        fileName: 'a',
        fileStem: 'a',
        extensionIsNone: true,
        filePrefix: 'a',
      );
    });

    test(r'c:\foo.txt', () {
      t(
        path: r'c:\foo.txt',
        isWindows: true,
        iter: const ['c:', r'\', 'foo.txt'],
        hasRoot: true,
        isAbsolute: true,
        parent: r'c:\',
        fileName: 'foo.txt',
        fileStem: 'foo',
        extension: 'txt',
        filePrefix: 'foo',
      );
    });

    test(r'\\server\share\foo.txt', () {
      t(
        path: r'\\server\share\foo.txt',
        isWindows: true,
        iter: const [r'\\server\share', r'\', 'foo.txt'],
        hasRoot: true,
        isAbsolute: true,
        parent: r'\\server\share\',
        fileName: 'foo.txt',
        fileStem: 'foo',
        extension: 'txt',
        filePrefix: 'foo',
      );
    });

    test(r'\\server\share', () {
      t(
        path: r'\\server\share',
        isWindows: true,
        iter: const [r'\\server\share', r'\'],
        hasRoot: true,
        isAbsolute: true,
        parentIsNone: true,
        fileNameIsNone: true,
        fileStemIsNone: true,
        extensionIsNone: true,
        filePrefixIsNone: true,
      );
    });

    test(r'\\server', () {
      t(
        path: r'\\server',
        isWindows: true,
        iter: const [r'\', 'server'],
        hasRoot: true,
        isAbsolute: false,
        parent: r'\',
        fileName: 'server',
        fileStem: 'server',
        extensionIsNone: true,
        filePrefix: 'server',
      );
    });

    test(r'\\?\bar\foo.txt', () {
      t(
        path: r'\\?\bar\foo.txt',
        isWindows: true,
        iter: const [r'\\?\bar', r'\', 'foo.txt'],
        hasRoot: true,
        isAbsolute: true,
        parent: r'\\?\bar\',
        fileName: 'foo.txt',
        fileStem: 'foo',
        extension: 'txt',
        filePrefix: 'foo',
      );
    });

    test(r'\\?\bar', () {
      t(
        path: r'\\?\bar',
        isWindows: true,
        iter: const [r'\\?\bar'],
        hasRoot: true,
        isAbsolute: true,
        parentIsNone: true,
        fileNameIsNone: true,
        fileStemIsNone: true,
        extensionIsNone: true,
        filePrefixIsNone: true,
      );
    });

    test(r'\\?\', () {
      t(
        path: r'\\?\',
        isWindows: true,
        iter: const [r'\\?\'],
        hasRoot: true,
        isAbsolute: true,
        parentIsNone: true,
        fileNameIsNone: true,
        fileStemIsNone: true,
        extensionIsNone: true,
        filePrefixIsNone: true,
      );
    });

    test(r'\\?\UNC\server\share\foo.txt', () {
      t(
        path: r'\\?\UNC\server\share\foo.txt',
        isWindows: true,
        iter: const [r'\\?\UNC\server\share', r'\', 'foo.txt'],
        hasRoot: true,
        isAbsolute: true,
        parent: r'\\?\UNC\server\share\',
        fileName: 'foo.txt',
        fileStem: 'foo',
        extension: 'txt',
        filePrefix: 'foo',
      );
    });

    test(r'\\?\UNC\server', () {
      t(
        path: r'\\?\UNC\server',
        isWindows: true,
        iter: const [r'\\?\UNC\server'],
        hasRoot: true,
        isAbsolute: true,
        parentIsNone: true,
        fileNameIsNone: true,
        fileStemIsNone: true,
        extensionIsNone: true,
        filePrefixIsNone: true,
      );
    });

    test(r'\\?\UNC\', () {
      t(
        path: r'\\?\UNC\',
        isWindows: true,
        iter: const [r'\\?\UNC\'],
        hasRoot: true,
        isAbsolute: true,
        parentIsNone: true,
        fileNameIsNone: true,
        fileStemIsNone: true,
        extensionIsNone: true,
        filePrefixIsNone: true,
      );
    });

    test(r'\\?\C:\foo.txt', () {
      t(
        path: r'\\?\C:\foo.txt',
        isWindows: true,
        iter: const [r'\\?\C:', r'\', 'foo.txt'],
        hasRoot: true,
        isAbsolute: true,
        parent: r'\\?\C:\',
        fileName: 'foo.txt',
        fileStem: 'foo',
        extension: 'txt',
        filePrefix: 'foo',
      );
    });

    test(r'\\?\C:\', () {
      t(
        path: r'\\?\C:\',
        isWindows: true,
        iter: const [r'\\?\C:', r'\'],
        hasRoot: true,
        isAbsolute: true,
        parentIsNone: true,
        fileNameIsNone: true,
        fileStemIsNone: true,
        extensionIsNone: true,
        filePrefixIsNone: true,
      );
    });

    test(r'\\?\C:', () {
      t(
        path: r'\\?\C:',
        isWindows: true,
        iter: const [r'\\?\C:'],
        hasRoot: true,
        isAbsolute: true,
        parentIsNone: true,
        fileNameIsNone: true,
        fileStemIsNone: true,
        extensionIsNone: true,
        filePrefixIsNone: true,
      );
    });

    test(r'\\?\foo/bar', () {
      t(
        path: r'\\?\foo/bar',
        isWindows: true,
        iter: const [r'\\?\foo/bar'],
        hasRoot: true,
        isAbsolute: true,
        parentIsNone: true,
        fileNameIsNone: true,
        fileStemIsNone: true,
        extensionIsNone: true,
        filePrefixIsNone: true,
      );
    });

    test(r'\\?\C:/foo/bar', () {
      t(
        path: r'\\?\C:/foo/bar',
        isWindows: true,
        iter: const [r'\\?\C:', r'\', 'foo/bar'],
        hasRoot: true,
        isAbsolute: true,
        parent: r'\\?\C:/',
        fileName: 'foo/bar',
        fileStem: 'foo/bar',
        extensionIsNone: true,
        filePrefix: 'foo/bar',
      );
    });

    test(r'\\.\foo\bar', () {
      t(
        path: r'\\.\foo\bar',
        isWindows: true,
        iter: const [r'\\.\foo', r'\', 'bar'],
        hasRoot: true,
        isAbsolute: true,
        parent: r'\\.\foo\',
        fileName: 'bar',
        fileStem: 'bar',
        extensionIsNone: true,
        filePrefix: 'bar',
      );
    });

    test(r'\\.\foo', () {
      t(
        path: r'\\.\foo',
        isWindows: true,
        iter: const [r'\\.\foo', r'\'],
        hasRoot: true,
        isAbsolute: true,
        parentIsNone: true,
        fileNameIsNone: true,
        fileStemIsNone: true,
        extensionIsNone: true,
        filePrefixIsNone: true,
      );
    });

    test(r'\\.\foo/bar', () {
      t(
        path: r'\\.\foo/bar',
        isWindows: true,
        iter: const [r'\\.\foo', r'\', 'bar'],
        hasRoot: true,
        isAbsolute: true,
        parent: r'\\.\foo/',
        fileName: 'bar',
        fileStem: 'bar',
        extensionIsNone: true,
        filePrefix: 'bar',
      );
    });

    test(r'\\.\foo\bar/baz', () {
      t(
        path: r'\\.\foo\bar/baz',
        isWindows: true,
        iter: const [r'\\.\foo', r'\', 'bar', 'baz'],
        hasRoot: true,
        isAbsolute: true,
        parent: r'\\.\foo\bar',
        fileName: 'baz',
        fileStem: 'baz',
        extensionIsNone: true,
        filePrefix: 'baz',
      );
    });

    test(r'\\.\', () {
      t(
        path: r'\\.\',
        isWindows: true,
        iter: const [r'\\.\', r'\'],
        hasRoot: true,
        isAbsolute: true,
        parentIsNone: true,
        fileNameIsNone: true,
        fileStemIsNone: true,
        extensionIsNone: true,
        filePrefixIsNone: true,
      );
    });

    test(r'\\?\a\b\', () {
      t(
        path: r'\\?\a\b\',
        isWindows: true,
        iter: const [r'\\?\a', r'\', 'b'],
        hasRoot: true,
        isAbsolute: true,
        parent: r'\\?\a\',
        fileName: 'b',
        fileStem: 'b',
        extensionIsNone: true,
        filePrefix: 'b',
      );
    });

    test(r'\\?\C:\foo.txt.zip', () {
      t(
        path: r'\\?\C:\foo.txt.zip',
        isWindows: true,
        iter: const [r'\\?\C:', r'\', 'foo.txt.zip'],
        hasRoot: true,
        isAbsolute: true,
        parent: r'\\?\C:\',
        fileName: 'foo.txt.zip',
        fileStem: 'foo.txt',
        extension: 'zip',
        filePrefix: 'foo',
      );
    });

    test(r'\\?\C:\.foo.txt.zip', () {
      t(
        path: r'\\?\C:\.foo.txt.zip',
        isWindows: true,
        iter: const [r'\\?\C:', r'\', '.foo.txt.zip'],
        hasRoot: true,
        isAbsolute: true,
        parent: r'\\?\C:\',
        fileName: '.foo.txt.zip',
        fileStem: '.foo.txt',
        extension: 'zip',
        filePrefix: '.foo',
      );
    });

    test(r'\\?\C:\.foo', () {
      t(
        path: r'\\?\C:\.foo',
        isWindows: true,
        iter: const [r'\\?\C:', r'\', '.foo'],
        hasRoot: true,
        isAbsolute: true,
        parent: r'\\?\C:\',
        fileName: '.foo',
        fileStem: '.foo',
        extensionIsNone: true,
        filePrefix: '.foo',
      );
    });

    test('a/.x.y.z (windows)', () {
      t(
        path: 'a/.x.y.z',
        isWindows: true,
        iter: const ['a', '.x.y.z'],
        hasRoot: false,
        isAbsolute: false,
        parent: 'a',
        fileName: '.x.y.z',
        fileStem: '.x.y',
        extension: 'z',
        filePrefix: '.x',
      );
    });
  });
}
