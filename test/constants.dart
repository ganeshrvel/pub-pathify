import 'package:pathify/src/constants.dart';
import 'package:test/test.dart';

void main() {
  group('UnixPaths', () {
    test('mainSeparator is 0x2F', () {
      expect(UnixPaths.mainSeparator, equals(0x2F));
    });

    test('mainSeparatorStr is /', () {
      expect(UnixPaths.mainSeparatorStr, equals('/'));
    });

    test('mainSeparator matches mainSeparatorStr code unit', () {
      expect(
        UnixPaths.mainSeparatorStr.codeUnitAt(0),
        equals(UnixPaths.mainSeparator),
      );
    });
  });

  group('WindowsPaths', () {
    test('mainSeparator is 0x5C', () {
      expect(WindowsPaths.mainSeparator, equals(0x5C));
    });

    test('mainSeparatorStr is backslash', () {
      expect(WindowsPaths.mainSeparatorStr, equals(r'\'));
    });

    test('mainSeparator matches mainSeparatorStr code unit', () {
      expect(
        WindowsPaths.mainSeparatorStr.codeUnitAt(0),
        equals(WindowsPaths.mainSeparator),
      );
    });

    test(r'verbatimDiskPrefix actual string value is \\?\', () {
      // Escaped value: "\\\\?\\"
      // Actual string value: \\?\
      expect(WindowsPaths.verbatimDiskPrefix, equals(r'\\?\'));
    });

    test('verbatimDiskPrefix length is 4', () {
      expect(WindowsPaths.verbatimDiskPrefix.length, equals(4));
    });

    test(r'deviceNsPrefix actual string value is \\.\', () {
      // Escaped value: "\\\\.\\"
      // Actual string value: \\.\
      expect(WindowsPaths.deviceNsPrefix, equals(r'\\.\'));
    });

    test('deviceNsPrefix length is 4', () {
      expect(WindowsPaths.deviceNsPrefix.length, equals(4));
    });

    test(r'diskSuffix actual string value is :\', () {
      // Escaped value: ":\\"
      // Actual string value: :\
      expect(WindowsPaths.diskSuffix, equals(r':\'));
    });

    test('diskSuffix length is 2', () {
      expect(WindowsPaths.diskSuffix.length, equals(2));
    });

    test(r'uncPrefix actual string value is \\?\UNC\', () {
      // Escaped value: "\\\\?\\UNC\\"
      // Actual string value: \\?\UNC\
      expect(WindowsPaths.uncPrefix, equals(r'\\?\UNC\'));
    });

    test('uncPrefix length is 8', () {
      expect(WindowsPaths.uncPrefix.length, equals(8));
    });

    test(r'standardUncPrefix actual string value is \\', () {
      // Escaped value: "\\\\"
      // Actual string value: \\
      expect(WindowsPaths.standardUncPrefix, equals(r'\\'));
    });

    test('standardUncPrefix length is 2', () {
      expect(WindowsPaths.standardUncPrefix.length, equals(2));
    });

    test(r'deviceNsPrefixNormalized actual string value is \\.\\', () {
      // Escaped value: "\\\\.\\\\\\"
      // Actual string value: \\.\\
      expect(WindowsPaths.deviceNsPrefixNormalized, equals(r'\\.\\'));
    });

    test('deviceNsPrefixNormalized length is 5', () {
      expect(WindowsPaths.deviceNsPrefixNormalized.length, equals(5));
    });

    test(r'verbatimMarker actual string value is ?\', () {
      // Escaped value: "?\\"
      // Actual string value: ?\
      expect(WindowsPaths.verbatimMarker, equals(r'?\'));
    });

    test('verbatimMarker length is 2', () {
      expect(WindowsPaths.verbatimMarker.length, equals(2));
    });

    test(r'uncMarker actual string value is UNC\', () {
      // Escaped value: "UNC\\"
      // Actual string value: UNC\
      expect(WindowsPaths.uncMarker, equals(r'UNC\'));
    });

    test('uncMarker length is 4', () {
      expect(WindowsPaths.uncMarker.length, equals(4));
    });

    test(r'deviceNsMarker actual string value is .\', () {
      // Escaped value: ".\\"
      // Actual string value: .\
      expect(WindowsPaths.deviceNsMarker, equals(r'.\'));
    });

    test('deviceNsMarker length is 2', () {
      expect(WindowsPaths.deviceNsMarker.length, equals(2));
    });
  });

  group('composition correctness', () {
    test(r'verbatimDiskPrefix is composed of \\ + ? + \', () {
      // Escaped value: "\\\\?\\"
      // Actual string value: \\?\
      expect(WindowsPaths.verbatimDiskPrefix, equals(r'\\?\'));
    });

    test(r'deviceNsPrefix is composed of \\ + . + \', () {
      // Escaped value: "\\\\.\\"
      // Actual string value: \\.\
      expect(WindowsPaths.deviceNsPrefix, equals(r'\\.\'));
    });

    test(r'uncPrefix is composed of \\ + ? + \ + UNC + \', () {
      // Escaped value: "\\\\?\\UNC\\"
      // Actual string value: \\?\UNC\
      expect(WindowsPaths.uncPrefix, equals(r'\\?\UNC\'));
    });

    test(r'deviceNsPrefixNormalized is composed of \\ + . + \ + \', () {
      // Escaped value: "\\\\.\\\\\\"
      // Actual string value: \\.\\
      expect(
        WindowsPaths.deviceNsPrefixNormalized,
        equals(r'\\.\\'),
      );
    });

    test(r'standardUncPrefix is composed of \\ + \\', () {
      // Escaped value: "\\\\"
      // Actual string value: \\
      expect(WindowsPaths.standardUncPrefix, equals(r'\\'));
    });

    test(r'diskSuffix is composed of : + \', () {
      // Escaped value: ":\\"
      // Actual string value: :\
      expect(WindowsPaths.diskSuffix, equals(r':\'));
    });

    test(r'verbatimMarker is composed of ? + \', () {
      // Escaped value: "?\\"
      // Actual string value: ?\
      expect(WindowsPaths.verbatimMarker, equals(r'?\'));
    });

    test(r'uncMarker is composed of UNC + \', () {
      // Escaped value: "UNC\\"
      // Actual string value: UNC\
      expect(WindowsPaths.uncMarker, equals(r'UNC\'));
    });

    test(r'deviceNsMarker is composed of . + \', () {
      // Escaped value: ".\\"
      // Actual string value: .\
      expect(WindowsPaths.deviceNsMarker, equals(r'.\'));
    });

    test(
      'verbatimDiskPrefix is composed of standardUncPrefix + verbatimMarker',
      () {
        expect(
          WindowsPaths.verbatimDiskPrefix,
          equals(
            WindowsPaths.standardUncPrefix +
                WindowsPaths.verbatimMarker,
          ),
        );
      },
    );

    test(
      'deviceNsPrefix is composed of standardUncPrefix + deviceNsMarker',
      () {
        expect(
          WindowsPaths.deviceNsPrefix,
          equals(
            WindowsPaths.standardUncPrefix +
                WindowsPaths.deviceNsMarker,
          ),
        );
      },
    );

    test('uncPrefix is composed of verbatimDiskPrefix + uncMarker', () {
      expect(
        WindowsPaths.uncPrefix,
        equals(
          WindowsPaths.verbatimDiskPrefix +
              WindowsPaths.uncMarker,
        ),
      );
    });

    test(
      'deviceNsPrefixNormalized is composed of deviceNsPrefix + mainSeparatorStr',
      () {
        expect(
          WindowsPaths.deviceNsPrefixNormalized,
          equals(
            WindowsPaths.deviceNsPrefix +
                WindowsPaths.mainSeparatorStr,
          ),
        );
      },
    );

    test('diskSuffix starts with colon and ends with mainSeparatorStr', () {
      expect(WindowsPaths.diskSuffix[0], equals(':'));
      expect(
        WindowsPaths.diskSuffix[1],
        equals(WindowsPaths.mainSeparatorStr),
      );
    });
  });
}
