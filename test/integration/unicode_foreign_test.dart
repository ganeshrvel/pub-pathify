import 'dart:convert';
import 'dart:typed_data';

import 'package:pathify/pathify.dart';
import 'package:test/test.dart';

import '_helpers.dart';

Uint8List _b(String s) => Uint8List.fromList(utf8.encode(s));

Uint16List _w(String s) => Uint16List.fromList(s.codeUnits);

void main() {
  group('Foreign scripts (POSIX override)', () {
    setUp(() {
      Pathify.instance.overriddenPlatform = PathifyPlatform.linux;
    });

    tearDown(Pathify.instance.resetForTesting);

    test('Japanese path components', () {
      final p = PathBuf.fromBytes(_b('/home/田中/写真/旅行.jpg'));
      final ext = p.extension();
      expect(ext, isNotNull);
      expect(cuStr(ext!), 'jpg');
    });

    test('Cyrillic path components', () {
      final p = PathBuf.fromBytes(_b('/home/Пользователь/документы/файл.txt'));
      final stem = p.fileStem();
      expect(stem, isNotNull);
      expect(cuStr(stem!), 'файл');
    });

    test('Arabic right-to-left path', () {
      final p = PathBuf.fromBytes(_b('/home/مستخدم/ملف.txt'));
      final name = p.fileName();
      expect(name, isNotNull);
      expect(cuStr(name!), 'ملف.txt');
    });

    test('Hindi devanagari path', () {
      final p = PathBuf.fromBytes(_b('/home/उपयोगकर्ता/दस्तावेज़.txt'));
      final ext = p.extension();
      expect(ext, isNotNull);
      expect(cuStr(ext!), 'txt');
    });
  });

  group('Foreign scripts (Windows override)', () {
    setUp(() {
      Pathify.instance.overriddenPlatform = PathifyPlatform.windows;
    });

    tearDown(Pathify.instance.resetForTesting);

    test('Japanese path components', () {
      final p = PathBuf.fromBytes(_w(r'C:\ユーザー\田中\写真.jpg'));
      final ext = p.extension();
      expect(ext, isNotNull);
      expect(cuStr(ext!), 'jpg');
    });

    test('Cyrillic UNC path', () {
      final p = PathBuf.fromBytes(_w(r'\\сервер\общий\документ.txt'));
      expect(p.prefix(), isA<UNC>());
      final ext = p.extension();
      expect(ext, isNotNull);
      expect(cuStr(ext!), 'txt');
    });
  });

  group('Foreign scripts deep tests (POSIX)', () {
    setUp(() {
      Pathify.instance.overriddenPlatform = PathifyPlatform.linux;
    });

    tearDown(Pathify.instance.resetForTesting);

    test('round trip multi-language path (fromStr → toStr)', () {
      const path = '/home/用户/Пользователь/مستخدم/文件.txt';
      final p = PathBuf.fromStr(path);

      expect(p.toStr(), path);
      expect(p.toStringLossy(), path);
    });

    test('round trip multi-language path (fromBytes)', () {
      const path = '/home/用户/Пользователь/مستخدم/文件.txt';
      final p = PathBuf.fromBytes(_b(path));

      expect(p.toStr(), path);
    });

    test('mixed scripts components extraction', () {
      final p = PathBuf.fromBytes(
        _b('/root/用户/данные/ملفات/file.txt'),
      );

      final names = p
          .components()
          .toList()
          .whereType<ComponentNormal>()
          .map((c) => cuStr(c.value))
          .toList();

      expect(
        names,
        equals(['root', '用户', 'данные', 'ملفات', 'file.txt']),
      );
    });

    test('RTL script filename extraction (Arabic)', () {
      final p = PathBuf.fromBytes(_b('/home/مستخدم/ملف.txt'));

      final name = p.fileName();
      expect(name, isNotNull);
      expect(cuStr(name!), 'ملف.txt');
    });

    test('Cyrillic fileStem extraction', () {
      final p = PathBuf.fromBytes(
        _b('/home/Пользователь/документ.txt'),
      );

      final stem = p.fileStem();
      expect(stem, isNotNull);
      expect(cuStr(stem!), 'документ');
    });

    test('Chinese extension extraction', () {
      final p = PathBuf.fromBytes(_b('/数据/文件.tar.gz'));

      final ext = p.extension();
      expect(ext, isNotNull);
      expect(cuStr(ext!), 'gz');
    });

    test('parent() preserves foreign scripts', () {
      final p = PathBuf.fromBytes(
        _b('/home/用户/文件夹/文件.txt'),
      );

      final parent = p.parent();
      expect(parent, isNotNull);

      expect(cuStr(parent!.codeUnits), '/home/用户/文件夹');
    });

    test('combining characters treated as distinct bytes', () {
      // é vs e + ́ (different representations)
      const composed = '/tmp/é.txt';
      const decomposed = '/tmp/e\u0301.txt';

      final p1 = PathBuf.fromBytes(_b(composed));
      final p2 = PathBuf.fromBytes(_b(decomposed));

      expect(p1.toStr(), composed);
      expect(p2.toStr(), decomposed);

      // They must NOT be equal
      expect(p1 == p2, isFalse);
    });

    test('startsWith / endsWith with foreign scripts', () {
      final p = PathBuf.fromBytes(
        _b('/home/用户/данные/ملف.txt'),
      );

      expect(
        p.startsWith(PathBuf.fromStr('/home/用户')),
        isTrue,
      );

      expect(
        p.endsWith(PathBuf.fromStr('ملف.txt')),
        isTrue,
      );

      expect(
        p.endsWith(PathBuf.fromStr('данные')),
        isFalse,
      );
    });

    test('invalid UTF-8 inside foreign script path', () {
      final bytes = Uint8List.fromList([
        ..._b('/home/用户/'),
        0xFF,
        0xFE,
      ]);

      final p = PathBuf.fromBytes(bytes);

      expect(p.toStr(), isNull);
      expect(p.toStringLossy(), isNotEmpty);
    });
  });

  group('Foreign scripts deep tests (Windows)', () {
    setUp(() {
      Pathify.instance.overriddenPlatform = PathifyPlatform.windows;
    });

    tearDown(Pathify.instance.resetForTesting);

    test('round trip multi-language path (fromStr)', () {
      const path = r'C:\用户\Пользователь\مستخدم\文件.txt';
      final p = PathBuf.fromStr(path);

      expect(p.toStr(), path);
      expect(p.toStringLossy(), path);
    });

    test('round trip multi-language path (fromBytes UTF-16)', () {
      const path = r'C:\用户\Пользователь\مستخدم\文件.txt';
      final p = PathBuf.fromBytes(_w(path));

      expect(p.toStr(), path);
    });

    test('components extraction with mixed scripts', () {
      final p = PathBuf.fromBytes(
        _w(r'C:\root\用户\данные\ملفات\file.txt'),
      );

      final names = p
          .components()
          .toList()
          .whereType<ComponentNormal>()
          .map((c) => cuStr(c.value))
          .toList();

      expect(
        names,
        equals(['root', '用户', 'данные', 'ملفات', 'file.txt']),
      );
    });

    test('UNC path with foreign scripts', () {
      final p = PathBuf.fromBytes(
        _w(r'\\сервер\общий\ملف.txt'),
      );

      expect(p.prefix(), isA<UNC>());

      final name = p.fileName();
      expect(name, isNotNull);
      expect(cuStr(name!), 'ملف.txt');
    });

    test('parent() preserves foreign scripts', () {
      final p = PathBuf.fromBytes(
        _w(r'C:\用户\文件夹\文件.txt'),
      );

      final parent = p.parent();
      expect(parent, isNotNull);

      final s = String.fromCharCodes(
        parent!.codeUnits.toTypedData() as Uint16List,
      );

      expect(s, contains('用户'));
      expect(s, contains('文件夹'));
    });

    test('fileStem with Cyrillic', () {
      final p = PathBuf.fromBytes(
        _w(r'C:\данные\документ.txt'),
      );

      final stem = p.fileStem();
      expect(stem, isNotNull);
      expect(cuStr(stem!), 'документ');
    });

    test('extension with Chinese characters', () {
      final p = PathBuf.fromBytes(
        _w(r'C:\数据\文件.tar.gz'),
      );

      final ext = p.extension();
      expect(ext, isNotNull);
      expect(cuStr(ext!), 'gz');
    });

    test('combining characters remain distinct', () {
      const composed = r'C:\tmp\é.txt';
      const decomposed = r'C:\tmp\e\u0301.txt';

      final p1 = PathBuf.fromBytes(_w(composed));
      final p2 = PathBuf.fromBytes(_w(decomposed));

      expect(p1.toStr(), composed);
      expect(p2.toStr(), decomposed);

      expect(p1 == p2, isFalse);
    });

    test('unpaired surrogate inside foreign path', () {
      final wide = Uint16List.fromList([
        ..._w(r'C:\用户\'),
        0xD83D, // invalid
      ]);

      final p = PathBuf.fromBytes(wide);

      expect(p.toStr(), isNull);
      expect(p.toStringLossy(), isNotEmpty);
    });

    test('startsWith / endsWith with foreign scripts', () {
      final p = PathBuf.fromBytes(
        _w(r'C:\用户\данные\ملف.txt'),
      );

      expect(
        p.startsWith(PathBuf.fromStr(r'C:\用户')),
        isTrue,
      );

      expect(
        p.endsWith(PathBuf.fromStr('ملف.txt')),
        isTrue,
      );

      expect(
        p.endsWith(PathBuf.fromStr('данные')),
        isFalse,
      );
    });
  });
}
