import 'package:pathify/src/pathify_platform.dart';
import 'package:test/test.dart';

void main() {
  group('Pathify singleton', () {
    setUp(Pathify.instance.resetForTesting);

    tearDown(Pathify.instance.resetForTesting);

    test('platform falls back to host when not overridden', () {
      Pathify.instance.overriddenPlatform = null;
      expect(Pathify.instance.platform, isA<PathifyPlatform>());
    });

    test('overriddenPlatform takes precedence over host detection', () {
      Pathify.instance.overriddenPlatform = PathifyPlatform.windows;
      expect(Pathify.instance.platform, PathifyPlatform.windows);
      expect(Pathify.instance.isWindows(), isTrue);
      expect(Pathify.instance.isUnix(), isFalse);
    });

    test('isUnix is true for every non-Windows override', () {
      for (final platform in PathifyPlatform.values) {
        Pathify.instance.overriddenPlatform = platform;
        if (platform == PathifyPlatform.windows) {
          expect(Pathify.instance.isUnix(), isFalse);
          expect(Pathify.instance.isPosix(), isFalse);
        } else {
          expect(Pathify.instance.isUnix(), isTrue);
          expect(Pathify.instance.isPosix(), isTrue);
        }
      }
    });

    test('individual platform predicates match the override', () {
      Pathify.instance.overriddenPlatform = PathifyPlatform.macOS;
      expect(Pathify.instance.isMacOS(), isTrue);
      expect(Pathify.instance.isLinux(), isFalse);
      expect(Pathify.instance.isWindows(), isFalse);

      Pathify.instance.overriddenPlatform = PathifyPlatform.android;
      expect(Pathify.instance.isAndroid(), isTrue);
      expect(Pathify.instance.isIOS(), isFalse);
    });

    test('resetForTesting clears the override', () {
      Pathify.instance.overriddenPlatform = PathifyPlatform.windows;
      expect(Pathify.instance.overriddenPlatform, isNotNull);
      Pathify.instance.resetForTesting();
      expect(Pathify.instance.overriddenPlatform, isNull);
    });
  });
}
