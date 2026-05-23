// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:typed_data';

import 'package:pathify/pathify.dart';
import 'package:test/test.dart';

void main() {
  group('Basic PathBuf tests', () {
    test('fromStr string conversions stay identical', () {
      final path = PathBuf.fromStr('/tmp/foo/bar.txt');

      expect(path.toString(), '/tmp/foo/bar.txt');
      expect(path.toStringLossy(), '/tmp/foo/bar.txt');
      expect(path.toStr(), '/tmp/foo/bar.txt');

      expect(path.toString(), path.toStringLossy());
      expect(path.toString(), path.toStr());
    });

    test('fromBytes string conversions stay identical', () {
      final path = PathBuf.fromBytes(
        Uint8List.fromList('/tmp/foo/bar.txt'.codeUnits),
      );

      expect(path.toString(), '/tmp/foo/bar.txt');
      expect(path.toStringLossy(), '/tmp/foo/bar.txt');
      expect(path.toStr(), '/tmp/foo/bar.txt');

      expect(path.toString(), path.toStringLossy());
      expect(path.toString(), path.toStr());
    });

    test('real world string interpolation flow', () {
      final path = PathBuf.fromStr('/var/log/system.log');

      final message = 'Opening file: $path';

      expect(
        message,
        'Opening file: /var/log/system.log',
      );
    });
  });
}
