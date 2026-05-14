import 'package:pathify/src/constants.dart';
import 'package:pathify/src/path_bytes.dart';

/// Windows path predicates and constants.
///
/// Windows accepts both `\` and `/` as separators in normal paths. Verbatim
/// paths (those beginning with `\\?\`) recognize only `\` as a separator;
/// `/` inside a verbatim path is a regular filename character.
class WindowsStyle {
  WindowsStyle._();

  /// The code-unit value of the canonical path separator: `\`.
  static const int mainSep = WindowsPaths.mainSeparator;

  /// The canonical path separator as a single-character string: `\`.
  static const String mainSepStr = WindowsPaths.mainSeparatorStr;

  /// Windows paths have prefix components (drive, UNC, verbatim, etc.).
  static const bool hasPrefixes = true;

  /// True when the value is a path separator in a non-verbatim path.
  ///
  /// Both `\` and `/` are recognized.
  static bool isSepByte(int b) =>
      b == PathBytes.backslash || b == PathBytes.slash;

  /// True when the value is a path separator in a verbatim path.
  ///
  /// Only `\` is recognized; `/` is treated as a regular filename character
  /// inside verbatim paths.
  static bool isVerbatimSep(int b) => b == PathBytes.backslash;

  /// True when the path begins with a verbatim prefix (`\\?\` or `\??\`).
  ///
  /// Operates on a code-unit list. Both `Uint8List` and `Uint16List` work
  /// because the relevant characters are ASCII.
  static bool isVerbatim(List<int> path) {
    if (path.length < 4) return false;
    // \\?\
    if (path[0] == PathBytes.backslash &&
        path[1] == PathBytes.backslash &&
        path[2] == PathBytes.question &&
        path[3] == PathBytes.backslash) {
      return true;
    }
    // \??\
    if (path[0] == PathBytes.backslash &&
        path[1] == PathBytes.question &&
        path[2] == PathBytes.question &&
        path[3] == PathBytes.backslash) {
      return true;
    }
    return false;
  }

  /// True when the path contains no separator characters and therefore
  /// represents a single file name.
  static bool isFileName(List<int> path) {
    for (final b in path) {
      if (isSepByte(b)) return false;
    }
    return true;
  }

  /// True when the final character of the path is a separator.
  ///
  /// Verbatim and non-verbatim paths use different separator rules; the
  /// appropriate predicate is selected based on whether the path begins
  /// with `\\?\`.
  static bool hasTrailingSlash(List<int> path) {
    if (path.isEmpty) return false;
    final verbatim =
        path.length >= 4 &&
        path[0] == PathBytes.backslash &&
        path[1] == PathBytes.backslash &&
        path[2] == PathBytes.question &&
        path[3] == PathBytes.backslash;
    final last = path[path.length - 1];
    return verbatim ? isVerbatimSep(last) : isSepByte(last);
  }
}
