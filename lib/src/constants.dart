import 'package:pathify/src/path_bytes.dart';

/// Unix path separator constants.
final class UnixPathConstants {
  UnixPathConstants._();

  /// The primary separator of path components for Unix-like systems.
  ///
  /// This is always `/` regardless of the current platform.
  static const int mainSeparator = PathBytes.slash;

  /// The string representation of the primary separator of path components for Unix-like systems.
  ///
  /// This is always "/" regardless of the current platform.
  static const String mainSeparatorStr = '/';
}

/// Windows path separator and prefix constants.
final class WindowsPathConstants {
  WindowsPathConstants._();

  /// The primary separator of path components for Windows systems.
  ///
  /// This is always `\` regardless of the current platform.
  static const int mainSeparator = PathBytes.backslash;

  /// The string representation of the primary separator of path components for Windows systems.
  ///
  /// This is always "\" regardless of the current platform.
  static const String mainSeparatorStr = r'\';

  /// The `VerbatimDisk` prefix for Windows verbatim disk paths.
  ///
  /// Escaped value: "\\\\?\\"
  /// Actual string value: \\?\
  static const String verbatimDiskPrefix =
      '$mainSeparatorStr$mainSeparatorStr?$mainSeparatorStr';

  /// The `DeviceNS` prefix for Windows device namespace paths.
  ///
  /// Escaped value: "\\\\.\\"
  /// Actual string value: \\.\
  static const String deviceNsPrefix =
      '$mainSeparatorStr$mainSeparatorStr.$mainSeparatorStr';

  /// The disk suffix for Windows disk roots with trailing separator.
  ///
  /// Escaped value: ":\\"
  /// Actual string value: :\
  static const String diskSuffix = ':$mainSeparatorStr';

  /// The UNC prefix for Windows UNC paths via verbatim syntax.
  ///
  /// Escaped value: "\\\\?\\UNC\\"
  /// Actual string value: \\?\UNC\
  static const String uncPrefix =
      '$mainSeparatorStr$mainSeparatorStr?${mainSeparatorStr}UNC$mainSeparatorStr';

  /// The standard UNC prefix for Windows UNC paths.
  ///
  /// Escaped value: "\\\\"
  /// Actual string value: \\
  static const String standardUncPrefix = '$mainSeparatorStr$mainSeparatorStr';

  /// The Device Namespace prefix after Windows PathBuf normalization.
  ///
  /// Warning: Only to be used in path validation functions as this is not a normal use case to handle.
  ///
  /// Escaped value: "\\\\.\\\\\\"
  /// Actual string value: \\.\\
  static const String deviceNsPrefixNormalized =
      '$mainSeparatorStr$mainSeparatorStr.$mainSeparatorStr$mainSeparatorStr';

  /// Escaped value: "?\\"
  /// Actual string value: ?\
  static const String verbatimMarker = '?$mainSeparatorStr';

  /// Escaped value: "UNC\\"
  /// Actual string value: UNC\
  static const String uncMarker = 'UNC$mainSeparatorStr';

  /// Escaped value: ".\\"
  /// Actual string value: .\
  static const String deviceNsMarker = '.$mainSeparatorStr';
}
