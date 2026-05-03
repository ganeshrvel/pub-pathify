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
}
