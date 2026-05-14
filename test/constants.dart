import 'package:pathify/src/constants.dart';
import 'package:test/test.dart';

void main() {
  group('UnixPathConstants', () {
    test('mainSeparator is 0x2F', () {
      expect(UnixPathConstants.mainSeparator, equals(0x2F));
    });

    test('mainSeparatorStr is /', () {
      expect(UnixPathConstants.mainSeparatorStr, equals('/'));
    });

    test('mainSeparator matches mainSeparatorStr code unit', () {
      expect(
        UnixPathConstants.mainSeparatorStr.codeUnitAt(0),
        equals(UnixPathConstants.mainSeparator),
      );
    });
  });

  group('WindowsPathConstants', () {
    test('mainSeparator is 0x5C', () {
      expect(WindowsPathConstants.mainSeparator, equals(0x5C));
    });

    test('mainSeparatorStr is backslash', () {
      expect(WindowsPathConstants.mainSeparatorStr, equals(r'\'));
    });

    test('mainSeparator matches mainSeparatorStr code unit', () {
      expect(
        WindowsPathConstants.mainSeparatorStr.codeUnitAt(0),
        equals(WindowsPathConstants.mainSeparator),
      );
    });

    test(r'verbatimDiskPrefix actual string value is \\?\', () {
      // Escaped value: "\\\\?\\"
      // Actual string value: \\?\
      expect(WindowsPathConstants.verbatimDiskPrefix, equals(r'\\?\'));
    });

    test('verbatimDiskPrefix length is 4', () {
      expect(WindowsPathConstants.verbatimDiskPrefix.length, equals(4));
    });

    test(r'deviceNsPrefix actual string value is \\.\', () {
      // Escaped value: "\\\\.\\"
      // Actual string value: \\.\
      expect(WindowsPathConstants.deviceNsPrefix, equals(r'\\.\'));
    });

    test('deviceNsPrefix length is 4', () {
      expect(WindowsPathConstants.deviceNsPrefix.length, equals(4));
    });

    test(r'diskSuffix actual string value is :\', () {
      // Escaped value: ":\\"
      // Actual string value: :\
      expect(WindowsPathConstants.diskSuffix, equals(r':\'));
    });

    test('diskSuffix length is 2', () {
      expect(WindowsPathConstants.diskSuffix.length, equals(2));
    });

    test(r'uncPrefix actual string value is \\?\UNC\', () {
      // Escaped value: "\\\\?\\UNC\\"
      // Actual string value: \\?\UNC\
      expect(WindowsPathConstants.uncPrefix, equals(r'\\?\UNC\'));
    });

    test('uncPrefix length is 8', () {
      expect(WindowsPathConstants.uncPrefix.length, equals(8));
    });

    test(r'standardUncPrefix actual string value is \\', () {
      // Escaped value: "\\\\"
      // Actual string value: \\
      expect(WindowsPathConstants.standardUncPrefix, equals(r'\\'));
    });

    test('standardUncPrefix length is 2', () {
      expect(WindowsPathConstants.standardUncPrefix.length, equals(2));
    });

    test(r'deviceNsPrefixNormalized actual string value is \\.\\', () {
      // Escaped value: "\\\\.\\\\\\"
      // Actual string value: \\.\\
      expect(WindowsPathConstants.deviceNsPrefixNormalized, equals(r'\\.\\'));
    });

    test('deviceNsPrefixNormalized length is 5', () {
      expect(WindowsPathConstants.deviceNsPrefixNormalized.length, equals(5));
    });

    test(r'verbatimMarker actual string value is ?\', () {
      // Escaped value: "?\\"
      // Actual string value: ?\
      expect(WindowsPathConstants.verbatimMarker, equals(r'?\'));
    });

    test('verbatimMarker length is 2', () {
      expect(WindowsPathConstants.verbatimMarker.length, equals(2));
    });

    test(r'uncMarker actual string value is UNC\', () {
      // Escaped value: "UNC\\"
      // Actual string value: UNC\
      expect(WindowsPathConstants.uncMarker, equals(r'UNC\'));
    });

    test('uncMarker length is 4', () {
      expect(WindowsPathConstants.uncMarker.length, equals(4));
    });

    test(r'deviceNsMarker actual string value is .\', () {
      // Escaped value: ".\\"
      // Actual string value: .\
      expect(WindowsPathConstants.deviceNsMarker, equals(r'.\'));
    });

    test('deviceNsMarker length is 2', () {
      expect(WindowsPathConstants.deviceNsMarker.length, equals(2));
    });
  });

  group('composition correctness', () {
    test(r'verbatimDiskPrefix is composed of \\ + ? + \', () {
      // Escaped value: "\\\\?\\"
      // Actual string value: \\?\
      expect(WindowsPathConstants.verbatimDiskPrefix, equals(r'\\?\'));
    });

    test(r'deviceNsPrefix is composed of \\ + . + \', () {
      // Escaped value: "\\\\.\\"
      // Actual string value: \\.\
      expect(WindowsPathConstants.deviceNsPrefix, equals(r'\\.\'));
    });

    test(r'uncPrefix is composed of \\ + ? + \ + UNC + \', () {
      // Escaped value: "\\\\?\\UNC\\"
      // Actual string value: \\?\UNC\
      expect(WindowsPathConstants.uncPrefix, equals(r'\\?\UNC\'));
    });

    test(r'deviceNsPrefixNormalized is composed of \\ + . + \ + \', () {
      // Escaped value: "\\\\.\\\\\\"
      // Actual string value: \\.\\
      expect(
        WindowsPathConstants.deviceNsPrefixNormalized,
        equals(r'\\.\\'),
      );
    });

    test(r'standardUncPrefix is composed of \\ + \\', () {
      // Escaped value: "\\\\"
      // Actual string value: \\
      expect(WindowsPathConstants.standardUncPrefix, equals(r'\\'));
    });

    test(r'diskSuffix is composed of : + \', () {
      // Escaped value: ":\\"
      // Actual string value: :\
      expect(WindowsPathConstants.diskSuffix, equals(r':\'));
    });

    test(r'verbatimMarker is composed of ? + \', () {
      // Escaped value: "?\\"
      // Actual string value: ?\
      expect(WindowsPathConstants.verbatimMarker, equals(r'?\'));
    });

    test(r'uncMarker is composed of UNC + \', () {
      // Escaped value: "UNC\\"
      // Actual string value: UNC\
      expect(WindowsPathConstants.uncMarker, equals(r'UNC\'));
    });

    test(r'deviceNsMarker is composed of . + \', () {
      // Escaped value: ".\\"
      // Actual string value: .\
      expect(WindowsPathConstants.deviceNsMarker, equals(r'.\'));
    });

    test(
      'verbatimDiskPrefix is composed of standardUncPrefix + verbatimMarker',
      () {
        expect(
          WindowsPathConstants.verbatimDiskPrefix,
          equals(
            WindowsPathConstants.standardUncPrefix +
                WindowsPathConstants.verbatimMarker,
          ),
        );
      },
    );

    test(
      'deviceNsPrefix is composed of standardUncPrefix + deviceNsMarker',
      () {
        expect(
          WindowsPathConstants.deviceNsPrefix,
          equals(
            WindowsPathConstants.standardUncPrefix +
                WindowsPathConstants.deviceNsMarker,
          ),
        );
      },
    );

    test('uncPrefix is composed of verbatimDiskPrefix + uncMarker', () {
      expect(
        WindowsPathConstants.uncPrefix,
        equals(
          WindowsPathConstants.verbatimDiskPrefix +
              WindowsPathConstants.uncMarker,
        ),
      );
    });

    test(
      'deviceNsPrefixNormalized is composed of deviceNsPrefix + mainSeparatorStr',
      () {
        expect(
          WindowsPathConstants.deviceNsPrefixNormalized,
          equals(
            WindowsPathConstants.deviceNsPrefix +
                WindowsPathConstants.mainSeparatorStr,
          ),
        );
      },
    );

    test('diskSuffix starts with colon and ends with mainSeparatorStr', () {
      expect(WindowsPathConstants.diskSuffix[0], equals(':'));
      expect(
        WindowsPathConstants.diskSuffix[1],
        equals(WindowsPathConstants.mainSeparatorStr),
      );
    });
  });
}
