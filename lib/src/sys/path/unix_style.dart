import 'dart:typed_data';

import 'package:pathify/src/path_bytes.dart';

/// POSIX path predicates and constants.
///
/// On POSIX systems the only path separator is `/`. There are no path prefix
/// components; the only structural elements are the optional leading `/` and
/// the body components separated by `/`.
class UnixStyle {
  UnixStyle._();

  /// The byte value of the path separator: `/`.
  static const int mainSep = PathBytes.slash;

  /// The path separator as a single-character string: `/`.
  static const String mainSepStr = '/';

  /// POSIX paths have no prefix component.
  static const bool hasPrefixes = false;

  /// True when the value is a path separator.
  static bool isSepByte(int b) => b == PathBytes.slash;

  /// True when the value is a separator inside a verbatim path.
  ///
  /// POSIX has no verbatim distinction; this is identical to [isSepByte].
  static bool isVerbatimSep(int b) => b == PathBytes.slash;

  /// POSIX paths never carry a parsed prefix.
  static Object? parsePrefix(Uint8List _) => null;
}
